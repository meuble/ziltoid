require_relative "../ziltoid"

Default logger is to $stdout, pass in a Logger instance (or Logger child class instance) to override it
watcher = Ziltoid.watcher.new(
  :logger => Logger.new(File.new('/tmp/ziltoid.log')),
  :progname => "Ziltoid Watcher",
  :log_level => Logger::DEBUG
)

watcher.notifier = EmailNotifier.new(
  :via_options => {
    :address        => 'smtp-out.bearstech.com',
    :port           => '25',
    :domain         => "banqyou.appliz.com"
  }
  :subject => "[#{APP_NAME}] #{self.process.name} - #{transition.to_name.to_s}"
  :to => ['stephane.akkaoui@sociabliz.com']
  :from => 'bluepill@epicbattle.appliz.com',
)

watcher.add(Ziltoid::Process.new("thin", {
  :pid_file => "/tmp/pids/thin.pid",
  :commands => {
    :start => "/home/ror/gem/bin/thin start -R config.ru -C /home/ror/http/thin_production.yml",
    :stop => "/home/ror/gem/bin/thin stop -R config.ru -C /home/ror/http/thin_production.yml"
  },
  :max_ram => "256",
  :max_cpu => "10"
}))
watcher.add(Ziltoid::Process.new("Lighty", {
  :pid_file => "/tmp/pids/lighty.pid",
  :commands {
    :start => "/home/ror/gem/bin/lighty start",
    :stop => "/home/ror/gem/bin/thin stop"
  },
  :max_ram => "256",
  :max_cpu => "5"
}))
watcher.add(Ziltoid::DiskUsage.new("Disk Usage", {
  :max => "80"
}))
watcher.add(Ziltoid::Load.new("Load", {
  :max => "3"
}))

watcher.watch!