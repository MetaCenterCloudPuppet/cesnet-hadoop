# == Class: hadoop::common::config
#
# Setup the part common for all nodes - core-site.xml.
#
class hadoop::common::config {
  file { '/etc/hadoop/core-site.xml':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    alias   => 'core-site.xml',
    content => template('hadoop/hadoop/core-site.xml.erb'),
  }

  if $hadoop::features["authorization"] {
    $rules = $hadoop::features["authorization"]
    file { '/etc/hadoop/hadoop-policy.xml':
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      alias  => 'hadoop-policy.xml',
      source => "puppet:///modules/hadoop/hadoop-policy.xml.${rules}",
    }
  }
}
