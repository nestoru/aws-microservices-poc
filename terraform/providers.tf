provider "aws" {
  region = "eu-north-1"
  profile = "default"
}

data "aws_eks_cluster" "cluster" {
  name = "cluster1" 
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = "cluster1" 
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = module.eks.cluster1_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster1_ca_certificate)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

