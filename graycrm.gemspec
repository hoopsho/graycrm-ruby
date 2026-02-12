# frozen_string_literal: true

require_relative "lib/graycrm/version"

Gem::Specification.new do |spec|
  spec.name = "graycrm"
  spec.version = GrayCRM::VERSION
  spec.authors = ["GrayCRM"]
  spec.email = ["support@graycrm.io"]

  spec.summary = "Ruby client for the GrayCRM API"
  spec.description = "Official Ruby client for GrayCRM — an API-first, AI-native CRM. Provides ActiveRecord-like syntax for contacts, properties, tags, flags, and more."
  spec.homepage = "https://github.com/hoopsho/graycrm-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*.rb", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  # Zero runtime dependencies — uses only Ruby stdlib (net/http, json, uri, openssl)

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webmock", "~> 3.0"
end
