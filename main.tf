resource "juju_application" "amf" {
  name = "amf"
  model = var.model_name

  charm {
    name = "sdcore-amf-k8s"
    channel = var.channel
  }

  units = 1
  trust = true
}

module "mongodb-k8s" {
  source     = "gatici/mongodb-k8s/juju"
  model_name = var.model_name
}

module "self-signed-certificates" {
  source     = "gatici/self-signed-certificates/juju"
  model_name = var.model_name
}

module "sdcore-nrf-k8s" {
  source  = "gatici/sdcore-nrf-k8s/juju"
  model_name = var.model_name
  certs_application_name = module.self-signed-certificates.certs_application_name
  db_application_name = module.mongodb-k8s.db_application_name
  channel = var.channel
}

resource "juju_integration" "amf-db" {
  model = var.model_name

  application {
    name     = juju_application.amf.name
    endpoint = "database"
  }

  application {
    name     = module.mongodb-k8s.db_application_name
    endpoint = "database"
  }
}

resource "juju_integration" "amf-certs" {
  model = var.model_name

  application {
    name     = juju_application.amf.name
    endpoint = "certificates"
  }

  application {
    name     = module.self-signed-certificates.certs_application_name
    endpoint = "certificates"
  }
}

resource "juju_integration" "amf-nrf" {
  model = var.model_name

  application {
    name     = juju_application.amf.name
    endpoint = "fiveg-nrf"
  }

  application {
    name     = module.sdcore-nrf-k8s.nrf_application_name
    endpoint = "fiveg-nrf"
  }
}

