output "instance_name" {
  description = "Name of the created instance."
  value       = google_compute_instance.tools.name
}

output "zone" {
  description = "Zone of the instance."
  value       = google_compute_instance.tools.zone
}

output "external_ip" {
  description = "Ephemeral external IP (outbound only), if assigned."
  value       = var.assign_external_ip ? google_compute_instance.tools.network_interface[0].access_config[0].nat_ip : "none"
}

output "iap_ssh_command" {
  description = "Break-glass SSH via Google IAP (no public port needed)."
  value       = "gcloud compute ssh ${var.ssh_username}@${google_compute_instance.tools.name} --zone ${var.zone} --tunnel-through-iap"
}

output "startup_log_hint" {
  description = "Where to watch the tool install progress on the VM."
  value       = "tail -f /var/log/tools-startup.log   (done when /var/lib/tools-vps-ready exists)"
}
