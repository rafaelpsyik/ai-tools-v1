# ai-tools-v1

A reproducible **Kubernetes tools VPS**: a Google Cloud VM preloaded with the
Kubernetes CLIs, reachable over SSH through a **Cloudflare Tunnel** — no public
ports, no public IP — from your PC or your phone.

## What you get

- **VM** (`e2-medium`, Debian 12) in a dedicated VPC with **default-deny ingress**.
- **CLIs installed on first boot**: `kubectl`, `helm`, `k9s`, `kubectx`/`kubens`,
  `kustomize`, `yq`, `gcloud`, `terraform`, `cloudflared`.
- **SSH over Cloudflare Tunnel** (`ssh.<your-domain>`) — outbound-only from the VM.
- **Google IAP** as a Google-authenticated break-glass SSH path.
- Everything as code (Terraform); you provision with **your own** credentials.

## Layout

```
ai-tools-v1/
├── terraform/        # GCP VM, VPC, firewall (IaC)
│   ├── main.tf  variables.tf  outputs.tf  versions.tf
│   └── terraform.tfvars.example
├── scripts/
│   └── startup.sh    # installs CLIs + cloudflared service on first boot
├── cloudflare/
│   └── README.md     # create the tunnel + (optional) Access / browser SSH
└── docs/
    ├── setup.md      # end-to-end provisioning walkthrough
    └── connect.md    # connect from PC and phone
```

## Quick start

1. Create the Cloudflare Tunnel and copy its token → [`cloudflare/README.md`](cloudflare/README.md)
2. Provision the VM → [`docs/setup.md`](docs/setup.md)
3. Connect from PC / phone → [`docs/connect.md`](docs/connect.md)

## Secrets

Never commit secrets. The Cloudflare tunnel token and your `*.tfvars` are
git-ignored; prefer `export TF_VAR_cloudflared_tunnel_token=...` for the token.
