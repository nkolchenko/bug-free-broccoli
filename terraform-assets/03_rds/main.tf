
resource "aws_db_instance" "default" {
  storage_type      = "standard"
  allocated_storage = 5

  multi_az               = true   # this adds cost and redundancy
  db_subnet_group_name   = data.terraform_remote_state.network.outputs.aws_db_subnets_ids #ADD
  vpc_security_group_ids = [data.terraform_remote_state.network.outputs.rds_sg_id]
  engine                 = "postgres"
  engine_version         = "10"
  instance_class         = "db.t3.micro" # shall be enough for this task
  db_name                = "app"
  username               = "postgres"  # this should go to secrets manager later
  password               = "changeme"  # this should go to secrets manager later
  parameter_group_name   = "default.postgres10"
  deletion_protection    = false       # to simplify tf destroy
  skip_final_snapshot    = true
}
