ziltoid
=======

Cron based monitoring system.

There is out there many softwares that aim to watch process and keep them clean. Some of them are well known : 
 - god (http://godrb.com)
 - monit (http://mmonit.com/monit/)
 - bluepill (https://github.com/bluepill-rb/bluepill)
 - ... (https://www.ruby-toolbox.com/categories/server_monitoring)

All have good and bad sides.
One of the bad side is that each alternative is based on a deamon who does its work and then sleeps for a while. How does monitoring this deamon work ? What if this process suddenly stops ?
Also, you often need root right to run those tools. On some hosting environments (mainly in shared hosting), this is an issue.

Ziltoid is an attempt to solve those issues using the crontab system. It's on every system, it launches a task periodically then waits for an amount of time, it dosn't need monitoring, it can send emails to warn of a an error, and can run any script.
