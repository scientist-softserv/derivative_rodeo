# frozen_string_literal: true

require_relative 'lib/derivative_rodeo/version'

Gem::Specification.new do |spec|
  # Renaming to reflect that we previously registered 'derivative-rodeo' and Rubygems guards against
  # names that are close in resemblence.
  spec.name          = 'derivative-rodeo'
  spec.version       = DerivativeRodeo::VERSION
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
  # spec.files = Dir.chdir(__dir__) do
  #   `git ls-files -z`.split("\x0").reject do |f|
  #     (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
  #   end
  # end
  spec.files = Dir['lib/**/*'].keep_if { |file| File.file?(file) } + %w[Gemfile LICENSE README.md Rakefile derivative_rodeo.gemspec]
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 5'
  spec.add_dependency 'aws-sdk-s3'
  spec.add_dependency 'aws-sdk-sqs'
  spec.add_dependency 'httparty'
  spec.add_dependency 'marcel'
  spec.add_dependency 'mime-types'
  spec.add_dependency 'mini_magick'
  spec.add_dependency 'nokogiri'

  spec.add_development_dependency 'bixby'
  spec.add_development_dependency 'byebug'
  # spec.add_development_dependency 'hydra-file_characterization'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard-activerecord'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'solargraph'
  spec.add_development_dependency 'yard'
end
