provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc_network" {
  name = "spark-kafka-vpc"
}

resource "google_compute_firewall" "default" {
  name    = "allow-internal-external"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "7077", "8080", "2181", "9092"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "nodes" {
  count        = var.node_count
  name         = "node-${count.index}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }

  metadata = {
    ssh-keys = "debian:${file("/home/pzero/python/pdd/zad2/.ssh/id_ed25519.pub")}"
  }

  tags = ["spark", "kafka"]
}

output "external_ips" {
  value = [for instance in google_compute_instance.nodes : instance.network_interface[0].access_config[0].nat_ip]
}
