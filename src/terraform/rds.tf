resource "aws_db_instance" "tf-ecs-example-app" {
  name                 = "tfecsapp"
  allocated_storage    = 10
  storage_type         = "gp2"
  engine            = "postgres"
  engine_version    = "9.6.3"
  instance_class       = "db.t2.medium"
  username             = "${var.database_username}"
  password             = "${var.database_password}"
  db_subnet_group_name = "${aws_db_subnet_group.rds.id}"

  vpc_security_group_ids = ["${aws_security_group.rds-permit-access-ecs-app.id}"]

  backup_retention_period   = 7
  final_snapshot_identifier = "${var.app_namespace}-final-snapshot"
  identifier_prefix         = "${var.app_namespace}-"

  multi_az = "${var.stage == "production" ? true : false}"
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds"
  subnet_ids = ["${module.vpc.rds_subnets}"]

  tags {
    Name = "rds"
  }
}

resource "aws_security_group" "rds-permit-access-ecs-app" {
  name        = "rds permit ${var.app_namespace}"
  description = "permits postgres access to members of rds-request-${var.app_namespace}"
  vpc_id      = "${module.vpc.vpc_id}"

  tags {
    Name = "RDS:${var.app_namespace} permit"
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = ["${aws_security_group.rds-request-access-ecs-app.id}"]
  }
}

resource "aws_security_group" "rds-request-access-ecs-app" {
  name        = "rds request ${var.app_namespace}"
  description = "requests sql access to rds-permit-${var.app_namespace}"
  vpc_id      = "${module.vpc.vpc_id}"

  tags {
    Name = "RDS:${var.app_namespace} request"
  }
}
