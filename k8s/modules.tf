module "db" {
  source                 = "./modules/mariadb"
  db_engine              = "MariaDB"
  db_engineVer           = "10.5"
  db_name                = var.db_name
  db_user                = var.db_user
  db_pass                = var.db_pass
  environment            = var.db_environment
  db_instance_class      = var.db_instance_class
  av_zone                = join("", [var.region, "b"])
  vpc_cidrs              = [module.vpc.vpc_cidr_block]
  db_subnet_list         = module.vpc.private_subnets
  available_from_subnets = module.vpc.private_subnets_cidr_blocks
  vpc_id                 = module.vpc.vpc_id
}
