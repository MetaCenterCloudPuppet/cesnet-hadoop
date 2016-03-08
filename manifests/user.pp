# == Define hadoop::user
#
# Create user account.
#
define hadoop::user(
  $touchfile,
  $shell,
  $hdfs,
  $groups = ['users'],
  $homedir = "/home/${title}",
  $realms = [],
) {
  $username = $title
  $usershell = $shell ? {
    true  => '/bin/bash',
    false => '/bin/false',
  }
  $principals = prefix($realms, "${username}@")

  group{$username:
    ensure => 'present',
  }
  ->
  user{$username:
    gid        => $username,
    groups     => $groups,
    managehome => $shell,
    shell      => $usershell,
  }

  if $shell and $realms and !empty($realms) {
    file{"${homedir}/.k5login":
      owner   => $username,
      group   => $username,
      mode    => '0644',
      content => join(suffix($principals, "\n"), ''),
      require => User[$username],
    }
  }

  if $hdfs {
    hadoop::mkdir{"/user/${username}":
      owner     => $username,
      group     => 'hadoop',
      mode      => '0750',
      touchfile => $touchfile,
    }
  }
}
