# == Class hadoop::datanode::config
#
class hadoop::datanode::config {
  contain hadoop::common::config
  contain hadoop::common::hdfs::config

  if $hadoop::realm {
    $keytab = '/etc/security/keytab/dn.service.keytab'

    file { $keytab:
      owner => 'hdfs',
      group => 'hdfs',
      mode  => '0400',
      alias => 'dn.service.keytab',
    }

    if $hadoop::features["krbrefresh"] {
      $user = 'hdfs'
      $file = '/tmp/krb5cc_dn'
      $principal = "dn/${::fqdn}@${hadoop::realm}"

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

      file { "/etc/sysconfig/hadoop-datanode":
        owner  => "root",
        group  => "root",
        alias  => "dn-env",
        source => "puppet:///modules/hadoop/hadoop-datanode",
      }
    }
  }
}
