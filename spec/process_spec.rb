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

  describe "#alive?" do
    it "should return true if pid is alive" do
      expect(Ziltoid::System).to receive(:pid_alive?).and_return(true)
      proc = Ziltoid::Process.new("dummy process", :pid_file => "sample_pid_file.pid")
      expect(proc.alive?).to be true
    end

    it "should return false if pid is not alive" do
      proc = Ziltoid::Process.new("dummy process", :pid_file => "sample_pid_file.fake.pid")
      expect(proc.alive?).to be false
    end

    it "should return false if process pid is nil" do
      proc = Ziltoid::Process.new("dummy process")
      expect(proc.alive?).to be false
    end
  end

  describe "#dead?" do
    it "should return false if pid is alive" do
      expect(Ziltoid::System).to receive(:pid_alive?).and_return(true)
      proc = Ziltoid::Process.new("dummy process", :pid_file => "sample_pid_file.pid")
      expect(proc.dead?).to be false
    end

    it "should return true if pid is not alive" do
      proc = Ziltoid::Process.new("dummy process", :pid_file => "sample_pid_file.fake.pid")
      expect(proc.dead?).to be true
    end

    it "should return true if process pid is nil" do
      proc = Ziltoid::Process.new("dummy process")
      expect(proc.dead?).to be true
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
      proc = Ziltoid::Process.new("dummy process", :limit => {:ram => 200}, :pid_file => sample_pid_file_path)
      expect(Ziltoid::System).to receive(:ram_usage).and_return(190000)
      expect(proc).not_to be_above_ram_limit
    end

    it "should exceed the ram limit" do
      proc = Ziltoid::Process.new("dummy process", :limit => {:ram => 200}, :pid_file => sample_pid_file_path)
      expect(Ziltoid::System).to receive(:ram_usage).and_return(250000)
      expect(proc).to be_above_ram_limit
    end
  end

  describe "#update_process_state(state)" do
    before :each do
      File.delete(sample_state_file_path) if File.exist?(sample_state_file_path)
      @watcher = Ziltoid::Watcher.new(:state_file => sample_state_file_path)
      @process = Ziltoid::Process.new("dummy process", {
        :commands => {
          :start => "/etc/init.d/script start",
          :stop => "/etc/init.d/script stop",
          :restart => "/etc/init.d/script restart"
        }
      })
    end

    it "should return nil when state is not allowed" do
      expect(@process.update_process_state("fake-state")).to be_nil
    end

    it "should write the state to the state file" do
      expect(Ziltoid::Watcher).to receive(:write_state).and_call_original
      @process.update_process_state("started")
    end

    it "should create a 'process name' entry in the state file if it does not exist" do
      time ||= Time.now
      allow(Time).to receive(:now).and_return(time)
      expect(Ziltoid::Watcher.read_state).not_to have_key(@process.name)
      @process.update_process_state("started")
      file = Ziltoid::Watcher.read_state
      expect(file).to have_key(@process.name)
      expect(file[@process.name]["state"]).to eq("started")
      expect(file[@process.name]["updated_at"]).to eq(time.to_i)
    end

    context "when updating with the same state" do
      it "should not update the updated_at key" do
        @process.update_process_state("started")
        updated_at = Ziltoid::Watcher.read_state[@process.name]["updated_at"]
        @process.update_process_state("started")
        expect(Ziltoid::Watcher.read_state[@process.name]["updated_at"]).to eq(updated_at)
      end
    end

    context "when updating with a different state" do
      it "should update the updated_at key" do
        @process.update_process_state("started")
        updated_at = Ziltoid::Watcher.read_state[@process.name]["updated_at"]
        sleep(2)
        @process.update_process_state("stopped")
        expect(Ziltoid::Watcher.read_state[@process.name]["updated_at"]).not_to eq(updated_at)
      end
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

    describe "#start!" do
      it "should return nil if the process is already running" do
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(true)
        expect(@process.start!).to be_nil
      end

      it "should remove the pid_file and launch the start command" do
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(false)
        expect(@process).to receive(:remove_pid_file)
        expect(@process).to receive(:`).with(@process.start_command)
        @process.start!
      end

      it "should log the action" do
        expect(Ziltoid::Watcher).to receive(:log).once
        allow(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(false)
        allow(@process).to receive(:remove_pid_file)
        allow(@process).to receive(:`).with(@process.start_command)
        @process.start!
      end
    end

    describe "#stop!" do
      it "should remove the pid file if the process is not running and return nil" do
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(false)
        expect(@process).to receive(:remove_pid_file)
        expect(@process.stop!).to be_nil
      end

      it "should send kill and kill-9 commands if there is no stop command" do
        proc = Ziltoid::Process.new("dummy process", {
          :pid_file => sample_pid_file_path,
          :commands => {
            :start => "/etc/init.d/script start",
            :restart => "/etc/init.d/script restart"
          }
        })

        allow(proc).to receive(:remove_pid_file)
        allow(proc).to receive(:`).with(anything())
        expect(proc).to receive(:`).with("kill 12345")
        expect(proc).to receive(:`).with("kill -9 12345")
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(true, true, true, true)
        proc.stop!
      end

      it "should launch the stop command" do
        allow(@process).to receive(:remove_pid_file)
        expect(@process).to receive(:`).with(@process.stop_command)
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(true, false, true)
        @process.stop!
      end

      it "should launch the stop command and the kill command if stop failed" do
        allow(@process).to receive(:remove_pid_file)
        allow(@process).to receive(:`).with(anything())
        expect(@process).to receive(:`).with(@process.stop_command)
        expect(@process).to receive(:`).with("kill 12345")
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(true, true, false, true)
        @process.stop!
      end

      it "should launch the stop command, the kill command AND the kill -9 if stop and kill failed" do
        allow(@process).to receive(:remove_pid_file)
        allow(@process).to receive(:`).with(anything())
        expect(@process).to receive(:`).with("kill 12345")
        expect(@process).to receive(:`).with("kill -9 12345")
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(true, true, true, true)
        @process.stop!
      end

      it "should remove the pid file if the process has been properly killed" do
        allow(@process).to receive(:remove_pid_file)
        allow(@process).to receive(:`).with(anything())
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(true, false, false)
        expect(@process).to receive(:remove_pid_file).once
        @process.stop!
      end

      it "should not remove the pid file at the end if the process has not been properly killed" do
        allow(@process).to receive(:`).with(anything())
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(true, false, true)
        expect(@process).not_to receive(:remove_pid_file)
        @process.stop!
      end

      it "should log the action" do
        expect(Ziltoid::Watcher).to receive(:log).once
        allow(@process).to receive(:`).with(anything())
        allow(Ziltoid::System).to receive(:pid_alive?).and_return(false)
        allow(@process).to receive(:remove_pid_file)
        @process.stop!
      end
    end

    describe "#restart!" do
      context "when the process has no pid" do
        let :process do
          Ziltoid::Process.new("dummy process", {
            :commands => {
              :start => "/etc/init.d/script start",
              :stop => "/etc/init.d/script stop",
              :restart => "/etc/init.d/script restart"
            }
          })
        end

        it "should start the process" do
          expect(process.pid).to be_nil
          expect(process).to receive(:start!)
          process.restart!
        end
      end

      context "when the process has a pid" do
        describe "with a dead pid" do
          before :each do
            expect(@process).to receive(:alive?).and_return(false)
          end

          it "should start the process" do
            expect(@process).to receive(:start!)
            @process.restart!
          end

          it "should clean the pid" do
            expect(@process).to receive(:`).with(@process.start_command)
            expect(@process).to receive(:remove_pid_file)
            @process.restart!
          end
        end

        describe "with an alive pid" do
          it "should stop and start the process if the process has no restart command" do
            proc = Ziltoid::Process.new("dummy process", {
              :pid_file => sample_pid_file_path,
              :commands => {
                :start => "/etc/init.d/script start",
                :stop => "/etc/init.d/script stop"
              }
            })

            expect(proc).to receive(:alive?).and_return(true)
            expect(proc).to receive(:stop!)
            expect(proc).to receive(:start!)
            proc.restart!
          end

          it "should send the restart_command if one is available" do
            expect(@process).to receive(:alive?).and_return(true)
            expect(@process).to receive(:`).with(@process.restart_command)
            @process.restart!
          end
        end
      end

      it "should log the action" do
        proc = Ziltoid::Process.new("dummy process", {
          :pid_file => sample_pid_file_path,
          :commands => {
            :start => "/etc/init.d/script start",
            :stop => "/etc/init.d/script stop"
          }
        })
        expect(Ziltoid::Watcher).to receive(:log)
        allow(proc).to receive(:alive?).and_return(false)
        allow(proc).to receive(:start!)
        proc.restart!
      end
    end

    describe "#watch" do
      context "when the process has no pid" do
        let :process do
          Ziltoid::Process.new("dummy process", {
            :commands => {
              :start => "/etc/init.d/script start",
              :stop => "/etc/init.d/script stop",
              :restart => "/etc/init.d/script restart"
            }
          })
        end

        it "should start the process" do
          expect(process.pid).to be_nil
          expect(process).to receive(:start!)
          process.watch!
        end
      end

      context "when the process has a pid" do
        describe "with a dead pid" do
          before :each do
            expect(@process).to receive(:alive?).and_return(false)
          end

          it "should start the process" do
            expect(@process).to receive(:start!)
            @process.watch!
          end

          it "should clean the pid" do
            expect(@process).to receive(:`).with(@process.start_command)
            expect(@process).to receive(:remove_pid_file)
            @process.watch!
          end
        end

        describe "with an alive pid" do
          it "should do nothing if ram and cpu are below limit" do
            expect(@process).to receive(:alive?).and_return(true)
            expect(@process).to receive(:above_cpu_limit?).and_return(false)
            expect(@process).to receive(:above_ram_limit?).and_return(false)
            expect(@process).not_to receive(:start!)
            expect(@process).not_to receive(:stop!)
            expect(@process).not_to receive(:restart!)
            @process.watch!
          end

          it "should restart if cpu is above limit" do
            expect(@process).to receive(:alive?).and_return(true)
            expect(@process).to receive(:above_cpu_limit?).and_return(true)
            expect(@process).to receive(:restart!)
            @process.watch!
          end

          it "should restart if ram is above limit" do
            expect(@process).to receive(:alive?).and_return(true)
            expect(@process).to receive(:above_cpu_limit?).and_return(false)
            expect(@process).to receive(:above_ram_limit?).and_return(true)
            expect(@process).to receive(:restart!)
            @process.watch!
          end

        end
      end

    end
  end
end