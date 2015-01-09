####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with hadoop](#setup)
    * [What cesnet-hadoop module affects](#what-hadoop-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with hadoop](#beginning-with-hadoop)
4. [Usage - Configuration options and additional functionality](#usage)
    * [Enable Security](#security)
    * [Enable HTTPS](#https)
    * [Multihome Support](#multihome)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

<a name="overview"></a>
##Overview

Management of Hadoop Cluster with security based on Kerberos and with High Availability. Puppet 3.x is required. Supported and tested are Fedora (native Hadoop) and Debian (Cloudera distribution).

<a name="module-description"></a>
##Module Description

This module installs and setups Hadoop Cluster, with all services collocated or separated across all nodes or single node as needed. Optionally other features can be enabled:

* the security based on Kerberos
* https
* high availability for HDFS Name Node and YARN Resource Manager (requires zookeeper)

Supported are:

* Fedora 21: native packages (tested on Hadoop 2.4.1)
* Debian 7/wheezy: Cloudera distribution (tested on Hadoop 2.5.0)

There are some limitations how to use this module. You should read the documentation, especially the [Setup Requirements](#setup-requirements) section.

<a name="setup"></a>
##Setup

<a name="what-hadoop-affects"></a>
###What cesnet-hadoop module affects

* Packages: installs Hadoop packages (common packages, subsets for requested services, or the client)
* Files modified:
 * /etc/hadoop/\* (or /etc/hadoop/conf/*)
 * /etc/sysconfig/hadoop\* (or /etc/default/hadoop\*)
 * /etc/cron.d/hadoop-\* (only when explicit key refresh or restarts are requested)
 * /usr/local/sbin/yellowmanager (not needed, only when administrator manager script is requested by *features*)
* Alternatives:
 * alternatives are used for /etc/hadoop/conf in Cloudera
 * this module switches to the new alternative by default, so the Cloudera original configuration can be kept intact
* Services:
 * only requested Hadoop services are setup and started
 * HDFS: namenode, journalnode, datanode, zkfc
 * YARN: resourcemanager, nodemanager
 * MAPRED: historyserver
* Data Files: Hadoop is using metadata and data in /var/lib/hadoop-\* (or /var/lib/hadoop\*/cache), for most of it the custom location can be setup (and it is recommended to use different HardDrives), see [http://wiki.apache.org/hadoop/DiskSetup](http://wiki.apache.org/hadoop/DiskSetup).
* Helper Files:
 * /var/lib/hadoop-hdfs/.puppet-hdfs-\*
* Secret Files (keytabs, certificates): some files are copied to home directories of service users: ~hdfs/, ~yarn/, ~mapred/

<a name="setup-requirements"></a>
###Setup Requirements

There are several known or intended limitations in this module.

Be aware of:

* **Hadoop repositories**
 * neither Cloudera nor Hortonworks repositories are configured in this module (for Cloudera you can find list and key files here: [http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh/](http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh/), Fedora has Hadoop as part of distribution, ...)
 * *java* is not installed by this module (*openjdk-7-jre-headless* is OK for Debian 7/wheezy)
 * for security the package providing kinit is also needed (Debian: *krb5-util*/*heimdal-clients*, Fedora: *krb5-workstation*)

* **one-node Hadoop cluster** (may be collocated on one machine): Hadoop replicates by default all data to at least to 3 data nodes. For one-node Hadoop cluster use property *dfs.replication=1* in *properties* parameter

* **no inter-node dependencies**: working HDFS (namenode+some data nodes) is required before history server launch or for state-store resourcemanager feature; some workarounds exists:
 * helper parameter *hdfs_deployed*: when false, services dependent on HDFS are not launched (default: true)
 * administrators are encouraged to use any other way to solve inter-node dependencies (PuppetDB?)
 * or just repeat setup on historyserver and resourcemanager machines

   Note: Hadoop cluster collocated on one-machine is handled OK

* **secure mode**: keytabs must be prepared in /etc/security/keytabs/ (see *realm* parameter)
 * Fedora:<br />
 1) see [RedHat Bug #1163892](https://bugzilla.redhat.com/show\_bug.cgi?id=1163892), you may use repository at [http://copr-fe.cloud.fedoraproject.org/coprs/valtri/hadoop/](http://copr-fe.cloud.fedoraproject.org/coprs/valtri/hadoop/)<br />
 2) you need to enable ticket refresh and RM restarts (see *features* module parameter)

* **https**:
 * prepare CA certificate keystore and machine certificate keystore in /etc/security/cacerts and /etc/security/server.keystore (location can be modified by *https_cacerts* and *https_keystore* parameters), see init.pp class for more https-related parameters
 * prepare /etc/security/http-auth-signature-secret file (with any content)

   Note: some files are copied into ~hdfs, ~yarn/, and ~mapred/ directories

<a name="beginning-with-hadoop"></a>
###Beginning with hadoop

Let's start with brief examples. Before beginning you should read the [Setup Requirements](#setup-requirements) section above.

**Example 1**: The simplest setup is one-node Hadoop cluster without security, with everything on single machine:

    class{"hadoop":
      hdfs\_hostname => $::fqdn,
      yarn\_hostname => $::fqdn,
      slaves => [ $::fqdn ],
      frontends => [ $:fqdn ],
      # security needs to be disabled explicitly by using empty string
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
      # MAPRED
      include hadoop::historyserver
      # slave (HDFS)
      include hadoop::datanode
      # slave (YARN)
      include hadoop::nodemanager
      # client
      include hadoop::frontend
    }

For full-fledged Hadoop cluster it is recommended (services can be collocated):

* one HDFS namenode (or two for high availability, see below)
* one YARN resourcemanager (or two for high availability, see below)
* N slaves with HDFS datanode and YARN nodemanager

Modify $::fqdn and node(s) section as needed. You can also remove the dfs.replication property with more data nodes.

Multiple HDFS namespaces are not supported now (ask or send patches, if you need it :-)).

**Example 2**: One-node Hadoop cluster with security (add also the node section from the single setup above):

    class{"hadoop":
      hdfs\_hostname => $::fqdn,
      yarn\_hostname => $::fqdn,
      slaves => [ $::fqdn ],
      frontends => [ $:fqdn ],
      realm => 'MY.REALM',
      properties => {
        'dfs.replication' => 1,
      }
      features => {
        #restarts => '00 */12 * * *',
        #krbrefresh => '00 */12 * * *',
        authorization => 'limit',
      },
      # https recommended (and other extensions may require it)
      https => true,
      https_cacerts_password => '',
      https_keystore_keypassword => 'changeit',
      https_keystore_password => 'changeit',
    }

Modify $::fqdn and add node(s) sections as needed for multi-node cluster.

TODO: try security example, high availability example and dependency on zookeeper

<a name="usage"></a>
##Usage

TODO: Put the classes, types, and resources for customizing, configuring, and doing the fancy stuff with your module here.

<a name="security"></a>
###Enable Security

Security in Hadoop is based on Kerberos. Keytab files needs to be prepared on the proper places before enabling the security.

Following parameters are used for security (see also hadoop class):

* *realm* (required parameter, empty string disables the security)<br />
  Enable security and Kerberos realm to use. Empty string disables the security.
  To enable security, there are required:
  * installed Kerberos client (Debian: krb5-user/heimdal-clients; RedHat: krb5-workstation)
  * configured Kerberos client (/etc/krb5.conf, /etc/krb5.keytab)
  * /etc/security/keytab/dn.service.keytab (on data nodes)
  * /etc/security/keytab/jhs.service.keytab (on job history node)
  * /etc/security/keytab/nm.service.keytab (on node manager nodes)
  * /etc/security/keytab/nn.service.keytab (on name nodes)
  * /etc/security/keytab/rm.service.keytab (on resource manager node)

* *features* (empty hash by default)<br />
 * *authorization* - enable authorization and select authorization rules (permit, limit); recommended to try 'permit' rules first

It is recommended also to enable HTTPS when security is enabled. See [Enable HTTPS](#https).

Note: for long-running applications as Spark Streaming jobs you may need to workaround user's delegation tokens a maximum lifetime of 7 days by these properties in *properties* parameter:

    'yarn.resourcemanager.proxy-user-privileges.enabled' => true,
    'hadoop.proxyuser.yarn.hosts' => RESOURCE MANAGER HOSTS,
    'hadoop.proxyuser.yarn.groups' => 'hadoop',

<a name="https"></a>
###Enable HTTPS

Hadoop is able to use SPNEGO protocol (="Kerberos tickets through HTTPS"). This requires proper configuration of the browser on the client side and valid Kerberos ticket.

HTTPS support requires:

* enabled security (*realm* => ...)
* /etc/security/cacerts file (*https_cacerts* parameter) - kept in the place, only permission changed if needed
* /etc/security/server.keystore file (*https_keystore* parameter) - copied for each daemon user
* /etc/security/http-auth-signature-secret file (any data, string or blob) - copied for each daemon user
* /etc/security/keytab/http.service.keytab - copied for each daemon user

Preparing the CA certificates store (/etc/security/cacerts):

    # for each CA certificate in the chain
    keytool -importcert -keystore cacerts -storepass changeit -trustcacerts -alias some-alias -file some-file.pem
    # check
    keytool -list -keystore cacerts -storepass changeit
    # move to the right default location
    mv cacerts /etc/security/

Preparing the certificates keystore (/etc/security/server.keystore):

    # X509 -> pkcs12
    # (enter some passphrase)
    openssl pkcs12 -export -in /etc/grid-security/hostcert.pem
                   -inkey /etc/grid-security/hostkey.pem \
                   -out server.p12 -name hadoop-dcv -certfile tcs-ca-bundle.pem

    # pkcs12 -> java
    # (the alias must be the same as the name above)
    keytool -importkeystore \
            -deststorepass changeit1 -destkeypass changeit2 -destkeystore server.keystore \
            -srckeystore server.p12 -srcstoretype PKCS12 -srcstorepass some-passphrase \
            -alias hadoop-dcv

    # check
    keytool -list -keystore server.keystore -storepass changeit1

    # move to the right default location
    chmod 0600 server.keystore
    mv server.keystore /etc/security/

Preparing the signature secret file (/etc/security/http-auth-signature-secret):

    dd if=/dev/random bs=128 count=1 > http-auth-signature-secret
    chmod 0600 http-auth-signature-secret
    mv http-auth-signature-secret /etc/security/

The following hadoop class parameters are used for HTTPS (see also hadoop class):
* *realm* (required for HTTPS)
  Enable security and Kerberos realm to use. See (#security)

* *https* (undef)
  Enable support for https.

* *https_cacerts* (/etc/security/cacerts)
  CA certificates file.

* *https_cacerts_password* ('')
  CA certificates keystore password.

* *https_keystore* (/etc/security/server.keystore)
  Certificates keystore file.

* *https_keystore_password* ('changeit')
  Certificates keystore file password.

* *https_keystore_keypassword* (undef)
  Certificates keystore key password. If not specified, *https_keystore_password* is used.


<a name="multihome"></a>
###Multihome Support

Multihome support doesn't work out-of-the box in Hadoop 2.6.x (2015-01). Properties and bind hacks to multihome support can be enabled by **multihome => true** in *features*. You will also need to add secondary IPs of datanodes to *datanode_hostnames* or *slaves*:

    class{"hadoop":
      hdfs\_hostname => $::fqdn,
      yarn\_hostname => $::fqdn,
      # for multi-home
      datanode\_hostnames => [ $::fqdn, '10.0.0.2', '192.169.0.2' ],
      slaves => [ $::fqdn ],
      frontends => [ $:fqdn ],
      realm => '',
      properties => {
        'dfs.replication' => 1,
      }
      # for multi-home
      features => {
        multihome => true,
      }
    }

Multi-home feature enables following properties:
* 'hadoop.security.token.service.use_ip' => false
* 'yarn.resourcemanager.bind-host' => '0.0.0.0'
* 'dfs.namenode.rpc-bind-host' => '0.0.0.0'


<a name="reference"></a>
##Reference

TODO: Here, list the classes, types, providers, facts, etc contained in your module. This section should include all of the under-the-hood workings of your module so people know what the module is touching on their system but don't need to mess with things. (We are working on automating this section!)
TODO2: HDFS dirs resource type

<a name="limitations"></a>
##Limitations

Idea in this module is to do only one thing - setup Hadoop cluster - and don't limit generic usage of this module by doing other stuff. You can have your own repository with Hadoop SW, you can use this module just by *puppet apply* (PuppetDB is not used so puppet master is not required). You can select which Kerberos implementation or Java version to use.

On other hand this leads to some limitations as mentioned in [Setup Requirements](#setup-requirements) section and you may need site-specific puppet module together with this one.

<a name="development"></a>
##Development

* Repository: [http://scientific.zcu.cz/git/?p=cesnet-hadoop.git;a=summary](http://scientific.zcu.cz/git/?p=cesnet-hadoop.git;a=summary)
* Email: František Dvořák &lt;valtri@civ.zcu.cz&gt;
