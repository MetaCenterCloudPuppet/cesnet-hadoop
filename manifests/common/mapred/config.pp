# == Class hadoop::common::mapred::config
#
# This class is called from hadoop.
#
class hadoop::common::mapred::config {
  file { '/etc/hadoop/mapred-site.xml':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    alias   => 'mapred-site.xml',
    content => template('hadoop/hadoop/mapred-site.xml.erb'),
  }
}
