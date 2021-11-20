# == Class hadoop::datanode::install
#
class hadoop::datanode::install {
  include ::stdlib
  contain hadoop::common::install
  contain hadoop::common::postinstall

  ensure_packages($hadoop::packages_dn)
  Package[$hadoop::packages_dn] -> Class['hadoop::common::postinstall']

  # workaround for BIGTOP-3603
  if $::osfamily == 'Debian' and "${::hadoop::version}/" =~ /^3(\.)?/ {
    $daemon = $hadoop::daemons['datanode']
    file { "/etc/init.d/${daemon}":
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => 'puppet:///modules/hadoop/hadoop-hdfs-datanode',
    }
  }
}
