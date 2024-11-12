#!/bin/bash

# Disable firewall to ensure Kubernetes networking can function without interference
sudo systemctl disable --now ufw 

# Disable swap, required for Kubernetes, and remove swap entries from /etc/fstab
sudo swapoff -a 
sudo sed -i '/ swap / s/^/#/' /etc/fstab 

# Update and upgrade system packages
sudo apt update && sudo apt upgrade -y 

# Configure sysctl parameters for Kubernetes networking
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1 
EOF

# Apply sysctl parameters immediately
sudo sysctl --system 

# Verify IP forwarding is enabled
sysctl net.ipv4.ip_forward 

# Install containerd, a container runtime for Kubernetes
sudo apt install -y containerd 

# Configure containerd
sudo mkdir -p /etc/containerd 
sudo containerd config default | sudo tee /etc/containerd/config.toml 

# Set systemd as the cgroup driver
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml 
sudo systemctl restart containerd 
sudo systemctl enable containerd 

# Install apt HTTPS packages
sudo apt install -y apt-transport-https ca-certificates curl gpg 

# Add Kubernetes apt repository key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 

# Add Kubernetes repository to sources
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list 

# Update package listings and install kubelet, kubeadm, and kubectl
sudo apt update 
sudo apt install -y kubelet kubeadm kubectl 

# Hold packages
sudo apt-mark hold kubelet kubeadm kubectl 

# Enable kubelet service
sudo systemctl enable --now kubelet 

# Mark file for completion
echo "Setup complete" > /home/ec2-user/setup_completed.txt

