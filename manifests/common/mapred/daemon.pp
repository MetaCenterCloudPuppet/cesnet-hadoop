# == Class hadoop::common::mapred::daemon
#
# Mapreduce specific setup. Called from historyserver classes.
#
class hadoop::common::mapred::daemon {
  if $hadoop::https {
    file { "${hadoop::mapred_homedir}/hadoop.keytab":
      owner  => 'mapred',
      group  => 'mapred',
      mode   => '0640',
      source => $hadoop::https_keytab,
    }
    file { "${hadoop::mapred_homedir}/http-auth-signature-secret":
      owner  => 'mapred',
      group  => 'mapred',
      mode   => '0640',
      source => '/etc/security/http-auth-signature-secret',
    }
    file { "${hadoop::mapred_homedir}/keystore.server":
      owner  => 'mapred',
      group  => 'mapred',
      mode   => '0640',
      source => $hadoop::https_keystore,
    }
  }
}
