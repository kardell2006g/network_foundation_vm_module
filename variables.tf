variable "region" {
  description = "AWS region to deploy the shared network into."
  type        = string
  default     = "us-east-2"
}

variable "cost_center" {
  description = "Cost center tag applied to every resource."
  type        = string

  validation {
    condition     = length(trimspace(var.cost_center)) > 0
    error_message = "cost_center must not be empty."
  }
}

variable "vpc_name" {
  description = "Name tag of the shared VPC. The windows-vm module looks the VPC up by this name."
  type        = string
  default     = "selfservice-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the shared VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread each network across (2+ recommended for the NLB)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count must be between 1 and 3."
  }
}

# Each network gets one subnet per AZ. Every subnet in a network carries the
# same Name tag ("Web", "App", "Bastion"), which is what the VM module filters on.
variable "networks" {
  description = "Map of network name => /20 index inside the VPC CIDR. Keys are the subnet Name tags."
  type        = map(number)
  default = {
    Web     = 0
    App     = 1
    Bastion = 2
  }
}
