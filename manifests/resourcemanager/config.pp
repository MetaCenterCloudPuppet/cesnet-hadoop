# == Class hadoop::resourcemanager::config
#
class hadoop::resourcemanager::config {
  contain hadoop::common::config
  contain hadoop::common::hdfs::config
  contain hadoop::common::mapred::config
  contain hadoop::common::yarn::config
  contain hadoop::common::yarn::daemon

  if $hadoop::realm and $hadoop::realm != '' {
    file { $hadoop::keytab_resourcemanager:
      owner => 'yarn',
      group => 'yarn',
      mode  => '0400',
      alias => 'rm.service.keytab',
    }
  }

  if $hadoop::features["restarts"] {
    $cron_ensure = 'present'
  } else {
    $cron_ensure = 'absent'
  }
  file { '/etc/cron.d/hadoop-resourcemanager-restarts':
    ensure  => $cron_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    alias   => 'rm-cron',
    content => template('hadoop/cron-resourcemanager.erb'),
  }
}
