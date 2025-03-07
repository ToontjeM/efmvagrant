# EDB Failover Manager demo

## Intro
This demo is deployed using Vagrant and will deploy the following nodes:
![](https://www.enterprisedb.com/docs/static/68da4913f0bb3b9a09585ec16cf63c5f/0c69d/failover_manager_overview.png)
| Name | IP | Cluster | Task | Remarks |
| -------- | -------- | ----- | -------- | -------- |
| pg1 | 192.168.56.11 | efm | Postgres Primary |  |
| pg2 | 192.168.56.12 | efm | Postgres Standby | |
| w1 | 192.168.56.13 | efm | Witness |  |
| VIP | 192.168.56.99 | efm | EFM VIP address | |

## Demo prep
### Pre-requisites
To deploy this demo the following needs to be installed in the PC from which you are going to deploy the demo:

- VirtualBox (https://www.virtualbox.org/)
- Vagrant (https://www.vagrantup.com/)
- Vagrant Hosts plug-in (`vagrant plugin install vagrant-hosts`)
- Vagrant Reload plug-in (`vagrant plugin install vagrant-reload`)
- A file called `.edbtoken` with your EDB repository 2.0 token. This token can be found in your EDB account profile here: https://www.enterprisedb.com/accounts/profile

The environment is deloyed in a VirtualBox **public** network. Adjust the IP addresses to your needs in `vars.yml`.

The EFM cluster which is created is called `efm`. 

Status of the EFM cluster can be shown using `/usr/edb/efm-4.8/bin/efm cluster-status pgcluster` from `primary` and as user `efm`. The provisioning process will also show you the progress of the cluster while the three machines are configured.

### Provisioning VM's.
Provision the hosts using `vagrant up`. This will create the bare virtual machines and will take appx. 5 minutes to complete. 

After provisioning, the hosts will have the current directory mounted in their filesystem under `/vagrant`

### Passwords
All passwords for the users `postgres`, `enterprisedb` en `efm` are the same as the usernames.

## Extra
### Configuring EFM in PEM
After provisioning the EFM environment the installation script will ask you if yo want to enroll the servers in PEM. This will call `registerPEM.sh` and assumes an existing PEM server. Please make sure that the correct IP for the PEM server is used in `env.sh`.

### Enable all probes
To be able to show all use cases you have to enable extra probes:
- In the top menu, select `Management / Manage Probes...`
- Click `manage Custom Probes` and switch `Show System Probes?` to On.
- Enable all probes except `xDB Replication` and the `PGD` probes. We are not using PGD here (yet?).
- Make sure you click the `Save` icon at the top of the table.

## Demo flow
TBD

## Demo cleanup
To clean up the demo environment you just have to run `99-deprovision.sh`. This script will remove the virtual machines and the cluster configuration.

## TODO / To fix
