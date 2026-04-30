output "web_url" {
  description = "URL de la app en DEV"
  value       = "http://${module.ec2.public_ip}"
}

output "instance_id" {
  value = module.ec2.instance_id
}
