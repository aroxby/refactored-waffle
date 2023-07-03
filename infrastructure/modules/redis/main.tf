resource "aws_security_group" "allow_redis_traffic" {
  name        = "allow_redis_traffic"
  description = "Allows redis traffic"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis whitelist"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.ingress_security_groups
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id    = var.name
  description             = "Shared cache for application"
  node_type               = "cache.t3.micro"
  num_node_groups         = 1
  replicas_per_node_group = 0
  security_group_ids      = [aws_security_group.allow_redis_traffic.id]
  subnet_group_name       = var.elasticache_subnet_group_name
  apply_immediately       = true
}
