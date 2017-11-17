resource "aws_kms_key" "ecs-app" {}

resource "aws_kms_alias" "ecs-app" {
  name          = "alias/ecs-app"
  target_key_id = "${aws_kms_key.ecs-app.key_id}"
}

resource "aws_ssm_parameter" "ecs-app-database_host" {
  name      = "${var.app_namespace}-database_host"
  type      = "String"
  value     = "${replace(aws_db_instance.tf-ecs-example-app.endpoint, ":5432", "")}"
  overwrite = true
}

resource "aws_ssm_parameter" "ecs-app-database_name" {
  name      = "${var.app_namespace}-database_name"
  type      = "String"
  value     = "${aws_db_instance.tf-ecs-example-app.name}"
  overwrite = true
}

resource "aws_ssm_parameter" "ecs-app-database_username" {
  name      = "${var.app_namespace}-database_username"
  type      = "String"
  value     = "${var.database_username}"
  overwrite = true
}

resource "aws_ssm_parameter" "ecs-app-database_password" {
  name      = "${var.app_namespace}-database_password"
  type      = "SecureString"
  value     = "${var.database_password}"
  overwrite = true
}
