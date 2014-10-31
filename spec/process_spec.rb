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
end