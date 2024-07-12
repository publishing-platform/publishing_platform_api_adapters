# frozen_string_literal: true

require_relative "lib/publishing_platform_api/version"

Gem::Specification.new do |spec|
  spec.name = "publishing_platform_api_adapters"
  spec.version = PublishingPlatformApi::VERSION
  spec.authors = ["Publishing Platform"]

  spec.summary = "Adapters to work with Publishing Platform APIs"
  spec.description = "Adapters to work with Publishing Platform APIs"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir.glob("lib/**/*") + %w[README.md Rakefile]
  spec.require_paths = %w[lib]

  spec.add_dependency "addressable"
  spec.add_dependency "link_header"
  spec.add_dependency "null_logger"
  spec.add_dependency "publishing_platform_location"
  spec.add_dependency "rest-client", "~> 2.0"

  spec.add_development_dependency "publishing_platform_rubocop"
end
