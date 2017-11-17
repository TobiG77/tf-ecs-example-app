#!/bin/sh

abort_on_error() {
  echo "$@" 1>&2
  exit 1
}

refresh_docker_image() {
  echo "Creating docker image locally ... "
  pushd ./src/hello_world_api
  docker build -t tobig77/tf-ecs-example-app -f Dockerfile.production . --no-cache --force-rm --pull
  docker tag tobig77/tf-ecs-example-app:latest ${REPOSITORY_URL}:latest
}

upload_docker_image() {

  echo "Uploading local docker image into AWS ECR repository ... "

  # log into the private docker registry, created in AWS ECR ( https://${AWS_REGION}.console.aws.amazon.com/ecs/home?region=${AWS_REGION}#/repositories)
  aws ecr get-login --no-include-email --region ${AWS_REGION} > docker.login
  source ./docker.login && rm -f ./docker.login

  # this bit will push the docker container
  docker push ${REPOSITORY_URL}:latest

}

set_tf_variables() {

  echo "Fetching relevant settings from terraform"

  pushd ./src/terraform >/dev/null

    AWS_REGION=$(terraform output current_region)
    REPOSITORY_URL=$(terraform output container_registry_url)
    ECS_CLUSTER=$(terraform output ecs_cluster_name)
    TASK_DEFINITION=$(terraform output ecs_task_definition)

  popd >/dev/null

}

[ -e "./ci/release.sh" ] || abort_on_error "Start from top directory"

set_tf_variables
refresh=false
test -n "$AWS_REGION" || refresh=true
test -n "$REPOSITORY_URL" || refresh=true
test -n "$ECS_CLUSTER" || refresh=true
test -n "$TASK_DEFINITION" || refresh=true

if [ "$refresh" == "true" ]
then
  echo "Missing variables, refreshing config from terraform ..."
  AWS_PROFILE=$AWS_PROFILE terraform refresh
  set_tf_variables
  test -n "$AWS_REGION" || abort_on_error "AWS_REGION not found in terraform state"
  test -n "$REPOSITORY_URL" || abort_on_error "REPOSITORY_URL not found in terraform state"
  test -n "$ECS_CLUSTER" || abort_on_error "ECS_CLUSTER not found in terraform state"
  test -n "$TASK_DEFINITION" || abort_on_error "TASK_DEFINITION not found in terraform state"
fi

# only the api is hosted in docker containers
git diff --name-only | egrep -q  "^src/hello_world_api" && FORCE_REFRESH=TRUE

[ "$1" == "--build" ] && FORCE_REFRESH=TRUE
[ "$1" == "--no-build" ] && FORCE_REFRESH=FALSE

[ "$FORCE_REFRESH" == "TRUE" ] && refresh_docker_image

upload_docker_image

# ToDo: this is not resilient, it only works for a single task in a docker cluster
current_task=$( AWS_PROFILE=$AWS_PROFILE aws ecs list-tasks --cluster $ECS_CLUSTER | jq .taskArns[0] | awk -F '/' '{print $NF}' | sed 's|"||g')

[ -n "$current_task" ] && \
[ "$current_task" != "null" ] && \
(

  echo "Stopping current task: $current_task"
  AWS_PROFILE=$AWS_PROFILE \
    aws ecs stop-task \
      --cluster $ECS_CLUSTER \
      --task $current_task \
      --reason "release initiated by $(whoami)" >/dev/null

  current_task_running=0
  count=1
  while [ "$current_task_running" == 0 ]
  do
    sleep 1
    count=$[count+1]
    [ "$count" -gt 30 ] && abort_on_error "Failed to delete current task"
    AWS_PROFILE=$AWS_PROFILE \
      aws ecs list-tasks \
        --cluster $ECS_CLUSTER | \
        grep -q $current_task ; current_task_running=$? ||:
  done

)

echo "Starting new task with def: $TASK_DEFINITION"
AWS_PROFILE=$AWS_PROFILE \
  aws ecs run-task \
    --cluster $ECS_CLUSTER \
    --task-definition $TASK_DEFINITION \
    --started-by $(whoami) >/dev/null
