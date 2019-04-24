# == Class hadoop::nfs::install
#
class hadoop::nfs::install {
  include ::stdlib
  contain hadoop::common::install
  contain hadoop::common::postinstall

  ensure_packages($hadoop::packages_system_nfs)
  ensure_packages($hadoop::packages_nfs)
  Package[$hadoop::packages_nfs] -> Class['hadoop::common::postinstall']

  # the startup script issue hack
  if "${::hadoop::version}." =~ /^3(\.)?/ {
    $daemon = $hadoop::daemons['nfs']
    $path = '/sbin:/usr/sbin:/bin:/usr/bin'

    Package[$hadoop::packages_nfs]
    ->
    exec { "patch ${daemon} PIDFILE":
      command => "sed -e 's/^\\(\\s*\\)\\(export PIDFILE\\s*=\\)/\\1#puppet cesnet-hadoop:\\2/' -i /etc/init.d/${daemon}",
      path    => $path,
      onlyif  => "test -f /etc/init.d/${daemon} && grep -q '^\\s*export PIDFILE\\s*=' /etc/init.d/${daemon}",
    }

    Package[$hadoop::packages_nfs]
    ->
    exec { "patch ${daemon} HADOOP_IDENT_STRING":
      command => "sed -e 's/^\\(\\s*\\)\\(export HADOOP_IDENT_STRING\\s*=\\)/\\1#puppet cesnet-hadoop:\\2/' -i /etc/init.d/${daemon}",
      path    => $path,
      onlyif  => "test -f /etc/init.d/${daemon} && grep -q '^\\s*export HADOOP_IDENT_STRING\\s*=' /etc/init.d/${daemon}",
    }
  }
}
