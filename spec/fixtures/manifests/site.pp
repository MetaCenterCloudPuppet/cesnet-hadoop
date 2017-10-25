class { '::hadoop':
  hdfs_hostname  => $::fqdn,
  realm          => 'MONKEY_ISLANDS',
}
