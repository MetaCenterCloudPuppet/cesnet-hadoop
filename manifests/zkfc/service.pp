# == Class hadoop::zkfc:service:
#
# This class is meant to be called from hadoop::zkfc.
# It ensures the service is running.
#
class hadoop::zkfc::service {
  service { $hadoop::daemons['hdfs-zkfc']:
    ensure    => 'running',
    enable    => true,
    subscribe => [File['core-site.xml'], File['hdfs-site.xml']],
  }

  # launch the format only once: on the first (main) namenode
  if $hadoop::zookeeper_hostnames and $hadoop::hdfs_hostname == $::fqdn {
    hadoop::kinit {'hdfs-zkfc-kinit':
      touchfile => 'hdfs-zkfc-formatted',
    }
    ->
    exec {'hdfs-zkfc-format':
      command => 'hdfs zkfc -formatZK',
      path    => '/sbin:/usr/sbin:/bin:/usr/bin',
      user    => 'hdfs',
      creates => '/var/lib/hadoop-hdfs/.puppet-hdfs-zkfc-formatted',
    }
    ->
    hadoop::kdestroy {'hdfs-zkfc-kdestroy':
      touchfile => 'hdfs-zkfc-formatted',
      touch     => true,
    }
    ->
    Service[$hadoop::daemons['hdfs-zkfc']]
  }
}
