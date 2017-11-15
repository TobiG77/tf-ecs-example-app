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

STATE_BUCKET="$APP_NAMESPACE-$STAGE-tf-state"

aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null || create_state_bucket
aws s3api get-bucket-lifecycle --bucket "$STATE_BUCKET" 2>/dev/null || put_bucket_lifecycle
aws s3api get-bucket-versioning --bucket "$STATE_BUCKET" 2>/dev/null || put_bucket_versioning

TF_VAR_region="${AWS_REGION}" \
TF_VAR_app_namespace="${APP_NAMESPACE}" \
terraform init \
  -get=true \
  -get-plugins=true \
  -verify-plugins=true \
  -backend-config="bucket=$STATE_BUCKET" \
  -backend-config="key=$STAGE/terraform.tfstate" \
  -backend-config="region=$AWS_REGION"

mkdir -p ../config


TF_VAR_region=${AWS_REGION} \
TF_VAR_app_namespace="${APP_NAMESPACE}" \
TF_VAR_stage=${STAGE} \
AWS_PROFILE=${AWS_PROFILE} \
envsubst < tf.env.tpl > ../config/tf-${STAGE}.env
