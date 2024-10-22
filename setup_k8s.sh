# Disable firewall to ensure Kubernetes networking can function without interference
sudo systemctl disable --now ufw 

# Disable swap, which is required for Kubernetes to work properly, and remove swap entries from /etc/fstab
sudo swapoff -a 
sudo sed -i '/ swap / s/^/#/' /etc/fstab 

# Update and upgrade system packages to the latest versions
sudo apt update && sudo apt upgrade -y 

# Configure sysctl parameters required for Kubernetes networking
# These parameters persist across reboots

cat<<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1 
EOF

# Apply sysctl parameters immediately, without requiring a reboot
sudo sysctl --system 

# Verify that IP forwarding is enabled
sysctl net.ipv4.ip_forward 

# Install containerd, a container runtime for Kubernetes
sudo apt update 
sudo apt install -y containerd 

# Create containerd configuration directory and apply the default configuration
sudo mkdir -p /etc/containerd 
sudo containerd config default | sudo tee /etc/containerd/config.toml 

# Restart and enable containerd to start on boot
sudo systemctl restart containerd 
sudo systemctl enable containerd 

# Configure containerd to use systemd as the cgroup driver, which is recommended for Kubernetes
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml 
sudo systemctl restart containerd 

# Install necessary packages for apt to use HTTPS repositories
sudo apt-get update 
sudo apt-get install -y apt-transport-https ca-certificates curl gpg 

# Add Kubernetes apt repository key for package verification
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 

# Add Kubernetes apt repository to the system’s sources list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list 

# Update package listings to include Kubernetes packages and install kubelet, kubeadm, and kubectl
sudo apt-get update 
sudo apt-get install -y kubelet kubeadm kubectl 

# Mark kubelet, kubeadm, and kubectl to prevent them from being automatically upgraded
sudo apt-mark hold kubelet kubeadm kubectl 

# Enable kubelet service to start automatically on boot
sudo systemctl enable --now kubelet 
