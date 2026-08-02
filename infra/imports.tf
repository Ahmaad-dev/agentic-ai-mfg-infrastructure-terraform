# Azure automatically creates the default DoNotReply sender together with an
# Azure-managed email domain. Import it declaratively so subsequent applies
# manage the existing sender instead of attempting to create a duplicate.
import {
  to = module.manual_resources.azurerm_email_communication_service_domain_sender_username.default
  id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.manual_rg_name}/providers/Microsoft.Communication/emailServices/${var.email_communication_service_name}/domains/AzureManagedDomain/senderUsernames/${var.acs_sender_username}"
}
