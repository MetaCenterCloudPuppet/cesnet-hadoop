# == Class hadoop::journalnode::config
#
# Configure Hadoop Journal Node daemon. See also hadoop::journalnode.
#
class hadoop::journalnode::config {
  include ::stdlib
  contain hadoop::common::config
  contain hadoop::common::hdfs::config
  contain hadoop::common::hdfs::daemon

  $keytab = $hadoop::keytab_journalnode
  $user = 'hdfs'
  $file = '/tmp/krb5cc_jn'
  $principal = "jn/${::fqdn}@${hadoop::realm}"
  # for templates in env/*
  $krbrefresh = $hadoop::features["krbrefresh"]

  # ensure proper owner and group
  # (better to enable sticky bit for more protection)
  ensure_resource('file', $hadoop::_hdfs_journal_dirs, {
    ensure => directory,
    owner  => 'hdfs',
    group  => 'hadoop',
    mode   => '1755',
  })

  if $hadoop::realm and $hadoop::realm != '' {
    file { $keytab:
      owner => 'hdfs',
      group => 'hdfs',
      mode  => '0400',
      alias => 'jn.service.keytab',
    }

    if $hadoop::features["krbrefresh"] {
      $cron_ensure = 'present'
    } else {
      $cron_ensure = 'absent'
    }
    file { '/etc/cron.d/hadoop-journalnode-krb5cc':
      ensure  => $cron_ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      alias   => 'jn-cron',
      content => template('hadoop/cron.erb'),
    }

    if $hadoop::features["krbrefresh"] {
      exec { 'jn-kinit':
        command     => "kinit -k -t ${keytab} ${principal}",
        user        => $user,
        path        => '/bin:/usr/bin',
        environment => [ "KRB5CCNAME=FILE:${file}" ],
        creates     => $file,
      }

      File[$keytab] -> Exec['jn-kinit']
    }
  }

  $env_journalnode = $hadoop::envs['journalnode']
  augeas{$env_journalnode:
    lens    => 'Shellvars.lns',
    incl    => $env_journalnode,
    changes => template('hadoop/env/hdfs-journalnode.augeas.erb'),
  }
  #notice(template('hadoop/env/hdfs-journalnode.augeas.erb'))
}
