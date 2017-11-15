#!/bin/bash

set -x

abort_on_error() {
  echo "$@" 1>&2
  exit 1
}

create_state_bucket() {

  aws s3api create-bucket \
    --bucket $STATE_BUCKET \
    --region $AWS_REGION \
    --create-bucket-configuration LocationConstraint=$AWS_REGION
  sleep 1

}

put_bucket_versioning(){

  aws s3api put-bucket-versioning \
    --bucket $STATE_BUCKET \
    --region $AWS_REGION \
    --versioning-configuration Status=Enabled
  sleep 1
}

put_bucket_lifecycle() {

  aws s3api put-bucket-lifecycle \
    --bucket $STATE_BUCKET \
    --region $AWS_REGION \
    --lifecycle-configuration file://tfstate-bucket-lifecycle.json
  sleep 1

}

set -e

[ -n "$AWS_REGION" ] || abort_on_error "Need AWS_REGION set"
[ -n "$STAGE" ] || abort_on_error "Need STAGE set"
[ -n "$AWS_PROFILE" ] && export AWS_PROFILE
[ -n "$APP_NAMESPACE" ] || abort_on_error "Need APP_PREFIX to be set"

export STATE_BUCKET="$APP_NAMESPACE-$STAGE-tf-state"
export TF_VAR_region=${AWS_REGION}
export TF_VAR_app_namespace="${APP_NAMESPACE}"
export TF_VAR_stage=${STAGE}
export AWS_PROFILE=${AWS_PROFILE}

mkdir -p ../config
envsubst < tf.env.tpl > ../config/tf-${STAGE}.env

aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null || create_state_bucket
aws s3api get-bucket-lifecycle --bucket "$STATE_BUCKET" 2>/dev/null || put_bucket_lifecycle
aws s3api get-bucket-versioning --bucket "$STATE_BUCKET" 2>/dev/null || put_bucket_versioning

terraform init \
  -get=true \
  -get-plugins=true \
  -verify-plugins=true \
  -backend-config="bucket=$STATE_BUCKET" \
  -backend-config="key=$TF_VAR_stage/terraform.tfstate" \
  -backend-config="region=$TF_VAR_region"
