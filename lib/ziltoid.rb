Dir.glob(File.join(File.dirname(__FILE__), 'ziltoid', '**')).each do |lib|
  require "#{lib}"
end