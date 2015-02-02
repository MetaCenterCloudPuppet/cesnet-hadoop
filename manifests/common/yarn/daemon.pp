# == Class hadoop::common::yarn::daemon
#
# YARN specific setup. Called from resourcemanager and nodemanager classes.
#
class hadoop::common::yarn::daemon {
  if $hadoop::https {
    file { "${hadoop::yarn_homedir}/hadoop.keytab":
      owner  => 'yarn',
      group  => 'yarn',
      mode   => '0640',
      source => $hadoop::https_keytab,
    }
    file { "${hadoop::yarn_homedir}/http-auth-signature-secret":
      owner  => 'yarn',
      group  => 'yarn',
      mode   => '0640',
      source => '/etc/security/http-auth-signature-secret',
    }
    file { "${hadoop::yarn_homedir}/keystore.server":
      owner  => 'yarn',
      group  => 'yarn',
      mode   => '0640',
      source => $hadoop::https_keystore,
    }
  }
}
