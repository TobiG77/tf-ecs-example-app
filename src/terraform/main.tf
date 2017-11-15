# in this contrived example we pull the vpc module in to have a fully self contained demo
# in an actual use case, we would setup the vpc in a different process and just import
# variables as such

module "vpc" {
  source = "../../../tf-mod-standardvpc"
  region = "${var.region}"
}

module "asg" {
  source = "../../../tf-mod-standardasg"

  ec2_ssh_key = "ec2-default"

  application_port = "3000"
  health_check_path = "/"
  instance_type = "t2.medium"

  image_id = "${data.aws_ami.amzn-linux-ecs.id}"
  iam_instance_profile = "foobar"
  instance_user_data = "#!/bin/bash\necho 'Hello World'"

  region = "${var.region}"
  stage  = "${var.stage}"

  permit_ping_cidr = "${module.vpc.vpc_cidr}"
  permit_ssh_cidr = "${module.vpc.vpc_cidr}"

  vpc_id      = "${module.vpc.vpc_id}"
  private_subnets = "${module.vpc.private_subnets}"
  public_subnets  = "${module.vpc.public_subnets}"

}
