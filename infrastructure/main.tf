provider "aws" {
  region = var.region
}

module "eks" {
  source  = "./modules/eks"
}

  }
}
