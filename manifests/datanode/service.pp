# == Class hadoop::datanode::service
#
class hadoop::datanode::service {
  service { 'hadoop-datanode':
    ensure    => 'running',
    enable    => true,
    require   => [Exec['datanode-systemctl-daemon-reload']],
    subscribe => [File['core-site.xml'], File['hdfs-site.xml'], File['sysconfig-hadoop-datanode'], File['hadoop-datanode.service']],
  }
}
