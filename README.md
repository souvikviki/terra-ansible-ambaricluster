hdp-ansible
-------------

## [Features] (id:features)

- Installs HDP using Ambari Blueprints

- Checkout `ranger` and apply patches for testing

- TODO


Installation
------------

## Install required tools (`Note: On local`)

1. Install Ansible and git:

  ```
  sudo su -
  yum/apt-get install gcc gcc-c++ python-pip python-devel -y
  pip install ansible
  ansible-galaxy install geerlingguy.mysql
  ```

2. Clone the repository

```
mkdir -p ~/repos && cd ~/repos && git clone https://github.com/gautamborad/hdp-ansible
```


## Setup variables  

Note: All the SSH logins must be known / setup in advance.

### Set the cluster/node level variable

Enter the cluster nodes info in the `inventory/cluster` file. This file contains two groups:

1. `master-nodes`
    * Nodes running the master Hadoop services. You can specify one, two or three nodes.
    * The last node from this list will be used to setup ambari-sever / ranger

1. `slave-nodes`
    * Nodes running the slave Hadoop services.
    * For single node cluster, dont specify anything here.

- Example of a 1 master / 3 slave nodes cluster:

  ```
  [master-nodes]
  master01 ansible_host=192.168.0.2

  [slave-nodes]
  slave01 ansible_host=192.168.0.3
  slave02 ansible_host=192.168.0.4
  ```

- Example for installing a single-node HDP cluster

  ```
  [master-nodes]
  master01 ansible_host=localhost
  ```

### Set the HDP/component level variables

Enter various service level variables in `playbooks/group_vars/all` to set the cluster configuration.

The following table will describe the most important variables:

| Variable             | Description                                                         |
| -------------------- | ------------------------------------------------------------------- |
| cluster_name         | The name of the HDP cluster                                         |
| hdp_version          | The HDP major version that should be installed                      |
| admin_password       | This is the Ambari admin user password                              |
| services_password    | This is a password used by everything else (like hive's database)   |
| install_*            | Set these to true in order to install the respective HDP component  |


## Run the HDP Installation

Run the below command to install Ambari and provision the HDP cluster using Ambari Blueprints:

```
bash provision_hdp.sh
```

After the installation is done, the Ambari server will be running on the last master-node.


## Run the Ranger Installation (Optional)

Ranger will be installed by default on the last master node (same as Ambari node)

This Ansible Role will perform the following:

1. Checkout [Apache Ranger](https://github.com/apache/incubator-ranger)
1. Setup git/maven etc.
1. Setup MySQL (more DB to come soon) and create various DB User / Databases (More info in `group_vars/rangerdb.yml`)
1. Apply patches (if present in `/data/patches/*.patch` dir
1. Build Ranger
1. Install Ranger
1. Start Ranger Admin

### Setup vars for ranger

Modify (**only if required**) the variables in `group_vars/ranger` file to tweak where Ranger is checked out, installed etc.

Run the below command to run the role.

```
bash provision_ranger.sh
```


---
