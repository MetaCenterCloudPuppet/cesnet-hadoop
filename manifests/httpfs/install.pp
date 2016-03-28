# == Class hadoop::httpfs::install
#
class hadoop::httpfs::install {
  include ::stdlib
  contain hadoop::common::install

  ensure_packages($hadoop::packages_httpfs)

  ::hadoop_lib::postinstall{ 'hadoop-httpfs':
    alternatives => $::hadoop::alternatives_httpfs,
  }

  if $::hadoop::alternatives_ssl and $::hadoop::alternatives_ssl != '' {
    if $hadoop::https {
      $conf = '/etc/hadoop-httpfs/tomcat-conf.https'
    } else {
      $conf = '/etc/hadoop-httpfs/tomcat-conf.dist'
    }
    alternatives{$::hadoop::alternatives_ssl:
      path => $conf,
    }

    Package[$hadoop::packages_httpfs] -> Alternatives[$::hadoop::alternatives_ssl]
  }

  Package[$hadoop::packages_httpfs] -> ::Hadoop_lib::Postinstall['hadoop-httpfs']
}
