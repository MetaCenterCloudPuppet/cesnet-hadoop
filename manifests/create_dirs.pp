# == Class hadoop::create_dirs
#
# Create root directory layout at Hadoop Filesystem. Take care also for Kerberos ticket inicialization and destruction, when realm is specified.
#
# Requirements: HDFS needs to be formatted and namenode service running.
#
# This class is called from hadoop::service.
#
class hadoop::create_dirs {
  $realm = $hadoop::realm
  # hadoop.security.auth_to_local not used by ResourceManager state-store
  # (Hadoop 2.4.1)
  if ($realm) { $rmstore_user = 'rm' }
  else { $rmstore_user = 'yarn' }

  # existing kerberos ticket is in the way when using 'runuser',
  # destroy it only when needed though
  exec { 'kdfs-kdestroy':
    command => 'kdestroy',
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    onlyif  => "test -n \"${realm}\"",
    creates => '/var/lib/hadoop-hdfs/.puppet-hdfs-root-created',
  }
  ->
  exec { 'hdfs-kinit':
    command => "runuser hdfs -s /bin/bash /bin/bash -c \"kinit -k nn/${::fqdn}@${realm} -t /etc/security/keytab/nn.service.keytab\"",
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    onlyif  => "test -n \"${realm}\"",
    creates => '/var/lib/hadoop-hdfs/.puppet-hdfs-root-created',
  }
  ->
  exec { 'hdfs-dirs':
    command => '/usr/sbin/hdfs-create-dirs && touch /var/lib/hadoop-hdfs/.puppet-hdfs-root-created',
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    creates => '/var/lib/hadoop-hdfs/.puppet-hdfs-root-created',
    # don't call multiple times (takes long) ==> use just 'true' as refresh
    # lint:ignore:quoted_booleans 'true' and 'false' are commands to run here
    refresh => 'true',
    # lint:endignore
  }
  ->
  # this directory is needed for ResourceManager state-store to work
  exec { 'hdfs-rmstore':
    command => "runuser hdfs -s /bin/bash /bin/bash -c \"hdfs dfs -mkdir /rmstore\"",
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    creates => '/var/lib/hadoop-hdfs/.puppet-hdfs-rmstore-created',
    # don't call multiple times (fails) ==> use just 'true' as refresh
    # lint:ignore:quoted_booleans 'true' and 'false' are commands to run here
    refresh => 'true',
    # lint:endignore
  }
  ->
  # this directory is needed for ResourceManager state-store to work
  exec { 'hdfs-rmstore-chown':
    command => "runuser hdfs -s /bin/bash /bin/bash -c \"hdfs dfs -chown ${rmstore_user}:hadoop /rmstore\" && touch /var/lib/hadoop-hdfs/.puppet-hdfs-rmstore-created",
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    creates => '/var/lib/hadoop-hdfs/.puppet-hdfs-rmstore-created',
  }
  ->
  exec { 'hdfs-kdestroy':
    command => "runuser hdfs -s /bin/bash /bin/bash -c \"kdestroy\"",
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    onlyif  => "test -n \"${realm}\"",
    creates => '/var/lib/hadoop-hdfs/.puppet-hdfs-root-created',
  }
}
