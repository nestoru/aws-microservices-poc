#!/bin/bash

# Check if all arguments are provided
if [ $# -lt 3 ]; then
    echo "Error: Missing arguments."
    echo "Usage: $0 <ALB_ADDRESS> <DOMAIN_NAME> <HOSTED_ZONE_NAME>"
    exit 1
fi

# Assigning passed arguments to variables
ALB_ADDRESS=$1
DOMAIN_NAME=$2
HOSTED_ZONE_NAME=$3

# Ensure HOSTED_ZONE_NAME ends with a dot
if [[ "${HOSTED_ZONE_NAME: -1}" != "." ]]; then
    HOSTED_ZONE_NAME="${HOSTED_ZONE_NAME}."
fi

# Dynamically find the Hosted Zone ID for the given domain name
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='${HOSTED_ZONE_NAME}'].Id" --output text | sed 's/\/hostedzone\///')

if [ -z "$HOSTED_ZONE_ID" ]; then
    echo "Error finding Hosted Zone ID for ${HOSTED_ZONE_NAME}"
    exit 1
fi

# Find the ALB's Hosted Zone ID using its address
ALB_HOSTED_ZONE_ID=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?DNSName=='${ALB_ADDRESS}'].CanonicalHostedZoneId" --output text)

if [ -z "$ALB_HOSTED_ZONE_ID" ]; then
    echo "Error finding ALB Hosted Zone ID for ${ALB_ADDRESS}"
    exit 1
fi

# Prepare the JSON for Route 53 ChangeBatch for DELETE action
JSON_CHANGE_BATCH=$(cat <<EOF
{
    "Comment": "Remove record pointing to ALB",
    "Changes": [
        {
            "Action": "DELETE",
            "ResourceRecordSet": {
                "Name": "${DOMAIN_NAME}",
                "Type": "A",
                "AliasTarget": {
                    "HostedZoneId": "${ALB_HOSTED_ZONE_ID}",
                    "DNSName": "${ALB_ADDRESS}",
                    "EvaluateTargetHealth": false
                }
            }
        }
    ]
}
EOF
)

# Remove Route 53 Record Set
aws route53 change-resource-record-sets --hosted-zone-id "${HOSTED_ZONE_ID}" --change-batch "${JSON_CHANGE_BATCH}"

if [ $? -eq 0 ]; then
    echo "Successfully removed Route 53 record for ${DOMAIN_NAME} pointing to the ALB."
else
    echo "Failed to remove Route 53 record."
fi

