# == Class hadoop::nodemanager::config
#
class hadoop::nodemanager::config {
  contain hadoop::common::config
  contain hadoop::common::hdfs::config
  contain hadoop::common::mapred::config
  contain hadoop::common::yarn::config

  if $hadoop::daemon_nodemanager and $hadoop::realm {
    $keytab = '/etc/security/keytab/nm.service.keytab'

    file { $keytab:
      owner  => 'yarn',
      group  => 'yarn',
      mode   => '0400',
      alias  => 'nm.service.keytab',
      before => File['yarn-site.xml'],
    }

    if $hadoop::features["krbrefresh"] {
      $user = 'yarn'
      $file = '/tmp/krb5cc_nm'
      $principal = "nm/${::fqdn}@${hadoop::realm}"

      file { '/etc/cron.d/hadoop-nodemanager-krb5cc':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        alias   => 'nm-cron',
        content => template('hadoop/cron.erb'),
      }

      exec { 'nm-kinit':
        command     => "kinit -k -t ${keytab} ${principal}",
        user        => $user,
        path        => '/bin:/usr/bin',
        environment => [ "KRB5CCNAME=FILE:${file}" ],
        creates     => $file,
      }

      File[$keytab] -> Exec['nm-kinit']

      file { '/etc/sysconfig/hadoop-nodemanager':
        owner  => 'root',
        group  => 'root',
        alias  => 'nm-env',
        source => 'puppet:///modules/hadoop/hadoop-nodemanager',
      }
    }
  }

  file { '/etc/hadoop/container-executor.cfg':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    alias   => 'container-executor.cfg',
    content => template('hadoop/hadoop/container-executor.cfg.erb'),
  }

  # fix Fedora startup - launch under group yarn
  file { '/etc/systemd/system/hadoop-nodemanager.service':
    owner  => 'root',
    group  => 'root',
    alias  => 'hadoop-nodemanager.service',
    source => 'puppet:///modules/hadoop/hadoop-nodemanager.service',
  }
  ~>
  # fix Fedora startup - reload systemd after changes
  exec { 'nodemanager-systemctl-daemon-reload':
    command     => 'systemctl daemon-reload',
    path        => '/sbin:/usr/sbin:/bin:/usr/bin',
    refreshonly => true,
  }
}
