source ENV['GEM_SOURCE'] || "https://rubygems.org"

group :test do
  if RUBY_VERSION >= '2.2'
    gem "rake"
  elsif RUBY_VERSION >= '2.0'
    gem "rake", '< 13'
  else
    gem "rake", '< 12.3.0'
  end
  gem "puppet", ENV['PUPPET_GEM_VERSION'] || '~> 3.8.0'
  gem "rspec"
  gem "puppetlabs_spec_helper"
  if RUBY_VERSION < '2.0.0'
    gem 'metadata-json-lint', '< 1.2.0'
    gem 'rspec-puppet', '< 2.8.0'
  else
    gem 'metadata-json-lint'
    gem 'rspec-puppet'
  end
  if RUBY_VERSION >= '2.4'
    gem 'rspec-puppet-facts'
    gem 'simplecov', '>= 0.11.0'
    gem 'simplecov-console'
  else
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

  if RUBY_VERSION < '2.5'
    gem 'activesupport', '< 6.0.0' if RUBY_VERSION >= '2.2'
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
    gem 'rb-inotify', '< 0.10'
    gem 'json', '< 2.5.0' if RUBY_VERSION >= '2.0.0'
    gem 'json_pure', '< 2.5.0' if RUBY_VERSION >= '2.0.0'
  end
  if RUBY_VERSION < '2.0.0'
    gem 'ffi', '< 1.11.0'
    gem 'json', '< 2.0.0'
    gem 'json_pure', '< 2.0.0'
    gem 'json-schema', '< 2.5.0'
    gem 'parallel_tests', '<= 2.9.0'
  end
end

group :development do
  gem "travis"              if RUBY_VERSION >= '2.1.0'
  gem "travis-lint"         if RUBY_VERSION >= '2.1.0'
  gem "guard-rake"          if RUBY_VERSION >= '2.2.5' # per dependency https://rubygems.org/gems/ruby_dep
end
