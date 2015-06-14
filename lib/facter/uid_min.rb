Facter.add('uid_min') {
  setcode {
    if File.exist?('/etc/login.defs')
      value=File.open('/etc/login.defs') { |openfile|
        openfile.readlines.select { |line|
          line =~ /^\s*UID_MIN\s+(.*)/
        }.map { |line|
          line =~ /^\s*UID_MIN\s+(.*)/
          $1
        }
      }

      if !value.empty? and value[0].to_i > 0
        value[0].to_i
      end
    end
  }
}
