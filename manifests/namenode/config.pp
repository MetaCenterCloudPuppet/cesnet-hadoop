# == Class hadoop::namenode::config
#
# This class is called from hadoop::namenode.
#
class hadoop::namenode::config {
  include stdlib
  contain hadoop::common::config
  contain hadoop::common::hdfs::config
  contain hadoop::common::hdfs::daemon
  contain hadoop::format

  # ensure proper owner and group
  # (better to enable sticky bit for more protection)
  ensure_resource('file', $hadoop::hdfs_name_dirs, {
    ensure => directory,
    owner  => 'hdfs',
    group  => 'hadoop',
    mode   => '1755',
  })

  if $hadoop::realm {
    file { '/etc/security/keytab/nn.service.keytab':
      owner  => 'hdfs',
      group  => 'hdfs',
      mode   => '0400',
      alias  => 'nn.service.keytab',
      before => File['hdfs-site.xml'],
    }

    file { '/etc/security/keytab/http.service.keytab':
      owner  => 'hdfs',
      group  => 'hdfs',
      mode   => '0400',
      alias  => 'http.service.keytab',
      before => File['hdfs-site.xml'],
    }
  }

  File[$hadoop::hdfs_name_dirs] -> Class['hadoop::format']
  Class['hadoop::common::config'] -> Class['hadoop::format']
  Class['hadoop::common::hdfs::config'] -> Class['hadoop::format']
}
