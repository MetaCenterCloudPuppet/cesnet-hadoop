class { '::hadoop':
  hdfs_hostname  => $::fqdn,
  yarn_hostname  => $::fqdn,
  realm          => 'MONKEY_ISLANDS',
}
