output "container_registry_url" {
  value = "${module.ecs.repository_url}"
}

output "lb_dns_name" {
  value = "${module.asg.lb_dns_name}"
}

output "ecs_cluster_name" {
  value = "${module.ecs.cluster_name}"
}

output "ecs_task_definition" {
  value = "${module.ecs.task_definition}"
}

output "current_region" {
  value = "${var.region}"
}
