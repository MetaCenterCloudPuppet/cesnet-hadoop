# == Define hadoop::kdestroy
#
# Destroy credentials. To be called after any hadoop::kinit() resource type call.
#
# === Requirements
#
# * User['hdfs']
#
define hadoop::kdestroy($touchfile, $touch) {
  $env = [ 'KRB5CCNAME=FILE:/tmp/krb5cc_nn_puppet' ]
  $path = '/sbin:/usr/sbin:/bin:/usr/bin'
  $puppetfile = "/var/lib/hadoop-hdfs/.puppet-${touchfile}"

  exec { "kdestroy-${touchfile}":
    command     => 'kdestroy',
    path        => $path,
    environment => $env,
    onlyif      => "test -n \"${hadoop::realm}\"",
    user        => 'hdfs',
    creates     => $puppetfile,
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
