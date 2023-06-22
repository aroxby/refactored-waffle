output "cluster" {
  description = "EKS Cluster Attributes"
  value       = {
    cluster_arn = module.eks.cluster_arn
    cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
    cluster_endpoint = module.eks.cluster_endpoint
    cluster_id = module.eks.cluster_id
    cluster_name = module.eks.cluster_name
    cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
    cluster_version = module.eks.cluster_version
    cluster_platform_version = module.eks.cluster_platform_version
    cluster_status = module.eks.cluster_status
    cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  }
}
