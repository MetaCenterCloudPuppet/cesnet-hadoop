####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with hadoop](#setup)
    * [What cesnet-hadoop module affects](#what-hadoop-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with hadoop](#beginning-with-hadoop)
4. [Usage - Configuration options and additional functionality](#usage)
    * [Enable Security](#security)
     * [Long running applications](#long-run)
     * [Auth to local mapping](#auth_to_local)
    * [Enable HTTPS](#https)
    * [Multihome Support](#multihome)
    * [High Availability](#ha)
     * [Fresh installation](#ha-fresh)
     * [Converting non-HA cluster](#ha-convert)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
    * [Resource Types](#resources)
    * [Module Parameters](#parameters)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

<a name="overview"></a>
##Overview

Management of Hadoop Cluster with security based on Kerberos and with High Availability. Puppet 3.x is required. Supported and tested are Fedora (native Hadoop), Debian (Cloudera distribution), and CentOS (Cloudera distribution).

<a name="module-description"></a>
##Module Description

This module installs and setups Hadoop Cluster, with all services collocated or separated across all nodes or single node as needed. Optionally other features can be enabled:

* Security based on Kerberos
* HTTPS
* High availability for HDFS Name Node and YARN Resource Manager (requires zookeeper)
* YARN Resource Manager state-store

Supported are:

* **Fedora 21**: native packages (tested with Hadoop 2.4.1)
* **Debian 7/wheezy**: Cloudera distribution (tested with CDH 5.3.1/5.4.1, Hadoop 2.5.0/2.6.0)
* **Ubuntu 14/trusty**: Cloudera distribution (tested with CDH 5.3.1, Hadoop 2.5.0)
* **RHEL 6, CentOS 6, Scientific Linux 6**: Cloudera distribution (tested with CDH 5.4.1, Hadoop 2.6.0)

There are some limitations how to use this module. You should read the documentation, especially the [Setup Requirements](#setup-requirements) section.

<a name="setup"></a>
##Setup

<a name="what-hadoop-affects"></a>
###What cesnet-hadoop module affects

* Packages: installs Hadoop packages (common packages, subsets for requested services, or the client)
* Files modified:
 * */etc/hadoop/\** (or */etc/hadoop/conf/\**)
 * */etc/sysconfig/hadoop\** (or */etc/default/hadoop\**)
 * */etc/cron.d/hadoop-\** (only when explicit key refresh or restarts are requested)
 * */usr/local/sbin/yellowmanager* (not needed, only when administrator manager script is requested by *features*)
* Alternatives:
 * alternatives are used for */etc/hadoop/conf* in Cloudera
 * this module switches to the new alternative by default, so the Cloudera original configuration can be kept intact
* Services:
 * only requested Hadoop services are setup and started
 * HDFS: namenode, journalnode, datanode, zkfc
 * YARN: resourcemanager, nodemanager
 * MAPRED: historyserver
* Data Files: Hadoop is using metadata and data in */var/lib/hadoop-\** (or */var/lib/hadoop\*/cache*), for most of it the custom location can be setup (and it is recommended to use different HardDrives), see [http://wiki.apache.org/hadoop/DiskSetup](http://wiki.apache.org/hadoop/DiskSetup).
* Helper Files:
 * */var/lib/hadoop-hdfs/.puppet-hdfs-\**
* Secret Files (keytabs, certificates): some files are copied to home directories of service users: ~hdfs/, ~yarn/, ~mapred/

<a name="setup-requirements"></a>
###Setup Requirements

There are several known or intended limitations in this module.

Be aware of:

* **Hadoop repositories**
 * neither Cloudera nor Hortonworks repositories are configured in this module (for Cloudera you can find list and key files here: [http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh/](http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh/), Fedora has Hadoop as part of distribution, ...)
 * *java* is not installed by this module (*openjdk-7-jre-headless* is OK for Debian 7/wheezy)
 * for security the package providing kinit is also needed (Debian: *krb5-util* or *heimdal-clients*, RedHat/Fedora: *krb5-workstation*)

* **One-node Hadoop cluster** (may be collocated on one machine): Hadoop replicates by default all data to at least to 3 data nodes. For one-node Hadoop cluster use property *dfs.replication=1* in *properties* parameter

* **No inter-node dependencies**: working HDFS (namenode+some data nodes) is required before history server launch or for state-store resourcemanager feature; some workarounds exists:
 * helper parameter *hdfs\_deployed*: when false, services dependent on HDFS are not launched (default: true)
 * administrators are encouraged to use any other way to solve inter-node dependencies (PuppetDB?)
 * or just repeat setup on historyserver and resourcemanager machines

   Note: Hadoop cluster collocated on one-machine is handled OK

* **Secure mode**: keytabs must be prepared in /etc/security/keytabs/ (see *realm* parameter)
 * Fedora:<br />
 1) see [RedHat Bug #1163892](https://bugzilla.redhat.com/show\_bug.cgi?id=1163892), you may use repository at [http://copr-fe.cloud.fedoraproject.org/coprs/valtri/hadoop/](http://copr-fe.cloud.fedoraproject.org/coprs/valtri/hadoop/)<br />
 2) you need to enable ticket refresh and RM restarts (see *features* module parameter)

* **HTTPS**:
 * prepare CA certificate keystore and machine certificate keystore in /etc/security/cacerts and /etc/security/server.keystore (location can be modified by *https\_cacerts* and *https\_keystore* parameters), see [Enable HTTPS](#https) section
 * prepare /etc/security/http-auth-signature-secret file (with any content)

   Note: some files are copied into ~hdfs, ~yarn/, and ~mapred/ directories

<a name="beginning-with-hadoop"></a>
###Beginning with hadoop

By default the main *hadoop* class do nothing but configuration of the hadoop puppet module. Main actions are performed by the included service and client classes.

Let's start with brief examples. Before beginning you should read the [Setup Requirements](#setup-requirements) section above.

**Example**: The simplest setup is one-node Hadoop cluster without security, with everything on single machine:

    class{"hadoop":
      hdfs_hostname => $::fqdn,
      yarn_hostname => $::fqdn,
      slaves => [ $::fqdn ],
      frontends => [ $::fqdn ],
      # security needs to be disabled explicitly by using empty string
      realm => '',
      properties => {
        'dfs.replication' => 1,
      }
    }

    node default {
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

<a name="usage"></a>
##Usage

<a name="security"></a>
###Enable Security

Security in Hadoop is based on Kerberos. Keytab files needs to be prepared on the proper places before enabling the security.

Following parameters are used for security (see also [Module Parameters](#parameters)):

* *realm* (required parameter)<br />
  Enable security and Kerberos realm to use. Empty string disables security.
  To enable security, there are required:
  * installed Kerberos client (Debian: krb5-user/heimdal-clients; RedHat: krb5-workstation)
  * configured Kerberos client (/etc/krb5.conf, /etc/krb5.keytab)
  * /etc/security/keytab/dn.service.keytab (on data nodes)
  * /etc/security/keytab/jhs.service.keytab (on job history node)
  * /etc/security/keytab/nm.service.keytab (on node manager nodes)
  * /etc/security/keytab/nn.service.keytab (on name nodes)
  * /etc/security/keytab/rm.service.keytab (on resource manager node)

* *authorization* (empty hash by default)

It is recommended also to enable HTTPS when security is enabled. See [Enable HTTPS](#https).

**Example**: One-node Hadoop cluster with security (add also the node section from the single-node setup above):

    class{"hadoop":
      hdfs_hostname => $::fqdn,
      yarn_hostname => $::fqdn,
      slaves => [ $::fqdn ],
      frontends => [ $:fqdn ],
      realm => 'MY.REALM',
      properties => {
        'dfs.replication' => 1,
      },
      features => {
        #restarts => '00 */12 * * *',
        #krbrefresh => '00 */12 * * *',
      },
      authorization => {
        'rules' => 'limit',
        # more paranoid permissions to users in "hadoopusers" group
        #'security.service.authorization.default.acl' => ' hadoop,hbase,hive,hadoopusers',
      },
      # https recommended (and other extensions may require it)
      https => true,
      https_cacerts_password => '',
      https_keystore_keypassword => 'changeit',
      https_keystore_password => 'changeit',
    }

Modify $::fqdn and add node sections as needed for multi-node cluster.

<a name="ha"></a>
###High Availability

Threre are needed also these daemons for High Availability:

* Secondary Name Node (1) - there will be two Name Node servers
* Journal Node (>=3) - requires HTTPS, when Kerberos security is enabled
* Zookeeper/Failover Controller (2) - on each Name Node
* Zookeeper (>=3)

<a name="ha-fresh"></a>
#### Fresh installation

Setup High Availability requires precise order of all steps. For example all zookeeper servers must be running before formatting zkfc (class *hadoop::zkfc::service*), or all journal nodes must running during initial formatting (class *hadoop::namenode::config*) or when converting existing cluster to cluster with high availability.

There are helper parameters to separate overall cluster setup to more stages:

1. *zookeeper\_deployed*=**false**, *hdfs\_deployed=***false**: zookeper quorum and journal nodes quorum
2. *zookeeper\_deployed*=**true**, *hdfs\_deployed=***false**: HDFS format and bootstrap (primary and secondary NN), setup and launch ZKFC and NN daemons
3. *zookeeper\_deployed*=**true**, *hdfs\_deployed=***true**: enable History Server and RM state-store feature, if enabled

These parameters are not required, the setup should converge when setup is repeated. They may help with debuging problems though, because less things will fail if the setup is separated to several stages over the whole cluster.

**Example**:

    $master1_hostname = 'hadoop-master1.example.com'
    $master2_hostname = 'hadoop-master2.example.com'
    $slaves           = ['hadoop1.example.com', 'hadoop2.example.com', ...]
    $frontends        = ['hadoop.example.com']
    $quorum_hostnames = [$master1_hostname, $master2_hostname, 'master3.example.com']
    $cluster_name     = 'example'

    $hdfs_deployed      = true
    $zookeeper_deployed = true

    class{'hadoop':
      hdfs_hostname           => $master1_hostname,
      hdfs_hostname2          => $master2_hostname,
      yarn_hostname           => $master1_hostname,
      yarn_hostname2          => $master2_hostname,
      historyserer_hostnamr   => $master1_hostname,
      slaves                  => $slaves,
      frontends               => $frontends,
      journalnode_hostnames   => $quorum_hostnames,
      zookeeper_hostnames     => $quorum_hostnames,
      cluster_name            => $cluster_name,
      realm                   => '',

      hdfs_deployed           => $hdfs_deployed,
      zookeeper_deployed      => $zookeeper_deployed,
    }

    node 'master1.example.com' {
      include hadoop::namenode
      include hadoop::resourcemanager
      include hadoop::historyserver
      include hadoop::zkfc
      include hadoop::journalnode

      class{'zookeeper':
        hostnames => $quorum_hostnames,
        realm     => '',
      }
    }

    node 'master2.example.com' {
      include hadoop::namenode
      include hadoop::resourcemanager
      include hadoop::zkfc
      include hadoop::journalnode

      class{'zookeeper':
        hostnames => $quorum_hostnames,
        realm     => '',
      }
    }

    node 'master3.example.com' {
      include hadoop::journalnode

      class{'zookeeper':
        hostnames => $quorum_hostnames,
        realm     => '',
      }
    }

    node 'frontend.example.com' {
      include hadoop::frontend
      include hadoop::journalnode

      class{'zookeeper':
        hostnames => $quorum_hostnames,
        realm     => '',
      }
    }

    node /hadoop\d+.example.com/ {
      include hadoop::datanode
      include hadoop::nodemanager
    }

Note: Journalnode and Zookeeper are not resource intensive daemons and can be collocated with other daemons. In this example the content of *master3.example.com* node can be moved to some slave node or the frontend.

<a name="ha-convert"></a>
#### Converting non-HA cluster

You can use the example above. But you will need to let skip bootstrap **on secondary Name Node before setup**:

    touch /var/lib/hadoop-hdfs/.puppet-hdfs-bootstrapped

And activate HA **on the secondary Name Node after setup** (under *hdfs* user):

    # when kerberos is enabled:
    #kinit -k -t /etc/security/keytab/nn.ervice.keytab nn/`hostname -f`
    #
    hdfs namenode -initializeSharedEdits

<a name="long-run"></a>
#### Long running applications

For long-running applications as Spark Streaming jobs you may need to workaround user's delegation tokens a maximum lifetime of 7 days by these properties in *properties* parameter:

    'yarn.resourcemanager.proxy-user-privileges.enabled' => true,
    'hadoop.proxyuser.yarn.hosts' => RESOURCE MANAGER HOSTS,
    'hadoop.proxyuser.yarn.groups' => 'hadoop',

<a name="auth_to_local"></a>
#### Auth to local mapping

You can consider changing or even removing property *hadoop.security.auth\_to\_local*:

    properties => {
      'hadoop.security.auth_to_local' => '::undef',
    }

Default value is valid for principal names according to Hadoop documentation at [http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SecureMode.html](http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/SecureMode.html).

In the default value in cesnet-hadoop module are also mappings for the following Hadoop addons:

* HBase: *hbase/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *hbase*
* Hive: *hive/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *hive*
* Hue: *hue/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *hue*
* Spark: *spark/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *spark*
* Zookeeper: *zookeeper/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *zookeeper*
* ... and helper principals:
 * HTTP SPNEGO: *HTTP/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *HTTP*
 * Tomcat: *tomcat/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *tomcat*

*hadoop.security.auth_to_local* is needed and can't be removed if:

* Kerberos principals and local user names are different
 * they differ in the official documenation: *nn/\_HOST* vs *hdfs*, ...
 * they are the same in Cloudera documentation: hdfs/\_HOST vs *hdfs*, ...
* when cross-realm authentication is needed
* when support for more principals is needed (another Hadoop addon, ...)

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

The following hadoop class parameters are used for HTTPS (see also [Module Parameters](#parameters)):
* *realm* (required for HTTPS)
  Enable security and Kerberos realm to use. See [Security](#security).

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

Consider also checking POSIX ACL support in the system and enable *acl* in Hadoop module. It's usefull for more pedantic rights on ssl-\*.xml files, which needs to be read by Hadoop additions (like HBase).


<a name="multihome"></a>
###Multihome Support

Multihome support doesn't work out-of-the box in Hadoop 2.6.x (2015-01). Properties and bind hacks to multihome support can be enabled by **multihome => true** in *features*. You will also need to add secondary IPs of datanodes to *datanode_hostnames* (or *slaves*, which sets *datanode_hostnames* and *nodemanager_hostnames*):

    class{"hadoop":
      hdfs_hostname => $::fqdn,
      yarn_hostname => $::fqdn,
      # for multi-home
      datanode_hostnames => [ $::fqdn, '10.0.0.2', '192.169.0.2' ],
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

* 'hadoop.security.token.service.use\_ip' => false
* 'yarn.resourcemanager.bind-host' => '0.0.0.0'
* 'dfs.namenode.rpc-bind-host' => '0.0.0.0'


<a name="reference"></a>
##Reference

<a name="classes"></a>
###Classes

* common:
 * hdfs:
  * config
  * daemon
 * mapred:
  * config
  * daemon
 * yarn:
  * config
  * daemon
 * config
 * install
 * postinstall
 * slaves
* config
* create\_dirs
* init
* install
* params
* service
* **datanode** - HDFS Data Node
 * config
 * install
 * service
* **frontend** - Hadoop client and examples
 * config
 * install
 * service (empty)
* **historyserver** - MapReduce Job History Server
 * config
 * install
 * service
* **journalnode** - HDFS Journal Node used for Quorum Journal Manager
 * config
 * install
 * service
* **namenode** - HDFS Name Node
 * bootstrap
 * config
 * format
 * install
 * service
* **nodemanager** - YARN Node Manager.
 * config
 * install
 * service
* **resourcemanager** - YARN Resource Manager
 * config
 * install
 * service
* **zkfc** - HDFS Zookeeper/Failover Controller
 * config
 * install
 * service

<a name="resources"></a>
###Resource Types

* **kinit** - Init credentials
* **kdestroy** - Destroy credentials
* **mkdir** - Creates a directory on HDFS

<a name="parameters"></a>
###Module Parameters

####`hdfs_hostname` $::fqdn

Hadoop Filesystem Name Node machine.

####`hdfs_hostname2` undef

Another Hadoop Filesystem Name Node machine. used for High Availability. This parameter will activate the HDFS HA feature. See [http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html](http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html).

If you're converting existing Hadoop cluster without HA to cluster with HA, you need to initialize journalnodes yet:

    hdfs namenode -initializeSharedEdits

Zookeepers are required for automatic transitions.

####`yarn_hostname` $::fqdn

Yarn machine (with Resource Manager and Job History services).

####`yarn_hostname2` undef

YARN resourcemanager second hostname for High Availability. This parameter will activate the YARN HA feature. See [http://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html](http://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html).

Zookeepers are required.

####`slaves` [$::fqdn]

Array of slave node hostnames.

####`frontends` (*slaves*)

Array of frontend hostnames. Used *slaves* by default.

####`cluster_name` 'cluster'

Name of the cluster. Used during initial formatting of HDFS. For non-HA configurations it may be undef.

####`realm` (required parameter, may be empty string)

  Enable security and Kerberos realm to use. Empty string disables the security.
  To enable security, there are required:

  * installed Kerberos client (Debian: krb5-user/heimdal-clients; RedHat: krb5-workstation)
  * configured Kerberos client (/etc/krb5.conf, /etc/krb5.keytab)
  * /etc/security/keytab/dn.service.keytab (on data nodes)
  * /etc/security/keytab/jhs.service.keytab (on job history node)
  * /etc/security/keytab/nm.service.keytab (on node manager nodes)
  * /etc/security/keytab/nn.service.keytab (on name nodes)
  * /etc/security/keytab/rm.service.keytab (on resource manager node)

It is used also as cookie domain (lowercased), if https is enabled. This may be overrided by http.authentication.cookie.domain in *properties*.

####`historyserver_hostname` undef

History Server machine. Used *yarn_hostname* by default.

####`nodemanager_hostnames` undef

Array of Node Manager machines. Used *slaves* by default.

####`datanode_hostnames` undef

Array of Data Node machines. Used *slaves* by default.

####`journalnode_hostnames` undef

Array of HDFS Journal Node machines. Used in HDFS namenode HA.

####`zookeeper_hostnames` undef

Array of Zookeeper machines. Used in HDFS namenode HA for automatic failover and YARN resourcemanager state-store feature.

Without zookeepers the manual failover is needed: the namenodes are always started in standby mode and one would need to be activated manually.

####`hdfs_name_dirs` (["/var/lib/hadoop-hdfs"], or ["/var/lib/hadoop-hdfs/cache"])

Directory prefixes to store the metadata on the namenode.

* directory for name table (fsimage)
* /${user.name}/dfs/namenode or /${user.name}/dfs/name suffix is always added
 * If there is multiple directories, then the name table is replicated in all of the directories, for redundancy.
 * All directories needs to be available to namenode work properly (==> good on mirrored raid)
 * Crucial data (==> good to save at different physical locations)

 When adding a new directory, you will need to replicate the contents from some of the other ones. Or set dfs.namenode.name.dir.restore to true and create NEW\_DIR/hdfs/dfs/namenode with proper owners.

####`hdfs_data_dirs` (["/var/lib/hadoop-hdfs"], or ["/var/lib/hadoop-hdfs/cache"])

Directory prefixes to store the data on HDFS datanodes.

* directory for DFS data blocks
 * /${user.name}/dfs/datanode suffix is always added
 * If there is multiple directories, then data will be stored in all directories, typically on different devices.

####`hdfs_secondary_dirs` undef

Directory prefixes to store metadata by secondary name nodes, if different from *hdfs_name_dirs*.

####`hdfs_journal_dirs` undef

Directory prefixes to store journal logs by journal name nodes, if different from *hdfs_name_dirs*.

####`properties` (see params.pp)

"Raw" properties for hadoop cluster. "::undef" will remove property set automatically by this module, empty string sets empty value.

####`descriptions` (see params.pp)

Descriptions for the properties. Just for cuteness.

####`environment` undef

Environment to set for all Hadoop daemons.

    environment => {'HADOOP_HEAPSIZE' => 4096, 'YARN_HEAPSIZE' => 4096}

####`features` (empty)

 Enable additional features:

* **rmstore**: resource manager recovery using state-store (YARN will depends on HDFS)
 * *hdfs*: store state on HDFS, this requires HDFS datanodes already running and /rmstore directory created ==> keep disabled on initial setup! Requires *hdfs\_deployed* to be true
 * *zookeeper*: store state on zookeepers; Requires *zookeeper_hostnames* specified. Warning: no authentication is used.
 * *true*: select automatically zookeeper or hdfs according to *zookeeper_hostnames*
* **restarts**: regular resource manager restarts (MIN HOUR MDAY MONTH WDAY); it shall never be restarted, but it may be needed for refreshing Kerberos tickets
* **krbrefresh**: use and refresh Kerberos credential cache (MIN HOUR MDAY MONTH WDAY); beware there is a small race-condition during refresh
* **yellowmanager**: script in /usr/local to start/stop all daemons relevant for given node
* **multihome**: enable properties required for multihome usage, you will need also add secondary IP addresses to *datanode_hostnames*
* **aggregation**: enable YARN log aggregation (recommended, YARN will depend on HDFS)

Recommended features to enable are: **rmstore**, **aggregation** and probably **multihome**.

####`acl` undef

Set to true, if setfacl command is available and /etc/hadoop is on filesystem supporting POSIX ACL.
It is used only when https is enabled to set less open privileges on ssl-server.xml.

####`alternatives` (Debian: 'cluster', other: undef)

Use alternatives to switch configuration. Use it only when supported (like with Cloudera for example).

####`authorization` (empty)

Hadoop service level authorization ACLs. Authorizations are enabled and predefined rule set and/or particular properties can be specified.

Each ACL is in the form of: (wildcard "\*" allowed)

* "USER1,USER2,... GROUP1,GROUP2"
* "USER1,USER2,..."
* " GROUP1,GROUP2,..." (notice the space character)

These properties are available:

* *rules* (**limit**, **permit**, **false**): predefined ACL sets from cesnet-hadoop puppet module
* *security.service.authorization.default.acl*: default ACL
* *security.client.datanode.protocol.acl*
* *security.client.protocol.acl*
* *security.datanode.protocol.acl*
* *security.inter.datanode.protocol.acl*
* *security.namenode.protocol.acl*
* *security.admin.operations.protocol.acl*
* *security.refresh.usertogroups.mappings.protocol.acl*
* *security.refresh.policy.protocol.acl*
* *security.ha.service.protocol.acl*
* *security.zkfc.protocol.acl*
* *security.qjournal.service.protocol.acl*
* *security.mrhs.client.protocol.acl*
* *security.resourcetracker.protocol.acl*
* *security.resourcemanager-administration.protocol.acl*
* *security.applicationclient.protocol.acl*
* *security.applicationmaster.protocol.acl*
* *security.containermanagement.protocol.acl*
* *security.resourcelocalizer.protocol.acl*
* *security.job.task.protocol.acl*
* *security.job.client.protocol.acl*
* ... and everything with *.blocked* suffix

ACL set: **limit**: policy tuned with minimal set of permissions:

* *security.datanode.protocol.acl* => ' hadoop'
* *security.inter.datanode.protocol.acl* => ' hadoop'
* *security.namenode.protocol.acl* => 'hdfs,nn,sn'
* *security.admin.operations.protocol.acl* => ' hadoop'
* *security.refresh.usertogroups.mappings.protocol.acl* => ' hadoop'
* *security.refresh.policy.protocol.acl* => ' hadoop'
* *security.ha.service.protocol.acl* => ' hadoop'
* *security.zkfc.protocol.acl* => ' hadoop'
* *security.qjournal.service.protocol.acl* => ' hadoop'
* *security.resourcetracker.protocol.acl* => 'yarn,nm,rm'
* *security.resourcemanager-administration.protocol.acl* => ' hadoop',
* *security.applicationmaster.protocol.acl* => '\*',
* *security.containermanagement.protocol.acl* => '\*',
* *security.resourcelocalizer.protocol.acl* => '\*',
* *security.job.task.protocol.acl* => '\*',

ACL set: **permit** defines this policy (it's default):

* *security.service.authorization.default.acl* => '\*'

See also [Service Level Authorization Hadoop documentation](http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ServiceLevelAuth.html).

You can use use **limit** rules. For more strict settings you can define *security.service.authorization.default.acl* to something different from '\*':

    authorization => {
      'rules' => 'limit',
      'security.service.authorization.default.acl' => ' hadoop,hbase,hive,spark,users',
    }

Note: Beware *...acl.blocked* are not used if the *....acl* counterpart is defined.

Note 2: If not using wildcards in permit rules, you should enable access also for Hadoop additions (as seen in example).

####`https` undef

Enable support for https.

Requires:

* enabled security (non-empty *realm*)
* /etc/security/cacerts file (https\_cacerts parameter) - kept in the place, only permission changed, if needed
* /etc/security/server.keystore file (https\_keystore parameter) - copied for each daemon user
* /etc/security/http-auth-signature-secret file (any data, string or blob) - copied for each daemon user
* /etc/security/keytab/http.service.keytab - copied for each daemon user

####`https_cacerts` '/etc/security/cacerts'

CA certificates file.

####`https_cacerts_password` ''

CA certificates keystore password.

####`https_keystore` '/etc/security/server.keystore'

Certificates keystore file.

####`https_keystore_password` 'changeit'

Certificates keystore file password.

####`https_keystore_keypassword` undef

Certificates keystore key password. If not specified, https\_keystore\_password is used.

####`https_keytab` '/etc/security/keytab/http.service.keytab'

Keytab file for HTTPS. It will be copied for each daemon user and according permissions and properties set.

####`min_uid` (autodetect)

Minimal permitted UID of Hadoop users. Used in Linux containers, when security is enabled.

####`perform` false

Launch all installation and setup here, from hadoop class.

####`hdfs_deployed` true

Perform also actions requiring working HDFS (namenode + enough datanodes): enabling RM HDFS state-store feature (if enabled), and starting MapReduce History Server. This action requires running namenode and datanodes, so you can set this to *false* during initial installation.

####`zookeeper_deployed` true

Perform also actions requiring working zookeeper and journal nodes: when enabled, launch ZKFC daemons and secondary namenode. You can set this to *false* during initial installation when High Availability is enabled.

####`keytab_namenode` '/etc/security/keytab/nn.service.keytab'

Keytab file for HDFS Name Node. This will set also property *dfs.namenode.keytab.file*, if not specified directly.

####`keytab_datanode` '/etc/security/keytab/dn.service.keytab'

Keytab file for HDFS Data Node. This will set also property *dfs.datanode.keytab.file*, if not specified directly.

####`keytab_jobhistory` '/etc/security/keytab/jhs.service.keytab'

Keytab file for Map Reduce Job History Server. This will set also property *mapreduce.jobhistory.keytab*, if not specified directly.

####`keytab_journalnode` '/etc/security/keytab/jn.service.keytab'

Keytab file for HDFS Data Node. This will set also property *dfs.journalnode.keytab.file*, if not specified directly.

####`keytab_resourcemanager` '/etc/security/keytab/rm.service.keytab'

Keytab file for YARN Resource Manager. This will set also property *yarn.resourcemanager.keytab*, if not specified directly.

####`keytab_nodemanager` '/etc/security/keytab/nm.service.keytab'

Keytab file for YARN Node Manager. This will set also property *yarn.nodemanager.keytab*, if not specified directly.


<a name="limitations"></a>
##Limitations

Idea in this module is to do only one thing - setup Hadoop cluster - and not limit generic usage of this module by doing other stuff. You can have your own repository with Hadoop SW, you can use this module just by *puppet apply*. You can select which Kerberos implementation or Java version to use.

On other hand this leads to some limitations as mentioned in [Setup Requirements](#setup-requirements) section and you may need site-specific puppet module together with this one.

<a name="development"></a>
##Development

* Repository: [https://github.com/MetaCenterCloudPuppet/cesnet-hadoop](https://github.com/MetaCenterCloudPuppet/cesnet-hadoop)
* Tests: [https://github.com/MetaCenterCloudPuppet/hadoop-tests](https://github.com/MetaCenterCloudPuppet/hadoop-tests)
* Email: František Dvořák &lt;valtri@civ.zcu.cz&gt;
