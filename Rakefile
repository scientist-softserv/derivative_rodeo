# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

desc 'Install commit hooks to ensure better practices'
task :install_hooks do
  require 'fileutils'
  Dir.glob('./git-hooks/*').each do |hook|
    next if File.file?("./.git/hooks/#{File.basename(hook)}")

    puts "Installing #{File.basename(hook)} git hook"
    FileUtils.cp(hook, './.git/hooks/')
  end
end

RSpec::Core::RakeTask.new(:spec)

desc 'Generate table of contents for README.md'
task :doctoc do
  if `which doctoc`.strip.empty?
    $stdout.puts 'Skipping doctoc generation; install via "npm install -g doctoc"'
  else
    $stdout.puts 'Generating table of contents for README.md'
    `doctoc README.md`
  end
end

task ci: %i[rubocop spec doctoc]

task default: %i[ci]
