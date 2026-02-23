provider "google" {
  credentials = file("C:/TERRAFORM/key/credentials.json") # Use forward slashes on Windows
  project     = "my-ever-first-project"
  region      = "us-central1"
  zone        = "us-central1-a"
  #manoj
}

# -------------------------------
# VPC and Subnet
# -------------------------------
resource "google_compute_network" "vpc_network" {
  name                    = "two-tier-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "two-tier-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
}

# -------------------------------
# Firewall Rule (allow SSH + HTTP)
# -------------------------------
resource "google_compute_firewall" "allow_ssh_http" {
  name    = "allow-ssh-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# # -------------------------------
# # VM Instances
# # -------------------------------
# resource "google_compute_instance" "web_vm" {
#   name         = "web-tier-vm"
#   machine_type = "e2-medium"
#   zone         = "us-central1-a"
#   deletion_protection = false

#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-11"
#     }
#   }

#   network_interface {
#     subnetwork   = google_compute_subnetwork.subnet.name
#     access_config {} # External IP
#   }
# }

# resource "google_compute_instance" "app_vm" {
#   name         = "app-tier-vm"
#   machine_type = "e2-medium"
#   zone         = "us-central1-a"
#   deletion_protection = false

#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-11"
#     }
#   }

#   network_interface {
#     subnetwork   = google_compute_subnetwork.subnet.name
#     access_config {} # External IP
#   }
# }

# -------------------------------
# Cloud SQL Instance (MySQL)
# -------------------------------
# resource "google_sql_database_instance" "db_instance" {
#   name             = "two-tier-sql"
#   database_version = "MYSQL_8_0"
#   region           = "us-central1"
#   deletion_protection = false

#   settings {
#     tier = "db-f1-micro"
#     ip_configuration {
#       ipv4_enabled    = true
#       authorized_networks {
#         name  = "vpc-access"
#         value = "0.0.0.0/0" # For demo; restrict in production
#       }
#     }
#   }
# }

# resource "google_sql_database" "app_db" {
#   name     = "appdb"
#   instance = google_sql_database_instance.db_instance.name
# }

# resource "google_sql_user" "db_user" {
#   name     = "appuser"
#   instance = google_sql_database_instance.db_instance.name
#   password = "StrongPassword123!"
# }

# -------------------------------
# Cloud SQL Instance (postgress)
# -------------------------------

resource "google_sql_database_instance" "postgres_instance" {
  name                = "my-postgres-instance"
  database_version    = "POSTGRES_14"
  region              = "us-central1"
  deletion_protection = false

  settings {
    tier              = "db-f1-micro" # small test tier, change for prod
    disk_size         = 20            # GB
    disk_type         = "PD_SSD"
    availability_type = "ZONAL"
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "vpc-access"
        value = "0.0.0.0/0" # For demo; restrict in production
      }
    }
    backup_configuration {
      enabled = true
    }
  }
}

resource "google_sql_database" "mydb" {
  name     = "my_database"
  instance = google_sql_database_instance.postgres_instance.name
}

resource "google_sql_user" "db_user1" {
  name     = "appuser1"
  instance = google_sql_database_instance.postgres_instance.name
  password = "SuperSecurePassword123!" # use Terraform variables or secrets
}
