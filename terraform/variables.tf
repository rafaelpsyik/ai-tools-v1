variable "project_id" {
  type        = string
  description = "GCP project ID where the tools VM will be created."
}

variable "region" {
  type        = string
  description = "GCP region."
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "GCP zone."
  default     = "us-central1-a"
}

variable "vm_name" {
  type        = string
  description = "Name of the tools VM (also used as a network tag)."
  default     = "tools-vps"
}

variable "machine_type" {
  type        = string
  description = "Compute Engine machine type."
  default     = "e2-medium"
}

variable "disk_size_gb" {
  type        = number
  description = "Boot disk size in GB."
  default     = 30
}

variable "disk_image" {
  type        = string
  description = "Boot disk image."
  default     = "debian-cloud/debian-12"
}

variable "ssh_username" {
  type        = string
  description = "Linux user to create / use for SSH (also the OS Login bypass user)."
  default     = "tools"
}

variable "ssh_public_key" {
  type        = string
  description = "Contents of your SSH public key (e.g. the line in ~/.ssh/id_ed25519.pub)."
}

variable "cloudflared_tunnel_token" {
  type        = string
  description = "Cloudflare Tunnel token (from Zero Trust > Networks > Tunnels). Sensitive — set via tfvars or TF_VAR_ env, never commit."
  sensitive   = true
}

variable "assign_external_ip" {
  type        = bool
  description = "Assign an ephemeral external IP. Needed for outbound internet (apt / cloudflared) unless you set up Cloud NAT. No inbound ports are opened regardless."
  default     = true
}

variable "enable_iap_ssh" {
  type        = bool
  description = "Allow inbound SSH (port 22) from Google IAP range only, as a break-glass fallback if the tunnel is down."
  default     = true
}

variable "trusted_ssh_cidr" {
  type        = string
  description = "Optional extra CIDR allowed to reach port 22 directly (e.g. your office IP/32). Empty = disabled. Prefer the tunnel instead."
  default     = ""
}
