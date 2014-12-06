# == Define hadoop::kinit
#
# Init credentials. To be called before any hadoop::mkdir() resource type.
#
# === Requirements
#
# * User['hdfs']
#
define hadoop::kinit($touchfile) {
  $env = [ 'KRB5CCNAME=FILE:/tmp/krb5cc_nn_puppet' ]
  $path = '/sbin:/usr/sbin:/bin:/usr/bin'
  $puppetfile = "/var/lib/hadoop-hdfs/.puppet-${touchfile}"

  # better to destroy the ticket (it may be owned by root),
  # destroy it only when needed though
  exec { "kdestroy-old-${touchfile}":
    command     => 'kdestroy',
    path        => $path,
    environment => $env,
    onlyif      => "test -n \"${realm}\"",
    creates     => $puppetfile,
  }
  ->
  exec { "kinit-$touchfile":
    command     => "kinit -k nn/${::fqdn}@${realm} -t /etc/security/keytab/nn.service.keytab",
    path        => $path,
    environment => $env,
    onlyif      => "test -n \"${realm}\"",
    user        => 'hdfs',
    creates     => $puppetfile,
  }
}
