# == Class hadoop::common::hdfs::daemon
#
# HDFS specific setup. Called from namenode and datanode classes.
#
class hadoop::common::hdfs::daemon {
  file { $hadoop::hdfs_socketdir:
    ensure => directory,
    owner  => 'hdfs',
    group  => 'hdfs',
    mode   => '0644',
  }
  if $hadoop::realm and $hadoop::realm != '' {
    file { "${hadoop::hdfs_homedir}/hadoop.keytab":
      owner  => 'hdfs',
      group  => 'hdfs',
      mode   => '0640',
      source => $hadoop::https_keytab,
    }
    file { "${hadoop::hdfs_homedir}/http-auth-signature-secret":
      owner  => 'hdfs',
      group  => 'hdfs',
      mode   => '0640',
      source => '/etc/security/http-auth-signature-secret',
    }
  }
  if $hadoop::https {
    file { "${hadoop::hdfs_homedir}/keystore.server":
      owner  => 'hdfs',
      group  => 'hdfs',
      mode   => '0640',
      source => $hadoop::https_keystore,
    }
  }
}
