##
locals {
  cloudinit= <<EOT
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker adminuser
EOT
  cloudinit2 = <<EOT
#cloud-config
package_upgrade: true
yum_repos:
  docker-ce:
    baseurl: https://download.docker.com/linux/centos/docker-ce.repo
    enabled: true
packages:
  - yum-utils
  - device-mapper-persistent-data
  - lvm2
  - docker-ce
  - docker-ce-cli
  - containerd.io

runcmd:
- curl --silent --remote-name https://releases.hashicorp.com/nomad/${var.NOMAD_VERSION}/nomad_${var.NOMAD_VERSION}_linux_amd64.zip
- unzip nomad_${var.NOMAD_VERSION}_linux_amd64.zip
- chown root:root nomad
- mv nomad /usr/local/bin/
- mkdir --parents /opt/nomad
write_files:
  - path: /etc/nomad.d/singlenode.hcl
    content: |
      datacenter = "dc1"
      data_dir = "/opt/nomad"
      bind_addr = "0.0.0.0" # the default

      server {
        enabled          = true
        bootstrap_expect = 1
      }

      client {
        enabled       = true
      }

      plugin "raw_exec" {
        config {
          enabled = true
        }
      }

  - path: /etc/systemd/system/nomad.service
    content: |
      [Unit]
      Description=Nomad
      Documentation=https://www.nomadproject.io/docs
      Wants=network-online.target
      After=network-online.target

      [Service]
      ExecReload=/bin/kill -HUP $MAINPID
      ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d
      KillMode=process
      KillSignal=SIGINT
      LimitNOFILE=infinity
      LimitNPROC=infinity
      Restart=on-failure
      RestartSec=2
      StartLimitBurst=3
      StartLimitIntervalSec=10
      TasksMax=infinity

      [Install]
      WantedBy=multi-user.target
runcmd:
  - [ systemctl, daemon-reload ]
  - [ systemctl, enable, nomad.service ]
  - [ systemctl, start, nomad.service ]

EOT
}