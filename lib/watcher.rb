require "logger"

module Ziltoid
  class Watcher
    attr_accessor :logger, :watchlist

    def logger
      @@logger
    end

    def self.logger
      @@logger
    end

    def self.log(message, level = Logger::INFO)
      @@logger ||= Logger.new($stdout)
      @@logger.add(level, message)
    end

    def initialize(options = {})
      self.watchlist ||= {}
      @@logger = options[:logger] || Logger.new($stdout)
      @@logger.progname = options[:progname] || "Ziltoid"
      @@logger.level = options[:log_level] || Logger::INFO
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
  end
end