variable "region" {
  description = "region projektu Google Cloud"
  type        = string
  default     = "europe-central2"

}

variable "project_id" {
  description = "ID projektu Google Cloud"
  type        = string
  default     = "ultra-depot-436413-c3"

}

variable "cluster_name" {
  description = "nazwa klastra"
  type        = string
  default     = "gke-cluster"

}

variable "loadbalancer_ip" {
  description = "loadbalancer ip"
  type        = string
  default     = "34.118.39.132"

}
