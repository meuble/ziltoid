require "logger"

module Ziltoid
  class Watcher
    attr_accessor :logger

    def initialize(options = {})
      self.logger = options[:logger] || Logger.new($stdout)
      self.logger.progname = options[:progname] || "Ziltoid"
      self.logger.level = options[:log_level] || Logger::INFO
    end
  end
end