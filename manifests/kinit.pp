# == Define hadoop::kinit
#
# Initialize credentials. To be called before any hadoop::mkdir() and hadoop::user() resource type.
#
# === Requirements
#
# * User['hdfs']
#
define hadoop::kinit($touchfile = $title) {
  $env = [ "KRB5CCNAME=FILE:/tmp/krb5cc_nn_puppet_${touchfile}" ]
  $path = '/sbin:/usr/sbin:/bin:/usr/bin'
  $puppetfile = "/var/lib/hadoop-hdfs/.puppet-${touchfile}"

  if $hadoop::hdfs_hostname {
    include ::hadoop::common::hdfs::config
  }

  if $hadoop::realm and $hadoop::realm != '' and $hadoop::zookeeper_deployed and $hadoop::_keytab_hdfs_admin and $hadoop::_principal_hdfs_admin {
    # better to destroy the ticket (it may be owned by root),
    # destroy it only when needed though
    exec { "kdestroy-old-${touchfile}":
      command     => 'kdestroy || true',
      path        => $path,
      environment => $env,
      provider    => 'shell',
      creates     => $puppetfile,
    }
    ->
    exec { "kinit-${touchfile}":
      command     => "kinit -k -t ${hadoop::_keytab_hdfs_admin} ${hadoop::_principal_hdfs_admin}",
      path        => $path,
      environment => $env,
      user        => 'hdfs',
      creates     => $puppetfile,
      require     => File["${hadoop::confdir}/hdfs-site.xml"],
    }
  }
}
