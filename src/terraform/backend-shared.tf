data "terraform_remote_state" "shared" {
  backend = "s3"

  config {
    bucket = "tf-ecs-example-app-${var.stage}-tf-state"
    key    = "${var.stage}/terraform.tfstate"
    region = "${var.region}"
  }
}
