# == Class: hadoop::common::config
#
# Setup the part common for all nodes - core-site.xml.
#
class hadoop::common::config {
  file { "${hadoop::confdir}/core-site.xml":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    alias   => 'core-site.xml',
    content => template('hadoop/hadoop/core-site.xml.erb'),
  }

  # common environment:
  # - required when environments were specified
  # - required in Debian
  # - not needed in RedHat
  if $hadoop::environments {
    $ensure_env = present
  } else {
    $ensure_env = $::osfamily ? {
      redhat => absent,
      default => present,
    }
  }
  $environments = $hadoop::environments
  file { $hadoop::envs['common']:
    ensure  => $ensure_env,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('hadoop/env/common.erb'),
  }

  if $hadoop::authorization {
    file { "${hadoop::confdir}/hadoop-policy.xml":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      alias   => 'hadoop-policy.xml',
      content => template('hadoop/hadoop/hadoop-policy.xml.erb'),
    }
  }

  if ($hadoop::features["yellowmanager"]) {
    file { '/usr/local/sbin/yellowmanager':
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      alias   => 'yellowmanager',
      content => template('hadoop/yellowmanager.erb'),
    }
  }

  if $hadoop::https {
    $keypass = $hadoop::https_keystore_keypassword
    if $hadoop::acl {
      $ssl_perms = '0640'
    } else {
      $ssl_perms = '0644'
    }
    file { "${hadoop::confdir}/ssl-server.xml":
      owner   => 'root',
      group   => 'hadoop',
      mode    => $ssl_perms,
      content => template('hadoop/hadoop/ssl-server.xml.erb'),
    }
    file { "${hadoop::confdir}/ssl-client.xml":
      owner   => 'root',
      group   => 'hadoop',
      mode    => $ssl_perms,
      content => template('hadoop/hadoop/ssl-client.xml.erb'),
    }
    file { $hadoop::https_cacerts:
      owner => 'root',
      group => 'root',
      mode  => '0644',
    }
  }
}
