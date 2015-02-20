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

  describe "::logger" do
    it "should be a singleton" do
      logger = Logger.new($stdout)
      Ziltoid::Watcher.new(:logger => logger)
      expect(Ziltoid::Watcher.logger).to eq(logger)
    end
  end

  describe "::state_file" do
    it "should be a singleton" do
      Ziltoid::Watcher.new(:state_file => "some/path/to/state/file")
      expect(Ziltoid::Watcher.state_file).to eq("some/path/to/state/file")
    end
  end

  describe "#state_file" do
    it "should have a state_file" do
      w = Ziltoid::Watcher.new
      expect(w).to respond_to(:state_file)
    end

    it "should return the singleton state_file" do
      w = Ziltoid::Watcher.new(:state_file => "path")
      expect(w.state_file).to eq("path")
    end
  end

  describe "::read_state" do
    context "when the file does not exist" do
      it "should return {}" do
        expect(Ziltoid::Watcher.read_state).to eq({})
      end
    end

    context "when the file is empty" do
      it "should return {}" do
        w = Ziltoid::Watcher.new(:state_file => File.join(File.dirname(__FILE__), '..', 'spec', 'files', 'sample_empty_state_file.ziltoid'))
        expect(Ziltoid::Watcher.read_state).to eq({})
      end
    end

    context "when the file exists and is not empty" do
      it "should return the correct state as a ruby hash" do
        w = Ziltoid::Watcher.new(:state_file => File.join(File.dirname(__FILE__), '..', 'spec', 'files', 'sample_read_state_file.ziltoid'))
        expect(Ziltoid::Watcher.read_state).to eq({"lighty" => {"state" => "started", "updated_at" => 11111}})
      end
    end
  end

  describe "::write_state(state = {})" do
    before :each do
      @file = File.join(File.dirname(__FILE__), '..', 'spec', 'files', 'sample_write_state_file.ziltoid')
      File.delete(@file) if File.exist?(@file)
    end

    it "should create a state_file if it does not exist" do
      expect(File.exist?(@file)).to be false
      w = Ziltoid::Watcher.new(:state_file => @file)
      w.write_state({})
      expect(File.exist?(@file)).to be true
    end

    it "should write a JSONed version of the ziltoid state" do
      w = Ziltoid::Watcher.new(:state_file => @file)
      state = {"lighty" => {"state" => "started", "count" => 1, "updated_at" => 11111}}
      w.write_state(state)
      expect(File.read(@file)).to include(JSON.generate(state))
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

  describe "#run!(command = :watch)" do
    before :each do
      @w = Ziltoid::Watcher.new
    end

    it "should send watch! to every watchables" do
      5.times do |i|
        p = Ziltoid::Process.new("dummy process #{i}")
        expect(p).to receive(:watch!).once()
        @w.add(p)
      end
      @w.run!(:watch)
    end

    it "should send start! to every watchables" do
      5.times do |i|
        p = Ziltoid::Process.new("dummy process #{i}")
        expect(p).to receive(:start!).once()
        @w.add(p)
      end
      @w.run!(:start)
    end

    it "should send restart! to every watchables" do
      5.times do |i|
        p = Ziltoid::Process.new("dummy process #{i}")
        expect(p).to receive(:restart!).once()
        @w.add(p)
      end
      @w.run!(:restart)
    end

    it "should send start! to every watchables" do
      5.times do |i|
        p = Ziltoid::Process.new("dummy process #{i}")
        expect(p).to receive(:stop!).once()
        @w.add(p)
      end
      @w.run!(:stop)
    end

  end

  describe "#run(command = 'watch')" do
    before :each do
      @w = Ziltoid::Watcher.new
    end

    it "should send watch! method" do
      expect(@w).to receive(:watch!).once()
      @w.run(:watch)
    end

    it "should send start! method" do
      expect(@w).to receive(:start!).once()
      @w.run(:start)
    end

    it "should send stop! method" do
      expect(@w).to receive(:stop!).once()
      @w.run(:stop)
    end

    it "should send restart! method" do
      expect(@w).to receive(:restart!).once()
      @w.run(:restart)
    end
  end

  describe "#watch!" do
    before :each do
      @w = Ziltoid::Watcher.new
    end

    it "should proxy run!(:watch)" do
      expect(@w).to receive(:run!).once().with(:watch)
      @w.watch!
    end
  end

  describe "#start!" do
    before :each do
      @w = Ziltoid::Watcher.new
    end

    it "should proxy run!(:start)" do
      expect(@w).to receive(:run!).once().with(:start)
      @w.start!
    end
  end

  describe "#stop!" do
    before :each do
      @w = Ziltoid::Watcher.new
    end

    it "should proxy run!(:stop)" do
      expect(@w).to receive(:run!).once().with(:stop)
      @w.stop!
    end
  end

  describe "#restart!" do
    before :each do
      @w = Ziltoid::Watcher.new
    end

    it "should proxy run!(:restart)" do
      expect(@w).to receive(:run!).once().with(:restart)
      @w.restart!
    end
  end
end