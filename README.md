<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [DerivativeZoo](#derivativezoo)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Interface](#interface)
  - [Supported Generators](#supported-generators)
  - [Supported Storage Adapters](#supported-storage-adapters)
  - [Development](#development)
  - [Contributing](#contributing)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# DerivativeZoo

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/derivative_zoo`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'derivative_zoo'
```

And then execute:

    $ bundle install

## Usage

TODO: Write usage instructions here

## Interface
Generators must have an initializer and build command
 -> new(array_of_file_urls, output_url_type, preprocessor url_type)
 -> generated_files (executes the generators actions) and returns array of files
 -> generated_uris (executes the generators actions) and returns array of output uris

## Supported Generators

- HorcGenerator - generated tesseract files from images, also creates monocrhome files as a prestep
- MonochromeGenerator - converts images to monochrome
- MoveGenerator - sends a set of uris to another location. For example from S3 to SQS or from filesystem to S3.

## Supported Storage Adapters

- file://
- s3://
- sqs://

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/derivative_zoo.
