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

  describe "::notifiers" do
    it "should set notifiers" do
      w = Ziltoid::Watcher.new(:notifiers => ["toto"])
      expect(w.notifiers).to eq(["toto"])
    end

    it "should be singleton" do
      w = Ziltoid::Watcher.new(:notifiers => ["toto"])
      expect(Ziltoid::Watcher.new.notifiers).to eq(["toto"])
      expect(Ziltoid::Watcher.notifiers).to eq(["toto"])
    end
  end

  describe "#add" do
    it "should have a watchlist" do
      w = Ziltoid::Watcher.new
      expect(w).to respond_to(:watchlist)
    end

    it "should add watchable item to the watchlist" do
      w = Ziltoid::Watcher.new
      dummy_process = Ziltoid::Process.new('dummy process')
      w.add(dummy_process)
      expect(w.watchlist['dummy process']).to eq(dummy_process)
    end
  end

  describe "#watch!" do
    it "should sed watch to every watchables" do
      w = Ziltoid::Watcher.new
      5.times do |i| 
        p = Ziltoid::Process.new("dummy process #{i}")
        expect(p).to receive(:watch!).once()
        w.add(p)
      end
      w.watch!
    end
  end

  describe "::logger" do
    it "should be a singleton" do
      logger = Logger.new($stdout)
      Ziltoid::Watcher.new(:logger => logger)
      expect(Ziltoid::Watcher.logger).to eq(logger)
    end
  end

  describe "::log" do
    class NullLoger < Logger
      def initialize(*args)
      end

      def add(*args, &block)
      end
    end

    before :each do
      Ziltoid::Watcher.new(:logger => NullLoger.new)
    end

    it "should log message" do
      message = "log message"
      expect(Ziltoid::Watcher.logger).to receive(:add).with(anything, message)
      Ziltoid::Watcher.log(message)
    end

    it "should add with info default level" do
      message = "log message"
      expect(Ziltoid::Watcher.logger).to receive(:add).with(Logger::INFO, message)
      Ziltoid::Watcher.log(message)
    end

    it "should accept a log level" do
      message = "log message"
      expect(Ziltoid::Watcher.logger).to receive(:add).with(Logger::DEBUG, message)
      Ziltoid::Watcher.log(message, Logger::DEBUG)
    end

    it "should send message to notifiers if level is aboce info" do
      message = "log message"
      mock_notifier = double
      mock_notifier_2 = double
      expect(mock_notifier).to receive(:send).with(message)
      expect(mock_notifier_2).to receive(:send).with(message)
      w = Ziltoid::Watcher.new(:notifiers => [mock_notifier, mock_notifier_2])
      Ziltoid::Watcher.log(message, Logger::ERROR)
    end

    it "should not send message to notifiers if level is under info" do
      message = "log message"
      mock_notifier = double
      mock_notifier_2 = double
      expect(mock_notifier).not_to receive(:send).with(message)
      expect(mock_notifier_2).not_to receive(:send).with(message)
      w = Ziltoid::Watcher.new(:notifiers => [mock_notifier, mock_notifier_2])
      Ziltoid::Watcher.log(message, Logger::DEBUG)
    end
  end
end