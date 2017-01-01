# vim: ts=2 sw=2 et

# 
# CLIENT-SET VARIABLES
#

variable "admin_email" {
  type        = "string"
  description = "The administrator's email addess"
}

variable "home_region" {
  type        = "string"
  description = "The home region, where most of the work is done"
}

variable "remote_region" {
  type        = "string"
  description = "An optional second region for additional resiliency"
  default     = "none"
}

variable "domain" {
  type        = "string"
  description = "A domain to use for the Route53 zone, containing hostnames that your Puppet clients connect to."
}

variable "bucket_prefix" {
  type        = "string"
  description = "A prefix for the S3 bucket(s) created to hold configuration."
}

variable "ssh_key" {
  type        = "string"
  description = "The SSH public key to use for SSHing into EC2 instances."
}
