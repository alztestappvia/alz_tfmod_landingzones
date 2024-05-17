output "storage_account_name" {
  value = azurecaf_name.storage.result
}

output "container_name" {
  value = var.container_name
}
