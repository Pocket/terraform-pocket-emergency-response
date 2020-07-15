locals {
  prefix = var.name_prefix
  tags   = var.tags

  escalation_levels  = var.escalation_levels
  pagerduty          = var.pagerduty
  services           = var.pagerduty_services != null ? var.pagerduty_services : [ ]
}

resource "aws_sns_topic" "topics" {
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

# generates a pagerduty service that receives an integration key that
# SNS subscriptions can use to hit PagerDuty
resource "pagerduty_service_integration" "pagerduty_service" {
  count   = length(local.services)
  name    = local.services[ count.index ][ "vendor_name" ]
  vendor  = local.services[ count.index ][ "vendor_id" ]
  service = pagerduty_service[ local.services[ count.index ][ "escalation_level" ] ][ "id" ]
}

# connects each pagerduty_service to its SNS escalation level
resource "aws_sns_topic_subscription" "pagerduty_sns" {
  count                           = length(local.services)
  topic_arn                       = aws_sns_topic.topics[ local.services[ count.index ][ "escalation_level" ] ][ "arn" ]
  protocol                        = "https"
  endpoint                        = "https://events.pagerduty.com/integration/${pagerduty_service_integration["pagerduty_service"][count.index]["integration_key"]}/enqueue"
  endpoint_auto_confirms          = local.services[ count.index ]["subscription"][ "auto_confirm" ]
  confirmation_timeout_in_minutes = local.services[ count.index ]["subscription"][ "confirm_timeout" ]
}
