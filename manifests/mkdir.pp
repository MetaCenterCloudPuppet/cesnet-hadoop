# == Define hadoop::mkdir
#
# Creates a directory on HDFS. Skip everything, if a $touchfile exists. It is recommended the last hadoop::mkdir() call to have '$touch => true' parameter.
#
# === Parameters
#
# [*(title)*]
#   The name of the directory is in the title of the resource instance.
#
# [*owner*] = undef
# [*group*] = undef
# [*mode*] = undef
# [*touchfile*] (required)
#
# === Requirement
#
# * working HDFS
# * configured local HDFS client
# * User['hdfs']
#
define hadoop::mkdir($owner = undef, $group = undef, $mode = undef, $touchfile, $recursive = false) {
  $dir = $title
  $env = [ "KRB5CCNAME=FILE:/tmp/krb5cc_nn_puppet_${touchfile}" ]
  $path = '/sbin:/usr/sbin:/bin:/usr/bin'
  $puppetfile = "/var/lib/hadoop-hdfs/.puppet-${touchfile}"

  if ($recursive) {
    $chown_args=' -R'
  }

  # directory
  exec { "hadoop-dir:${dir}":
    command     => "hdfs dfs -mkdir -p ${dir}",
    path        => $path,
    environment => $env,
    unless      => "hdfs dfs -test -d ${dir}",
    user        => 'hdfs',
    creates     => $puppetfile,
  }

  # ownership
  if $owner or $group {
    exec { "hadoop-chown:${dir}":
      command     => "hdfs dfs -chown${chown_args} ${owner}:${group} ${dir}",
      path        => $path,
      environment => $env,
      user        => 'hdfs',
      creates     => $puppetfile,
    }
    Exec["hadoop-dir:${dir}"] -> Exec["hadoop-chown:${dir}"]
  }

  # mode
  if $mode {
    exec { "hadoop-chmod:${dir}":
      command     => "hdfs dfs -chmod ${mode} ${dir}",
      path        => $path,
      environment => $env,
      user        => 'hdfs',
      creates     => $puppetfile,
    }
    Exec["hadoop-dir:${dir}"] -> Exec["hadoop-chmod:${dir}"]
  }
}
