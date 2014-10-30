ziltoid
=======

Cron based monitoring system.

There is out there many softwares that aim to watch process and keep them clean. Some of them are well knonw : 
 - god (http://godrb.com)
 - monit (http://mmonit.com/monit/)
 - bluepill (https://github.com/bluepill-rb/bluepill)
 - ... (https://www.ruby-toolbox.com/categories/server_monitoring)

All have good and bad sides.
One of the bad side is that each alternative is based on a deamon who do is work then sleep for a time. How is monitoring this deamon ? What if this process suddenly stop ?
Also, you often need root right to run those tools. On some hosting environments (mainly in shared hosting), this is an issue.

Ziltoid is an attempt to solve those issues using the crontab system. It's on every systems, it launch a task periodically then wait for an amount of time, it dosn't need monitoring, it can send mails to warn of a an error, and can run any script.
