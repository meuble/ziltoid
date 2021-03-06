#encoding: utf-8

require 'simplecov'

# Code coverage
SimpleCov.start do
  add_filter "/vendor/"
  add_filter "/spec/"
end

require File.join(File.dirname(__FILE__), '..', 'lib', 'ziltoid')

RSpec.configure do |config|
  config.mock_with :rspec
  config.expect_with :rspec
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.color = true

  # Force using expect and not should
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Silence logger output to $stdout
  config.before(:all) do 
    $stderr = StringIO.new
    $stdout = StringIO.new
  end

  config.after(:all) do
    file = File.join(File.dirname(__FILE__), 'files', 'sample_state_file.ziltoid')
    File.delete(file) if File.exist?(file)
  end
end

def sample_pid_file_path
  File.join(File.dirname(__FILE__), '..', 'spec', 'files', 'sample_pid_file.pid')
end

def sample_state_file_path
  File.join(File.dirname(__FILE__), '..', 'spec', 'files', 'sample_state_file.ziltoid')
end