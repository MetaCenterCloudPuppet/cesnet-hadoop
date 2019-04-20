require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

include RspecPuppetFacts

require 'simplecov'
require 'simplecov-console'

SimpleCov.start do
  add_filter '/spec'
  add_filter '/vendor'
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ])
end

$test_os={
    :supported_os => [
        {
            'osfamily' => 'Debian',
            'operatingsystem' => 'Debian',
            'operatingsystemrelease' => ['7']
        }, {
            'osfamily' => 'RedHat',
            'operatingsystem' => 'Fedora',
            'operatingsystemrelease' => ['24']
        }, {
            'osfamily' => 'RedHat',
            'operatingsystem' => 'RedHat',
            'operatingsystemrelease' => ['6']
        }, {
            'osfamily' => 'RedHat',
            'operatingsystem' => 'CentOS',
            'operatingsystemrelease' => ['7']
        }, {
            'osfamily' => 'Debian',
            'operatingsystem' => 'Ubuntu',
            'operatingsystemrelease' => ['14.04']
        }
    ]
}

$test_config_dir={
  'CentOS' => '/etc/hadoop/conf',
  'Debian' => '/etc/hadoop/conf',
  'Fedora' => '/etc/hadoop',
  'RedHat' => '/etc/hadoop/conf',
  'Scientific' => '/etc/hadoop/conf',
  'Ubuntu' => '/etc/hadoop/conf',
}

$httpfs_config_dir={
  'CentOS' => '/etc/hadoop-httpfs/conf',
  'Debian' => '/etc/hadoop-httpfs/conf',
  'Fedora' => '/etc/hadoop',
  'RedHat' => '/etc/hadoop-httpfs/conf',
  'Scientific' => '/etc/hadoop-httpfs/conf',
  'Ubuntu' => '/etc/hadoop-httpfs/conf',
}

#
# For testing parameters originated from separated hadoop class
#
# There is *realm* parameter in site.pp file, which means the following keytab
# files must be used.
#
$keytabs={
  'hdfs_namenode' => '/etc/security/keytab/nn.service.keytab',
  'hdfs_datanode' => '/etc/security/keytab/dn.service.keytab',
  'hdfs_httpfs' => '/etc/security/keytab/httpfs-http.service.keytab',
  'hdfs_journalnode' => '/etc/security/keytab/jn.service.keytab',
  'hdfs_nfs' => '/etc/security/keytab/nfs.service.keytab',
  'mapred_historyserver' => '/etc/security/keytab/jhs.service.keytab',
  'yarn_nodemanager' => '/etc/security/keytab/nm.service.keytab',
  'yarn_resourcemanager' => '/etc/security/keytab/rm.service.keytab',
}
