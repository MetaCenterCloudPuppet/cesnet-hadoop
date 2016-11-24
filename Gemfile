source ENV['GEM_SOURCE'] || "https://rubygems.org"

group :test do
  gem "rake", '< 11'
  gem "puppet", ENV['PUPPET_GEM_VERSION'] || '~> 3.8.0'
  gem "rspec", '< 3.2.0'
  gem "rspec-puppet"
  gem "puppetlabs_spec_helper"
  gem "metadata-json-lint"
  gem "rspec-puppet-facts"
  gem 'simplecov', '>= 0.11.0'
  gem 'simplecov-console'

  gem "puppet-lint-absolute_classname-check"
  gem "puppet-lint-leading_zero-check"
  gem "puppet-lint-trailing_comma-check"
  gem "puppet-lint-version_comparison-check"
  gem "puppet-lint-classes_and_types_beginning_with_digits-check"
  gem "puppet-lint-unquoted_string-check"
  gem 'puppet-lint-resource_reference_syntax'

  # >= 2.0.1 hard requires ruby >= 2.0
  gem 'json', '< 2.0.0'
  # >= 2.0.1 hard requires ruby >= 2.0
  gem 'json_pure', '< 2.0.0'
  # >= 3.1 hard requires newest ruby
  gem 'listen', '< 3.1'
end

group :development do
  gem "travis"              if RUBY_VERSION >= '2.1.0'
  gem "travis-lint"         if RUBY_VERSION >= '2.1.0'
  gem "puppet-blacksmith"
  gem "guard-rake"          if RUBY_VERSION >= '2.2.5' # per dependency https://rubygems.org/gems/ruby_dep
end
