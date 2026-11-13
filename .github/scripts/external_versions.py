#!/usr/bin/env python3
"""Find and update outdated versioned references to externally published templates.

Recognized references:
  * raw GitHub URLs pinned to a tag, e.g.
    https://raw.githubusercontent.com/Sage-Bionetworks/aws-infra/v0.7.6/templates/IAM/oidc-provider.yaml
  * S3 URLs to templates published by aws-infra and the Sage-Bionetworks-IT lambda/macro/custom
    resource repos, e.g.
    https://${AdminCentralCfnBucket}.s3.amazonaws.com/lambda-ebs-cleanup/1.0.4/lambda-ebs-cleanup.yaml

The latest version is the highest semver tag of the source repo whose copy of the referenced file
actually exists, so a reference is never moved to a release that dropped or relocated the file.
References are never downgraded.

A reference is reported as an alert when the newest release of its repo no longer contains the
referenced file (it was moved or removed), along with any files of the same name in that release.

S3 URLs whose repo segment is a template variable (e.g. the Service Catalog product histories
using `{{stack_group_config.service_catalog_library}}`) are deliberately not matched.

Updates are grouped into one PR per deployment unit: each org-formation stage directory
(org-formation/<stage>/) and each sceptre environment (sceptre/<account>/config/<env>/), so that
e.g. develop and prod are updated separately.

Usage:
  external_versions.py scan [--alerts-file F]  # print a JSON list of groups with available updates,
                                               # and write moved/removed file alerts to F as markdown
  external_versions.py update [--alerts-file F] FILE...
                                               # update FILEs in place, print a PR body, and write
                                               # moved/removed file alerts to F as markdown
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from functools import cache

# Directories to scan, mapped to the number of path components that make up a group
SCAN_DIRS = {"org-formation": 2, "sceptre": 4}
SCAN_SUFFIXES = (".yaml", ".yml", ".j2", ".json")

# GitHub owners to search, in order, for the repo that publishes an S3-hosted template
GITHUB_OWNERS = ["Sage-Bionetworks-IT", "Sage-Bionetworks"]

# Template variables used in place of the bucket name, mapped to the real bucket
# (see org-formation/_parameters.yaml and sceptre/*/config/config.yaml)
BUCKET_VARIABLES = {
    "${AdminCentralCfnBucket}": "bootstrap-awss3cloudformationbucket-19qromfd235z9",
    "{{stack_group_config.admincentral_cf_bucket}}": "bootstrap-awss3cloudformationbucket-19qromfd235z9",
}

# Repo directory that each repo publishes to S3, for repos whose S3 templates are copied from the
# repo tree (lambda repos publish a built template instead)
S3_TREE_PREFIXES = {"aws-infra": "templates/"}

VERSION = r"v?\d+\.\d+\.\d+"
PATH = r"[^\s'\"]+"

RAW_GITHUB_RE = re.compile(
    r"https://raw\.githubusercontent\.com/"
    r"(?P<owner>[\w.-]+)/(?P<repo>[\w.-]+)/"
    rf"(?P<version>{VERSION})/(?P<path>{PATH})"
)
S3_RE = re.compile(
    r"https://(?P<bucket>[^/\s'\"]+)\.s3(?P<region>\.[a-z0-9-]+)?\.amazonaws\.com/"
    rf"(?P<repo>[\w-]+)/(?P<version>{VERSION})/(?P<path>{PATH})"
)


def parse_version(version):
    return tuple(int(part) for part in version.lstrip("v").split("."))


@cache
def repo_tags(owner, repo):
    """Return the release tags (vX.Y.Z or X.Y.Z) of a public GitHub repo, newest first."""
    result = subprocess.run(
        ["git", "ls-remote", "--tags", "--refs", f"https://github.com/{owner}/{repo}.git"],
        capture_output=True,
        text=True,
        env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
    )
    if result.returncode != 0:
        return []
    tags = [line.rsplit("/", 1)[-1] for line in result.stdout.splitlines()]
    tags = [tag for tag in tags if re.fullmatch(VERSION, tag)]
    return sorted(tags, key=parse_version, reverse=True)


@cache
def find_repo(repo):
    """Return (owner, tags) for the first GitHub owner that has tagged releases of repo."""
    for owner in GITHUB_OWNERS:
        tags = repo_tags(owner, repo)
        if tags:
            return owner, tags
    return None, []


@cache
def url_exists(url):
    request = urllib.request.Request(url, method="HEAD")
    try:
        with urllib.request.urlopen(request, timeout=30):
            return True
    except urllib.error.HTTPError as error:
        if error.code in (403, 404):
            return False
        raise


@cache
def repo_files(owner, repo, tag):
    """Return the file paths in a tag of a public GitHub repo, without fetching file contents."""
    with tempfile.TemporaryDirectory() as clone:
        git = ["git", "-c", "advice.detachedHead=false"]
        url = f"https://github.com/{owner}/{repo}.git"
        options = ["--quiet", "--depth", "1", "--filter=blob:none", "--no-checkout", "--branch", tag]
        env = {**os.environ, "GIT_TERMINAL_PROMPT": "0"}
        if subprocess.run(git + ["clone", *options, url, clone], capture_output=True, env=env).returncode:
            return []
        result = subprocess.run(
            git + ["-C", clone, "ls-tree", "-r", "--name-only", "HEAD"], capture_output=True, text=True
        )
        return result.stdout.splitlines()


def same_name_files(owner, repo, tag, path):
    """Return the files in tag with the same name as path, ignoring the extension."""
    stem = os.path.splitext(os.path.basename(path))[0]
    return [f for f in repo_files(owner, repo, tag) if os.path.splitext(os.path.basename(f))[0] == stem]


def latest_version(current, tags, url_for):
    """Return the newest tag above current whose url_for(tag) exists, or None."""
    has_prefix = current.startswith("v")
    for tag in tags:
        if parse_version(tag) <= parse_version(current):
            break
        if tag.startswith("v") != has_prefix:
            continue
        if url_exists(url_for(tag)):
            return tag
    return None


def newest_version(current, tags):
    """Return the newest tag with the same v-prefix style as current."""
    return next((tag for tag in tags if tag.startswith("v") == current.startswith("v")), None)


def check_reference(match, owner, repo, tags, url_for, tree_path):
    """Return (update, alert) for one reference; either may be None.

    tree_path is the referenced file's path in the repo, or None if it isn't in the repo tree.
    """
    version = match.group("version")
    newest = newest_version(version, tags)
    if not newest or parse_version(newest) <= parse_version(version):
        return None, None

    new = latest_version(version, tags, url_for)
    info = dict(match=match, owner=owner, repo=repo, old=version, new=new)
    update = info if new else None
    alert = None
    if new != newest:
        suggestions = same_name_files(owner, repo, newest, tree_path) if tree_path else []
        alert = dict(info, newest=newest, path=tree_path or match.group("path"), suggestions=suggestions)
    return update, alert


def find_references(text):
    """Return (updates, alerts) for the references in text."""
    updates, alerts = [], []

    def add(update, alert):
        if update:
            updates.append(update)
        if alert:
            alerts.append(alert)

    for match in RAW_GITHUB_RE.finditer(text):
        owner, repo, path = match.group("owner", "repo", "path")
        add(*check_reference(
            match,
            owner,
            repo,
            repo_tags(owner, repo),
            lambda tag: f"https://raw.githubusercontent.com/{owner}/{repo}/{tag}/{path}",
            path,
        ))

    for match in S3_RE.finditer(text):
        bucket, region, repo, path = match.group("bucket", "region", "repo", "path")
        bucket = BUCKET_VARIABLES.get(bucket, bucket)
        if not re.fullmatch(r"[a-z0-9.-]+", bucket):
            continue  # unresolved template variable
        owner, tags = find_repo(repo)
        prefix = S3_TREE_PREFIXES.get(repo)
        add(*check_reference(
            match,
            owner,
            repo,
            tags,
            lambda tag: f"https://{bucket}.s3{region or ''}.amazonaws.com/{repo}/{tag}/{path}",
            prefix + path if prefix is not None else None,
        ))

    return updates, alerts


def apply_updates(text, updates):
    """Replace the version segment of each updated reference, leaving everything else alone."""
    for update in sorted(updates, key=lambda u: u["match"].start("version"), reverse=True):
        start, end = update["match"].span("version")
        text = text[:start] + update["new"] + text[end:]
    return text


def candidate_files():
    for scan_dir in SCAN_DIRS:
        for root, _, files in os.walk(scan_dir):
            for name in sorted(files):
                if name.endswith(SCAN_SUFFIXES):
                    yield os.path.join(root, name)


def group_of(path):
    """Return the group directory of path, or its parent directory if it is shallower than that."""
    parts = path.split("/")
    depth = SCAN_DIRS[parts[0]]
    return "/".join(parts[:min(depth, len(parts) - 1)])


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def summarize(updates):
    """Return the distinct (owner, repo, old, new) bumps in updates, in a stable order."""
    bumps = {(u["owner"], u["repo"], u["old"], u["new"]) for u in updates}
    return sorted(bumps, key=lambda b: (b[1], parse_version(b[2])))


def line_number(text, match):
    return text.count("\n", 0, match.start()) + 1


def location_link(path, lines):
    """Return path and line numbers, linked to the first line on GitHub when run in Actions."""
    shown = ", ".join(map(str, lines[:5])) + (f" and {len(lines) - 5} more" if len(lines) > 5 else "")
    label = f"`{path}` line{'s' if len(lines) > 1 else ''} {shown}"
    if not os.environ.get("GITHUB_REPOSITORY"):
        return label
    server, repo, sha = (os.environ.get(k) for k in ("GITHUB_SERVER_URL", "GITHUB_REPOSITORY", "GITHUB_SHA"))
    return f"[{label}]({server}/{repo}/blob/{sha}/{path}#L{lines[0]})"


def alerts_table(alerts):
    """Return markdown lines describing references whose file is missing from the newest release.

    Identical references in the same file are combined into one row.
    """
    rows = {}
    for alert in alerts:
        key = (alert["file"], alert["owner"], alert["repo"], alert["path"], alert["old"])
        rows.setdefault(key, dict(alert, lines=[]))["lines"].append(alert["line"])

    lines = [
        "| Location | Referenced file | Pinned | Newest with file | Newest release | Same name in newest release |",
        "|---|---|---|---|---|---|",
    ]
    for row in rows.values():
        suggestions = "<br>".join(f"`{f}`" for f in row["suggestions"]) or "none found"
        lines.append(
            f"| {location_link(row['file'], row['lines'])} | {row['owner']}/{row['repo']} `{row['path']}` "
            f"| {row['old']} | {row['new'] or 'none'} | {row['newest']} | {suggestions} |"
        )
    return lines


def write_alerts(path, alerts):
    """Write alerts to path as markdown, or leave path empty if there are none."""
    if not path:
        return
    lines = [
        "### Moved or removed files",
        "",
        "These references can't be updated to the newest release of their source repo because it no",
        "longer has the referenced file. Update them by hand, e.g. to a file of the same name in the",
        "newest release.",
        "",
        *alerts_table(alerts),
    ]
    with open(path, "w", encoding="utf-8") as f:
        if alerts:
            f.write("\n".join(lines) + "\n")


def check_files(paths):
    """Return (updates, alerts) by file, with each alert's file and line filled in."""
    updates, alerts = {}, []
    for path in paths:
        text = read(path)
        file_updates, file_alerts = find_references(text)
        if file_updates:
            updates[path] = (text, file_updates)
        for alert in file_alerts:
            alerts.append(dict(alert, file=path, line=line_number(text, alert["match"])))
    return updates, alerts


