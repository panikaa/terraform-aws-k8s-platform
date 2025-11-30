resource "random_password" "password" {
  length  = 20
  special = false
}

resource "aws_secretsmanager_secret" "db_password" {
  name        = "rds-${var.db_name}-password"
  description = "Database password for ${var.db_name}"
}

resource "aws_secretsmanager_secret_version" "db_pass_version" {
  secret_id = aws_secretsmanager_secret.db_password.id

  secret_string = jsonencode({
    username = var.username
    password = random_password.password.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}

# Subnet Group
resource "aws_db_subnet_group" "db" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "rds-subnet-group-${var.db_name}"
  }
}

# Security Group for Postgres
resource "aws_security_group" "db_sg" {
  name        = "rds-${var.db_name}-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  tags = {
    Name = "rds-${var.db_name}-sg"
  }
}

# Allow EKS nodes to connect to RDS
resource "aws_security_group_rule" "eks_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = var.eks_node_sg_id
}

# RDS INSTANCE
resource "aws_db_instance" "this" {
  engine            = "postgres"
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  identifier        = "${var.db_name}-db"
  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.username
  password = random_password.password.result

  db_subnet_group_name = aws_db_subnet_group.db.name
  publicly_accessible  = var.publicly_accessible
  multi_az             = var.multi_az

  vpc_security_group_ids = [aws_security_group.db_sg.id]

  skip_final_snapshot = true

  tags = {
    Name = "${var.db_name}-rds"
  }
}
