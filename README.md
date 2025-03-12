# EDB Failover Manager demo

## Intro
This demo is deployed using Vagrant and will deploy the following nodes:
![](https://www.enterprisedb.com/docs/static/68da4913f0bb3b9a09585ec16cf63c5f/0c69d/failover_manager_overview.png)
| Name | IP | Cluster | Task | Remarks |
| -------- | -------- | ----- | -------- | -------- |
| pg1 | 192.168.56.11 | efm | Postgres Primary |  |
| pg2 | 192.168.56.12 | efm | Postgres Standby | |
| w1 | 192.168.56.13 | efm | Witness |  |
| VIP | 192.168.56.20 | efm | EFM VIP address | |

## Demo prep
### Pre-requisites
To deploy this demo the following needs to be installed in the PC from which you are going to deploy the demo:

- VirtualBox (https://www.virtualbox.org/)
- Vagrant (https://www.vagrantup.com/)
- Vagrant Hosts plug-in (`vagrant plugin install vagrant-hosts`)
- Vagrant Reload plug-in (`vagrant plugin install vagrant-reload`)
- A file called `.edb_subscription_token` with your EDB repository 2.0 token. This token can be found in your EDB account profile here: https://www.enterprisedb.com/accounts/profile

The environment is deloyed in a VirtualBox network. Please check if the private network in your VirtualBox setup is `192.168.56.0`.

### Provisioning
Provision the demo environment like always using `00-provision.sh`.

After provisioning, the hosts will have their regular directory mounts as defined in the `Vagrantfile`:
```
  config.vm.synced_folder ".", "/vagrant"
  config.vm.synced_folder "./scripts", "/vagrant_scripts"
  config.vm.synced_folder "./config", "/vagrant_config"
  config.vm.synced_folder "#{ENV['HOME']}/tokens", "/tokens"
```

### Passwords
All passwords for the users `postgres`, `enterprisedb` en `efm` are the same as the usernames.

The EFM cluster which is created is called `efm`. 

Status of the EFM cluster can be shown using `/usr/edb/efm-4.10/bin/efm cluster-status efm` from `pg1` and as user `efm`. The provisioning process will also show you the progress of the cluster while the three machines are configured.
```
[efm@pg1 ~]$ /usr/edb/efm-4.10/bin/efm cluster-status efm
Cluster Status: efm

        Agent Type  Address              DB       VIP
        ----------------------------------------------------------------
        Primary     192.168.56.11        UP       192.168.56.20*
        Standby     192.168.56.12        UP       192.168.56.20
        Witness     192.168.56.13        N/A      192.168.56.20

Allowed node host list:
        192.168.56.11 192.168.56.12 192.168.56.13

Membership coordinator: 192.168.56.11

Standby priority host list:
        192.168.56.12

Promote Status:

        DB Type     Address              WAL Received LSN   WAL Replayed LSN   Info
        ---------------------------------------------------------------------------
        Primary     192.168.56.11                           0/4000168          
        Standby     192.168.56.12        0/4000168          0/4000168          

        Standby database(s) in sync with primary. It is safe to promote.
```

## Demo flow
- Open three terminal panes, one for the primary, one for the witness and one to a local machine which has the Postgres Client Tools installed.

**W1**
- `sudo su - efm`
- `watch sudo /usr/edb/efm-4.10/bin/efm cluster-status efm` | |

**Client**
- `01-client_create_table.sh`
  ```
  psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'CREATE TABLE test (id SERIAL PRIMARY KEY, random_text TEXT);' edb

  CREATE TABLE
  ```

- `02-client_insert_data.sh`
  ```
  psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'INSERT INTO test (random_text) SELECT md5(random()::text) FROM generate_series(1, 100);' edb
  
  INSERT 0 100
  ```

Show LSN updating on both nodes indicating that replication is working.

- `03-client_show_data.sh`
```
psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'SELECT * FROM test LIMIT 10;' edb

psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'SELECT count(*) FROM test;' edb

 id |           random_text            
----+----------------------------------
  1 | 064b2d6f62f7d2a76957a362b10484b5
  2 | 1b65525a0b3598a0be87d524fc3431d9
  3 | c5ddc91f4a64ae00aaab4c926754f497
  4 | 9d15738d5c94e7a1542052e977905337
  5 | a0fe83d80a262fc1af30983b6a442a51
  6 | a0d00a4c8b987e24825ab9dfd41bc6c3
  7 | 45bfd0729730c16782a376fe98293e42
  8 | da92e3f0c28bc09b60d8a29a01ddf065
  9 | b2facaddacc56ac40adbb32253fd106e
 10 | 21f1c7df9e23e8171082045c5cb5a863
(10 rows)

 count 
-------
   100
(1 row)
```

**PG1**
- `03-pg1_stop_postgres.sh`
  Notice that EFM will detect Postgres not available and will performa a failover.
  ```
  Cluster Status: efm
  
          Agent Type  Address              DB       VIP
          ----------------------------------------------------------------
          Idle        192.168.56.11        UNKNOWN  192.168.56.20
          Primary     192.168.56.12        UP       192.168.56.20*
          Witness     192.168.56.13        N/A      192.168.56.20
  
  Allowed node host list:
          192.168.56.11 192.168.56.12 192.168.56.13
  
  Membership coordinator: 192.168.56.11
  
  Standby priority host list:
          (List is empty.)
  
  Promote Status:
  
          DB Type     Address              WAL Received LSN   WAL Replayed LSN   Info
          ---------------------------------------------------------------------------
          Primary     192.168.56.12                           0/40B01C0
  
          No standby databases were found.
  
  Idle Node Status (idle nodes ignored in WAL LSN comparisons):
  
          Address              WAL Received LSN   WAL Replayed LSN   Info
          ---------------------------------------------------------------
          192.168.56.11        UNKNOWN            UNKNOWN            Connection to 192.168.56.11:5444 refused. Check
  that the hostname and port are correct and that the postmaster is accepting TCP/IP connections.
  ```

**Client**
- `05-client_show_data.sh`
  ```
  FATAL:  terminating connection due to administrator command
  server closed the connection unexpectedly
          This probably means the server terminated abnormally
          before or while processing the request.
  The connection to the server was lost. Attempting reset: Succeeded.
  psql (17.4 (Homebrew), server 17.4.0)
  WARNING: psql major version 17, server major version 17.
           Some psql features might not work.
  edb=# select count(*) from test;
   count 
  -------
     100
  (1 row)
  ```
- `06-client_insert_more_data.sh`
  ```
  psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'INSERT INTO test (random_text) SELECT md5(random()::text) FROM generate_series(1, 100);' edb
  
  INSERT 0 100
  ```

**PG1**
- `07-pg1_start_postgres.sh`
  ```
  sudo su - enterprisedb -c 'pg_ctl start -D '
  
  waiting for server to start....2025-03-12 12:55:32 UTC LOG:  redirecting log output to logging collector process
  2025-03-12 12:55:32 UTC HINT:  Future log output will appear in directory "log".
   stopped waiting
  pg_ctl: could not start server
  Examine the log output.
  ```
- `08-pg1_show_log.sh
  ```
  sudo su - enterprisedb -c 'tail -f <latest postgres.log>'
  
  2025-03-12 12:55:32 UTC LOG:  starting PostgreSQL 17.4 (EnterpriseDB Advanced Server 17.4.0) on x86_64-pc-linux-gnu, compiled by gcc (GCC) 11.5.0 20240719 (Red Hat 11.5.0-5), 64-bit
  2025-03-12 12:55:32 UTC LOG:  listening on IPv4 address "0.0.0.0", port 5444
  2025-03-12 12:55:32 UTC LOG:  listening on IPv6 address "::", port 5444
  2025-03-12 12:55:32 UTC LOG:  listening on Unix socket "/tmp/.s.PGSQL.5444"
  2025-03-12 12:55:32 UTC LOG:  database system was shut down at 2025-03-12 12:23:04 UTC
  2025-03-12 12:55:32 UTC FATAL:  using recovery command file "recovery.conf" is not supported
  2025-03-12 12:55:32 UTC LOG:  startup process (PID 14293) exited with exit code 1
  2025-03-12 12:55:32 UTC LOG:  aborting startup due to startup process failure
  2025-03-12 12:55:32 UTC LOG:  database system is shut down
  ```

- `09-pg1_recover_pg1.sh
```
Remove old database'
rm -rf ${PGDATA}/*


Restore database from standby
pg_basebackup -h pg2 -D /var/lib/edb-as/17/data -U replicator -P -R
57627/57627 kB (100%), 1/1 tablespace

Restart pg1 as standby'
sudo systemctl restart edb-as-17
```

Show efm cluster status.

```
Cluster Status: efm

        Agent Type  Address              DB       VIP
        ----------------------------------------------------------------
        Idle        192.168.56.11        UNKNOWN  192.168.56.20
        Primary     192.168.56.12        UP       192.168.56.20*
        Witness     192.168.56.13        N/A      192.168.56.20

Allowed node host list:
        192.168.56.11 192.168.56.12 192.168.56.13

Membership coordinator: 192.168.56.11

Standby priority host list:
        (List is empty.)

Promote Status:

        DB Type     Address              WAL Received LSN   WAL Replayed LSN   Info
        ---------------------------------------------------------------------------
        Primary     192.168.56.12                           0/6000060

        No standby databases were found.

Idle Node Status (idle nodes ignored in WAL LSN comparisons):

        Address              WAL Received LSN   WAL Replayed LSN   Info
        ---------------------------------------------------------------
        192.168.56.11        0/6000000          0/6000000          DB is in recovery.
```


## Demo cleanup
To clean up the demo environment you just have to run `99-deprovision.sh`. This script will remove the virtual machines and the cluster configuration.

## TODO / To fix
