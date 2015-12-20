# with perform => true all services are installed and configured right away
class{'::hadoop':
  hdfs_hostname => $::fqdn,
  yarn_hostname => $::fqdn,
  slaves        => [ $::fqdn ],
  frontends     => [ $::fqdn ],
  realm         => '',
  properties    => {
    'dfs.replication' => 1,
  },
  perform       => true,
}
