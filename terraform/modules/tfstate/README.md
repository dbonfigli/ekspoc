# tfstate module

this module is meant to create aws resources to be used as terraform state (s3 + dynamodb table for locks).

## Example

Deploy this module using the local backend, e.g. in a directory tfstate/main.tf:

```hcl
terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "aws" {
  region  = "<aws region>"
  version = "~> 2.0"
}

module "state" {
  source      = "<tfstate module location>"
  bucket_name = "<bucket name>"
  table_name  = "<dynamodb table name>"
}
```

Initialize and run the terraform code:
```bash
terraform init
terraform apply
```

Now, after the aws resources to be used as terraform state have been created, modify tfstate/main.tf specifying s3 as backend:

```hcl
terraform {
  required_version = ">= 0.12, < 0.13"
  backend "s3" {
    bucket         = "<bucket name>"
    key            = "<tfstate object path>"
    dynamodb_table = "<dynamodb table name>"
    region         = "<aws region>"
    encrypt        = true
  }
}
```

and initialize again terraform, answering 'yes' to the request to transfer the state from the local backend to the s3 backend:

```bash
terraform init
```

Now you have the state in the s3 backend and can use it for any other resource.

