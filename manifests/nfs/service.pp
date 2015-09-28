# == Class hadoop::nfs::service
#
# Start HDFS NFS Gateway service. Mount it locally, when the *hadoop::nfs_mount* parameter is non-empty.
#
# Namenode should be launched first if it is colocated with nfs
# (just cosmetics, some initial exceptions in logs)
#
# Dependencies works automatically, when collocated with HDFS namenode class. When not collocated, *hadoop::hdfs_deployed* parameter could be used for two-stage installation (not required).
#
class hadoop::nfs::service {
  # NFS server gateway requires working HDFS
  if $hadoop::hdfs_deployed {
    service { $hadoop::daemons['nfs']:
      ensure    => running,
      enable    => true,
      subscribe => [File['core-site.xml'], File['hdfs-site.xml']],
    }

    if $hadoop::daemons['portmap'] {
      service { $hadoop::daemons['portmap']:
        ensure => running,
        enable => true,
        before => Service[$hadoop::daemons['nfs']],
      }
    }

    # namenode should be launched first if it is colocated with nfs
    # (just cosmetics, some initial exceptions in logs)
    if $hadoop::daemon_namenode {
      include ::hadoop::namenode::service
      Class['hadoop::namenode::service'] -> Class['hadoop::nfs::service']
    }

    Service[$hadoop::daemons['nfs']] -> Hadoop::Nfs::Mount <| ensure == 'mounted' and nfs_hostname == $::fqdn |>

  } else {
    service { $hadoop::daemons['nfs']:
      ensure => 'stopped',
      enable => true,
    }
  }

  # always mount the NFS locally, if we have a mountpoint
  if $hadoop::nfs_mount and $hadoop::nfs_mount != '' {
    hadoop::nfs::mount { $hadoop::nfs_mount:
      ensure        => mounted,
      hdfs_deployed => $hadoop::hdfs_deployed,
    }
  }
}
