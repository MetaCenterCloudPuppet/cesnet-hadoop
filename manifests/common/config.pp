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

  if $hadoop::features["authorization"] {
    $rules = $hadoop::features["authorization"]
    file { "${hadoop::confdir}/hadoop-policy.xml":
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      alias  => 'hadoop-policy.xml',
      source => "puppet:///modules/hadoop/hadoop-policy.xml.${rules}",
    }
  }

  if ($hadoop::features["yellowmanager"]) {
    file { '/usr/local/sbin/yellowmanager':
      mode    => '0755',
      alias   => 'yellowmanager',
      content => template('hadoop/yellowmanager.erb'),
    }
  }
}
