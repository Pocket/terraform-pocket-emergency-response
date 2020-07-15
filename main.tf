locals {
  prefix = var.name_prefix
  tags   = var.tags

  escalation_levels  = var.escalation_levels
  pagerduty          = var.pagerduty
  pagerduty_services = var.pagerduty_services != null ? var.pagerduty_services : [ ]
}

resource "aws_sns_topic" "sns_escalation_levels" {
  for_each = toset(local.escalation_levels)
  name     = "${local.prefix}-SNS-${title(each.value)}"
  tags     = local.tags
}

resource "pagerduty_service" "pagerduty" {
  for_each                = local.pagerduty
  name                    = "${local.prefix}-PagerDuty-${each.key}"
  auto_resolve_timeout    = each.value[ "auto_resolve_timeout" ]
  acknowledgement_timeout = each.value[ "acknowledgement_timeout" ]
  alert_creation          = each.value[ "alert_action" ]
  escalation_policy       = each.value[ "escalation_policy" ]

  incident_urgency_rule {
    type    = each.value[ "rule" ][ "type" ]
    urgency = each.value[ "rule" ][ "urgency" ]
  }
}

resource "pagerduty_service_integration" "pagerduty_service" {
  for_each = local.pagerduty_services
  name     = each.value[ "vendor_name" ]
  vendor   = each.value[ "vendor_id" ]
  service  = pagerduty_service[ each.value[ "escalation_level" ] ][ "id" ]
}
