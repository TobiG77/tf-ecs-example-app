# in this contrived example we pull the vpc module in to have a fully self contained demo
# in an actual use case, we would setup the vpc in a different process and just import
# variables as such

module "vpc" {
  source = "../../../tf-mod-standardvpc"
  region = "${var.region}"
}
