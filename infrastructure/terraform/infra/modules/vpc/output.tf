
output "vpc" {
  value = aws_vpc.main
}

output "private_subnets" {
  value = { for key, subnet in aws_subnet.private :
    key => subnet
  }
}

output "public_subnets" {
  value = { for key, subnet in aws_subnet.public :
    key => subnet
  }
}

output "subnets" {
  value = merge(
    { 
      for key, subnet in aws_subnet.private :
      key => subnet
    },
    { 
      for key, subnet in aws_subnet.public :
      key => subnet
    }
  )
}
