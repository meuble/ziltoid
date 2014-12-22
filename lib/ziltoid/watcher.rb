require "logger"

module Ziltoid
  class Watcher
    attr_accessor :watchlist

    def logger
      Ziltoid::Watcher.logger
    end

    def self.logger
      @@logger
    end

    def notifiers
      Ziltoid::Watcher.notifiers
    end

    def self.notifiers
      @@notifiers ||= []
      return @@notifiers
    end

    def self.log(message, level = Logger::INFO)
      @@logger ||= Logger.new($stdout)
      @@logger.add(level, message)
      if level > Logger::INFO
        self.notifiers.each do |n|
          n.send(message)
        end
      end
    end

    def initialize(options = {})
      self.watchlist ||= {}
      @@logger = options[:logger] || Logger.new($stdout)
      @@logger.progname = options[:progname] || "Ziltoid"
      @@logger.level = options[:log_level] || Logger::INFO
      @@notifiers = options[:notifiers] if options[:notifiers]
    end

    def add(watchable)
      self.watchlist[watchable.name] = watchable
    end

    def run!(command = :watch)
      watchlist.values.each do |watchable|
        watchable.send("#{command}!".to_sym)
      end
    end

    def watch!
      Watcher.log("Ziltoid is now on duty : watching all watchables !")
      run!(:watch)
    end

    def start!
      Watcher.log("Ziltoid is now on duty : all watchables starting !")
      run!(:start)
    end

    def stop!
      Watcher.log("Ziltoid is now on duty : all watchables stoping !")
      run!(:stop)
    end

    def restart!
      Watcher.log("Ziltoid is now on duty : all watchables restarting !")
      run!(:restart)
    end

    def run(command = :watch)
      case command
      when :watch
        watch!
      when :start
        start!
      when :stop
        stop!
      when :restart
        restart!
      end
    end

  end
end