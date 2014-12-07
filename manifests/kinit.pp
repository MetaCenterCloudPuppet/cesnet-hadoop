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

  if $hadoop::realm {
    # better to destroy the ticket (it may be owned by root),
    # destroy it only when needed though
    exec { "kdestroy-old-${touchfile}":
      command     => 'kdestroy',
      path        => $path,
      environment => $env,
      creates     => $puppetfile,
    }
    ->
    exec { "kinit-${touchfile}":
      command     => "kinit -k nn/${::fqdn}@${hadoop::realm} -t /etc/security/keytab/nn.service.keytab",
      path        => $path,
      environment => $env,
      user        => 'hdfs',
      creates     => $puppetfile,
    }
  }
}
