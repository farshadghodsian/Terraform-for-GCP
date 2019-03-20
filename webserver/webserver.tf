
#########################
####    Providers    ####
#########################

provider "google" {
  credentials = "${file("../../credentials.json")}"
  project     = "${var.project}"
  region      = "us-central1"
}

############################
####    VPC Networks    ####
############################

data "google_compute_network" "vpn-network-1" {
  name = "default"
}

data "google_compute_subnetwork" "subnet-a" {
  # depends_on = ["data.google_compute_network.vpn-network-1"]
  name = "default"
  region = "us-central1"
  //network = "${data.google_compute_network.vpn-network-1.name}"
}

##############################
####    Firewall Rules    ####
##############################

resource "google_compute_firewall" "default-allow-http-https" {
  name    = "default-allow-http-https"
  network = "${data.google_compute_network.vpn-network-1.name}"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["http-server", "https-server"]
}

#################################
####    Compute Instances    ####
#################################
resource "google_compute_instance" "webserver" {
  depends_on = ["data.google_compute_subnetwork.subnet-a"]
  name = "webserver"
  zone = "us-central1-a"
  machine_type = "f1-micro"

  tags = ["http-server", "https-server"]
  metadata = {
    startup-script-url =  "gs://www.learningautomation.io/apache-mystartupscript.sh"
    my-server-id = "webserver"
    }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
    auto_delete = false
  }

  network_interface {
    subnetwork = "${data.google_compute_subnetwork.subnet-a.self_link}"
    access_config = {
    }
  }
}


#######################
####    Outputs    ####
#######################

output "webserver_externalip" {
  depends_on=["google_compute_instance.webserver"]
  value = "${google_compute_instance.webserver.network_interface.0.access_config.0.nat_ip}"
  description = "External IP to access webserver"
}

output "webserver_internalip" {
  depends_on=["google_compute_instance.webserver"]
  value = "${google_compute_instance.webserver.network_interface.0.network_ip}"
  description = "Internal IP to access webserver"
}