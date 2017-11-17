# in this contrived example we pull the vpc module in to have a fully self contained demo
# in an actual use case, we would setup the vpc in a different process and repository
# and just import variables as such

data "template_file" "user-data" {
  template = "${file("user-data.sh.tpl")}"

  vars {
    cluster_name = "${module.ecs.cluster_name}"
    registry_url = "${module.ecs.repository_url}"
  }
}

module "vpc" {
  source = "../../../tf-mod-standardvpc"
  region = "${var.region}"
}

module "asg" {

  source = "../../../tf-mod-standardasg"

  application_name = "tf-ecs-example-app"

  application_port  = "4000"
  health_check_path = "/api"
  instance_type     = "t2.medium"

  image_id                = "${data.aws_ami.amzn-linux-ecs.id}"
  iam_instance_profile    = "${module.ecs.instance_profile}"
  instance_user_data      = "${data.template_file.user-data.rendered}"
  instance_security_group = "${aws_security_group.rds-request-access-ecs-app.id}"

  ec2_ssh_key = "ec2-default"

  region = "${var.region}"
  stage  = "${var.stage}"

  permit_ping_cidr = "${module.vpc.vpc_cidr}"
  permit_ssh_cidr  = "${module.vpc.vpc_cidr}"

  vpc_id          = "${module.vpc.vpc_id}"
  private_subnets = "${module.vpc.private_subnets}"
  public_subnets  = "${module.vpc.public_subnets}"
}

module "ecs" {
  source = "../../../tf-mod-ecs-app"

  application_name = "tf-ecs-example-app"

  region = "${var.region}"
  stage  = "${var.stage}"

  application_port = "4000"
  target_group_arn = "${module.asg.lb_target_group_arn}"

  cpu    = 10
  memory = 2048
}
