job "metabase" {
  region = "campus"

  datacenters = ["bcdc"]

  type = "service"

  group "metabase" {
    network {
      port "http" {}
    }

    task "metabase" {
      driver = "docker"

      consul {}

      config {
        image = "metabase/metabase:v0.56.8"

        force_pull = true

        network_mode = "host"
      }

      template {
        data = <<EOH
{{- range $key, $value := (key "metabase" | parseJSON) -}}
{{- $key | trimSpace -}}={{- $value | toJSON }}
{{ end -}}
MB_JETTY_PORT={{ env "NOMAD_PORT_http" }}
EOH

        destination = "/secrets/.env"
        env = true
      }

      resources {
        cpu = 100
        memory = 512
        memory_max = 2048
      }

      service {
        name = "metabase"

        port = "http"

        tags = [
          "http"
        ]

        check {
          success_before_passing = 3
          failures_before_critical = 2

          interval = "1s"

          name = "HTTP"
          path = "/api/health"
          port = "http"
          protocol = "http"
          timeout = "1s"
          type = "http"
        }

        check_restart {
          limit = 5
          grace = "120s"
        }

        meta {
          nginx-config = trimspace(trimsuffix(trimspace(regex_replace(regex_replace(regex_replace(regex_replace(regex_replace(regex_replace(regex_replace(regex_replace(trimspace(file("nginx.conf")),"server\\s{\\s",""),"server_name\\s\\S+;",""),"root\\s\\S+;",""),"listen\\s.+;",""),"#.+\\n",""),";\\s+",";"),"{\\s+","{"),"\\s+"," ")),"}"))
          firewall-rules = jsonencode(["internet"])
          no-default-headers = true
        }
      }

      restart {
        attempts = 1
        delay = "10s"
        interval = "1m"
        mode = "fail"
      }
    }

    reschedule {
      attempts  = 0
      unlimited = false
    }
  }

  update {
    max_parallel = 0
  }
}
