# == Define hadoop::kinit
#
# Initialize credentials. To be called before any hadoop::mkdir() and hadoop::user() resource type.
#
# === Requirements
#
# * User['hdfs']
#
define hadoop::kinit($touchfile = $title) {
  include ::hadoop::common::hdfs::config

  $env = [ "KRB5CCNAME=FILE:/tmp/krb5cc_nn_puppet_${touchfile}" ]
  $path = '/sbin:/usr/sbin:/bin:/usr/bin'
  $puppetfile = "/var/lib/hadoop-hdfs/.puppet-${touchfile}"

  if $hadoop::realm and $hadoop::realm != '' and $hadoop::zookeeper_deployed {
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
      command     => "kinit -k -t ${hadoop::keytab_namenode} nn/${::fqdn}@${hadoop::realm}",
      path        => $path,
      environment => $env,
      user        => 'hdfs',
      creates     => $puppetfile,
      require     => File['hdfs-site.xml'],
    }
  }
}
