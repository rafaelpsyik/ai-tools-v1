# Cloudflare Tunnel — SSH access

The tunnel lets you SSH into the VPS **without opening any inbound port** and
**without a public IP**. `cloudflared` on the VM makes an outbound-only
connection to Cloudflare; you reach it through `ssh.<your-domain>`.

## 1. Create the tunnel (one time)

Cloudflare Zero Trust dashboard → **Networks → Tunnels → Create a tunnel**:

1. Type: **Cloudflared**.
2. Name it, e.g. `tools-vps`.
3. On the "Install connector" screen, **copy the install token** (the long
   `eyJ...` string in the `cloudflared service install <TOKEN>` command).
   - This is the value for `cloudflared_tunnel_token` in Terraform.
   - Treat it as a secret. Prefer `export TF_VAR_cloudflared_tunnel_token=...`
     over writing it into `terraform.tfvars`.
4. **Public Hostname** tab → **Add a public hostname**:
   - Subdomain: `ssh`  · Domain: `your-domain.com`
   - Service: **Type = SSH**, URL = `localhost:22`
   - Save. Cloudflare creates the `ssh.your-domain.com` DNS record automatically.

You do **not** run `cloudflared` by hand — the VM's startup script installs it
as a service using the token (read from instance metadata).

## 2. (Recommended) Protect it with Access

Networks → ... or **Access → Applications → Add an application → Self-hosted**:

- Application domain: `ssh.your-domain.com`
- Add a policy allowing only your email (e.g. Include → Emails → you@example).
- **Enable "Browser rendering" → SSH** on the application. This gives you a
  full SSH terminal in the browser — the easiest way to connect **from a phone**.

## 3. Connect

See [`../docs/connect.md`](../docs/connect.md) for PC and phone instructions.

## Rotating the token

If the token leaks: delete/recreate the tunnel (or rotate the connector token)
in the dashboard, update `TF_VAR_cloudflared_tunnel_token`, and
`terraform apply` (or re-run `cloudflared service install <new-token>` on the VM).
