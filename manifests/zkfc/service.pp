# == Class hadoop::zkfc:service:
#
# This class is meant to be called from hadoop::zkfc.
# It ensures the service is running.
#
class hadoop::zkfc::service {
  # zkfc requires working zookeeper first
  if $hadoop::zookeeper_deployed {
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
        # If the znode created by -formatZK already exists, and for
        # some buggy reason it happens to run, -formatZK will prompt
        # the user to confirm if the znode should be reformatted.
        # Puppet isn't able to answer this question on its own.
        # Default to answering with 'N' if the command asks.
        # This should never happen, but just in case it does,
        # We don't want this eternally unanswered prompt to fill up
        # puppet logs and disks.
        command => 'echo N | hdfs zkfc -formatZK',
        path    => '/sbin:/usr/sbin:/bin:/usr/bin',
        user    => 'hdfs',
        creates => '/var/lib/hadoop-hdfs/.puppet-hdfs-zkfc-formatted',
        # acceptable responses 0 = success, 2 = znode already exists
        returns => [ '0', '2', ],
      }
      ->
      hadoop::kdestroy {'hdfs-zkfc-kdestroy':
        touchfile => 'hdfs-zkfc-formatted',
        touch     => true,
      }
      ->
      Service[$hadoop::daemons['hdfs-zkfc']]

      Service[$hadoop::daemons['hdfs-zkfc']] -> Hadoop::Mkdir <| |>
    }
  }
}
