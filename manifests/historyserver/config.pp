# == Class hadoop::historyserver::config
#
class hadoop::historyserver::config {
  contain hadoop::common::config
  contain hadoop::common::hdfs::config
  contain hadoop::common::mapred::config
  contain hadoop::common::yarn::config

  $keytab = '/etc/security/keytab/jhs.service.keytab'
  $user = 'mapred'
  $file = '/tmp/krb5cc_jhs'
  $principal = "jhs/${::fqdn}@${hadoop::realm}"

  if $hadoop::realm {
    file { $keytab:
      owner  => 'mapred',
      group  => 'mapred',
      mode   => '0400',
      alias  => 'jhs.service.keytab',
      before => File['mapred-site.xml'],
    }

    if $hadoop::features["krbrefresh"] {
      file { '/etc/cron.d/hadoop-historyserver-krb5cc':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        alias   => 'jhs-cron',
        content => template('hadoop/cron.erb'),
      }

      exec { 'jhs-kinit':
        command     => "kinit -k -t ${keytab} ${principal}",
        user        => $user,
        path        => '/bin:/usr/bin',
        environment => [ "KRB5CCNAME=FILE:${file}" ],
        creates     => $file,
      }

      File[$keytab] -> Exec['jhs-kinit']
    }
  }

  if $::osfamily == 'RedHat' and !$hadoop::features["krbrefresh"] {
    $env_ensure = 'absent'
  } else {
    $env_ensure = 'present'
  }
  file { $hadoop::envs['historyserver']:
    ensure => $env_ensure,
    owner  => 'root',
    group  => 'root',
    alias  => 'jhs-env',
    content => template('hadoop/env/mapred-historyserver.erb'),
  }
}
