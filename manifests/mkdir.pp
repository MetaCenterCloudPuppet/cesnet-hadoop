# == Define hadoop::mkdir
#
# Creates a directory on HDFS. Skip everything, if a $touchfile exists.
#
# === Parameters
#
# [*(title)*]
#   The name of the directory is in the title of the resource instance.
#
# [*touchfile*] (required)
# [*owner*] = undef
# [*group*] = undef
# [*mode*] = undef
#
# === Requirement
#
# * working HDFS
# * configured local HDFS client
# * User['hdfs']
#
define hadoop::mkdir($touchfile, $owner = undef, $group = undef, $mode = undef, $recursive = false) {
  include ::hadoop::common::hdfs::config

  $dir = $title
  $env = [ "KRB5CCNAME=FILE:/tmp/krb5cc_nn_puppet_${touchfile}" ]
  $path = '/sbin:/usr/sbin:/bin:/usr/bin'
  $puppetfile = "/var/lib/hadoop-hdfs/.puppet-${touchfile}"

  if ($recursive) {
    $chown_args=' -R'
  } else {
    $chown_args=''
  }

  if $hadoop::zookeeper_deployed {
    # directory
    exec { "hadoop-dir:${dir}":
      command     => "hdfs dfs -mkdir -p ${dir}",
      path        => $path,
      environment => $env,
      unless      => "hdfs dfs -test -d ${dir}",
      user        => 'hdfs',
      creates     => $puppetfile,
      require     => File['hdfs-site.xml'],
    }

    # ownership
    if $owner and $owner != '' or $group and $group != '' {
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
    if $mode and $mode != '' {
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
}
