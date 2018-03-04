// This script will spin up a few resources:
//
// - Kubernetes cluster in GCE
// - Replication controller of the sreeval docker image
// - Service (Should be a DaemonSet) of datadog agent software
// - Monitor in datadog to report / email on down container nodes

variable "cluster_name" {
  default = "sreeval-ec-k8s-cluster"
}

// kubernetes desired username and password
variable "k8s_username" {}

variable "k8s_password" {}

// Your datadog credentials
variable "datadog_api_key" {}

variable "datadog_app_key" {}

// Where alerts should be sent to
variable "alert_email" {}

variable "region" {
  default = "us-east1"
}

provider "google" {
  region = "${var.region}"

  // Provider settings to be provided via ENV variables
}

provider "datadog" {
  api_key = "${var.datadog_api_key}"
  app_key = "${var.datadog_app_key}"
}

provider "kubernetes" {
  host     = "https://${google_container_cluster.primary.endpoint}"
  username = "${var.k8s_username}"
  password = "${var.k8s_password}"
}

data "google_compute_zones" "available" {}

resource "google_container_cluster" "primary" {
  name               = "${var.cluster_name}"
  zone               = "${data.google_compute_zones.available.names[0]}"
  initial_node_count = 3

  additional_zones = [
    "${data.google_compute_zones.available.names[1]}",
  ]

  master_auth {
    username = "${var.k8s_username}"
    password = "${var.k8s_password}"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "kubernetes_replication_controller" "app" {
  metadata {
    name = "sreeval"

    labels {
      App = "sreeval"
    }
  }

  spec {
    selector {
      App = "sreeval"
    }

    replicas = 3

    template {
      container {
        image = "gaieges/sreeval:v1.2"
        name  = "sreeval"

        port {
          container_port = 1234
          protocol       = "UDP"
        }

        resources {
          limits {
            cpu    = "0.5"
            memory = "512Mi"
          }

          requests {
            cpu    = "250m"
            memory = "50Mi"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "lb" {
  metadata {
    name = "sreeval-lb"
  }

  spec {
    selector {
      App = "${kubernetes_replication_controller.app.metadata.0.labels.App}"
    }

    session_affinity = "ClientIP"

    port {
      port        = 1234
      target_port = 1234
      protocol    = "UDP"
    }

    type = "LoadBalancer"
  }
}

# add data dog agent helm
resource "kubernetes_replication_controller" "datadog-agent" {
  metadata {
    name = "datadog-agent"

    labels {
      App = "DataDogAgentRS"
    }
  }

  spec {
    selector {
      App = "datadogAgent"
    }

    replicas = 6 # TODO: should be the count of nodes, or better yet, a container per node

    template {
      container {
        image = "datadog/agent:latest"
        name  = "datadog-agent"

        resources {
          limits {
            cpu    = "100m"
            memory = "512Mi"
          }

          requests {
            cpu    = "100m"
            memory = "128Mi"
          }
        }

        port {
          container_port = 8125
          name           = "datastatsdport"
          protocol       = "UDP"
        }

        env {
          name  = "DD_API_KEY"
          value = "${var.datadog_api_key}"
        }

        env {
          name  = "KUBERNETES"
          value = "yes"
        }

        env {
          name = "DD_KUBERNETES_KUBELET_HOST"

          value_from {
            field_ref {
              field_path = "status.hostIP"
            }
          }
        }

        volume_mount {
          name       = "dockersocket"
          mount_path = "/var/run/docker.sock"
        }

        volume_mount {
          name       = "procdir"
          mount_path = "/host/proc"
          read_only  = true
        }

        volume_mount {
          name       = "cgroups"
          mount_path = "/host/sys/fs/cgroup"
          read_only  = true
        }
      }

      volume {
        name = "dockersocket"

        host_path {
          path = "/var/run/docker.sock"
        }
      }

      volume {
        name = "cgroups"

        host_path {
          path = "/sys/fs/cgroup"
        }
      }

      volume {
        name = "procdir"

        host_path {
          path = "/proc"
        }
      }
    }
  }
}

# add data dog monitor to check for containers down
resource "datadog_monitor" "containerdown" {
  name                = "SREEval container count low"
  query               = "change(avg(last_5m),last_5m):sum:docker.containers.running{kube_replication_controller:sreeval} by {container_id} < -2"
  type                = "query alert"
  notify_no_data      = false
  include_tags        = true
  notify_audit        = true
  require_full_window = false

  thresholds {
    ok       = 0
    warning  = -1
    critical = -2
  }

  message = "SREeval container count: {{value}} @${var.alert_email}"
}

output "app_datadog_monitor_url" {
  value = "https://app.datadoghq.com/monitors#${datadog_monitor.containerdown.id}"
}

output "app_ingress_ip" {
  value = "${kubernetes_service.lb.load_balancer_ingress.0.ip}"
}

output "k8s_cluster_name" {
  value = "${google_container_cluster.primary.name}"
}

output "k8s_primary_zone" {
  value = "${google_container_cluster.primary.zone}"
}

output "k8s_additional_zones" {
  value = "${google_container_cluster.primary.additional_zones}"
}

output "k8s_endpoint" {
  value = "${google_container_cluster.primary.endpoint}"
}

output "k8s_version" {
  value = "${google_container_cluster.primary.node_version}"
}
