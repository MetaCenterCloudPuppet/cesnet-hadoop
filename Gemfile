source ENV['GEM_SOURCE'] || "https://rubygems.org"

group :test do
  if RUBY_VERSION >= '2.2'
    gem "rake"
  else
    gem "rake", '< 13'
  end
  gem "puppet", ENV['PUPPET_GEM_VERSION'] || '~> 3.8.0'
  gem "rspec"
  gem 'metadata-json-lint'
  if RUBY_VERSION >= '2.4'
    gem 'rspec-puppet'
    gem 'rspec-puppet-facts'
    gem 'simplecov', '>= 0.11.0'
    gem 'simplecov-console'
  else
    gem 'rspec-puppet', '<= 2.10.0'
    gem 'rspec-puppet-facts', '< 2.0.0'
    gem 'simplecov', '>= 0.11.0', '< 0.18'
    gem 'simplecov-console', '< 0.18'
    gem 'simplecov-html', '< 0.11'
  end

  # troubles with "top-scope variable" problem in puppet-lint afte 2.3.6
  gem "puppet-lint", '< 2.4.0'
  gem "puppet-lint-absolute_classname-check"
  gem "puppet-lint-leading_zero-check"
  gem "puppet-lint-trailing_comma-check"
  gem "puppet-lint-version_comparison-check"
  gem "puppet-lint-classes_and_types_beginning_with_digits-check"
  gem 'puppet-lint-resource_reference_syntax'
  if RUBY_VERSION < '2.4'
    gem 'puppet-lint-unquoted_string-check', '< 2.0.0'
  else
    gem 'puppet-lint-unquoted_string-check'
  end

  if RUBY_VERSION < '2.6'
    gem 'pathspec', '< 1.0.0'
  end
  if RUBY_VERSION < '2.5'
    gem 'activesupport', '< 6.0.0' if RUBY_VERSION >= '2.2'
    gem 'docile', '< 1.4.0'
  end
  if RUBY_VERSION < '2.3'
    gem 'faraday', '< 1.0.0'
    gem 'ffi', '< 1.13.0' if RUBY_VERSION >= '2.0.0'
    gem 'i18n', '< 1.5.2'
    gem 'public_suffix', '<= 3.0.3'
  end
  if RUBY_VERSION < '2.2'
    gem 'activesupport', '< 5.0.0'
    gem 'listen', '< 3.1'
    gem 'minitest', '< 5.12.0'
    gem 'puppetlabs_spec_helper', '< 2.16.0' # 3.0.0 incompatible with ruby 2.1, 2.16.0 Lua compatibility bug
    gem 'rb-inotify', '< 0.10'
    gem 'json', '< 2.5.0' if RUBY_VERSION >= '2.0.0'
    gem 'json_pure', '< 2.5.0' if RUBY_VERSION >= '2.0.0'
  else
    gem 'puppetlabs_spec_helper'
  end
end
