output "ec2-ip" {
  value = aws_instance.this.public_ip
}

output "instance_id" {
  value = aws_instance.this.id
}

output "instance" {
  value = aws_instance.this
}
