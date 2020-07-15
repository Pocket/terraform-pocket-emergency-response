variable "name_prefix" {
  type        = string
  description = "The prefix to append to all resource names"
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources"
  default     = {}
}

variable "escalation_levels" {
  type        = list(string)
  description = "Define your escalation levels, e.g.: [critical, urgent, non-critical]"
}

variable "pagerduty" {
  type        = map(object({
    escalation_policy       = string
    auto_resolve_timout     = number
    acknowledgement_timeout = number
    alert_action            = string
    rule                    = object({
      type    = string
      urgency = string
    })
  }))
  description = "Defines PagerDuty integration where each key corresponds to an escalation level value."
}

variable "pagerduty_services" {
  type        = list(object({
    vendor_name      = string
    vendor_id        = string
    escalation_level = string
  }))
  description = "Specify list of services that hook into PagerDuty alerts"
}
