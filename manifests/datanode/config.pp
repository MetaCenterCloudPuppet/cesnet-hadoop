# == Class hadoop::datanode::config
#
class hadoop::datanode::config {
  contain hadoop::common::config
  contain hadoop::common::hdfs::config

  $keytab = '/etc/security/keytab/dn.service.keytab'
  $user = 'hdfs'
  $file = '/tmp/krb5cc_dn'
  $principal = "dn/${::fqdn}@${hadoop::realm}"

  if $hadoop::realm {
    file { $keytab:
      owner => 'hdfs',
      group => 'hdfs',
      mode  => '0400',
      alias => 'dn.service.keytab',
    }

    if $hadoop::features["krbrefresh"] {
      file { '/etc/cron.d/hadoop-datanode-krb5cc':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        alias   => 'dn-cron',
        content => template('hadoop/cron.erb'),
      }

      exec { 'dn-kinit':
        command     => "kinit -k -t ${keytab} ${principal}",
        user        => $user,
        path        => '/bin:/usr/bin',
        environment => [ "KRB5CCNAME=FILE:${file}" ],
        creates     => $file,
      }

      File[$keytab] -> Exec['dn-kinit']
    }
  }

  if $::osfamily == 'RedHat' and !$hadoop::features["krbrefresh"] {
    $env_ensure = 'absent'
  } else {
    $env_ensure = 'present'
  }
  file { $hadoop::envs['datanode']:
    ensure  => $env_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    alias   => 'dn-env',
    content => template('hadoop/env/hdfs-datanode.erb'),
  }
}
