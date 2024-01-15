provider "aws" {
  region = "eu-west-2"
}

resource "aws_secretsmanager_secret" "database_credentials" {
  name = "my_database_credentials"
}

# Create secrets for RDS username and password
resource "aws_secretsmanager_secret_version" "database_credentials_version" {
  secret_id      = aws_secretsmanager_secret.database_credentials.id
  secret_string  = jsonencode({
    username = "",
    password = "" 
  })
}

# Create RDS Database 
resource "aws_db_instance" "cd_rds_db" {
  identifier            = "my-rds-instance"
  engine                = "mysql"
  instance_class        = "db.t3.medium"
  allocated_storage     = 100
  storage_type          = "gp2"
  multi_az              = true
  publicly_accessible   = false

  # Reference the stored credentials from AWS Secrets Manager
  username              = jsondecode(aws_secretsmanager_secret_version.database_credentials_version.secret_string)["username"]
  password              = sensitive(jsondecode(aws_secretsmanager_secret_version.database_credentials_version.secret_string)["password"])

  # Additional settings for production use, maintenance window and automated backups every week 
  backup_retention_period = 7
  backup_window           = "02:00-03:00"
  maintenance_window      = "sun:04:00-sun:05:00"
}

output "rds_endpoint" {
  value = aws_db_instance.cd_rds_db.endpoint
}
