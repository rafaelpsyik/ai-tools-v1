#!/usr/bin/env bash
#
# Startup script for the Kubernetes tools VPS.
# Installs CLIs and registers cloudflared as a service for SSH-over-tunnel.
# Runs as root on first boot via GCE metadata_startup_script.
#
set -euo pipefail
exec > >(tee -a /var/log/tools-startup.log) 2>&1
echo "=== tools-vps startup started: $(date -u) ==="

export DEBIAN_FRONTEND=noninteractive
KEYRINGS=/etc/apt/keyrings
mkdir -p "$KEYRINGS"

md() { # read an instance metadata attribute
  curl -fsS -H "Metadata-Flavor: Google" \
    "http://metadata.google.internal/computeMetadata/v1/instance/attributes/$1" || true
}

# --- base packages ---------------------------------------------------------
apt-get update -y
apt-get install -y \
  curl wget git jq vim tmux htop unzip ca-certificates gnupg \
  apt-transport-https lsb-release bash-completion

# --- kubectl (pkgs.k8s.io) -------------------------------------------------
K8S_MINOR="v1.30"
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/Release.key" \
  | gpg --dearmor -o "$KEYRINGS/kubernetes-apt-keyring.gpg"
echo "deb [signed-by=$KEYRINGS/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/ /" \
  > /etc/apt/sources.list.d/kubernetes.list

# --- helm ------------------------------------------------------------------
curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor -o "$KEYRINGS/helm.gpg"
echo "deb [signed-by=$KEYRINGS/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" \
  > /etc/apt/sources.list.d/helm-stable-debian.list

# --- google cloud cli ------------------------------------------------------
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o "$KEYRINGS/cloud.google.gpg"
echo "deb [signed-by=$KEYRINGS/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  > /etc/apt/sources.list.d/google-cloud-sdk.list

# --- hashicorp / terraform -------------------------------------------------
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o "$KEYRINGS/hashicorp.gpg"
echo "deb [signed-by=$KEYRINGS/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list

apt-get update -y
apt-get install -y kubectl helm google-cloud-cli terraform

# --- k9s (binary release) --------------------------------------------------
K9S_VERSION="$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)"
curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" \
  | tar xz -C /usr/local/bin k9s

# --- kubectx / kubens ------------------------------------------------------
if [ ! -d /opt/kubectx ]; then
  git clone --depth 1 https://github.com/ahmetb/kubectx /opt/kubectx
fi
ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -sf /opt/kubectx/kubens  /usr/local/bin/kubens

# --- kustomize -------------------------------------------------------------
( cd /tmp && curl -fsSL "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash )
install -m 0755 /tmp/kustomize /usr/local/bin/kustomize

# --- yq --------------------------------------------------------------------
YQ_VERSION="$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r .tag_name)"
curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq

# --- shell niceties (kubectl completion + aliases) -------------------------
cat > /etc/profile.d/k8s-tools.sh <<'EOF'
source <(kubectl completion bash) 2>/dev/null || true
alias k=kubectl
complete -o default -F __start_kubectl k 2>/dev/null || true
EOF

# --- cloudflared + tunnel service ------------------------------------------
curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb \
  -o /tmp/cloudflared.deb
dpkg -i /tmp/cloudflared.deb

CF_TOKEN="$(md cloudflared-token)"
if [ -n "$CF_TOKEN" ]; then
  # Remotely-managed tunnel: ingress (ssh.domain -> ssh://localhost:22) is set in the dashboard.
  cloudflared service install "$CF_TOKEN"
  systemctl enable --now cloudflared || true
  echo "cloudflared service installed."
else
  echo "WARNING: no cloudflared-token in metadata; skipping tunnel install."
fi

echo "=== tools-vps startup finished: $(date -u) ==="
touch /var/lib/tools-vps-ready
