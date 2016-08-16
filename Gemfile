source ENV['GEM_SOURCE'] || "https://rubygems.org"

group :test do
  gem "rake", '< 11'
  gem "puppet", ENV['PUPPET_GEM_VERSION'] || '~> 3.8.0'
  gem "rspec", '< 3.2.0'
  gem "rspec-puppet", :git => 'https://github.com/rodjek/rspec-puppet.git'
  gem "puppetlabs_spec_helper"
  gem "metadata-json-lint"
  gem "rspec-puppet-facts"
  gem 'simplecov', '>= 0.11.0'
  gem 'simplecov-console'
  # >= 2.0.1 hard requires ruby >= 2.0
  gem 'json', '< 2.0.0'
  # >= 2.0.1 hard requires ruby >= 2.0
  gem 'json_pure', '< 2.0.0'
  # >= 3.1 hard requires newest ruby
  gem 'listen', '< 3.1'

  gem "puppet-lint-absolute_classname-check"
  gem "puppet-lint-leading_zero-check"
  gem "puppet-lint-trailing_comma-check"
  gem "puppet-lint-version_comparison-check"
  gem "puppet-lint-classes_and_types_beginning_with_digits-check"
  gem "puppet-lint-unquoted_string-check"
end

group :development do
  gem "travis"
  gem "travis-lint"
  gem "puppet-blacksmith"
  gem "guard-rake"
end
