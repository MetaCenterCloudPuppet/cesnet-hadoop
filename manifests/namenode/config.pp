# == Class hadoop::namenode::config
#
# This class is called from hadoop::namenode.
#
class hadoop::namenode::config {
  include stdlib
  contain hadoop::common::config
  contain hadoop::common::hdfs::config
  contain hadoop::common::hdfs::daemon

  # ensure proper owner and group
  # (better to enable sticky bit for more protection)
  ensure_resource('file', $hadoop::_hdfs_name_dirs, {
    ensure => directory,
    owner  => 'hdfs',
    group  => 'hadoop',
    mode   => '1755',
  })

  if $hadoop::realm {
    file { $hadoop::keytab_namenode:
      owner  => 'hdfs',
      group  => 'hdfs',
      mode   => '0400',
      alias  => 'nn.service.keytab',
      before => File['hdfs-site.xml'],
    }

    file { $hadoop::https_keytab:
      owner  => 'hdfs',
      group  => 'hdfs',
      mode   => '0400',
      alias  => 'http.service.keytab',
      before => File['hdfs-site.xml'],
    }
  }

  # format only on the first namenode
  if $hadoop::hdfs_hostname == $::fqdn {
    contain hadoop::format

    File[$hadoop::_hdfs_name_dirs] -> Class['hadoop::format']
    Class['hadoop::common::config'] -> Class['hadoop::format']
    Class['hadoop::common::hdfs::config'] -> Class['hadoop::format']
  }
}
