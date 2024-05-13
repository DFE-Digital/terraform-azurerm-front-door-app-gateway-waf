output "environment" {
  value = local.environment
}

output "custom_error_web_page_storage_accounts" {
  value       = azurerm_storage_account.custom_error
  description = "Storage Accounts used for holding custom error pages"
}
