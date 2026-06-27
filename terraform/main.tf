provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Dedicated VPC. Custom networks have a default-deny ingress policy, so no
# port is reachable from the internet unless we add an explicit allow rule.
resource "google_compute_network" "tools" {
  name                    = "${var.vm_name}-net"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "tools" {
  name          = "${var.vm_name}-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.tools.id
}

# Break-glass SSH from Google IAP range only (Google-authenticated, no public exposure).
resource "google_compute_firewall" "iap_ssh" {
  count     = var.enable_iap_ssh ? 1 : 0
  name      = "${var.vm_name}-allow-iap-ssh"
  network   = google_compute_network.tools.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = [var.vm_name]
}

# Optional: allow a specific trusted CIDR to reach port 22 directly.
resource "google_compute_firewall" "trusted_ssh" {
  count     = var.trusted_ssh_cidr == "" ? 0 : 1
  name      = "${var.vm_name}-allow-trusted-ssh"
  network   = google_compute_network.tools.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.trusted_ssh_cidr]
  target_tags   = [var.vm_name]
}

resource "google_compute_instance" "tools" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = [var.vm_name]

  boot_disk {
    initialize_params {
      image = var.disk_image
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.tools.id

    # Ephemeral external IP for outbound only (no inbound rule references it).
    dynamic "access_config" {
      for_each = var.assign_external_ip ? [1] : []
      content {}
    }
  }

  metadata = {
    # Use metadata SSH keys (not OS Login) so cloudflared SSH works with your key.
    enable-oslogin    = "FALSE"
    ssh-keys          = "${var.ssh_username}:${var.ssh_public_key}"
    cloudflared-token = var.cloudflared_tunnel_token
    tools-user        = var.ssh_username
  }

  metadata_startup_script = file("${path.module}/../scripts/startup.sh")

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  service_account {
    # Default compute SA with cloud-platform scope so gcloud/kubectl-to-GKE work.
    scopes = ["cloud-platform"]
  }
}
