require_relative "../ziltoid"

# Configure notifiers
notifiers = [
  Ziltoid::EmailNotifier.new(
    :via_options => {
      :address        => 'smtp.ziltoid.com',
      :port           => '25',
      :domain         => "ziltoid.com"
    },
    :subject => "[Balloonz] Ziltoid message",
    :to => ['developers@sociabliz.com'],
    :from => 'ziltoidd@ziltoid.com'
  )
]
# Create a watcher, with custom file logger and notifiers
watcher = Ziltoid::Watcher.new(
  :logger => Logger.new(File.new('/home/ror/site/prod/log/ziltoid.log', 'a+')),
  :progname => "Ziltoid Watcher",
  :log_level => Logger::DEBUG,
  :notifiers => notifiers
)

# add production processes
production_ports = [4567, 4568]
production_ports.each do |port|
  watcher.add(Ziltoid::Process.new("thin - production - #{port}", {
    :pid_file => "/home/ror/http/tmp/thin.#{port}.pid",
    :commands => {
      :start => "/home/ror/gem/bin/thin start -R config.ru -C /home/ror/http/thin_production.yml",
      :stop => "/home/ror/gem/bin/thin stop -R config.ru -C /home/ror/http/thin_production.yml"
    },
    :limit => {
      :ram => 256,
      :cpu => 10
    }
  }))
end

# add staging processes
watcher.add(Ziltoid::Process.new("thin - staging - 4565", {
  :pid_file => "/home/ror/http/tmp/thin.4565.pid",
  :commands => {
    :start => "RAILS_ENV=staging /home/ror/gem/bin/thin start -R config.ru -C /home/ror/http/thin_staging.yml",
    :stop => "RAILS_ENV=staging /home/ror/gem/bin/thin stop -R config.ru -C /home/ror/http/thin_staging.yml"
  },
  :limit => {
    :ram => 256,
    :cpu => 10
  }
}))

# add webserver process
watcher.add(Ziltoid::Process.new("Lighty", {
  :pid_file => "/home/ror/http/tmp/lighttpd.pid",
  :commands => {
    :start => "/home/ror/bin/lighty start",
    :stop => "/home/ror/bin/lighty stop"
  },
  :limit => {
    :ram => 256,
    :cpu => 10
  }
}))

# Begin the watch
watcher.watch!