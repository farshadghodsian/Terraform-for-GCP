#########################
####    Providers    ####
#########################

provider "google" {
  credentials = "${file("../../credentials.json")}"
  project     = "${var.project}"
  region      = "us-central1"
}

provider "google-beta"{
  credentials = "${file("../../credentials.json")}"
  project     = "${var.project}"
  region = "us-central1"
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


#####################
####    Disks    ####
#####################

resource "google_compute_image" "webserver-image" {
  name  = "mywebserver1"
  source_disk = "projects/${var.project}/zones/us-central1-a/disks/webserver"
}

#################################
####    Compute Instances    ####
#################################

resource "google_compute_instance" "stress-test" {
  depends_on = ["data.google_compute_subnetwork.subnet-a"]
  name = "stress-test"
  zone = "us-central1-a"
  machine_type = "f1-micro"

  tags = ["http-server", "https-server"]
  metadata = {
    startup-script-url =  "gs://www.learningautomation.io/apache-mystartupscript.sh"
    my-server-id = "stress-test"
    }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
    auto_delete = true
  }

  network_interface {
    subnetwork = "${data.google_compute_subnetwork.subnet-a.self_link}"
    access_config = {
    }
  }
}

#####################################
####    Managed Instance Group   ####
#####################################

resource "google_compute_instance_template" "webserver-template" {
  name        = "webserver-template"
  description = "This template is used to create web server instances."
  region      = "us-central1"
  depends_on = ["google_compute_image.webserver-image"]
  tags = ["http-server", "https-server"]

  machine_type         = "f1-micro"

  metadata = {
    startup-script-url =  "gs://www.learningautomation.io/hostname-script.sh"
  }
  
  // Create a new boot disk from an image
  disk {
    source_image = "${google_compute_image.webserver-image.name}"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
  }

}
resource "google_compute_http_health_check" "webserver-healthcheck" {
  provider = "google-beta"
  name                = "webserver-healthcheck"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
  request_path = "/"
}

resource "google_compute_region_instance_group_manager" "mywebserver-group" {
  provider = "google-beta"
  name = "mywebserver-group"
  region = "us-central1"

  base_instance_name = "webserver"
  named_port = {
    name = "http"
    port = 80
  }
  version {
  instance_template  = "${google_compute_instance_template.webserver-template.self_link}"
  name = "web"
  }

  auto_healing_policies {
    health_check      = "${google_compute_http_health_check.webserver-healthcheck.self_link}"
    initial_delay_sec = 60
  }
}
resource "google_compute_region_autoscaler" "mywebserver-autoscaler" {
  provider = "google-beta"
  name   = "mywebserver-autoscaler"
  region = "us-central1"
  target = "${google_compute_region_instance_group_manager.mywebserver-group.self_link}"

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

##################################
####    HTTP Load Balancer    ####
##################################
resource "google_compute_backend_service" "mywebserver-backend" {
  name        = "mywebserver-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  
  health_checks = ["${google_compute_http_health_check.webserver-healthcheck.self_link}"]
  backend = {
   group = "${google_compute_region_instance_group_manager.mywebserver-group.instance_group}"
   max_utilization = 0.5
  }
}

resource "google_compute_url_map" "webserver-load-balancer" {
  name            = "webserver-load-balancer"
  description     = "The Load Balancer"
  default_service = "${google_compute_backend_service.mywebserver-backend.self_link}"
}

resource "google_compute_target_http_proxy" "http-proxy" {
  name        = "webserver-loadbalancer"
  url_map     = "${google_compute_url_map.webserver-load-balancer.self_link}"
}

resource "google_compute_global_forwarding_rule" "mywebserver-frontend" {
  name       = "mywebserver-frontend"
  target     = "${google_compute_target_http_proxy.http-proxy.self_link}"
  port_range = "80"
}
#######################
####    Outputs    ####
#######################

output "Load_Balancer_IP" {
  depends_on=["google_compute_global_forwarding_rule.mywebserver-frontend"]
  value = "http://${google_compute_global_forwarding_rule.mywebserver-frontend.0.ip_address}"
  description = "External Load Balancer IP to access webservers"
}

output "stress-test_externalip" {
  depends_on=["google_compute_instance.stress-test"]
  value = "${google_compute_instance.stress-test.network_interface.0.access_config.0.nat_ip}"
  description = "External IP to access stress-test server"
}