require "logger"

module Ziltoid
  class Watcher
    attr_accessor :logger, :watchlist

    def initialize(options = {})
      self.watchlist ||= {}
      self.logger = options[:logger] || Logger.new($stdout)
      self.logger.progname = options[:progname] || "Ziltoid"
      self.logger.level = options[:log_level] || Logger::INFO
    end

    def add(watchable)
      self.watchlist[watchable.name] = watchable
    end
  end
end