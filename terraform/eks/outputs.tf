output "cluster1_id" {
  value = module.cluster1.cluster_id
}

output "cluster1_endpoint" {
  value = module.cluster1.cluster_endpoint
}

output "cluster1_ca_certificate" {
  value = module.cluster1.cluster_certificate_authority_data
}

output "cluster1_name" {
  value = module.cluster1.cluster_id # Adjusted assuming `cluster_id` as proxy if direct name is unavailable
}

output "cluster1_token" {
  sensitive = true
  value = data.aws_eks_cluster_auth.cluster.token
}
