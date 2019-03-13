#########################
####    Providers    ####
#########################

provider "google" {
  credentials = "${file("../credentials.json")}"
  project     = "learning-automation-test"
  region      = "us-east1"
}


############################
####    VPC Networks    ####
############################

resource "google_compute_subnetwork" "subnet-a" {
  name          = "subnet-a"
  ip_cidr_range = "10.5.4.0/24"
  region        = "us-east1"
  network       = "${google_compute_network.vpn-network-1.self_link}"
  # secondary_ip_range {
  #   range_name    = "tf-test-secondary-range-update1"
  #   ip_cidr_range = "192.168.10.0/24"
  # }
}

resource "google_compute_network" "vpn-network-1" {
  name                    = "vpn-network-1"
  auto_create_subnetworks = "false"
  description = "Primary VPC Network in US-East Region"
}

resource "google_compute_subnetwork" "subnet-b" {
  name          = "subnet-b"
  ip_cidr_range = "10.1.3.0/24"
  region        = "europe-west1"
  network       = "${google_compute_network.vpn-network-2.self_link}"
  # secondary_ip_range {
  #   range_name    = "tf-test-secondary-range-update1"
  #   ip_cidr_range = "192.168.10.0/24"
  # }
}

resource "google_compute_network" "vpn-network-2" {
  name                    = "vpn-network-2"
  auto_create_subnetworks = "false"
  description = "Alternate VPC Network in Europe-West Region"
}

##############################
####    Firewall Rules    ####
##############################

resource "google_compute_firewall" "allow-icmp-ssh-network-1" {
  name    = "allow-icmp-ssh-network-1"
  network = "${google_compute_network.vpn-network-1.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  #source_tags = ["web"]
}

resource "google_compute_firewall" "allow-icmp-ssh-network-2" {
  name    = "allow-icmp-ssh-network-2"
  network = "${google_compute_network.vpn-network-2.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  #source_tags = ["web"]
}

#################################
####    Compute Instances    ####
#################################
resource "google_compute_instance" "server-1" {
    depends_on = ["google_compute_subnetwork.subnet-a"]
    name = "server-1"
    zone = "us-east1-b"
    machine_type = "f1-micro"


  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-a.self_link}"
    access_config = {
    }
  }
  # service_account {
  #   email = ""
  #   scopes = ["compute-rw"]
  # }
}

resource "google_compute_instance" "server-2" {
    depends_on = ["google_compute_subnetwork.subnet-b"]
    name = "server-2"
    zone = "europe-west1-b"
    machine_type = "f1-micro"


  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet-b.self_link}"
    access_config = {
    }
  }
  # service_account {
  #   email = ""
  #   scopes = ["compute-rw"]
  # }
}


#######################
####    Outputs    ####
#######################

output "server-1_externalip" {
  depends_on=["google_compute_instance.server-1"]
  value = "${google_compute_instance.server-1.network_interface.0.access_config.0.nat_ip}"
  description = "External IP to access server-1"
}

output "server-1_internalip" {
  depends_on=["google_compute_instance.server-1"]
  value = "${google_compute_instance.server-1.network_interface.0.network_ip}"
  description = "Internal IP to access server-1"
}

output "server-2_externalip" {
  depends_on=["google_compute_instance.server-2"]
  value = "${google_compute_instance.server-2.network_interface.0.access_config.0.nat_ip}"
  description = "External IP to access server-2"
}

output "server-2_internalip" {
  depends_on=["google_compute_instance.server-2"]
  value = "${google_compute_instance.server-2.network_interface.0.network_ip}"
  description = "Internal IP to access server-2"
}