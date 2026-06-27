# Setup — Kubernetes tools VPS on GCP + Cloudflare Tunnel

End-to-end: provision an `e2-medium` Debian VM with Kubernetes CLIs, reachable
over SSH through a Cloudflare Tunnel (no public ports), from your PC or phone.

## Prerequisites

- A GCP project with billing enabled, and `gcloud` authenticated locally:
  ```bash
  gcloud auth login
  gcloud auth application-default login
  gcloud config set project <YOUR_PROJECT_ID>
  gcloud services enable compute.googleapis.com
  ```
- Terraform >= 1.5 installed locally.
- A domain managed in Cloudflare.
- An SSH key pair. Create one if needed:
  ```bash
  ssh-keygen -t ed25519 -C "you@yourpc"
  cat ~/.ssh/id_ed25519.pub   # this goes into ssh_public_key
  ```

## 1. Create the Cloudflare Tunnel

Follow [`../cloudflare/README.md`](../cloudflare/README.md) and copy the
**tunnel install token**.

## 2. Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: project_id, ssh_public_key, etc.

# Provide the secret token via env (preferred over the tfvars file):
export TF_VAR_cloudflared_tunnel_token="eyJ...your-token..."
```

## 3. Apply

```bash
terraform init
terraform plan
terraform apply
```

Terraform prints the instance name, the IAP break-glass SSH command, and where
to watch install progress.

## 4. Wait for the tools to install

First boot installs all CLIs. Watch it (via IAP) until done:

```bash
gcloud compute ssh tools@tools-vps --zone us-central1-a --tunnel-through-iap \
  --command 'tail -n +1 -f /var/log/tools-startup.log'
```

Install is complete when `/var/lib/tools-vps-ready` exists.

## 5. Connect

See [`connect.md`](connect.md).

## Security posture

- The VPC is custom (default-deny ingress); **no inbound port is open** to the
  internet. SSH arrives only through the Cloudflare Tunnel (outbound from the VM).
- IAP SSH (`35.235.240.0/20`) is allowed as a Google-authenticated break-glass
  path. Disable with `enable_iap_ssh = false`.
- The external IP is **outbound-only** (no firewall rule exposes it). Set
  `assign_external_ip = false` if you add Cloud NAT for egress instead.
- Add a Cloudflare Access policy (see cloudflare README) so only your identity
  can use `ssh.<domain>`.

## Cost note

`e2-medium` + a 30GB pd-balanced disk + an external IP bill while running. Stop
the VM when idle to save money:
```bash
gcloud compute instances stop tools-vps --zone us-central1-a
gcloud compute instances start tools-vps --zone us-central1-a
```

## Tear down

```bash
cd terraform && terraform destroy
```
Then delete the tunnel in the Cloudflare dashboard if you no longer need it.
