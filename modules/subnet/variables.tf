variable "environment" {
  type        = string
  description = "Environment of the storage account."
}

variable "name" {
  type        = string
  description = "Name of the Subnet to create."
}

variable "location" {
  type        = string
  description = "Location of the Subnet to create."
  default     = "uksouth"
}

variable "security_rules" {
  type = list(object({
    name = string
    properties = object({
      access                   = string
      description              = string
      destinationAddressPrefix = string
      destinationPortRange     = string
      direction                = string
      priority                 = number
      protocol                 = string
      sourceAddressPrefix      = string
      sourcePortRange          = string
    })
  }))
  description = "Security rules to apply to the Subnet."
  default     = []
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR of the Subnet to create."
}

variable "vnet_id" {
  type        = string
  description = "Virtual Network ID to create the Subnet within."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Network Security Group associated with the Subnet."
  default     = {}
}
