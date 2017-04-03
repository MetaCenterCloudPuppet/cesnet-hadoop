require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet/version'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'
require 'metadata-json-lint/rake_task'

if Puppet.version.to_f >= 4.9
  require 'semantic_puppet'
elsif Puppet.version.to_f >= 3.6 && Puppet.version.to_f < 4.9
  require 'puppet/vendor/semantic/lib/semantic'
end

# These gems aren't always present, for instance
# on Travis with --without development
begin
  require 'puppet_blacksmith/rake_tasks'
rescue LoadError
end

exclude_paths = [
  "bundle/**/*",
  "pkg/**/*",
  "vendor/**/*",
  "spec/**/*",
]

Rake::Task[:lint].clear

PuppetLint.configuration.relative = true
PuppetLint.configuration.disable_80chars
PuppetLint.configuration.disable_140chars
PuppetLint.configuration.disable_class_inherits_from_params_class
PuppetLint.configuration.disable_class_parameter_defaults
PuppetLint.configuration.fail_on_warnings = true
# false alarms
PuppetLint.configuration.disable_single_quote_string_with_variables
# this style leads to syntax errors (puppet < 3.7)
PuppetLint.configuration.disable_relative_classname_inclusion
# for bigger code chunks
PuppetLint.configuration.disable_arrow_on_right_operand_line

PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = exclude_paths
end

PuppetSyntax.exclude_paths = exclude_paths

desc "Populate CONTRIBUTORS file"
task :contributors do
  system("git log --format='%aN' | sort -u > CONTRIBUTORS")
end

desc "Run syntax, lint, and spec tests."
task :test => [
  :metadata_lint,
  :syntax,
  :lint,
  :spec,
]
