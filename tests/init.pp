# this only configures this hadoop module,
# particular services need to be included in the nodes
class{'::hadoop':
  hdfs_hostname => $::fqdn,
  yarn_hostname => $::fqdn,
  slaves        => [ $::fqdn ],
  frontends     => [ $::fqdn ],
  realm         => '',
  properties    => {
    'dfs.replication' => 1,
  },
}
