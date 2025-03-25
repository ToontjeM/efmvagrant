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
  config.vm.synced_folder "./scripts", "/scripts"
  config.vm.synced_folder "./config", "/config"
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
- `watch sudo /usr/edb/efm-4.10/bin/efm cluster-status efm`

**Client**
- `01-client_create_table.sh`
  ```
  Create table test
  
  
  psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'CREATE TABLE test (id SERIAL PRIMARY KEY, random_text TEXT);' edb
  
  CREATE TABLE
  ```

- `02-client_insert_data.sh`
  ```
  Insert 100 records in table
  
  
  psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'INSERT INTO test (random_text) SELECT md5(random()::text) FROM generate_series(1, 100);' edb
  
  INSERT 0 100
  ```

Show LSN updating on both nodes indicating that replication is working.

- `03-client_show_data.sh`
  ```
  Show records in database


  psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'SELECT * FROM test LIMIT 10;' edb
  
   id |           random_text            
  ----+----------------------------------
    1 | 6761b3dfe540fee4a09ea840d0f47fa7
    2 | 07569e5010acb920cd4ed6870338869e
    3 | ff31d9a5f4e09a9a934575ae106ecad0
    4 | d402401137f48adbbafa55267af07976
    5 | 1ac91c404d8456565d3f1d3a0f7060ae
    6 | 192a19fdd9ea7b4201e99daede797348
    7 | 14f14ae2cf3e74a8c01580de45dce54c
    8 | addb099d3dad1fd6de90e62c99f33e54
    9 | 2a460a667a5c540a39e92eb12e1beca1
   10 | 31dc792536844d4195f8d721c08815af
  (10 rows)
  
  
  psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'SELECT count(*) FROM test;' edb
  
   count 
  -------
     100
  (1 row)
  ```

