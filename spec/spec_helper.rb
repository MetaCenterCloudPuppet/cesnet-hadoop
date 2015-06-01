require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
include RspecPuppetFacts

$test_os=[{
    'osfamily' => 'Debian',
    'operatingsystem' => 'Debian',
    'operatingsystemrelease' => ['7']
  }, {
    'osfamily' => 'RedHat',
    'operatingsystem' => 'Fedora',
    'operatingsystemrelease' => ['21']
  }, {
    'osfamily' => 'RedHat',
    'operatingsystem' => 'RedHat',
    'operatingsystemrelease' => ['6']
  }, {
    'osfamily' => 'RedHat',
    'operatingsystem' => 'CentOS',
    'operatingsystemrelease' => ['6']
  }, {
    'osfamily' => 'Debian',
    'operatingsystem' => 'Ubuntu',
    'operatingsystemrelease' => ['14.04']
  }]

$test_config_dir={
  'CentOS' => '/etc/hadoop/conf',
  'Debian' => '/etc/hadoop/conf',
  'Fedora' => '/etc/hadoop',
  'RedHat' => '/etc/hadoop/conf',
  'Ubuntu' => '/etc/hadoop/conf',
}
