resource "kubernetes_deployment" "deployment" {
  metadata {
    name = var.deployment_name
    labels = {
      App = "${var.deployment_name}-app"
    }
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        App = "${var.deployment_name}-app"
      }
    }
    template {
      metadata {
        labels = {
          App = "${var.deployment_name}-app"
        }
      }
      spec {
        container {
          image = var.image
          image_pull_policy = "Always"
          name  = "${var.deployment_name}-container"

          dynamic "env" {
            for_each = var.env
            content {
              name  = env.value.name
              value = env.value.value
            }
          }

          port {
            container_port = var.container_port
          }
        }

        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key = "worker-type"
                  operator = "NotIn"
                  values = ["batch-jobs"]
                }
              }
            }
          }
        }

        service_account_name = var.service_account_name
      }
    }
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name = var.service_name
  }
  spec {
    selector = {
      App = kubernetes_deployment.deployment.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = var.load_balancer_port
      target_port = var.container_port
    }

    type = "LoadBalancer"
  }
}
