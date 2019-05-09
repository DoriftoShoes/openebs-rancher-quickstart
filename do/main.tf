# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = "${var.do_token}"
}

variable "do_token" {
  default = "xxx"
}

variable "prefix" {
  default = "yourname"
}

variable "rancher_version" {
  default = "latest"
}

variable "count_agent_all_nodes" {
  default = "3"
}

variable "count_agent_etcd_nodes" {
  default = "0"
}

variable "count_agent_controlplane_nodes" {
  default = "0"
}

variable "count_agent_worker_nodes" {
  default = "0"
}

variable "admin_password" {
  default = "admin"
}

variable "cluster_name" {
  default = "quickstart"
}

variable "region" {
  default = "ams3"
}

variable "server_size" {
  default = "s-2vcpu-4gb"
}

variable "all_size" {
  default = "s-2vcpu-4gb"
}

variable "controlplane_size" {
  default = "s-2vcpu-4gb"
}

variable "worker_size" {
  default = "s-2vcpu-4gb"
}

variable "etcd_size" {
  default = "s-2vcpu-4gb"
}

variable "docker_version_server" {
  default = "18.09"
}

variable "docker_version_agent" {
  default = "18.09"
}

variable "ssh_keys" {
  default = []
}

resource "digitalocean_droplet" "rancherserver" {
  count     = "1"
  image     = "ubuntu-18-04-x64"
  name      = "${var.prefix}-rancherserver"
  region    = "${var.region}"
  size      = "${var.server_size}"
  user_data = "${data.template_file.userdata_server.rendered}"
  ssh_keys  = "${var.ssh_keys}"
}

resource "digitalocean_droplet" "rancheragent-all" {
  count     = "${var.count_agent_all_nodes}"
  image     = "ubuntu-18-04-x64"
  name      = "${var.prefix}-rancheragent-${count.index}-all"
  region    = "${var.region}"
  size      = "${var.all_size}"
  user_data = "${data.template_file.userdata_agent.rendered}"
  ssh_keys  = "${var.ssh_keys}"
}

resource "digitalocean_droplet" "rancheragent-etcd" {
  count     = "${var.count_agent_etcd_nodes}"
  image     = "ubuntu-18-04-x64"
  name      = "${var.prefix}-rancheragent-${count.index}-etcd"
  region    = "${var.region}"
  size      = "${var.etcd_size}"
  user_data = "${data.template_file.userdata_agent.rendered}"
  ssh_keys  = "${var.ssh_keys}"
}

resource "digitalocean_droplet" "rancheragent-controlplane" {
  count     = "${var.count_agent_controlplane_nodes}"
  image     = "ubuntu-18-04-x64"
  name      = "${var.prefix}-rancheragent-${count.index}-controlplane"
  region    = "${var.region}"
  size      = "${var.controlplane_size}"
  user_data = "${data.template_file.userdata_agent.rendered}"
  ssh_keys  = "${var.ssh_keys}"
}

resource "digitalocean_volume" "rancheragent-worker-a" {
  count                   = "${var.count_agent_worker_nodes}"
  region                  = "${var.region}"
  name                    = "${var.prefix}-rancheragent-${count.index}-worker-a"
  size                    = 100
  description             = "Rancheragent worker volume A"
}

resource "digitalocean_volume" "rancheragent-worker-b" {
  count                   = "${var.count_agent_worker_nodes}"
  region                  = "${var.region}"
  name                    = "${var.prefix}-rancheragent-${count.index}-worker-b"
  size                    = 100
  description             = "Rancheragent worker volume B"
}

resource "digitalocean_volume" "rancheragent-worker-c" {
  count                   = "${var.count_agent_worker_nodes}"
  region                  = "${var.region}"
  name                    = "${var.prefix}-rancheragent-${count.index}-worker-c"
  size                    = 100
  description             = "Rancheragent worker volume C"
}

resource "digitalocean_droplet" "rancheragent-worker" {
  count      = "${var.count_agent_worker_nodes}"
  image      = "ubuntu-18-04-x64"
  name       = "${var.prefix}-rancheragent-${count.index}-worker"
  region     = "${var.region}"
  size       = "${var.worker_size}"
  user_data  = "${data.template_file.userdata_agent.rendered}"
  ssh_keys   = "${var.ssh_keys}"
  volume_ids = ["${element(digitalocean_volume.rancheragent-worker-a.*.id, count.index)}","${element(digitalocean_volume.rancheragent-worker-b.*.id, count.index)}","${element(digitalocean_volume.rancheragent-worker-c.*.id, count.index)}"]
}

data "template_file" "userdata_server" {
  template = "${file("files/userdata_server")}"

  vars {
    admin_password        = "${var.admin_password}"
    cluster_name          = "${var.cluster_name}"
    docker_version_server = "${var.docker_version_server}"
    rancher_version       = "${var.rancher_version}"
  }
}

data "template_file" "userdata_agent" {
  template = "${file("files/userdata_agent")}"

  vars {
    admin_password       = "${var.admin_password}"
    cluster_name         = "${var.cluster_name}"
    docker_version_agent = "${var.docker_version_agent}"
    rancher_version      = "${var.rancher_version}"
    server_address       = "${digitalocean_droplet.rancherserver.ipv4_address}"
  }
}

output "rancher-url" {
  value = ["https://${digitalocean_droplet.rancherserver.ipv4_address}"]
}
