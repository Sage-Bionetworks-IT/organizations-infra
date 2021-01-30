#! /usr/bin/env python3

# Run `manage_ec2.py --help` for commands and available parameters

"""Manage EC2 Instances
"""

import argparse
import boto3
import sys


def parse_args():
    parser = argparse.ArgumentParser(
        description=__doc__)
    parser.add_argument(
        'synapse_id',
        help='The ID of the Synapse user who provisioned the instances to be managed')
    parser.add_argument(
        '-y', '--yes',
        action='store_true',
        help='Skip verification prompts')
    parser.add_argument(
        '-s', '--stop',
        action='store_true',
        help='Stop instances')
    parser.add_argument(
        '-p', '--profile',
        help='Name of AWS profile in the local config file')
    return parser.parse_args()

def get_instances(session, synapse_id):
    """Get all active instances owned by synapse user"""
    client = session.client('ec2')

    response = client.describe_instances(
        Filters=[
            {
                'Name': 'tag-key',
                'Values': [
                    'aws:servicecatalog:provisioningPrincipalArn'
                ]
            },
            {
                'Name': 'tag-value',
                'Values': [
                    f'arn:aws:sts::*:assumed-role/*/{synapse_id}'
                ]
            },
        ],
    )

    ACTIVE_STATUS = ['pending', 'running']
    active_instances = []
    for reservation in response['Reservations']:
        instances = reservation['Instances']
        for instance in instances:
            instance_state = instance['State']['Name']
            if instance_state in ACTIVE_STATUS:
                active_instances.append(instance['InstanceId'])

    return active_instances

def stop_instances(session, instances):
    """Stops all instances"""
    client = session.client('ec2')

    if instances:
        response = client.stop_instances(
            InstanceIds=instances
        )


def main():
    args = parse_args()
    synapse_id = args.synapse_id
    session = boto3.Session(profile_name=args.profile)

    instances = get_instances(session, synapse_id)
    print("Instances for synapse user "
          f'{synapse_id}'
          " : "
          f'{instances}')

    if args.stop:
        if not args.yes:
            verify = input('Confirm that you want to stop all instances (y/n): ')
            if verify is not 'y' and verify is not 'Y':
                print('Exiting')
                sys.exit()
        print("All instances stopped")
        stop_instances(session, instances)

if __name__ == "__main__":
    main()
