# == Class hadoop::httpfs::config
#
class hadoop::httpfs::config {
  contain hadoop::common::config
  contain hadoop::common::hdfs::config

  $keytab = $hadoop::keytab_httpfs

  file { "${::hadoop::confdir_httpfs}/httpfs-site.xml":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('hadoop/hadoop/httpfs-site.xml.erb'),
  }

  if $hadoop::realm and $hadoop::realm != '' {
    file { $keytab:
      owner => 'httpfs',
      group => 'httpfs',
      mode  => '0400',
      alias => 'httpfs-hadoop.service.keytab',
    }
  }

  if $hadoop::https {
    file { "${::hadoop::httpfs_homedir}/.keystore":
      owner  => 'httpfs',
      group  => 'httpfs',
      mode   => '0400',
      source => $::hadoop::https_keystore,
    }

    file { "${hadoop::httpfs_homedir}/http-auth-signature-secret":
      owner  => 'httpfs',
      group  => 'httpfs',
      mode   => '0600',
      source => '/etc/security/http-auth-signature-secret',
    }
  }

  $env_file = "${::hadoop::confdir_httpfs}/httpfs-env.sh"
  if $hadoop::https {
    $environment = {
      'HTTPFS_SSL_ENABLED' => true,
      'HTTPFS_SSL_KEYSTORE_FILE' => '${HOME}/.keystore',
      'HTTPFS_SSL_KEYSTORE_PASS' => "'${::hadoop::https_keystore_password}'",
    }
  } else {
    $environment = {
      'HTTPFS_SSL_ENABLED' => false,
      'HTTPFS_SSL_KEYSTORE_FILE' => '::undef',
      'HTTPFS_SSL_KEYSTORE_PASS' => '::undef',
    }
  }
  file { $env_file:
    owner => 'httpfs',
    group => 'httpfs',
    mode  => '0600',
  }
  augeas { $env_file:
    incl    => $env_file,
    lens    => 'Shellvars.lns',
    changes => template('hadoop/env/common.augeas.erb'),
  }
}
