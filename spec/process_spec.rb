#encoding: utf-8

require File.join(File.dirname(__FILE__), 'spec_helpers')

describe Ziltoid::Process do
  describe "#initialisation" do
    describe "commands" do
      before :each do
        @process = Ziltoid::Process.new("dummy process", {
          :commands => {
            :start => "/etc/init.d/script start",
            :stop => "/etc/init.d/script stop",
            :restart => "/etc/init.d/script restart"
          }
        })
      end

      it "should set start command" do
        expect(@process.start_command).to eq("/etc/init.d/script start")
      end

      it "should set stop command" do
        expect(@process.stop_command).to eq("/etc/init.d/script stop")
      end

      it "should set restart command" do
        expect(@process.restart_command).to eq("/etc/init.d/script restart")
      end
    end

    describe "pid_file" do
      it "should set the pid_file" do
        proc = Ziltoid::Process.new("dummy process", {:pid_file => "/tmp/pids/script.pid"})
        expect(proc.pid_file).to eq("/tmp/pids/script.pid")
      end
    end

    describe "limits" do
      it "should set ram limit" do
        proc = Ziltoid::Process.new("dummy process", {:limit => {:ram => 300}})
        expect(proc.ram_limit).to eq(300)
      end

      it "should set cpu limit" do
        proc = Ziltoid::Process.new("dummy process", {:limit => {:cpu => 10}})
        expect(proc.cpu_limit).to eq(10)
      end
    end
  end

  describe "#pid" do
    it "should read the pid file and return the corresponding pid" do
      proc = Ziltoid::Process.new("dummy process", :pid_file => sample_pid_file_path)
      expect(proc.pid).to eq(12345)
    end

    it "should return nil if the pid_file doesn't exist" do
      proc = Ziltoid::Process.new("dummy process", :pid_file => "ouioui")
      expect(proc.pid).to be_nil
    end

    it "should return nil if the process has no pid_file" do
      proc = Ziltoid::Process.new("dummy process")
      expect(proc.pid).to be_nil
    end
  end

  describe "#remove_pid_file" do
    it "should return nil if the process has no pid_file" do
      proc = Ziltoid::Process.new("dummy process")
      expect(proc.remove_pid_file).to be_nil
    end

    it "should return nil if the pid_file does not exist" do
      proc = Ziltoid::Process.new("dummy process", :pid_file => "ouioui")
      expect(proc.remove_pid_file).to be_nil
    end

    it "should correctly remove the pid file" do
      file = open("sample_file.pid", 'w')
      file.write("1234")
      file.close
      expect(File.exist?("sample_file.pid")).to be true
      proc = Ziltoid::Process.new("dummy process", :pid_file => "sample_file.pid")
      proc.remove_pid_file
      expect(File.exist?("sample_file.pid")).to be false
    end
  end

  describe "#above_cpu_limit?(include_children = true)" do
    it "should not exceed the cpu limit" do
      proc = Ziltoid::Process.new("dummy process", :limit => {:cpu => 20}, :pid_file => sample_pid_file_path)
      expect(Ziltoid::System).to receive(:cpu_usage).and_return(10)
      expect(proc).not_to be_above_cpu_limit
    end

    it "should exceed the cpu limit" do
      proc = Ziltoid::Process.new("dummy process", :limit => {:cpu => 5}, :pid_file => sample_pid_file_path)
      expect(Ziltoid::System).to receive(:cpu_usage).and_return(10)
      expect(proc).to be_above_cpu_limit
    end
  end

  describe "#above_ram_limit?(include_children = true)" do
    it "should not exceed the ram limit" do
      proc = Ziltoid::Process.new("dummy process", :limit => {:ram => 200000}, :pid_file => sample_pid_file_path)
      expect(Ziltoid::System).to receive(:ram_usage).and_return(190000)
      expect(proc).not_to be_above_ram_limit
    end

    it "should exceed the ram limit" do
      proc = Ziltoid::Process.new("dummy process", :limit => {:ram => 200000}, :pid_file => sample_pid_file_path)
      expect(Ziltoid::System).to receive(:ram_usage).and_return(250000)
      expect(proc).to be_above_ram_limit
    end
  end

  context "when manipulating proccesses" do
    before :each do
      @process = Ziltoid::Process.new("dummy process", {
        :pid_file => sample_pid_file_path,
        :commands => {
          :start => "/etc/init.d/script start",
          :stop => "/etc/init.d/script stop",
          :restart => "/etc/init.d/script restart"
        }
      })
    end

    describe "#start" do
      it "should return nil if the process is already running" do
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(true)
        expect(@process.start).to be_nil
      end

      it "should launch the start command" do
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(false)
        expect(@process).to receive(:`).with(@process.start_command)
        @process.start
      end
    end

    describe "#stop" do
      it "should remove the pid file if the process is not running and return nil" do
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(false)
        expect(@process).to receive(:remove_pid_file)
        expect(@process.stop).to be_nil
      end

      it "should launch the start command" do
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(true)
        expect(@process).to receive(:`).with(@process.stop_command)
        @process.stop
      end
    end

  end
end