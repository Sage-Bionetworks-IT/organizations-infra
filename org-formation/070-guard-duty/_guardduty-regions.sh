#!/usr/bin/env bash
#
# Shared helper, sourced by enable-delegated-admin.sh and configure-org-auto-enable.sh.
# Reads the guardDutyRegions parameter from _tasks.yaml so the region list has a single
# source of truth.
#
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/_guardduty-regions.sh"
#   load_guardduty_regions   # populates the REGIONS array
#
# Requires python3 with PyYAML. Set GUARDDUTY_TASKS_FILE to read a different file.

load_guardduty_regions() {
  local tasks_file="${GUARDDUTY_TASKS_FILE:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_tasks.yaml}"
  local output region

  if ! output=$(python3 - "${tasks_file}" <<'PY'
import sys

try:
    import yaml
except ImportError:
    sys.exit("ERROR: PyYAML is required (pip3 install pyyaml).")


class Loader(yaml.SafeLoader):
    # `<<: !Include ...` merges another file into Parameters. PyYAML requires merge
    # values to be mappings, and the included file isn't needed here, so replace those
    # merge values with an empty mapping.
    def flatten_mapping(self, node):
        node.value = [
            (k, yaml.MappingNode("tag:yaml.org,2002:map", []))
            if k.tag == "tag:yaml.org,2002:merge" and v.tag == "!Include" else (k, v)
            for k, v in node.value
        ]
        super().flatten_mapping(node)


# Treat other org-formation tags (!Ref, !Sub, !CopyValue, ...) as plain values.
def ignore_tag(loader, suffix, node):
    if isinstance(node, yaml.ScalarNode):
        return loader.construct_scalar(node)
    if isinstance(node, yaml.SequenceNode):
        return loader.construct_sequence(node)
    return loader.construct_mapping(node)


Loader.add_multi_constructor("!", ignore_tag)

path = sys.argv[1]
try:
    with open(path) as f:
        doc = yaml.load(f, Loader=Loader)
except (OSError, yaml.YAMLError) as e:
    sys.exit(f"ERROR: Could not read {path}: {e}")

try:
    regions = doc["Parameters"]["guardDutyRegions"]["Default"]
except (KeyError, TypeError):
    sys.exit(f"ERROR: Parameters.guardDutyRegions.Default not found in {path}.")

if not isinstance(regions, list) or not regions or not all(isinstance(r, str) and r for r in regions):
    sys.exit(f"ERROR: Parameters.guardDutyRegions.Default in {path} must be a non-empty list of region names.")

print("\n".join(regions))
PY
  ); then
    echo "ERROR: Failed to load guardDutyRegions from ${tasks_file}." >&2
    return 1
  fi

  REGIONS=()
  while IFS= read -r region; do
    REGIONS+=("${region}")
  done <<< "${output}"
}
