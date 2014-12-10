# == Class hadoop::journalnode::config
#
# Configure Hadoop Journal Node daemon. See also hadoop::journalnode.
#
class hadoop::journalnode::config {
  contain hadoop::common::config
  contain hadoop::common::hdfs::config
  contain hadoop::common::hdfs::daemon

  $keytab = '/etc/security/keytab/jn.service.keytab'
  $user = 'hdfs'
  $file = '/tmp/krb5cc_jn'
  $principal = "jn/${::fqdn}@${hadoop::realm}"

  if $hadoop::realm {
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

  if $::osfamily == 'RedHat' and !$hadoop::features["krbrefresh"] {
    $env_ensure = 'absent'
  } else {
    $env_ensure = 'present'
  }
  file { $hadoop::envs['journalnode']:
    ensure  => $env_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    alias   => 'jn-env',
    content => template('hadoop/env/hdfs-journalnode.erb'),
  }
}