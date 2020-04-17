#cloud-config

users:
  - default
  - name: slavko
    passwd: $1$slavko$3qoKYqsEr9ZU9xhAiTTuB.
    ssh_pwauth: True
    chpasswd: { expire: False }
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCzT2CJoS/GjsHxa4cWxoaVKkvGL+angx2jYlR62t4/pHZ8JNS2Q+Ptb+YL5UHiwOV74sOUn0PrKDDGoc+BSUTHX6E28Vz1YfRUrL6lLJ/JRg3ZIARXSuOdF87/FakGc83wi3YV7oFb7EtQObrDmIj01XPLATaGsfeK/0sywFgAmIDnIUWVn/asc+ijON0VCmbiXkcbb7/S+MIIOr08FtpJ6u8bJVwGCOdxn2GdcJ4Wu2TZRq20DmNWDu1iNj3JY5ADMC7rOL2F+mfuT8QjQyAX5nMJCp4ere0JdLUznZiiUZacu7vpqh9lLgxIgK1PFZwm6RiM2/s5PvPHLNJTrNLB t480@main

packages:
 - ntp
 - ntpdate
 - curl

# Override ntp with chrony configuration on Ubuntu
ntp:
  enabled: true
  ntp_client: chrony  # Uses cloud-init default chrony configuration
runcmd:
    - date > /tmp/cloudinit.log
    - whoami >> /tmp/cloudinit.log
    - sudo dhclient ens36
    - sudo echo "Done tf cloud-init" >>/tmp/cloudinit.log


# Override ntp with chrony configuration on Ubuntu
ntp:
  enabled: true
  ntp_client: chrony  # Uses cloud-init default chrony configuration

# More ideas  https://cloudinit.readthedocs.io/en/latest/topics/examples.html
