Gem::Specification.new do |s|
  s.name        = 'ziltoid'
  s.version     = '1.0.2'
  s.date        = '2018-08-06'
  s.summary     = "Ziltoid, crontab based monitoring system"
  s.description = <<EOF
  There are many software applications that aim to watch processes, and keep them alive and clean. Some of them are well known: god, monit, bluepill.
  All have good and bad sides. One of the bad sides is that each alternative is based on a deamon that computes data and then sleeps for a while. Who is monitoring this particular deamon ? What if this process suddenly stops ? Also, you often need root rights to run those tools. On some hosting environments (mainly in shared hosting), this is an issue.

  Ziltoid is an attempt to solve those issues using the crontab system, which comes with many good sides :
 - it's on every system
 - it launches a task periodically then waits for an amount of time
 - it doesn't need monitoring
 - it can send emails to warn of an error
 - and it can run any script.
EOF

  s.authors     = ["Stéphane Akkaoui", "Vincent Gabou"]
  s.email       = ['sakkaoui@gmail.com', "vincent.gabou@gmail.com>"]
  s.files       =  Dir.glob(File.join("lib", "**", "*.rb"))
  s.homepage    = 'https://github.com/meuble/ziltoid'
  s.license     = 'WTFPL'
  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/meuble/ziltoid/issues",
    "homepage_uri"      => "https://github.com/meuble/ziltoid",
    "source_code_uri"   => "https://github.com/meuble/ziltoid"
  }
  s.add_runtime_dependency 'pony', "~> 1.11"
end