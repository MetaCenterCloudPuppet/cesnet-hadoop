# == Class: hadoop::common::yarn::config
#
# Setup the "yarn part" on the nodes. This class is used for example for historyserver, resourcemanager, nodemanagers or frontends.
#
class hadoop::common::yarn::config {
  include ::hadoop::common::install
  include ::hadoop::common::slaves

  if $hadoop::nodemanager_hostnames {
    $file_slaves = 'slaves-yarn'

    file { "${hadoop::confdir}/slaves-yarn":
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      alias   => 'slaves-yarn',
      content => template('hadoop/hadoop/slaves-yarn.erb'),
    }
  } else {
    $file_slaves = 'slaves'

    file { "${hadoop::confdir}/slaves-yarn":
      ensure  => absent,
    }
  }
  file { "${hadoop::confdir}/yarn-site.xml":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    alias   => 'yarn-site.xml',
    content => template('hadoop/hadoop/yarn-site.xml.erb'),
    require => [ Exec['touch-excludes'], File[$file_slaves] ],
  }

  # slaves needs Hadoop configuration directory
  Class['hadoop::common::install'] -> Class['hadoop::common::slaves']
}
