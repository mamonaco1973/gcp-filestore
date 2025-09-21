resource "google_filestore_instance" "nfs_server" {
  name       = "nfs-server"
  tier       = "STANDARD"              # Options: BASIC_HDD, BASIC_SSD, HIGH_SCALE_SSD, ENTERPRISE
  location   = "us-central1-b"         # Must be a zone, not just a region
  project    = local.credentials.project_id

  file_shares {
    capacity_gb = 1024                 # 1 TB minimum
    name        = "filestore"
  }

  networks {
    network = data.google_compute_network.ad_vpc.name
    modes   = ["MODE_IPV4"]
  }
}


resource "google_compute_firewall" "allow_nfs" {
  name    = "allow-nfs"
  network = data.google_compute_network.ad_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["2049"]
  }

  allow {
    protocol = "udp"
    ports    = ["2049"]
  }

  source_ranges = ["0.0.0.0/0"] # ⚠️ Lab only; tighten to your subnet CIDR in production
}

