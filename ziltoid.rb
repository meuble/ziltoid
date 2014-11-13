Dir["./lib/**"].each do |lib|
  require "#{lib}"
end