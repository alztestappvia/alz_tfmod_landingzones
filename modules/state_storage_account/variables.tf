variable "name" {
  type        = string
  description = "Name of the storage account."
  validation {
    condition     = can(regex("^[a-z0-9]{3,9}$", var.name))
    error_message = "The name must be between 3 and 9 characters long and can only contain lowercase letters and numbers."
  }
}

variable "location" {
  type        = string
  description = "Location of the storage account."
}

variable "principal_id" {
  type        = string
  description = "Principal id of the service connection that will access the state file."
}

variable "environment" {
  type        = string
  description = "Environment of the storage account."
}

variable "reader_principal_ids" {
  type        = map(string)
  description = "Principal ids of the service connections that will read the state file."
  default     = {}
}

variable "subscription_resource_id" {
  type        = string
  description = "Resource id of the subscription that the storage account will be created in."
}

variable "tags" {
  type        = map(string)
  description = "Tags to be applied to the storage account."
  default     = {}
}

variable "container_name" {
  type        = string
  description = "Name of the container to be created in the storage account."
  default     = "tfstate"
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet id for the private endpoint."
  default     = null
}

variable "use_private_endpoint" {
  type        = bool
  description = "Whether to use a private endpoint to access the storage account."
  default     = true
}
