# == Define hadoop::kdestroy
#
# Destroy credentials. To be called after any hadoop::kinit() resource type call.
#
# === Requirements
#
# * User['hdfs']
#
define hadoop::kdestroy($touchfile = $title, $touch = true) {
  $env = [ "KRB5CCNAME=FILE:/tmp/krb5cc_nn_puppet_${touchfile}" ]
  $path = '/sbin:/usr/sbin:/bin:/usr/bin'
  $puppetfile = "/var/lib/hadoop-hdfs/.puppet-${touchfile}"

  if $hadoop::zookeeper_deployed {
    if $hadoop::realm and $hadoop::realm != '' and $hadoop::_keytab_hdfs_admin and $hadoop::_principal_hdfs_admin {
      exec { "kdestroy-${touchfile}":
        command     => 'kdestroy || true',
        path        => $path,
        environment => $env,
        onlyif      => "test -n \"${hadoop::realm}\"",
        provider    => 'shell',
        user        => 'hdfs',
        creates     => $puppetfile,
      }
    }

    if $touch {
      exec { "hadoop-touch-${touchfile}":
        command     => "touch ${puppetfile}",
        path        => $path,
        environment => $env,
        user        => 'hdfs',
        creates     => $puppetfile,
      }
    }
  }
}
