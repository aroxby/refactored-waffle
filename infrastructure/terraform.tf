terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.46.0, < 5.0.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 1.0, < 3.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster.cluster_name
      ]
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster.cluster_name
    ]
  }
}
