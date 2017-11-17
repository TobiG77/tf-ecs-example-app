#!/bin/bash

# variable formats

# only $ will be replaced at runtime with envsubst
# $ with { } will be interpolated at deployment via terraform
set -xe

yum install -y awslogs jq gettext

cat >> /etc/ecs/ecs.config <<"EOF"

ECS_CLUSTER=${cluster_name}

EOF

cat > /etc/awslogs/awslogs.conf.tpl <<"EOF"
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/dmesg]
file = /var/log/dmesg
log_group_name = /aws/ecs/$cluster
log_stream_name = host-dmesg/$container_instance_id

[/var/log/messages]
file = /var/log/messages
log_group_name = /aws/ecs/$cluster
log_stream_name = host-messages/$container_instance_id
datetime_format = %b %d %H:%M:%S


[/var/log/secure]
file = /var/log/secure
log_group_name = /aws/ecs/$cluster
log_stream_name = host-secure/$container_instance_id
datetime_format = %b %d %H:%M:%S

[/var/log/docker]
file = /var/log/docker
log_group_name = /aws/ecs/$cluster
log_stream_name = host-docker/$container_instance_id
datetime_format = %Y-%m-%dT%H:%M:%S.%f

[/var/log/ecs/ecs-init.log]
file = /var/log/ecs/ecs-init.log.*
log_group_name = /aws/ecs/$cluster
log_stream_name = host-ecs-init/$container_instance_id
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/ecs-agent.log]
file = /var/log/ecs/ecs-agent.log.*
log_group_name = /aws/ecs/$cluster
log_stream_name = host-ecs-agent/$container_instance_id
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/audit.log]
file = /var/log/ecs/audit.log.*
log_group_name = /aws/ecs/$cluster
log_stream_name = host-ecs-audit/$container_instance_id
datetime_format = %Y-%m-%dT%H:%M:%SZ

EOF

/usr/libexec/amazon-ecs-init pre-start
( /usr/libexec/amazon-ecs-init start )&

cnt=0

while [ -z "$cluster" ]
do
  export cluster=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .Cluster')
  sleep 1
  cnt=$[cnt+1]
  [ "$cnt" -gt 10 ] && abort_on_error
done

export container_instance_id=$(curl -s http://localhost:51678/v1/metadata | jq -r '. | .ContainerInstanceArn' | awk -F/ '{print $2}' )
export aws_region=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
export ec2_instance_id=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .instanceId)

[ -n "$cluster" ] || abort_on_error
[ -n "$container_instance_id" ] || abort_on_error
[ -n "$aws_region" ] || abort_on_error

new_config_file=$(mktemp)

envsubst < /etc/awslogs/awslogs.conf.tpl > $new_config_file
mv -v --backup=numbered $new_config_file /etc/awslogs/awslogs.conf

# set to current region in /etc/awslogs/awscli.conf

sed -i -e "s|us-east-1|$aws_region|g" /etc/awslogs/awscli.conf

set +e

# ToDo how does this interact with sysinit/cloud-init scripts?
/usr/libexec/amazon-ecs-init pre-stop
killall /usr/libexec/amazon-ecs-init pre-stop
/usr/libexec/amazon-ecs-init post-stop

service awslogs start
chkconfig awslogs on
