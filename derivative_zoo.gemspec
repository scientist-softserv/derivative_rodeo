# frozen_string_literal: true

require_relative 'lib/derivative_zoo/version'

Gem::Specification.new do |spec|
  spec.name          = 'derivative_zoo'
  spec.version       = DerivativeZoo::VERSION
  spec.authors       = ['Rob Kaufman', 'Jeremy Friesen']
  spec.email         = ['rob@notch8.com', 'jeremy.n.friesen@gmail.com']

  spec.summary = 'An ETL Ecosystem for Derivative Processing.'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/scientist-softserv/derivative_rodeo'
  spec.required_ruby_version = '>= 2.7.0'
  spec.licenses = ['APACHE-2.0']

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # NOTE: aws-sdk-s3 could be a rodeo plugin, but for now, it's part of the main show
  spec.add_dependency 'aws-sdk-s3'
  # NOTE: aws-sdk-sqs could be a rodeo plugin, but for now, it's part of the main show
  spec.add_dependency 'activesupport', '>= 5'
  spec.add_dependency 'aws-sdk-sqs'
  spec.add_dependency 'httparty'
  spec.add_dependency 'marcel'
  spec.add_dependency 'mime-types'
  spec.add_dependency 'mini_magick'
  spec.add_dependency 'nokogiri'

  spec.add_development_dependency 'bixby'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'hydra-file_characterization'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'solargraph'
end
