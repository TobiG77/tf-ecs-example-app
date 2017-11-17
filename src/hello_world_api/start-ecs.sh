#!/bin/bash

# if you enable set -x you will log credentials in clear text in cloudwatch
#
# set -x

set -e

cd $1

SSM_PREFIX=tf-ecs-example-app
SECRETS="database_username database_password database_host database_name"

log_debug() {

    [ "$MIX_ENV" == "prod" ] || echo "$@"

}

log_info() {

    echo "$@"
}

set_secret_envvar() {

    retval=$( aws ssm get-parameter --with-decryption --name $1 --region $AWS_REGION | jq -r .Parameter.Value )

    log_debug "$1: $retval"

    case "$retval" in
        *[[:space:]]*)
            [ -n "$retval" ] && export $secret="$retval"
             ;;
        *)
            [ -n "$retval" ] && export $secret=$retval
            ;;
    esac

}


for secret in ${SECRETS}
do
    set_secret_envvar "${SSM_PREFIX}-${secret}"
done

export POSTGRES_DATABASE=$database_name
export POSTGRES_USERNAME=$database_username
export POSTGRES_PASSWORD=$database_password
export POSTGRES_HOSTNAME=$database_host
export REPLACE_OS_VARS=true

log_debug "$( export )"

if [ "$MIX_ENV" == "prod" ]
then
    log_info "Starting application in prod mode ... "
    /opt/app/hello_world_api/bin/hello_world_api foreground
else
    log_info "Starting application in dev mode ... "
    envsubst < config/dev.secret.exs.tpl > config/dev.secret.exs
    mix phx.server
fi
