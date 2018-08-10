#!/bin/bash

# Prereqs
[[ ! -x "$(which terraform)" ]] && echo "Couldn't find terraform in your PATH. Please see https://www.terraform.io/downloads.html" && exit 1
[[ ! -x "$(which curl)" ]] && echo "Couldn't find curl in your PATH." && exit 1
[[ ! -x "$(which ssh)" ]] && echo "Couldn't find ssh in your PATH." && exit 1
[[ ! -x "$(which ssh-keygen)" ]] && echo "Couldn't find ssh-keygen in your PATH." && exit 1

# Ensure the environment variables for AWS are provided
: "${AWS_ACCESS_KEY_ID:?Please make sure you have exported an AWS_ACCESS_KEY_ID.}"
: "${AWS_SECRET_ACCESS_KEY:?Please make sure you have exported an AWS_SECRET_ACCESS_KEY.}"

# Get AMI ID
jenkins_ami=$(cat ../packer/jenkins-manifest.json | jq ".builds[0].artifact_id" -r | sed 's/.*://')
nexus_ami=$(cat ../packer/nexus-manifest.json | jq ".builds[0].artifact_id" -r | sed 's/.*://')

# Generate the SSH key pair, if it doesn't exist
if [[ ! -f "id_rsa" ]]; then
	echo "Generating 4096-bit RSA SSH key pair. This can take a few seconds."
	ssh-keygen -t rsa -b 4096 -f id_rsa -N ""
fi

# Grab our external IP for the security groups
MANAGEMENT_IP=$(curl -s http://ipinfo.io/ip)
[[ ! "$MANAGEMENT_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && echo "Couldn't determine your external IP: $MANAGEMENT_IP" && exit 1

# Using Terraform, deploy Jenkins & Nexus servers
terraform init
terraform plan -var AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
               -var AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
               -var "management_ip=$MANAGEMENT_IP" \
               -var "jenkins_ami=$jenkins_ami" \
               -var "nexus_ami=$nexus_ami" \
               -out tfplan
terraform apply tfplan