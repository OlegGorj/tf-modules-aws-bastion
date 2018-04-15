#!/bin/bash
set -x

# Firewall skeleton
systemctl stop firewalld
systemctl mask firewalld
yum install -y iptables-services
systemctl enable iptables
cat << EOL > /etc/sysconfig/iptables
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -d 127.0.0.0/8 ! -i lo -j DROP
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
-A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7
-A INPUT -j DROP
-A FORWARD -j DROP
-A OUTPUT -j ACCEPT
COMMIT
EOL
iptables-restore < /etc/sysconfig/iptables

# Ensure dependencies are installed
yum install -y epel-release
yum update -y epel-release
yum install -y python-pip \
    python-devel \
    git \
    openssl-devel \
    libffi-devel \
    awscli \
    python-six \
    python-boto \
    python-jinja2 \
    python-demjson \
    ansible

pip install --upgrade pip
pip install --upgrade setuptools

# If you don't unset these, then the aws cli commands will fail with a 'partial credentials have been found' error
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_KEY

# Because this is not us-east-1, we need to explicitly state the region for the aws commands
export AWS_DEFAULT_REGION=${TERRAFORM_region}

# Get the machine-user key so we can pull code from the remote repository
mkdir -p /root/.ssh
chmod 0700 /root/.ssh
aws s3 cp s3://${TERRAFORM_s3bucket}/ssh/${TERRAFORM_env}/machine-user/github-machine-user /root/.ssh/github-machine-user
chmod 0600 /root/.ssh/github-machine-user

# Get the github.com SSH information so we don't get prompted when pulling code
ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts
command cp /root/.ssh/known_hosts /home/${TERRAFORM_user}/.ssh/known_hosts
chown ${TERRAFORM_user}:${TERRAFORM_user} /home/${TERRAFORM_user}/.ssh/known_hosts

# Let's say you wanted to allow Ansible to SSH in from Jenkins
##############################################################
# mkdir -p /home/${TERRAFORM_user}/.ssh
# chmod 0700 /home/${TERRAFORM_user}/.ssh
# chown ${TERRAFORM_user}:${TERRAFORM_user} /home/${TERRAFORM_user}/.ssh
# aws s3 cp s3://my-state-bucket/ssh/${TERRAFORM_env}/common/${TERRAFORM_env}_jenkinsdeploy.pub /home/${TERRAFORM_user}/.ssh/${TERRAFORM_env}_jenkinsdeploy.pub
# cat /home/${TERRAFORM_user}/.ssh/${TERRAFORM_env}_jenkinsdeploy.pub >> /home/${TERRAFORM_user}/.ssh/authorized_keys
# rm -f /home/${TERRAFORM_user}/.ssh/${TERRAFORM_env}_jenkinsdeploy.pub

# Get the ansible playbook from the repository
ssh-agent bash -c "ssh-add ~/.ssh/gitlab-machine-user; \
    cd /root; \
    git clone git@github.com:pgporada/ansible-playbook-bastion.git"

# Install Ansible playbook dependencies
cd /root/ansible-playbook-bastion
make install-python-requirements

# Install ansible roles
ssh-agent bash -c "ssh-add ~/.ssh/gitlab-machine-user; \
    cd /root/ansible-playbook-bastion; \
    make install-ansible-modules"

# Gather any secrets from S3
aws s3 cp s3://${TERRAFORM_s3bucket}/ansible/${TERRAFORM_env}/bastion/all.yml /root/ansible-playbook-bastion/ansible/environments/aws/group_vars/all.yml
chmod +x /root/ansible-playbook-bastion/ansible/environments/aws/inventory/ec2.py

# Run the playbook on the node itself
cd /root/ansible-playbook-bastion/ansible
ansible-playbook playbooks/deploy-aws-${TERRAFORM_role}.yml \
    -i environments/aws \
    -e cli_myhosts='localhost' \
    -e cli_role=${TERRAFORM_role} \
    -e cli_env=${TERRAFORM_env} \
    --connection=local

# Cleanup
rm -rf /root/ansible-playbook-bastion
rm -f /root/.ssh/gitlab-machine-user
