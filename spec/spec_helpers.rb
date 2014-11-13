#encoding: utf-8

require File.join(File.dirname(__FILE__), '..', 'lib', 'watcher')
require File.join(File.dirname(__FILE__), '..', 'lib', 'process')
require File.join(File.dirname(__FILE__), '..', 'lib', 'system')

def sample_pid_file_path
  File.join(File.dirname(__FILE__), '..', 'spec', 'sample_pid_file.pid')
end

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
end