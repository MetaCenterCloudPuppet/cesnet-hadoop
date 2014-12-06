# == Class hadoop::common::postinstall
#
# Preparation steps after installation. It switches hadoop-conf alternative, if enabled.
#
class hadoop::common::postinstall {
  $confname = $hadoop::features['alternatives']
  $path = '/sbin:/usr/sbin:/bin:/usr/bin'
  $altcmd = $::osfamily ? {
    'Debian' => 'update-alternatives',
    'RedHat' => 'alternatives',
  }

  if $confname {
    exec { 'hadoop-copy-config':
      command => "cp -a ${hadoop::confdir}/ /etc/hadoop/conf.${confname}",
      path => $path,
      creates => "/etc/hadoop/conf.${confname}",
    }
    exec { 'hadoop-install-alternatives':
      command => "${altcmd} --install /etc/hadoop/conf hadoop-conf /etc/hadoop/conf.${confname} 50",
      path => $path,
      refreshonly => true,
      subscribe => Exec['hadoop-copy-config'],
    }
    exec { 'hadoop-set-alternatives':
      command => "${altcmd} --set hadoop-conf /etc/hadoop/conf.${confname}",
      path => $path,
      refreshonly => true,
      subscribe => Exec['hadoop-copy-config'],
    }
  }
}
