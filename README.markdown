####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with hadoop](#setup)
    * [What cesnet-hadoop module affects](#what-hadoop-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with hadoop](#beginning-with-hadoop)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

##Overview

Management of Hadoop Cluster with security based on Kerberos and High Availability. Puppet 3.x is required. Supported and tested are Fedora (native Hadoop) and Debian (Cloudera distribution).

##Module Description

This module installs and setups Hadoop Cluster, with all services colocated or separated across all nodes or single node as needed. Optionally can be enabled other features:
* the security based on Kerberos
* https
* high availability for HDFS Name Node and YARN Resource Manager (requires zookeeper)

Supported are:
* Fedora 21: native packages (tested on Hadoop 2.4.1)
* Debian 7/wheezy: Cloudera distribution (tested on Hadoop 2.5.0)

There are some limitations how to use this module. You should read the documentation, especially the **Setup Requirements section**.

##Setup

###What cesnet-hadoop module affects

* Packages: installs Hadoop packages (common packages, and subsets for requested services or the client)
* Files modified:
** /etc/hadoop/\*
** /etc/sysconfig/hadoop\* (or /etc/default/hadoop\*)
** /etc/cron.d/hadoop-\* (not needed, only when explicit key refresh or restarts are requested)
** /usr/local/sbin/yellowmanager (not needed, only when administrator manager script is requested)
* Alternatives:
** alternatives are used for /etc/hadoop/config in Cloudera
** this module switches to the new alternative, so the Cloudera original configuration can be kept intact
* Services:
** only requested Hadoop services are setup and started
** HDFS: namenode, journalnode, datanode, zkfc
** YARN: resourcemanager, nodemanager
** MAPRED: historyserver
* Data Files: Hadoop is using metadata and data in /var/lib/hadoop-\* (or /var/lib/hadoop\*/cache), for most of it the custom location can be setup (and it is recommended to use different HardDrives), see http://wiki.apache.org/hadoop/DiskSetup.
* Helper Files:
** /var/lib/hadoop-hdfs/.puppet-hdfs-\*
* security files (keytabs, certificates): some files are copied to home directories of service users: ~hdfs/, ~yarn/, ~mapred/

###Setup Requirements

There are several known or intended limitations in this module.

Be aware of:
* **Hadoop repositories**
** neither Cloudera nor Hortonworks repositories are configured in this module (for cloudera you can find list and key files here: http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh/, Fedora has Hadoop as part of distribution, ...)
** *java* is not installed by this module (*openjdk-7-jre-headless* is OK for Debian 7/wheezy)
** package providing kinit is also needed (Debian: *krb5-util*/*heimdal-clients*, Fedora: *krb5-workstation*)
* **one-node Hadoop cluster** (may be collocated on one machine): Hadoop replicates by default all data to at least 3 datanodes. For one-node Hadoop cluster use property *dfs.replication=1* in *properties* parameter
* **no inter-node depedencies**: working HDFS (namenode+some datanodes) is required before history server launch, or for state-store resourcemanager feature; some workarounds exists:
** helper parameter *hdfs_deployed*: when false, services dependent on HDFS are not launched (default: true)
** administrators are encouraged to use any other way to solve inter-node dependencies (PuppetDB?)
** or just repeat setup on historyserver and resourcemenagager machines
** Note: Hadoop cluster collocated on one-machine is handled OK
* **secure mode**: keytabs must be prepared in /etc/security/keytabs/ (see *realm* parameter)
** Fedora: 1) see https://bugzilla.redhat.com/show\_bug.cgi?id=1163892, you may use repository at http://copr-fe.cloud.fedoraproject.org/coprs/valtri/hadoop/; 2) you need to enable refresh and RM restarts (see *features* module parameter)
* **https**:
** prepare CA certificate keystore and machine certificate keystore in /etc/security/cacerts and /etc/security/server.keystore (location can be modified by *https_cacerts* and *https_keystore* parameters), see init.pp class for more https-related parameters.
** prepared /etc/security/http-auth-signature-secret file (with any content)
** Note: some files are copied into ~hadfs, ~yarn/, and ~mapred/ directories

###Beginning with hadoop

The simplest setup is one-node Hadoop cluster without security with everything on single machine:

*site.pp* file:
 class{"hadoop":
   hdfs\_hostname => $::fqdn,
   yarn\_hostname => $::fqdn,
   slaves => [ $::fqdn ],
   frontends => [ $:fqdn ],
   # security needs to be disabled explicitely by using empty string
   realm => '',
   properties => {
     'dfs.replication' => 1,
   }
 }
 
 node $::fqdn {
   # HDFS
   include hadoop::namenode
   # YARN
   include hadoop::resourcemanager
   # slave (HDFS)
   include hadoop::datanode
   # slave (YARN)
   include hadoop::nodemanager
   # client
   include hadoop::frontend
 }

For full-fledged Hadoop cluster it is recommended:
* one HDFS namenode (or two for high availability, see bellow)
* one YARN resourcemanager (or two for high availability, see bellow)
* N slaves with HDFS datanode and YARN nodemanager

Services may be collocated as needed. Multiple HDFS namespaces are not supported here (ask or send patches, if you need it :-)).

TODO: security example, high availability example and dependency on zookeeper

##Usage

TODO: Put the classes, types, and resources for customizing, configuring, and doing the fancy stuff with your module here.

##Reference

TODO: Here, list the classes, types, providers, facts, etc contained in your module. This section should include all of the under-the-hood workings of your module so people know what the module is touching on their system but don't need to mess with things. (We are working on automating this section!)
TODO2: HDFS dirs resource type

##Limitations

Idea in this module is to do only one thing - setup Hadoop cluster - and don't limit generic usage of this module by doing other stuff. You can have your own repository with Hadoop SW, you can use this module just by *puppet apply* (PuppetDB is not used so puppet master is not required). You can select which Kerberos implementation or Java version to use.

On other hand this leads to some limitations as mentioned in #setup-requirements and you may need site-specific puppet module together with this one.

##Development

Idea in this module is to do only one thing - setup Hadoop cluster - and don't limit general usage of this module. You can have your own repository with Hadoop SW (Cloudera/Hortonworks is not setup), you can you this module just by using 'puppet apply) (PuppetDB is not used so puppet master is not required).

##Release Notes/Contributors/Etc **Optional**

If you aren't using changelog, put your release notes here (though you should consider using changelog). You may also add any additional sections you feel are necessary or important to include here. Please use the `## ` header. 
