output "note_service_instance_id" {
  description = "ID of the NoteService EC2 instance"
  value       = aws_instance.NoteService.id
}

output "user_service_instance_id" {
  description = "ID of the UserService EC2 instance"
  value       = aws_instance.UserService.id
}

output "kafka_server_instance_id" {
  description = "ID of the KafkaServer EC2 instance"
  value       = aws_instance.KafkaServer.id
}

output "zookeeper_server_instance_id" {
  description = "ID of the ZookeeperServer EC2 instance"
  value       = aws_instance.ZookeeperServer.id
}

output "note_service_private_ip" {
  description = "Private IP address of the NoteService EC2 instance"
  value       = aws_instance.NoteService.private_ip
}

output "user_service_private_ip" {
  description = "Private IP address of the UserService EC2 instance"
  value       = aws_instance.UserService.private_ip
}

output "kafka_server_private_ip" {
  description = "Private IP address of the KafkaServer EC2 instance"
  value       = aws_instance.KafkaServer.private_ip
}

output "zookeeper_server_private_ip" {
  description = "Private IP address of the ZookeeperServer EC2 instance"
  value       = aws_instance.ZookeeperServer.private_ip
}