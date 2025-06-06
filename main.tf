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
    ports    = ["22","2049",   "3000-54057","7077","7078","4040" ,"8080","8081", "2181", "9092", "8888"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_disk" "nfs_disk" {
  name  = "nfs-disk"
  type  = "pd-standard"
  zone  = var.zone
  size  = 20
}

resource "google_compute_instance" "nfs_server" {
  name         = "nfs-server"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  attached_disk {
    source      = google_compute_disk.nfs_disk.id
    device_name = "nfs-disk"
  }

  network_interface {
    network       = google_compute_network.vpc_network.name
    access_config {}
  }

  metadata = {
    ssh-keys = "debian:${file("/home/pzero/python/pdd/zad2/.ssh/id_ed25519.pub")}"
  }

  service_account {
    email  = "default"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["nfs"]
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

  service_account {
    email  = "default"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["spark", "kafka"]
}

resource "google_compute_instance" "driver" {
  name         = "driver-node"
  machine_type = "e2-medium"
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

  service_account {
    email  = "default"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["spark", "driver"]
}



output "external_ips" {
  value = [for instance in google_compute_instance.nodes : instance.network_interface[0].access_config[0].nat_ip]
}


output "driver_ip" {
  value = google_compute_instance.driver.network_interface[0].access_config[0].nat_ip
}

output "nfs_internal_ip" {
  value = google_compute_instance.nfs_server.network_interface[0].network_ip
}