**PG1**
- `04-pg1_stop_postgres.sh`
  ```
  Primary database failure!
  
  
  sudo su - enterprisedb -c 'pg_ctl stop -D '
  
  waiting for server to shut down.... done
  server stopped
  ```

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
          Primary     192.168.56.12                           0/4049908
  
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
  Database continues to be available


  psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'SELECT * FROM test LIMIT 10;' edb
  
   count 
  -------
     100
  (1 row)
  
   id |           random_text            
  ----+----------------------------------
    1 | 6761b3dfe540fee4a09ea840d0f47fa7
    2 | 07569e5010acb920cd4ed6870338869e
    3 | ff31d9a5f4e09a9a934575ae106ecad0
    4 | d402401137f48adbbafa55267af07976
    5 | 1ac91c404d8456565d3f1d3a0f7060ae
    6 | 192a19fdd9ea7b4201e99daede797348
    7 | 14f14ae2cf3e74a8c01580de45dce54c
    8 | addb099d3dad1fd6de90e62c99f33e54
    9 | 2a460a667a5c540a39e92eb12e1beca1
   10 | 31dc792536844d4195f8d721c08815af
  (10 rows)
  
  
  psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'SELECT count(*) FROM test;' edb
  
   count 
  -------
     100
  (1 row)
  ```
- `06-client_insert_more_data.sh`

  ```
  Database continues to be used
  
  
  psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'INSERT INTO test (random_text) SELECT md5(random()::text) FROM generate_series(1, 100);' edb
  
  INSERT 0 100
  ```

**PG1**
- `07-pg1_start_postgres.sh`

  ```
  Database server is running, trying to reover database
  
  
  sudo su - enterprisedb -c 'pg_ctl start -D '
  
  waiting for server to start....2025-03-13 12:02:08 UTC LOG:  redirecting log output to logging collector process
  2025-03-13 12:02:08 UTC HINT:  Future log output will appear in directory "log".
   stopped waiting
  pg_ctl: could not start server
  Examine the log output.
  ```

- `08-pg1_show_log.sh`

  ```
  Database didn't start to prevent split-brain
  
  
  sudo su - enterprisedb -c 'tail -f <latest postgres.log>'
  
  2025-03-13 12:02:08 UTC LOG:  starting PostgreSQL 17.4 (EnterpriseDB Advanced Server 17.4.0) on x86_64-pc-linux-gnu, compiled by gcc (GCC) 11.5.0 20240719 (Red Hat 11.5.0-5), 64-bit
  2025-03-13 12:02:08 UTC LOG:  listening on IPv4 address "0.0.0.0", port 5444
  2025-03-13 12:02:08 UTC LOG:  listening on IPv6 address "::", port 5444
  2025-03-13 12:02:08 UTC LOG:  listening on Unix socket "/tmp/.s.PGSQL.5444"
  2025-03-13 12:02:08 UTC LOG:  database system was shut down at 2025-03-13 11:58:33 UTC
  2025-03-13 12:02:08 UTC FATAL:  using recovery command file "recovery.conf" is not supported
  2025-03-13 12:02:08 UTC LOG:  startup process (PID 12567) exited with exit code 1
  2025-03-13 12:02:08 UTC LOG:  aborting startup due to startup process failure
  2025-03-13 12:02:08 UTC LOG:  database system is shut down
  ```

- `09-pg1_recover_pg1.sh`
  ```
  Recovering old Primary by:
  
  
  1. Remove old database
  rm -rf $\{PGDATA\}/*
  
  
  2. Restore database from standby
  pg_basebackup -h pg2 -D $\{PGDATA\} -U replicator -P -R -v -X stream
  pg_basebackup: initiating base backup, waiting for checkpoint to complete
  pg_basebackup: checkpoint completed
  pg_basebackup: write-ahead log start point: 0/5000028 on timeline 2
  pg_basebackup: starting background WAL receiver
  pg_basebackup: created temporary replication slot "pg_basebackup_12298"
  57602/57602 kB (100%), 1/1 tablespace                                         
  pg_basebackup: write-ahead log end point: 0/5000120
  pg_basebackup: waiting for background process to finish streaming ...
  pg_basebackup: syncing data to disk ...
  pg_basebackup: renaming backup_manifest.tmp to backup_manifest
  pg_basebackup: base backup completed
  
  3. Restart pg1 as standby
  sudo systemctl restart edb-as-17
  ```

Show efm cluster status.

```
Cluster Status: efm

        Agent Type  Address              DB       VIP
        ----------------------------------------------------------------
        Standby     192.168.56.11        UP       192.168.56.20
        Primary     192.168.56.12        UP       192.168.56.20*
        Witness     192.168.56.13        N/A      192.168.56.20

Allowed node host list:
        192.168.56.11 192.168.56.12 192.168.56.13

Membership coordinator: 192.168.56.12

Standby priority host list:
        192.168.56.11

Promote Status:

        DB Type     Address              WAL Received LSN   WAL Replayed LSN   Info
        ---------------------------------------------------------------------------
        Primary     192.168.56.12                           0/6000060
        Standby     192.168.56.11        0/6000060          0/6000060

        Standby database(s) in sync with primary. It is safe to promote.
```

- `10-pg1_switchover.sh`
  ```
  Switching pg1 back to Primary
  
  
  /usr/edb/efm-4.10/bin/efm promote efm -switchover
  Promote/switchover command accepted by local agent. Proceeding with promotion and will reconfigure original primary. Run the 'cluster-status' command for information about the new cluster state.
  ```

EFM cluster status.
```
Cluster Status: efm

        Agent Type  Address              DB       VIP
        ----------------------------------------------------------------
        Primary     192.168.56.11        UP       192.168.56.20*
        Standby     192.168.56.12        UP       192.168.56.20
        Witness     192.168.56.13        N/A      192.168.56.20

Allowed node host list:
        192.168.56.11 192.168.56.12 192.168.56.13

Membership coordinator: 192.168.56.12

Standby priority host list:
        192.168.56.12

Promote Status:

        DB Type     Address              WAL Received LSN   WAL Replayed LSN   Info
        ---------------------------------------------------------------------------
        Primary     192.168.56.11                           0/6000218
        Standby     192.168.56.12        0/6000218          0/6000218

        Standby database(s) in sync with primary. It is safe to promote.
```

## Demo cleanup
To clean up the demo environment you just have to run `99-deprovision.sh`. This script will remove the virtual machines and the cluster configuration.

## TODO / To fix
Need to manually create the replication slot on `pg1` to make the switch-back successful. This is now incorporated in `10-pg1_switchover.sh`. 
Investigating.
