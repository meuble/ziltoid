#encoding: utf-8

require File.join(File.dirname(__FILE__), '..', 'lib', 'watcher')
require File.join(File.dirname(__FILE__), '..', 'lib', 'process')
require File.join(File.dirname(__FILE__), '..', 'lib', 'system')

def sample_pid_file_path
  File.join(File.dirname(__FILE__), '..', 'spec', 'sample_pid_file.pid')
end