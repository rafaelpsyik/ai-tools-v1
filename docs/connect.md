# Connecting to the tools VPS

`<domain>` = your Cloudflare domain · hostname = `ssh.<domain>` · user = `tools`.

## From your PC (cloudflared ProxyCommand)

1. Install `cloudflared`:
   - macOS: `brew install cloudflared`
   - Debian/Ubuntu: download the `.deb` from the cloudflared releases page.
   - Windows: `winget install --id Cloudflare.cloudflared`

2. Add to `~/.ssh/config`:
   ```
   Host tools-vps
     HostName ssh.<domain>
     User tools
     ProxyCommand cloudflared access ssh --hostname %h
     IdentityFile ~/.ssh/id_ed25519
   ```

3. Connect:
   ```bash
   ssh tools-vps
   ```
   If Cloudflare Access is enabled, a browser window opens once to
   authenticate, then SSH proceeds.

## From your phone

### Option A — Browser SSH (easiest, nothing to install)

If you enabled **Browser rendering → SSH** on the Access application
(see `../cloudflare/README.md`), just open:

```
https://ssh.<domain>
```

in your phone's browser. Authenticate with your Access identity → you get a
full terminal in the browser. Works on iOS and Android.

### Option B — Native SSH app (Termius, etc.)

1. Install **Cloudflare WARP** on the phone and enroll it in your Zero Trust
   organization (Settings → Account). WARP routes traffic to your tunnel/Access.
2. Or use an SSH client that supports a ProxyCommand/jump via `cloudflared`.
   Browser SSH (Option A) is simpler on mobile and recommended.

## Quick smoke test once connected

```bash
kubectl version --client
helm version
k9s version
kubectx --help
terraform version
gcloud version
```

## Pointing kubectl at a cluster

```bash
# GKE example (uses the VM's service account):
gcloud container clusters get-credentials <CLUSTER> --region <REGION> --project <PROJECT>
kubectl get nodes
```
