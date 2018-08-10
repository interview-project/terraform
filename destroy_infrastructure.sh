# Get AMI ID
jenkins_ami=$(cat ../packer/jenkins-manifest.json | jq ".builds[0].artifact_id" -r | sed 's/.*://')
nexus_ami=$(cat ../packer/nexus-manifest.json | jq ".builds[0].artifact_id" -r | sed 's/.*://')

terraform destroy -var AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
                  -var AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
                  -var "management_ip=$MANAGEMENT_IP" \
                  -var "jenkins_ami=$jenkins_ami" \
                  -var "nexus_ami=$nexus_ami" \
                  -auto-approve