# == Class hadoop::common::postinstall
#
# Preparation steps after installation. It switches hadoop-conf alternative, if enabled.
#
class hadoop::common::postinstall {
  $confname = $hadoop::alternatives
  $path = '/sbin:/usr/sbin:/bin:/usr/bin'

  if $confname and $confname != '' {
    exec { 'hadoop-copy-config':
      command => "cp -a ${hadoop::confdir}/ /etc/hadoop/conf.${confname}",
      path    => $path,
      creates => "/etc/hadoop/conf.${confname}",
    }
    ->
    alternative_entry{"/etc/hadoop/conf.${confname}":
      altlink  => '/etc/hadoop/conf',
      altname  => 'hadoop-conf',
      priority => 50,
    }
    ->
    alternatives{'hadoop-conf':
      path => "/etc/hadoop/conf.${confname}",
    }
  }
}
