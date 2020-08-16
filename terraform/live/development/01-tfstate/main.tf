module "state" {
  source      = "../../../modules/tfstate"
  bucket_name = "ekspoc-development-tfstate"
  table_name  = "ekspoc-development-tfstate-locks"
}