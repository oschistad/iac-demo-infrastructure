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
  cloudinit3: <<EOT
write_files:
  - path: "/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7"
    permissions: "0644"
    owner: "root:root"
    content: |
      -----BEGIN PGP PUBLIC KEY BLOCK-----
      Version: GnuPG v1.4.11 (GNU/Linux)
      mQINBFKuaIQBEAC1UphXwMqCAarPUH/ZsOFslabeTVO2pDk5YnO96f+rgZB7xArB
      OSeQk7B90iqSJ85/c72OAn4OXYvT63gfCeXpJs5M7emXkPsNQWWSju99lW+AqSNm
      jYWhmRlLRGl0OO7gIwj776dIXvcMNFlzSPj00N2xAqjMbjlnV2n2abAE5gq6VpqP
      vFXVyfrVa/ualogDVmf6h2t4Rdpifq8qTHsHFU3xpCz+T6/dGWKGQ42ZQfTaLnDM
      jToAsmY0AyevkIbX6iZVtzGvanYpPcWW4X0RDPcpqfFNZk643xI4lsZ+Y2Er9Yu5
      S/8x0ly+tmmIokaE0wwbdUu740YTZjCesroYWiRg5zuQ2xfKxJoV5E+Eh+tYwGDJ
      n6HfWhRgnudRRwvuJ45ztYVtKulKw8QQpd2STWrcQQDJaRWmnMooX/PATTjCBExB
      9dkz38Druvk7IkHMtsIqlkAOQMdsX1d3Tov6BE2XDjIG0zFxLduJGbVwc/6rIc95
      T055j36Ez0HrjxdpTGOOHxRqMK5m9flFbaxxtDnS7w77WqzW7HjFrD0VeTx2vnjj
      GqchHEQpfDpFOzb8LTFhgYidyRNUflQY35WLOzLNV+pV3eQ3Jg11UFwelSNLqfQf
      uFRGc+zcwkNjHh5yPvm9odR1BIfqJ6sKGPGbtPNXo7ERMRypWyRz0zi0twARAQAB
      tChGZWRvcmEgRVBFTCAoNykgPGVwZWxAZmVkb3JhcHJvamVjdC5vcmc+iQI4BBMB
      AgAiBQJSrmiEAhsPBgsJCAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRBqL66iNSxk
      5cfGD/4spqpsTjtDM7qpytKLHKruZtvuWiqt5RfvT9ww9GUUFMZ4ZZGX4nUXg49q
      ixDLayWR8ddG/s5kyOi3C0uX/6inzaYyRg+Bh70brqKUK14F1BrrPi29eaKfG+Gu
      MFtXdBG2a7OtPmw3yuKmq9Epv6B0mP6E5KSdvSRSqJWtGcA6wRS/wDzXJENHp5re
      9Ism3CYydpy0GLRA5wo4fPB5uLdUhLEUDvh2KK//fMjja3o0L+SNz8N0aDZyn5Ax
      CU9RB3EHcTecFgoy5umRj99BZrebR1NO+4gBrivIfdvD4fJNfNBHXwhSH9ACGCNv
      HnXVjHQF9iHWApKkRIeh8Fr2n5dtfJEF7SEX8GbX7FbsWo29kXMrVgNqHNyDnfAB
      VoPubgQdtJZJkVZAkaHrMu8AytwT62Q4eNqmJI1aWbZQNI5jWYqc6RKuCK6/F99q
      thFT9gJO17+yRuL6Uv2/vgzVR1RGdwVLKwlUjGPAjYflpCQwWMAASxiv9uPyYPHc
      ErSrbRG0wjIfAR3vus1OSOx3xZHZpXFfmQTsDP7zVROLzV98R3JwFAxJ4/xqeON4
      vCPFU6OsT3lWQ8w7il5ohY95wmujfr6lk89kEzJdOTzcn7DBbUru33CQMGKZ3Evt
      RjsC7FDbL017qxS+ZVA/HGkyfiu4cpgV8VUnbql5eAZ+1Ll6Dw==
      =hdPa
      -----END PGP PUBLIC KEY BLOCK-----
  - path: "/etc/yum/pluginconf.d/fastestmirror.conf"
    permissions: "0644"
    owner: "root:root"
    content: |
      [main]
      enabled=0
      verbose=0
      always_print_best_host = true
      socket_timeout=3
      hostfilepath=timedhosts.txt
      maxhostfileage=10
      maxthreads=15
yum_repos:
  epel:
    name: "Extra Packages for Enterprise Linux 7 - $basearch"
    baseurl: "http://download.fedoraproject.org/pub/epel/7/$basearch"
    metalink: "https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch"
    failovermethod: "priority"
    enabled: true
    gpgcheck: true
    gpgkey: "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7"
packages:
  - chrony
  - docker-compose
  - docker-latest
  - etcd
  - iptables-services
  - yum-plugin-ovl
EOT
}