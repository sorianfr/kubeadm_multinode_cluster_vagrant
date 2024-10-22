# Define the number of worker nodes and static IPs
NUM_WORKER_NODES = 2
MASTER_IP = "192.168.86.103"
WORKER_IPS = ["192.168.86.104", "192.168.86.105"]

# Host operating system detection
module OS
  def OS.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def OS.mac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
  end

  def OS.unix?
    !OS.windows?
  end

  def OS.linux?
    OS.unix? and not OS.mac?
  end

  def OS.jruby?
    RUBY_ENGINE == "jruby"
  end
end

# Determine host adapter for bridging in BRIDGE mode
def get_bridge_adapter()
  if OS.windows?
    return %x{powershell -Command "Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Get-NetAdapter | Select-Object -ExpandProperty InterfaceDescription"}.chomp
  elsif OS.linux?
    return %x{ip route | grep default | awk '{ print $5 }'}.chomp
  elsif OS.mac?
    return %x{mac/mac-bridge.sh}.chomp
  end
end

# Helper method for Kubernetes node provisioning
def provision_kubernetes_node(node)
  node.vm.provision "shell", inline: <<-SHELL
    # Remove existing hostname entries
    sudo sed -i '/127.0.1.1/d' /etc/hosts
    sudo sed -i '/127.0.2.1/d' /etc/hosts
    # Add static IP entries for cluster nodes
    echo "192.168.86.103 master" | sudo tee -a /etc/hosts
    echo "192.168.86.104 nodo01" | sudo tee -a /etc/hosts
    echo "192.168.86.105 nodo02" | sudo tee -a /etc/hosts
  SHELL
  # Upload and execute setup_k8s.sh in parallel
  #node.vm.provision "setup-k8s", type: "shell", path: "setup_k8s.sh"
end

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.boot_timeout = 900
  config.vm.box_check_update = false

  # Provision Control Plane
  config.vm.define "master" do |node|
    node.vm.provider "virtualbox" do |vb|
      vb.name = "master"
      vb.memory = 2048
      vb.cpus = 2
    end
    node.vm.hostname = "master"
    node.vm.network :public_network, ip: MASTER_IP, bridge: get_bridge_adapter()
    provision_kubernetes_node(node)
  end

  # Provision Worker Nodes with static IPs
  (1..NUM_WORKER_NODES).each do |i|
    config.vm.define "nodo0#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "nodo0#{i}"
        vb.memory = 2048
        vb.cpus = 2
      end
      node.vm.hostname = "nodo0#{i}"
      node.vm.network :public_network, ip: WORKER_IPS[i - 1], bridge: get_bridge_adapter()
      provision_kubernetes_node(node)
    end
  end
end
