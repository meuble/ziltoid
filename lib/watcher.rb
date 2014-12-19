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

    def watch!
      Watcher.log("Ziltoid is on duty, begining the watch")
      watchlist.values.each do |watchable|
        watchable.watch!
      end
    end

    def run!(command = "watch")
      case command
      when "watch"
      when "start!"
      when "stop!"
      when "restart!"
      else
      end
    end

  end
end