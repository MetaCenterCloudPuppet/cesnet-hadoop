source ENV['GEM_SOURCE'] || "https://rubygems.org"

group :test do
  gem "rake", '< 11'
  gem "puppet", ENV['PUPPET_GEM_VERSION'] || '~> 3.8.0'
  gem "rspec"
  gem "rspec-puppet"
  gem "puppetlabs_spec_helper"
  if RUBY_VERSION < '2.0.0'
    gem 'metadata-json-lint', '< 1.2.0'
  else
    gem 'metadata-json-lint'
  end
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

  gem 'json', '< 2.0.0' if RUBY_VERSION < '2.0.0'
  gem 'json_pure', '< 2.0.0' if RUBY_VERSION < '2.0.0'
  gem 'json-schema', '< 2.5.0' if RUBY_VERSION < '2.0.0'
  gem 'listen', '< 3.1' if RUBY_VERSION < '2.2'
  gem 'parallel_tests', '<= 2.9.0' if RUBY_VERSION < '2.0.0'
end

group :development do
  gem "travis"              if RUBY_VERSION >= '2.1.0'
  gem "travis-lint"         if RUBY_VERSION >= '2.1.0'
  gem "puppet-blacksmith"
  gem "guard-rake"          if RUBY_VERSION >= '2.2.5' # per dependency https://rubygems.org/gems/ruby_dep
end
