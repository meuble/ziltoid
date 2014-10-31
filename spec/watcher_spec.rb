#encoding: utf-8

require File.join(File.dirname(__FILE__), 'spec_helpers')

class MockLogger < Logger; end

describe Ziltoid::Watcher do
  describe "#logger" do
    it "should have a logger" do
      w = Ziltoid::Watcher.new
      expect(w).to respond_to(:logger)
    end

    it "should have ruby logger as default logger" do
      w = Ziltoid::Watcher.new
      expect(w.logger).to be_kind_of(Logger)
    end

    it "should accept different loggers" do
      w = Ziltoid::Watcher.new(:logger => MockLogger.new($stdout))
      expect(w.logger).to be_kind_of(MockLogger)
    end

    it "should set the logger progname" do
      w = Ziltoid::Watcher.new(:progname => "Test Ziltoid")
      expect(w.logger.progname).to eq("Test Ziltoid")
    end

    it "should set the log level" do
      w = Ziltoid::Watcher.new(:log_level => Logger::WARN)
      expect(w.logger.level).to eq(Logger::WARN)
    end
  end
end