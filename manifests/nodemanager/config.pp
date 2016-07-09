# == Class hadoop::nodemanager::config
#
class hadoop::nodemanager::config {
  contain hadoop::common::config
  contain hadoop::common::hdfs::config
  contain hadoop::common::mapred::config
  contain hadoop::common::yarn::config
  contain hadoop::common::yarn::daemon

  $keytab = $hadoop::keytab_nodemanager
  $user = 'yarn'
  $file = '/tmp/krb5cc_nm'
  $principal = "nm/${::fqdn}@${hadoop::realm}"
  # for templates in env/*
  $krbrefresh = $hadoop::features["krbrefresh"]

  if $hadoop::scratch_dir {
    file{$hadoop::scratch_dir:
      ensure => 'directory',
      mode   => '1777',
      owner  => 'yarn',
      group  => 'hadoop',
    }
  }

  if $hadoop::realm and $hadoop::realm != '' {
    file { $keytab:
      owner  => 'yarn',
      group  => 'yarn',
      mode   => '0400',
      alias  => 'nm.service.keytab',
      before => File['yarn-site.xml'],
    }

    if $hadoop::features["krbrefresh"] {
      $cron_ensure = 'present'
    } else {
      $cron_ensure = 'absent'
    }
    file { '/etc/cron.d/hadoop-nodemanager-krb5cc':
      ensure  => $cron_ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      alias   => 'nm-cron',
      content => template('hadoop/cron.erb'),
    }

    if $hadoop::features["krbrefresh"] {
      exec { 'nm-kinit':
        command     => "kinit -k -t ${keytab} ${principal}",
        user        => $user,
        path        => '/bin:/usr/bin',
        environment => [ "KRB5CCNAME=FILE:${file}" ],
        creates     => $file,
      }

      File[$keytab] -> Exec['nm-kinit']
    }
  }

  $env_nodemanager = $hadoop::envs['nodemanager']
  augeas{ $env_nodemanager:
    lens    => 'Shellvars.lns',
    incl    => $env_nodemanager,
    changes => template('hadoop/env/yarn-nodemanager.augeas.erb'),
  }
  #notice(template('hadoop/env/yarn-nodemanager.augeas.erb'))

  file { "${hadoop::confdir}/container-executor.cfg":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    alias   => 'container-executor.cfg',
    content => template('hadoop/hadoop/container-executor.cfg.erb'),
  }
}
