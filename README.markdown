##Hadoop

[![Build Status](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-hadoop.svg?branch=master)](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-hadoop) [![Puppet Forge](https://img.shields.io/puppetforge/v/cesnet/hadoop.svg)](https://forge.puppetlabs.com/cesnet/hadoop)

####Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
2. [Setup - The basics of getting started with hadoop](#setup)
    * [What cesnet-hadoop module affects](#what-hadoop-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with hadoop](#beginning-with-hadoop)
3. [Usage - Configuration options and additional functionality](#usage)
    * [Enable Security](#security)
     * [Long running applications](#long-run)
     * [Auth to local mapping](#auth_to_local)
    * [Enable HTTPS](#https)
    * [Multihome Support](#multihome)
    * [High Availability](#ha)
     * [Fresh installation](#ha-fresh)
     * [Converting non-HA cluster](#ha-convert)
     * [HA Quorum Security](#ha-security)
     * [Hadoop addons](#ha-addons)
    * [HDFS NFS Gateway](#nfs)
     * [Security](#nfs-sec)
     * [Authorization](#nfs-auth)
     * [Quick Check](#nfs-check)
    * [HTTPFS Proxy](#httpfs)
     * [Security](#httpfs-sec)
     * [Authorization](#httpfs-auth)
     * [Usage](#httpfs-check)
    * [Upgrade](#upgrade)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
    * [Facts](#facts)
    * [Resource Types](#resources)
    * [Module Parameters (hadoop class)](#class-hadoop)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

<a name="module-description"></a>
##Module Description

Management of Hadoop Cluster with security based on Kerberos and with High Availability. All services can be separated across all nodes or collocated at single node as needed. Optionally other features can be enabled:

* Security based on Kerberos
* HTTPS
* High availability for HDFS Name Node and YARN Resource Manager (requires zookeeper)
* YARN Resource Manager state-store

Puppet >= 3.x is required.

Supported are:

* **Debian 7/wheezy**: Cloudera distribution (tested with CDH 5.3/5.4/5.5, Hadoop 2.5.0/2.6.0)
* **Fedora**: native packages (tested with Hadoop 2.4.1)
* **Ubuntu 14/trusty**: Cloudera distribution (tested with CDH 5.3.1, Hadoop 2.5.0)
* **RHEL 6 and clones**: Cloudera distribution (tested with CDH 5.4.1, Hadoop 2.6.0)

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
 * */usr/local/sbin/yellowmanager* (not needed, only when administrator manager script is requested by `features`)
* Alternatives:
 * alternatives are used for */etc/hadoop/conf* in Cloudera
 * this module switches to the new alternative by default, so the Cloudera original configuration can be kept intact
* Services:
 * only requested Hadoop services are setup and started
 * HDFS: namenode, journalnode, datanode, zkfc, nfs
 * YARN: resourcemanager, nodemanager
 * MAPRED: historyserver
* Data Files: Hadoop is using metadata and data in */var/lib/hadoop-\** (or */var/lib/hadoop\*/cache*), for most of it the custom location can be setup (and it is recommended to use different hard drives), see [http://wiki.apache.org/hadoop/DiskSetup](http://wiki.apache.org/hadoop/DiskSetup).
* Helper Files:
 * */var/lib/hadoop-hdfs/.puppet-hdfs-\**
* Secret Files (keytabs, certificates): some files are copied to home directories of service users: ~hdfs/, ~yarn/, ~mapred/

It is enabled also HDFS blocks metadata, which is required for Impala addon. You can disable it by setting *dfs.datanode.hdfs-blocks-metadata.enabled* to *false* in `properties` parameter.

<a name="setup-requirements"></a>
###Setup Requirements

There are several known or intended limitations in this module.

Be aware of:

* **Hadoop repositories**
 * neither Cloudera nor Hortonworks repositories are configured in this module (for Cloudera you can find list and key files here: [http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh/](http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh/), Fedora has Hadoop as part of distribution, ...)
 * *java* is not installed by this module (*openjdk-7-jre-headless* is OK for Debian 7/wheezy)
 * for security the package providing kinit is also needed (Debian: *krb5-util* or *heimdal-clients*, RedHat/Fedora: *krb5-workstation*)

* **One-node Hadoop cluster** (may be collocated on one machine): Hadoop replicates by default all data to at least to 3 data nodes. For one-node Hadoop cluster use property *dfs.replication=1* in `properties` parameter

* **No inter-node dependencies**: working HDFS (namenode+some data nodes) is required before history server launch or for state-store resourcemanager feature; some workarounds exists:
 * helper parameter `hdfs_deployed`: when false, services dependent on HDFS are not launched (default: true)
 * repeat setup on historyserver and resourcemanager machines is needed

   Note: Hadoop cluster collocated on one-machine is handled OK

* **Secure mode**: keytabs must be prepared in */etc/security/keytabs/* (see `realm` parameter)
 * Fedora:<br />
 1) see [RedHat Bug #1163892](https://bugzilla.redhat.com/show\_bug.cgi?id=1163892), you may use repository at [http://copr-fe.cloud.fedoraproject.org/coprs/valtri/hadoop/](http://copr-fe.cloud.fedoraproject.org/coprs/valtri/hadoop/)<br />
 2) you need to enable ticket refresh and RM restarts (see `features` module parameter)

* **HTTPS**:
 * prepare CA certificate keystore and machine certificate keystore in */etc/security/cacerts* and */etc/security/server.keystore* (location can be modified by `https_cacerts` and `https_keystore` parameters), see [Enable HTTPS](#https) section
 * prepare */etc/security/http-auth-signature-secret* file (with any content)

   Note: some files are copied into *~hdfs/*, *~yarn/*, and *~mapred/* directories

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

Modify *$::fqdn* and node(s) section as needed. You can also remove the *dfs.replication* property with more data nodes.

Multiple HDFS namespaces are not supported now (ask or send patches, if you need it :-)).

<a name="usage"></a>
##Usage

<a name="security"></a>
###Enable Security

Security in Hadoop is based on Kerberos. Keytab files needs to be prepared on the proper places before enabling the security.

Following parameters are used for security (see also [Module Parameters](#parameters)):

* `realm` ('')<br />
  Enable security and Kerberos realm to use. Empty string disables security.
  To enable security, there are required:
  * installed Kerberos client (Debian: *krb5-user*/*heimdal-clients*; RedHat: *krb5-workstation*)
  * configured Kerberos client (*/etc/krb5.conf*, */etc/krb5.keytab*)
  * */etc/security/keytab/dn.service.keytab* (on data nodes)
  * */etc/security/keytab/jhs.service.keytab* (on job history node)
  * */etc/security/keytab/nm.service.keytab* (on node manager nodes)
  * */etc/security/keytab/nn.service.keytab* (on name nodes)
  * */etc/security/keytab/rm.service.keytab* (on resource manager node)
  * */etc/security/keytab/httpfs-http.service.keytab* (on HTTPFS proxy node)
  * */etc/security/keytab/nfs.service.keytab* (on NFS gateway node)

* `authorization` (empty hash by default)

We recommend to enable HTTPS when security is enabled. See [Enable HTTPS](#https).

**Example**: One-node Hadoop cluster with security (add also the node section from the single-node setup above):

    class{"hadoop":
      hdfs_hostname => $::fqdn,
      yarn_hostname => $::fqdn,
      slaves => [ $::fqdn ],
      frontends => [ $::fqdn ],
      realm => 'MY.REALM',
      properties => {
        'dfs.replication' => 1,
      },
      authorization => {
        'rules' => 'limit',
        # more paranoid permissions only for users in "users" group
        'security.client.protocol.acl' => 'hue,nfs,root hadoop,hbase,hive,impala,oozie,spark,users',
        'security.service.authorization.default.acl' => ' hadoop,users',
      },
      # https recommended (and other extensions may require it)
      https => true,
      https_cacerts_password => '',
      https_keystore_keypassword => 'changeit',
      https_keystore_password => 'changeit',
    }

Modify *$::fqdn* and add node sections as needed for multi-node cluster.

<a name="long-run"></a>
#### Long running applications

For long-running applications as Spark Streaming jobs you may need to workaround user's delegation tokens a maximum lifetime of 7 days by these properties in `properties` parameter:

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
* Impala: *impala/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *impala*
* Oozie: *oozie/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *oozie*
* Solr: *solr/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *solr*
* Spark: *spark/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *spark*
* Sqoop: *sqoop/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *sqoop*
* Zookeeper: *zookeeper/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *zookeeper*
* ... and helper principals:
 * HTTFS proxy: *httpfs/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *httpfs*
 * HTTP SPNEGO: *HTTP/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *HTTP*
 * Tomcat: *tomcat/&lt;HOST&gt;@&lt;REALM&gt;* -&gt; *tomcat*

*hadoop.security.auth_to_local* is needed and can't be removed if:

* Kerberos principals and local user names are different
 * they differ in the official documentation: *nn/\_HOST* vs *hdfs*, ...
 * they are the same in Cloudera documentation: hdfs/\_HOST vs *hdfs*, ...
* when cross-realm authentication is needed

<a name="https"></a>
###Enable HTTPS

Hadoop is able to use SPNEGO protocol (="Kerberos tickets through HTTPS"). This requires proper configuration of the browser on the client side and valid Kerberos ticket.

HTTPS support requires:

* enabled security (non-empty `realm`)
* */etc/security/cacerts* file (`https_cacerts` parameter) - kept in the place, only permission changed if needed
* */etc/security/server.keystore* file (`https_keystore` parameter) - copied for each daemon user
* */etc/security/http-auth-signature-secret* file (any data, string or blob) - copied for each daemon user
* */etc/security/keytab/http.service.keytab* - copied for each daemon user

Preparing the CA certificates store (*/etc/security/cacerts*):

    # for each CA certificate in the chain
    keytool -importcert -keystore cacerts -storepass changeit -trustcacerts -alias some-alias -file some-file.pem
    # check
    keytool -list -keystore cacerts -storepass changeit
    # move to the right default location
    mv cacerts /etc/security/

Preparing the certificates keystore (*/etc/security/server.keystore*):

    # example values for certificate alias and passphrase
    alias='hadoop-dcv'
    read pass

    # X509 -> pkcs12
    # (enter some passphrase)
    openssl pkcs12 -export -in /etc/grid-security/hostcert.pem
                   -inkey /etc/grid-security/hostkey.pem \
                   -out server.p12 -name ${alias} -certfile tcs-ca-bundle.pem

    # pkcs12 -> java
    # (the alias must be the same as the name above)
    # (some addons may need the same store passphrase and key passphrase)
    keytool -importkeystore \
            -deststorepass ${pass} -destkeypass ${pass} -destkeystore server.keystore \
            -srckeystore server.p12 -srcstoretype PKCS12 -srcstorepass some-passphrase \
            -alias ${alias}

    # check
    keytool -list -keystore server.keystore -storepass ${pass}

    # move to the right default location
    chmod 0600 server.keystore
    mv server.keystore /etc/security/

Preparing the signature secret file (*/etc/security/http-auth-signature-secret*):

    dd if=/dev/random bs=128 count=1 > http-auth-signature-secret
    chmod 0600 http-auth-signature-secret
    mv http-auth-signature-secret /etc/security/

The following hadoop class parameters are used for HTTPS (see also [Module Parameters](#parameters)):

* `realm` (required for HTTPS)
  Enable security and Kerberos realm to use. See [Security](#security).

* `https` (undef)
  Enable support for https.

* `https_cacerts` (*/etc/security/cacerts*)
  CA certificates file.

* `https_cacerts_password` ('')
  CA certificates keystore password.

* `https_keystore` (*/etc/security/server.keystore*)
  Certificates keystore file.

* `https_keystore_password` ('changeit')
  Certificates keystore file password.

* `https_keystore_keypassword` (undef)
  Certificates keystore key password. If not specified, `https_keystore_password` is used.

Consider also checking POSIX ACL support in the system and enabling `acl` in Hadoop module. It's useful for more pedantic rights on *ssl-&#42;.xml* files, which needs to be read by Hadoop additions (like HBase).


<a name="multihome"></a>
###Multihome Support

Multihome support doesn't work out-of-the box in Hadoop 2.6.x (2015-01). Properties and bind hacks to multihome support can be enabled by **multihome => true** in `features`. You will also need to add secondary IPs of datanodes to `datanode_hostnames` (or `slaves`, which sets `datanode_hostnames` and `nodemanager_hostnames`):

    class{"hadoop":
      hdfs_hostname => $::fqdn,
      yarn_hostname => $::fqdn,
      # for multi-home
      datanode_hostnames => [ $::fqdn, '10.0.0.2', '192.169.0.2' ],
      slaves => [ $::fqdn ],
      frontends => [ $::fqdn ],
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

* *hadoop.security.token.service.use\_ip* => false
* *yarn.resourcemanager.bind-host* => '0.0.0.0'
* *dfs.namenode.http-bind-host* => '0.0.0.0'
* *dfs.namenode.https-bind-host* => '0.0.0.0'
* *dfs.namenode.rpc-bind-host* => '0.0.0.0'
* *dfs.namenode.servicerpc-bind-host* => '0.0.0.0'

Also **Oozie** addon may have problems accessing MapRed History Server. For example there is needed public access to the **port 10020** in network environment with addresses in DNS and private addresses in */etc/hosts*. This mapping helps in such case:

    iptables -t nat -A PREROUTING -p tcp -m tcp -d $PUBLIC_IP --dport 10020 -j DNAT --to-destination $PRIVATE_BIND_IP:10020


<a name="ha"></a>
###High Availability

There are needed also these daemons for High Availability:

* Secondary Name Node (1) - there will be two Name Node servers
* Journal Node (>=3) - requires HTTPS, when Kerberos security is enabled
* Zookeeper/Failover Controller (2) - on each Name Node
* Zookeeper (>=3)

There is also recommended for WebHDFS and High Availability:

* HTTPFS proxy (1) - required for Apache Hue, requires also HTTPS

When specifying zookeeper (`zookeeper_hostnames` parameter), automatic failover is enabled. You can override it by *dfs.ha.automatic-failover.enabled* and *yarn.resourcemanager.ha.automatic-failover.enabled* properties in `properties` parameter.

<a name="ha-fresh"></a>
#### Fresh installation

Setup High Availability requires precise order of all steps. For example all zookeeper servers must be running before formatting zkfc (class *hadoop::zkfc::service*), or all journal nodes must running during initial formatting (class *hadoop::namenode::config*) or when converting existing cluster to cluster with high availability.

There are helper parameters to separate overall cluster setup to more stages:

1. `zookeeper_deployed`=**false**, `hdfs_deployed`=**false**: zookeeper quorum and journal nodes quorum
2. `zookeeper_deployed`=**true**, `hdfs_deployed`=**false**: HDFS format and bootstrap (primary and secondary NN), setup and launch ZKFC and NN daemons
3. `zookeeper_deployed`=**true**, `hdfs_deployed`=**true**: enable History Server and RM state-store feature, if enabled

These parameters are not required, the setup should converge when setup is repeated. They may help with debugging problems though, because less things will fail if the setup is separated to several stages over the whole cluster.

**Example**:

    $master1_hostname = 'hadoop-master1.example.com'
    $master2_hostname = 'hadoop-master2.example.com'
    $slaves           = ['hadoop1.example.com', 'hadoop2.example.com', ...]
    $frontends        = ['hadoop.example.com']
    $httpfs_hostnames = [$master1_hostname]
    $quorum_hostnames = [$master1_hostname, $master2_hostname, 'master3.example.com']
    $cluster_name     = 'example'

    $hdfs_deployed      = true
    $zookeeper_deployed = true

    class{'hadoop':
      hdfs_hostname           => $master1_hostname,
      hdfs_hostname2          => $master2_hostname,
      yarn_hostname           => $master1_hostname,
      yarn_hostname2          => $master2_hostname,
      historyserver_hostname  => $master1_hostname,
      httpfs_hostnames        => $httpfs_hostnames,
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
      include hadoop::httpfs
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
    }

    node /hadoop\d+.example.com/ {
      include hadoop::datanode
      include hadoop::nodemanager
    }

Note: Journalnode and Zookeeper are not resource intensive daemons and can be collocated with other daemons. In this example the content of *master3.example.com* node can be moved to some slave node or the frontend (and *$quorum_hostnames* updated).

<a name="ha-convert"></a>
#### Converting non-HA cluster

You can use the example above. But you will need to let skip bootstrap **on secondary Name Node before setup**:

    touch /var/lib/hadoop-hdfs/.puppet-hdfs-bootstrapped

And activate HA **on the primary Name Node after Journal Nodes Quorum setup** (under *hdfs* user):

    # when Kerberos is enabled:
    #export KRB5CCNAME=FILE:/tmp/krb5cc_hdfs_admin
    #kinit -k -t /etc/security/keytab/nn.service.keytab nn/`hostname -f`
    #
    hdfs namenode -initializeSharedEdits

You must rsync namenode metadata from the primary Name Node **to the secondary Name Node after setup**, then start the secondary Name Node server (this replaces the command *hdfs namenode -bootstrapStandby*, which seems to have issues).

<a name="ha-security"></a>
#### HA Quorum Security

It is recommended to secure zookeeper quorum in secured Hadoop cluster.

See *hadoop* class parameters:

* [ha\_credentials](#ha_credentials)
* [ha\_digest](#ha_digest)

<a name="ha-addons"></a>
#### Hadoop addons

Some Hadoop addons may require extra actions:

* Hive schema needs to be updated when changing non-HA cluster to HA (because defaultFS has been changed), see [Hive#defaultfs](https://github.com/MetaCenterCloudPuppet/cesnet-hive#defaultfs)

<a name="nfs"></a>
#### HDFS NFS Gateway

HDFS NFS Gateway provides limited support for direct access to HDFS. Beware, the NFS may still have issues (problems with <= 3 nodes, problems with HDFS HA and cluster name), tested on Hadoop 2.6.0/Cloudera 5.4.7.

The class *hadoop::nfs* will setup the daemon and mount locally HDFS to /hdfs. The resource *hadoop::nfs::mount* is used to perform the mounting. If mounting remotely, don't forget to add authorization access to the remote HDFS NFS server.

HDFS NFS Gateway doesn't support any authentication, so we recommend to filter clients at least by hostnames/IPs. By default only local machine is allowed to mount the NFS (`nfs_exports` parameter).

Useful properties:

* *nfs.superuser*: super-user name (not configured by default)
* *nfs.metrics.percentiles.intervals*: **100** will enable latency histogram in Nfs3Metrics
* *nfs.port.monitoring.disabled*: **true** to allow mounting from unprivileged users

Useful environments:

* *HADOOP\_NFS3\_OPTS*: JVM settings (heap, GC, ...)

**Example 1**: local HDFS NFS Gateway

    class{"hadoop":
       ...
       #nfs_dumpdir => '/mnt/scratch/.hdfs-nfs',
       nfs_hostnames => ['hadoop-frontend.example.com'],
    }

    node 'hadoop-frontend.example.com' {
      include hadoop::nfs
    }

**Example 2**: remote HDFS NFS Gateway

    class{"hadoop":
       ...
       nfs_hostnames => ['hadoop-frontend.example.com'],
       #nfs_dumpdir => '/mnt/scratch/.hdfs-nfs',
       nfs_exports => "${::fqdn} rw; external-host.example.com rw",
    }

    node 'hadoop-frontend.example.com' {
      include hadoop::nfs
    }

    node 'external-host.example.com' {
      hadoop::nfs::mount { '/mnt/hadoop':
        nfs_hostname => 'hadoop-frontend.example.com',
      }
    }

<a name="nfs-sec"></a>
##### Security

The keytab file */etc/security/keytab/nfs.service.keytab* is required. It must contain principal for HDFS NFS Gateway.

The principal must correspond to the valid system user (`auth_to_local` rules provides the mapping). This system user will be used also as Hadoop proxy user. The default value is 'nfs'.

Principals needed:

* host/&lt;HOSTNAME&gt;@&lt;REALM&gt;
* nfs/&lt;HOSTNAME&gt;@&lt;REALM&gt;

<a name="nfs-auth"></a>
##### Authorization

*root* user must be authorized for client access to able to mount. In secured cluster, *nfs* user needs to be authorized too. By default this is not needed, authorization is '\*'. See `authorization` parameter.

Example of changing HADOOP default ACL to more strict settings with NFS:

     authorization => {
       'rules' => 'limit',
       'security.client.protocol.acl' => 'hue,nfs,root hadoop,hbase,hive,impala,oozie,spark,users',
       'security.service.authorization.default.acl' => ' hadoop,users',
     }

<a name="nfs-check"></a>
##### Quick check

    nfs_hostname=`hostname -f`

    rpcinfo -p ${nfs_hostname}
    showmount -e ${nfs_hostname}

<a name="httpfs"></a>
#### HTTPFS Proxy

HTTPFS Proxy is not as good as the internal WebHDFS, because all communication must go through the proxy. But it is probably good enough as local proxy. It is required for Apache Hue, when there is used High Availability of HDFS.

<a name="httpfs-sec"></a>
##### Security

The keytab file */etc/security/keytabs/httpfs-http.service.keytab* is required. Following principals must be available (replace *HOSTNAME* and *REALM* for real values):

* *httpfs/HOSTNAME@REALM*
* *HTTP/HOSTNAME@REALM*

<a name="httpfs-auth"></a>
##### Authorization

Properties *hadoop.proxyuser.httpfs.hosts* and *hadoop.proxyuser.httpfs.groups* are set, parameter *httpfs_hostnames* is used for the list of the hostnames (it may be overridden by using the *hadoop.proxyuser.httpfs.hosts* property directly).

<a name="httpfs-check"></a>
##### Usage

**Example**: list status (without security)

    httpfs_hostname=...
    user=...
    HDFS_FILE=/user/...
    curl -i "https://${httpfs_hostname}:14000/webhdfs/v1${HDFS_FILE}?op=liststatus&user.name=${user}"

**Example**: list status (with security)

    httpfs_hostname=...
    HDFS_FILE=/user/...
    curl --negotiate -u : -i "https://${httpfs_hostname}:14000/webhdfs/v1${HDFS_FILE}?op=liststatus"

**Example**: creating the file (with security):

    httpfs_hostname=...
    LOCAL_FILE=...
    HDFS_FILE=/user/...
    curl --negotiate -u : -i -T ${LOCAL_FILE} -H 'Content-Type: application/octet-stream' "https://${httpfs_hostname}:14000/webhdfs/v1${HDFS_FILE}?op=create&data=true"

<a name="upgrade"></a>
### Upgrade

The best way is to refresh configurations from the new original (=remove the old) and relaunch puppet on top of it.

For example:

    alternative='cluster'
    d='hadoop'
    mv /etc/{d}$/conf.${alternative} /etc/${d}/conf.cdhXXX
    update-alternatives --auto ${d}-conf

    # upgrade
    ...

    puppet agent --test
    #or: puppet apply ...

<a name="reference"></a>
##Reference

<a name="classes"></a>
###Classes

* [**`hadoop`**](#class-hadoop): Main configuration class
* `hadoop::common::hdfs::config`
* `hadoop::common::hdfs::daemon`
* `hadoop::common::mapred::config`
* `hadoop::common::mapred::daemon`
* `hadoop::common::yarn::config`
* `hadoop::common::yarn::daemon`
* `hadoop::common::config`
* `hadoop::common::install`
* `hadoop::common::postinstall`
* `hadoop::common::slaves`
* `hadoop::config`
* `hadoop::create_dirs`
* `hadoop::install`
* `hadoop::params`
* `hadoop::service`
* **`hadoop::datanode`**: HDFS Data Node
* `hadoop::datanode::config`
* `hadoop::datanode::install`
* `hadoop::datanode::service`
* **`hadoop::frontend`**: Hadoop client and examples
* `hadoop::frontend::config`
* `hadoop::frontend::install`
* `hadoop::frontend::service` (empty)
* **`hadoop::historyserver`**: MapReduce Job History Server
* `hadoop::historyserver::config`
* `hadoop::historyserver::install`
* `hadoop::historyserver::service`
* **`hadoop::httpfs`**: Hadoop HTTPFS proxy
* `hadoop::httpfs::config`
* `hadoop::httpfs::install`
* `hadoop::httpfs::service`
* **`hadoop::journalnode`**: HDFS Journal Node used for Quorum Journal Manager
* `hadoop::journalnode::config`
* `hadoop::journalnode::install`
* `hadoop::journalnode::service`
* **`hadoop::namenode`**: HDFS Name Node
* `hadoop::namenode::bootstrap`
* `hadoop::namenode::config`
* `hadoop::namenode::format`
* `hadoop::namenode::install`
* `hadoop::namenode::service`
* **`hadoop::nfs`**: HDFS NFS Gateway
* `hadoop::nfs::config`
* `hadoop::nfs::install`
* `hadoop::nfs::service`
* `hadoop::nfs::user`: Create system user for NFS Gateway (if needed)
* **`hadoop::nodemanager`**: YARN Node Manager
* `hadoop::nodemanager::config`
* `hadoop::nodemanager::install`
* `hadoop::nodemanager::service`
* **`hadoop::resourcemanager`**: YARN Resource Manager
* `hadoop::resourcemanager::config`
* `hadoop::resourcemanager::install`
* `hadoop::resourcemanager::service`
* **`hadoop::zkfc`**: HDFS Zookeeper/Failover Controller
* `hadoop::zkfc::config`
* `hadoop::zkfc::install`
* `hadoop::zkfc::service`

<a name="facts"></a>
###Facts

* **`uid_min`**: minimal UID (*UID_MIN* as read from */etc/login.defs*)

<a name="resources"></a>
###Resource Types

* **`hadoop::kinit`**: Initialize credentials
* **`hadoop::kdestroy`**: Destroy credentials
* [**`hadoop::mkdir`**](#resource-mkdir): Creates a directory on HDFS
* **`hadoop::nfs::mount`**: Mount NFS provided by the HDFS NFS gateway
* [**`hadoop::user`**](#resource-user): Create user account

<a name="class-hadoop"></a>
### `hadoop` class

<a name="parameters"></a>
#### Parameters

#####`acl`

Determines, if setfacl command is available and /etc/hadoop is on filesystem supporting POSIX ACL. Default: undef.

It is used only when https is enabled to set less open privileges on ssl-server.xml.

#####`alternatives`

Switches the alternatives used for the configuration. Default: 'cluster' (Debian) or undef.

It can be used only when supported (for example with Cloudera distribution).

#####`alternatives_httpfs`

Switches the alternatives used for the configuration of HTTPFS proxy. Default: 'cluster' (Debian) or undef.

It can be used only when supported (for example with Cloudera distribution).

#####`authorization`

Hadoop service level authorization ACLs. Default: {}.

Authorizations are enabled and predefined rule set and/or particular properties can be specified.

Each ACL is in the form of: (wildcard "\*" is allowed)

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
      'security.client.protocol.acl' => 'hue,nfs,root hadoop,hbase,hive,impala,oozie,spark,users',
      'security.service.authorization.default.acl' => ' hadoop,users',
    }

Note: Beware *...acl.blocked* are not used if the *....acl* counterpart is defined.

Note 2: If not using wildcards in permit rules, you should enable access also for Hadoop additions (as seen in the example).

Note 3: See also [HDFS NFS Gateway: Authorization](#nfs-auth).

#####`cluster_name`

Name of the cluster. Default: 'cluster'.

Used during initial formatting of HDFS. For non-HA configurations it may be undef.

#####`compress_enable`

Enable compression of intermediate files by snappy codec. Default: true.

This will set following properties:

* *mapred.compress.map.output*: true
* *mapred.map.output.compression.codec*: "org.apache.hadoop.io.compress.SnappyCodec"

#####`datanode_hostnames`

Array of Data Node machines. Default: `slaves`.

#####`descriptions`

Descriptions for the properties. Default: see params.pp.

Just for cuteness of config files.

#####`environment`

Environment to set for all Hadoop daemons. Default: undef.

    environment => {'HADOOP_HEAPSIZE' => 4096, 'YARN_HEAPSIZE' => 4096}

#####`features`

Enable additional features. Default: {}.

Available features:

* **rmstore**: resource manager recovery using state-store (YARN may depends on HDFS)
 * *hdfs*: store state on HDFS, this requires HDFS datanodes already running and /rmstore directory created ==> you may want to keep it disabled on initial setup. Requires *hdfs\_deployed* to be true.
 * *zookeeper*: store state on zookeepers. Requires *zookeeper\_hostnames* specified. Warning: no authentication is used.
 * *true*: select automatically zookeeper or hdfs according to *zookeeper\_hostnames*
* **restarts**: regular resource manager restarts (MIN HOUR MDAY MONTH WDAY); it shall never be restarted, but it may be needed for refreshing Kerberos tickets
* **krbrefresh**: use and refresh Kerberos credential cache (MIN HOUR MDAY MONTH WDAY); beware there is a small race-condition during refresh
* **yellowmanager**: script in /usr/local to start/stop all daemons relevant for given node
* **multihome**: enable properties required for multihome usage. You will need also add secondary IP addresses to *datanode\_hostnames*.
* **aggregation**: enable YARN log aggregation (we recommend, but YARN will depend on HDFS)

We recommend to enable: **rmstore**, **aggregation** and probably **multihome**.

#####`frontends`

Array of frontend hostnames. Default: `slaves`.

<a name="ha_credentials"></a>
#####`ha_credentials`

Zookeeper credentials for HA HDFS. Default: undef.

With enabled high availability of HDFS in secured cluster, it is recommended to secure also zookeeper. The value is in the form *USER:PASSWORD*.

Set this to something like: **hdfs-zkfcs:PASSWORD**.

<a name="ha_digest"></a>
#####`ha_digest`

Digest version of *ha\_credentials*. Default: undef.

You can generate it this way:

    ZK_HOME=/usr/lib/zookeeper
    ZK_CP=`ls -1 $ZK_HOME/lib/*.jar $ZK_HOME/*.jar | tr '\n' ':'`
    java -cp $ZK_CP org.apache.zookeeper.server.auth.DigestAuthenticationProvider hdfs-zkfcs:PASSWORD

#####`hdfs_data_dirs`

Directory prefixes to store the data on HDFS datanodes. Default: ["/var/lib/hadoop-hdfs"] or ["/var/lib/hadoop-hdfs/cache"].

They are used for DFS data blocks.

Expected is an array, the format of each item is: **[TYPE]SCHEME://PATH**

* *[TYPE]* (optional): **[DISK]**, **[SSD]**, **[ARCHIVE]**, **[RAM\_DISK]** (default: *[DISK]*)
* *SCHEME* (optional): **file** (default: *file*)
* *PATH*: the directory for the data

Notes:

* */${user.name}/dfs/datanode* suffix is always added
* if there are multiple directories, then data will be stored in all directories, typically on different devices

Examples:

    ['/data/1', '/data/2']
    ['[RAM_DISK]/ram', '[DISK]/var/lib/hadoop-hdfs/cache']

#####`hdfs_deployed`

Perform also actions requiring working HDFS (namenode + enough datanodes). Default: true.

You can set this to **false** during initial installation and divide setup this way to two separated stages. **false** will disable following actions:

* starting MapReduce History Server
* enabling RM HDFS state-store feature (if enabled)
* starting NFS server and NFS mounts (if enabled)

Two stage setup is not required, but it is recommended to avoid errors during initial installation.

#####`hdfs_hostname`

Hadoop Filesystem Name Node machine. Default: $::fqdn.

#####`hdfs_hostname2`

Another Hadoop Filesystem Name Node machine for High Availability. Default: undef.

Used for High Availability. This parameter will activate the HDFS HA feature. See [http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html](http://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html).

If you're converting existing Hadoop cluster without HA to cluster with HA, you need to initialize journalnodes yet:

    hdfs namenode -initializeSharedEdits

Zookeepers are required for automatic transitions.

If Hadoop cluster is secured, it is recommended also secure Zookeeper. See `ha_credentials` and `ha_digest` parameters.

#####`hdfs_journal_dirs`

Directory prefixes to store journal logs by journal name nodes, if different from `hdfs_name_dirs`. Default: undef.

#####`hdfs_name_dirs`

Directory prefixes to store the metadata on the namenode. Default: ["/var/lib/hadoop-hdfs"] or ["/var/lib/hadoop-hdfs/cache"].

* directory for name table (fsimage)
* /${user.name}/dfs/namenode or /${user.name}/dfs/name suffix is always added
 * If there is multiple directories, then the name table is replicated in all of the directories, for redundancy
 * All directories needs to be available to namenode work properly (==> good on mirrored raid)
 * Crucial data (==> good to save at different physical locations)

When adding a new directory, you will need to replicate the contents from some of the other ones. Or set dfs.namenode.name.dir.restore to true and create NEW\_DIR/hdfs/dfs/namenode with proper owners.

#####`hdfs_secondary_dirs`

Directory prefixes to store metadata by secondary name nodes, if different from `hdfs_name_dirs`. Default: undef.

#####`historyserver_hostname`

History Server machine. Default: `yarn_hostname`.

#####`httpfs_hostnames`

List of HTTPFS proxy hostnames. Default: [].

#####`hue_hostnames`

List of Apache Hue hostnames. Default: [].

Used for proxyuser authorization properties:

* *httpfs.proxyuser.hue.groups*
* *httpfs.proxyuser.hue.hosts*
* *hadoop.proxyuser.hue.groups*
* *hadoop.proxyuser.hue.hosts*

#####`https`

Enable support for https. Default: undef.

See also [Enable HTTPS](#https).

#####`https_cacerts`

CA certificates file. Default: '/etc/security/cacerts'.

#####`https_cacerts_password`

CA certificates keystore password. Default: ''.

#####`https_keystore`

Certificates keystore file. Default: '/etc/security/server.keystore'.

See also [Enable HTTPS](#https).

#####`https_keystore_keypassword`

Certificates keystore key password. Default: undef.

If not specified, `https_keystore_password` is used.

#####`https_keystore_password`

Certificates keystore file password. Default: 'changeit'.

#####`https_keytab`

Keytab file for HTTPS. Default: '/etc/security/keytab/http.service.keytab'.

It will be copied for each daemon user and according permissions and properties set.

#####`impala_enable`

Enable settings needed for Impala addon. Default: true.

Features enabled:

* HDFS blocks metadata (*dfs.datanode.hdfs-blocks-metadata.enabled*)
* Short-circuit reads (*dfs.client.read.shortcircuit*, *dfs.domain.socket.path*)

#####`scratch_dir`

Creates and sets directory for local computational data for YARN. Default: undef.

Sets also the property *yarn.nodemanager.local-dirs*, suffix */${user.name}/nm-local-dir* is always added.

This parameter is used on YARN slave nodes. To boost performance, it should be set to quick local disk (striped raid, SSD, ...), big enough to hold temporary computational data.

If not set, it is used system default (*${hadoop.tmp.dir}/nm-local-dir*, which points to */tmp/hadoop-${user.name}*).

#####`journalnode_hostnames`

Array of HDFS Journal Node machines. Default: undef.

Used in HDFS namenode HA.

#####`keytab_datanode`

Keytab file for HDFS Data Node. Default: '/etc/security/keytab/dn.service.keytab'.

This will set also property *dfs.datanode.keytab.file*, if not specified directly. The keytab file must already exists.

#####`keytab_httpfs`

Keytab file for HDFS HTTP Proxy. Default: '/etc/security/keytab/httpfs-http.service.keytab'.

This will set also property *httpfs.authentication.kerberos.keytab*, if not specified directly.

The keytab file must already exists. Following principals must be available (replace *HOSTNAME* and *REALM* for real values):

* *httpfs/HOSTNAME@REALM*
* *HTTP/HOSTNAME@REALM*

#####`keytab_jobhistory`

Keytab file for Map Reduce Job History Server. Default: '/etc/security/keytab/jhs.service.keytab'.

This will set also property *mapreduce.jobhistory.keytab*, if not specified directly. The keytab file must already exists.

#####`keytab_journalnode`

Keytab file for HDFS Data Node. Default: '/etc/security/keytab/jn.service.keytab'.

This will set also property *dfs.journalnode.keytab.file*, if not specified directly. The keytab file must already exists.

#####`keytab_namenode`

Keytab file for HDFS Name Node. Default: '/etc/security/keytab/nn.service.keytab'.

This will set also property *dfs.namenode.keytab.file*, if not specified directly. The keytab file must already exists.

#####`keytab_nfs`

Keytab file for HDFS NFS Gateway. Default: '/etc/security/keytab/hdfs.service.keytab'.

This will set also property *nfs.keytab.file*, if not specified directly. The keytab file must already exists.

#####`keytab_nodemanager`

Keytab file for YARN Node Manager. Default: '/etc/security/keytab/nm.service.keytab'.

This will set also property *yarn.nodemanager.keytab*, if not specified directly. The keytab file must already exists.

#####`keytab_resourcemanager`

Keytab file for YARN Resource Manager. Default: '/etc/security/keytab/rm.service.keytab'.

This will set also property *yarn.resourcemanager.keytab*, if not specified directly. The keytab file must already exists.

#####`min_uid`

Minimal permitted UID of Hadoop users. Default: autodetect by facter.

Used in Linux containers, when security is enabled.

#####`nfs_dumpdir`

Directory used to temporarily save out-of-order writes before writing to HDFS. Default: '/tmp/.hdfs-nfs'.

Enough space is needed (>= 1 GB).

#####`nfs_exports`

NFS host access privileges. Default: "${::fqdn} rw".

As HDFS NFS Gateway doesn't have any authentication, we recommend to limit access according to IP/hostnames. Java regular expressions are used, entries are separated by ';'. Example: '192.168.0.0/22 rw ; \\w*\\.example\\.com ; host1.test.org ro'.

#####`nfs_hostnames`

Array of HDFS NFS Gateway hostnames. Default: [].

#####`nfs_mount`

Default directory to mount HDFS NFS Gateway. Default: '/hdfs'.

HDFS NFS Gateway is automatically mounted locally, but this can be disabled using empty string. Mounts are handled by **hadoop::nfs::mount** resource.

#####`nfs_mount_options`

Additional NFS mount options. Default: undef.

#####`nfs_proxy_user`

HDFS proxy user for NFS Gateway. Default: 'nfs' (secured cluster), *nfs\_system\_user* (without security).

This must be a system user. It is created automatically, if needed.

The Kerberos principal prefix from *keytab\_nfs* must be the same as this user. If it is not, you need to ensure:

1. Proper mapping from principal name to *nfs\_proxy\_user* must be specified in *hadoop.security.auth\_to\_local* property.
2. Principal must be specified in *nfs.kerberos.principal* property.

#####`nfs_system_user`

System user for HDFS NFS Gateway server. Default: 'hdfs'.

The value must correspond to packaging of Hadoop distribution.

#####`nodemanager_hostnames`

Array of Node Manager machines. Default: `slaves`.

#####`oozie_hostnames`

List of Apache Oozie hostnames. Default: [].

Used for proxyuser authorization properties:

* *hadoop.proxyuser.oozie.groups*
* *hadoop.proxyuser.oozie.hosts*

#####`perform`

Launch all installation and setup here, from hadoop class. Default: false.

#####`properties`

"Raw" properties for hadoop cluster. Default: (see params.pp).

"::undef" value will remove given property set automatically by this module, empty string sets the empty value.

#####`realm`

Enable security and Kerberos realm to use. Default: ''.

Empty string disables the security.

When security is enabled, there is required:

* installed Kerberos client (Debian: krb5-user/heimdal-clients; RedHat: krb5-workstation)
* configured Kerberos client (*/etc/krb5.conf*, */etc/krb5.keytab*)
* */etc/security/keytab/dn.service.keytab* (on data nodes)
* */etc/security/keytab/jhs.service.keytab* (on job history node)
* */etc/security/keytab/nm.service.keytab* (on node manager nodes)
* */etc/security/keytab/nn.service.keytab* (on name nodes)
* */etc/security/keytab/rm.service.keytab* (on resource manager node)
* */etc/security/keytab/httpfs-http.service.keytab* (on HTTPFS proxy node)
* */etc/security/keytab/nfs.service.keytab* (on NFS gateway node)

If https is enabled, cookie domain is set automatically to lowercased `realm`. This may be overridden by *http.authentication.cookie.domain* in `properties`.

#####`slaves`

Array of slave node hostnames. Default: [$::fqdn].

#####`yarn_hostname`

Yarn machine (with Resource Manager and Job History services). Default: $::fqdn.

#####`yarn_hostname2`

YARN resourcemanager second hostname for High Availability. Default: undef.

This parameter will activate the YARN HA feature. See [http://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html](http://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html).

Zookeepers are required (`zookeeper_hostnames` parameter).

#####`zookeeper_deployed`

Perform also actions requiring working zookeeper and journal nodes. Default: true.

When **true**, launch ZKFC daemons and secondary namenode (if enabled). You can set this to **false** during initial installation when High Availability is enabled.

#####`zookeeper_hostnames`

Array of Zookeeper machines. Default: undef.

Used in HDFS namenode HA for automatic failover and for YARN resourcemanager state-store feature.

Without zookeepers and HDFS HA, the manual failover is needed: the namenodes are always started in standby mode and one would need to be activated manually.

<a name="resource-mkdir"></a>
### `mkdir` resource

Creates a directory on HDFS. Skips everything, if a helper *$touchfile* exists. Parent directories are created, if needed.

**Example**:

    hadoop::kinit { 'hdfs-extradir-created': }
    ->
    hadoop::mkdir{'/bigdata':
      owner     => 'hawking',
      group     => 'users',
      mode      => '1770',
      touchfile => 'hdfs-extradir-created',
    }
    ->
    hadoop::kdestroy { 'hdfs-extradir-created': }

#####`owner`

Sets the owner. Default: undef (system default is 'hdfs').

#####`group`

Sets the group. Default: undef (system default is 'supergroup').

#####`mode`

Sets the permissions. Default: undef (system default is '0755', if the property *fs.permissions.umask-mode* has default value of *022*).

#####`recursive`

Changes permissions recursively. Default: false.

#####`touchfile`

Helper file name. Required.

The name should be the same as used in *hadoop::kinit()* and *hadoop::kdestroy()* resources. It skips everything, if the touchfile already exists.

<a name="resource-user"></a>
### `user` resource

Creates user account. Beware there is no additional logic! *hdfs* must be enabled only once and on HDFD name node, *shell* is not needed except the frontend.

**Example**:

    hadoop::kinit { 'hdfs-user-created': }
    ->
    hadoop::user{['hawking']:
      groups    => 'users',
      hdfs      => ($hadoop::hdfs_hostname == $::fqdn),
      shell     => member($hadoop::frontends, $::fqdn),
      realms    => ['EXAMPLE.COM'],
      touchfile => 'hdfs-user-created',
    }
    ->
    hadoop::kdestroy { 'hdfs-user-created': }

#####`groups`

Additional user groups. Default: ['users'].

#####`hdfs`

Create also user directory on HDFS. Required.

Values:

* **true**
* **false**

#####`homedir`

User home directory, where to create *.k5login* file. Default: "/home/${title}".

#####`realms`

Kerberos realms, if any. Default: [].

Creates the *.k5login* file, if the *realms* specified.

#####`shell`

Enable shell. Required.

Values:

* **true**
* **false**

#####`touchfile`

Helper file name. Required.

The name should be the same as used in *hadoop::kinit()* and *hadoop::kdestroy()* resources. It skips everything, if the touchfile already exists.

<a name="limitations"></a>
##Limitations

Idea in this module is to do only one thing - setup Hadoop cluster - and not limit generic usage of this module by doing other stuff. You can have your own repository with Hadoop SW, you can select which Kerberos implementation or Java version to use.

On other hand this leads to some limitations as mentioned in [Setup Requirements](#setup-requirements) section and usage is more complicated - you may need site-specific puppet module together with this one.

Other limitation is poor support for synchronization across multiple machines. Setup will converge on repeated runs, but it is better to separate setup to two (or more) stages.

###High Availability

*zookeeper\_deployed=true*, *hdfs\_deployed=false*: HDFC zkfc startup on secondary NN fails before primary NN is completely setup, it's started later during another puppet launch.

###Unit tests

Only Puppet 3 can be tested by unit-tests, Puppet 4 can't use *site.pp* from tests.

<a name="development"></a>
##Development

* Repository: [https://github.com/MetaCenterCloudPuppet/cesnet-hadoop](https://github.com/MetaCenterCloudPuppet/cesnet-hadoop)
* Tests:
 * basic: see *.travis.yml*
 * vagrant: [https://github.com/MetaCenterCloudPuppet/hadoop-tests](https://github.com/MetaCenterCloudPuppet/hadoop-tests)
* Email: František Dvořák &lt;valtri@civ.zcu.cz&gt;