def scan(args):
    updates, alerts = check_files(sorted(candidate_files()))

    groups = {}
    for path, (_, file_updates) in updates.items():
        group = groups.setdefault(group_of(path), {"files": [], "updates": []})
        group["files"].append(path)
        group["updates"] += file_updates
        for owner, repo, old, new in summarize(file_updates):
            print(f"{path}: {repo} {old} -> {new}", file=sys.stderr)
    for alert in alerts:
        print(f"{alert['file']}:{alert['line']}: {alert['repo']} {alert['old']} {alert['path']} "
              f"is not in {alert['newest']}", file=sys.stderr)

    write_alerts(args.alerts_file, alerts)

    results = [
        {
            "group": name,
            "files": group["files"],
            "branch": f"external-versions/{name}",
            "title": pr_title(name, summarize(group["updates"])),
        }
        for name, group in sorted(groups.items())
    ]
    print(json.dumps(results))


def pr_title(group, bumps):
    if len(bumps) == 1:
        _, repo, old, new = bumps[0]
        return f"Bump {repo} from {old} to {new} in {group}"
    return f"Bump external template versions in {group}"


def update(args):
    updates, alerts = check_files(args.files)
    if not updates:
        print("No updates found", file=sys.stderr)
        return
    all_updates = []
    for path, (text, file_updates) in updates.items():
        with open(path, "w", encoding="utf-8") as f:
            f.write(apply_updates(text, file_updates))
        all_updates += file_updates

    lines = ["Updates external template references:", ""]
    lines.append("| Repo | From | To | Changes |")
    lines.append("|---|---|---|---|")
    for owner, repo, old, new in summarize(all_updates):
        compare = f"https://github.com/{owner}/{repo}/compare/{old}...{new}"
        lines.append(f"| {owner}/{repo} | {old} | {new} | [compare]({compare}) |")
    lines += ["", "Files changed:", ""]
    lines += [f"- `{path}`" for path in updates]
    lines += [
        "",
        "Each reference was moved to the newest release that still publishes the referenced file.",
        "Review the changes for new or renamed template parameters before merging.",
    ]
    lines += ["", "Created automatically by the `external-versions` workflow."]
    print("\n".join(lines))
    write_alerts(args.alerts_file, alerts)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    subparsers = parser.add_subparsers(required=True)
    scan_parser = subparsers.add_parser("scan")
    scan_parser.add_argument("--alerts-file", help="write moved/removed file alerts here as markdown")
    scan_parser.set_defaults(func=scan)
    update_parser = subparsers.add_parser("update")
    update_parser.add_argument("--alerts-file", help="write moved/removed file alerts here as markdown")
    update_parser.add_argument("files", nargs="+")
    update_parser.set_defaults(func=update)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
