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
          },
          :grace_times => {
            :start => 30,
            :stop => 30,
            :restart => 30,
            :cpu => 30,
            :ram => 30
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

    describe "grace times" do
      it "should set start grace time" do
        proc = Ziltoid::Process.new("dummy process", {:grace_times => {:start => 60}})
        expect(proc.start_grace_time).to eq(60)
      end

      it "should set stop grace time" do
        proc = Ziltoid::Process.new("dummy process", {:grace_times => {:stop => 60}})
        expect(proc.stop_grace_time).to eq(60)
      end

      it "should set restart grace time" do
        proc = Ziltoid::Process.new("dummy process", {:grace_times => {:restart => 60}})
        expect(proc.restart_grace_time).to eq(60)
      end

      it "should set cpu grace time" do
        proc = Ziltoid::Process.new("dummy process", {:grace_times => {:cpu => 60}})
        expect(proc.cpu_grace_time).to eq(60)
      end

      it "should set ram grace time" do
        proc = Ziltoid::Process.new("dummy process", {:grace_times => {:ram => 60}})
        expect(proc.ram_grace_time).to eq(60)
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

  describe "#state" do
    before :each do
      File.delete(sample_state_file_path) if File.exist?(sample_state_file_path)
      watcher = Ziltoid::Watcher.new(:state_file => sample_state_file_path)
      @process = Ziltoid::Process.new("dummy process")
    end

    it "should return nil if process is not in the state hash" do
      expect(@process.state).to be_nil
    end

    it "should return the state of the process" do
      @process.update_state("started")
      expect(@process.state).to eq("started")
    end
  end

  describe "#updated_at" do
    before :each do
      File.delete(sample_state_file_path) if File.exist?(sample_state_file_path)
      watcher = Ziltoid::Watcher.new(:state_file => sample_state_file_path)
      @process = Ziltoid::Process.new("dummy process")
    end

    it "should return nil if process is not in the state hash" do
      expect(@process.state).to be_nil
    end

    it "should return the updated_at of the process" do
      time ||= Time.now
      allow(Time).to receive(:now).and_return(time)
      @process.update_state("started")
      expect(@process.updated_at).to eq(time.to_i)
    end
  end

  describe "#processable?(target_state)" do
    before :each do
      File.delete(sample_state_file_path) if File.exist?(sample_state_file_path)
      watcher = Ziltoid::Watcher.new(:state_file => sample_state_file_path)
      @process = Ziltoid::Process.new("dummy process", {:grace_times => {:start => 10, :stop => 10, :restart => 10, :cpu => 10, :ram => 10}})
    end

    it "should return false if the grace time of predominant states is not over" do
      Ziltoid::Process::PREDOMINANT_STATES.each do |p_state|
        @process.update_state(p_state)
        Ziltoid::Process::ALLOWED_STATES.each do |a_state|
          expect(@process.processable?(a_state)).to be false
        end
      end
    end

    context "when wanting to start a process" do
      it "should return true if grace time is over" do
        allow(@process).to receive(:updated_at).and_return(Time.now.to_i - 1000)
        @process.update_state("started")
        expect(@process.processable?("started")).to be true
      end

      it "should return false if grace time is not over" do
        time ||= Time.now
        allow(Time).to receive(:now).and_return(time)
        @process.update_state("started")
        expect(@process.processable?("started")).to be false
      end

      it "should return true if the process is not in the state hash" do
        process = Ziltoid::Process.new("some proc")
        expect(process.processable?("started")).to be true
      end
    end

    context "when wanting to stop a process" do
      it "should return true if grace time is over" do
        allow(@process).to receive(:updated_at).and_return(Time.now.to_i - 1000)
        @process.update_state("stopped")
        expect(@process.processable?("stopped")).to be true
      end

      it "should return false if grace time is not over" do
        time ||= Time.now
        allow(Time).to receive(:now).and_return(time)
        @process.update_state("stopped")
        expect(@process.processable?("stopped")).to be false
      end
    end

    context "when wanting to restart a process" do
      it "should return true if grace time is over" do
        allow(@process).to receive(:updated_at).and_return(Time.now.to_i - 1000)
        @process.update_state("restarted")
        expect(@process.processable?("restarted")).to be true
      end

      it "should return false if grace time is not over" do
        time ||= Time.now
        allow(Time).to receive(:now).and_return(time)
        @process.update_state("restarted")
        expect(@process.processable?("restarted")).to be false
      end
    end

    context "when wanting to process above_cpu_limit" do
      context "when previous state is not above_cpu_limit" do
        it "should return false" do
          allow(@process).to receive(:updated_at).and_return(Time.now.to_i - 1000)
          @process.update_state("restarted")
          expect(@process.processable?("above_cpu_limit")).to be false
        end
      end

      context "when previous state is above_cpu_limit" do
        it "should return true if grace time is over" do
          allow(@process).to receive(:updated_at).and_return(Time.now.to_i - 1000)
          @process.update_state("above_cpu_limit")
          expect(@process.processable?("above_cpu_limit")).to be true
        end

        it "should return false if grace time is not over" do
          time ||= Time.now
          allow(Time).to receive(:now).and_return(time)
          @process.update_state("above_cpu_limit")
          expect(@process.processable?("above_cpu_limit")).to be false
        end
      end

      it "should return false if the process is not in the state hash" do
        process = Ziltoid::Process.new("some proc")
        expect(process.processable?("above_cpu_limit")).to be false
      end
    end

    context "when wanting to process above_ram_limit" do
      context "when previous state is not above_ram_limit" do
        it "should return false" do
          allow(@process).to receive(:updated_at).and_return(Time.now.to_i - 1000)
          @process.update_state("restarted")
          expect(@process.processable?("above_ram_limit")).to be false
        end
      end

      context "when previous state is above_ram_limit" do
        it "should return true if grace time is over" do
          allow(@process).to receive(:updated_at).and_return(Time.now.to_i - 1000)
          @process.update_state("above_ram_limit")
          expect(@process.processable?("above_ram_limit")).to be true
        end

        it "should return false if grace time is not over" do
          time ||= Time.now
          allow(Time).to receive(:now).and_return(time)
          @process.update_state("above_ram_limit")
          expect(@process.processable?("above_ram_limit")).to be false
        end
      end

      it "should return false if the process is not in the state hash" do
        process = Ziltoid::Process.new("some proc")
        expect(process.processable?("above_ram_limit")).to be false
      end
    end
  end

  describe "#update_state(state)" do
    before :each do
      File.delete(sample_state_file_path) if File.exist?(sample_state_file_path)
      @watcher = Ziltoid::Watcher.new(:state_file => sample_state_file_path)
      @process = Ziltoid::Process.new("dummy process", {
        :commands => {
          :start => "/etc/init.d/script start",
          :stop => "/etc/init.d/script stop",
          :restart => "/etc/init.d/script restart"
        },
        :grace_times => {
          :start => 30,
          :stop => 30,
          :restart => 30,
          :cpu => 30,
          :ram => 30
        }
      })
    end

    it "should return nil when state is not allowed" do
      expect(@process.update_state("fake-state")).to be_nil
    end

    it "should write the state to the state file" do
      expect(Ziltoid::Watcher).to receive(:write_state).and_call_original
      @process.update_state("started")
    end

    it "should create a 'process name' entry in the state file if it does not exist" do
      time ||= Time.now
      allow(Time).to receive(:now).and_return(time)
      expect(Ziltoid::Watcher.read_state).not_to have_key(@process.name)
      @process.update_state("started")
      file = Ziltoid::Watcher.read_state
      expect(file).to have_key(@process.name)
      expect(file[@process.name]["state"]).to eq("started")
      expect(file[@process.name]["updated_at"]).to eq(time.to_i)
    end

    context "when updating with the same state" do
      it "should not update the updated_at key" do
        @process.update_state("started")
        updated_at = Ziltoid::Watcher.read_state[@process.name]["updated_at"]
        @process.update_state("started")
        expect(Ziltoid::Watcher.read_state[@process.name]["updated_at"]).to eq(updated_at)
      end
    end

    context "when updating with a different state" do
      it "should update the updated_at key" do
        @process.update_state("started")
        updated_at = Ziltoid::Watcher.read_state[@process.name]["updated_at"]
        sleep(2)
        @process.update_state("stopped")
        expect(Ziltoid::Watcher.read_state[@process.name]["updated_at"]).not_to eq(updated_at)
      end
    end
  end

  context "when manipulating proccesses" do
    before :each do
      watcher = Ziltoid::Watcher.new(:state_file => sample_state_file_path)
      @process = Ziltoid::Process.new("dummy process", {
        :pid_file => sample_pid_file_path,
        :commands => {
          :start => "/etc/init.d/script start",
          :stop => "/etc/init.d/script stop",
          :restart => "/etc/init.d/script restart"
        },
        :grace_times => {
          :start => 30,
          :stop => 30,
          :restart => 30,
          :cpu => 30,
          :ram => 30
        }
      })
    end

    describe "#start!" do
      it "should return nil if the process is already running" do
        expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(true)
        expect(@process.start!).to be_nil
      end

      context "when process is not processable" do
        before :each do
          allow(@process).to receive(:processable?).with("started").and_return(false)
        end

        it "should return nil" do
          expect(@process.start!).to be_nil
        end
      end

      context "when process is processable" do
        before :each do
          allow(@process).to receive(:processable?).with("started").and_return(true)
        end

        it "should remove the pid_file and launch the start command" do
          allow(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(false)
          expect(@process).to receive(:remove_pid_file)
          expect(@process).to receive(:`).with(@process.start_command)
          allow(@process).to receive(:update_state).with("started")
          @process.start!
        end

        it "should log the action" do
          expect(Ziltoid::Watcher).to receive(:log).once
          allow(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(false)
          allow(@process).to receive(:remove_pid_file)
          allow(@process).to receive(:`).with(@process.start_command)
          allow(@process).to receive(:update_state).with("started")
          @process.start!
        end

        it "should update the process state to started" do
          @process.update_state("stopped")
          expect(@process.state).not_to eq("started")
          allow(Ziltoid::Watcher).to receive(:log).once
          allow(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(false)
          allow(@process).to receive(:remove_pid_file)
          allow(@process).to receive(:`).with(@process.start_command)

          @process.start!
          expect(@process.state).to eq("started")
        end
      end
    end

    describe "#stop!" do
      context "when process is processable" do
        before :each do
          allow(@process).to receive(:processable?).with("stopped").and_return(true)
        end

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
            },
            :grace_times => {
              :start => 30,
              :stop => 30,
              :restart => 30,
              :cpu => 30,
              :ram => 30
            }
          })

          allow(proc).to receive(:processable?).with("stopped").and_return(true)
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

        it "should update the process state to stopped if the process has been properly killed" do
          @process.update_state("started")
          expect(@process.state).not_to eq("stopped")
          allow(@process).to receive(:remove_pid_file).twice
          allow(@process).to receive(:`).with(anything())
          expect(Ziltoid::System).to receive(:pid_alive?).with(12345).and_return(true, false, false)
          @process.stop!
          expect(@process.state).to eq("stopped")
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

      context "when process is not processable" do
        before :each do
          allow(@process).to receive(:processable?).with("stopped").and_return(false)
        end

        it "should return nil" do
          expect(@process.stop!).to be_nil
        end

        it "should not update the process state" do
          @process.update_state("started")
          expect(@process.state).not_to eq("stopped")
          @process.stop!
          expect(@process.state).not_to eq("stopped")
        end
      end
    end

    describe "#restart!" do
      context "when the process is processable" do
        before :each do
          allow(@process).to receive(:processable?).and_return(true)
        end

        context "when the process has no pid" do
          let :process do
            Ziltoid::Process.new("dummy process", {
              :commands => {
                :start => "/etc/init.d/script start",
                :stop => "/etc/init.d/script stop",
                :restart => "/etc/init.d/script restart"
              },
              :grace_times => {
                :start => 30,
                :stop => 30,
                :restart => 30,
                :cpu => 30,
                :ram => 30
              }
            })
          end

          it "should start the process" do
            allow(process).to receive(:processable?).and_return(true)
            expect(process.pid).to be_nil
            expect(process).to receive(:start!)
            process.restart!
          end
        end

        context "when the process has a pid" do
          context "when the process is dead" do
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

          context "when the process is alive" do
            context "when the process has no restart command" do
              it "should stop and start the process" do
                proc = Ziltoid::Process.new("dummy process", {
                  :pid_file => sample_pid_file_path,
                  :commands => {
                    :start => "/etc/init.d/script start",
                    :stop => "/etc/init.d/script stop"
                  },
                  :grace_times => {
                    :start => 30,
                    :stop => 30,
                    :restart => 30,
                    :cpu => 30,
                    :ram => 30
                  }
                })
                allow(proc).to receive(:processable?).and_return(true)

                allow(proc).to receive(:alive?).and_return(true)
                expect(proc).to receive(:stop!)
                expect(proc).to receive(:start!)
                proc.restart!
              end
            end

            context "when the process has a restart command" do
              it "should send the restart_command if one is available" do
                allow(@process).to receive(:alive?).and_return(true)
                expect(@process).to receive(:`).with(@process.restart_command)
                @process.restart!
              end

              it "should update the process state to restarted" do
                @process.update_state("started")
                expect(@process.state).not_to eq("restarted")
                allow(@process).to receive(:alive?).and_return(true)
                allow(@process).to receive(:`).with(@process.restart_command)
                @process.restart!

                expect(@process.state).to eq("restarted")
              end
            end
          end
        end

        it "should log the action" do
          expect(Ziltoid::Watcher).to receive(:log)
          allow(@process).to receive(:alive?).and_return(false)
          allow(@process).to receive(:start!)
          @process.restart!
        end
      end

      context "when the process is not processable" do
        before :each do
          allow(@process).to receive(:processable?).and_return(false)
        end

        it "should return nil" do
          expect(@process.restart!).to be_nil
        end

        it "should not update the process state" do
          @process.update_state("started")
          expect(@process.state).not_to eq("restarted")
          @process.restart!
          expect(@process.state).not_to eq("restarted")
        end
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
            },
            :grace_times => {
              :start => 30,
              :stop => 30,
              :restart => 30,
              :cpu => 30,
              :ram => 30
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
            allow(@process).to receive(:processable?).with("started").and_return(true)
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

          context "when the cpu usage is above limit" do
            context "when the process is not processable" do
              before :each do
                allow(@process).to receive(:processable?).with("above_cpu_limit").and_return(false)
              end

              it "should update the process state to above_cpu_limit if there is no pending grace time" do
                @process.update_state("above_ram_limit")
                expect(@process.state).not_to eq("above_cpu_limit")
                allow(@process).to receive(:alive?).and_return(true)
                allow(@process).to receive(:above_cpu_limit?).and_return(true)
                allow(@process).to receive(:above_ram_limit?).and_return(false)

                @process.watch!
                expect(@process.state).to eq("above_cpu_limit")
              end

              it "should not update the process state to above_cpu_limit if there is a pending grace time" do
                @process.update_state("started")
                expect(@process.state).not_to eq("above_cpu_limit")
                allow(@process).to receive(:alive?).and_return(true)
                allow(@process).to receive(:above_cpu_limit?).and_return(true)
                allow(@process).to receive(:above_ram_limit?).and_return(false)

                @process.watch!
                expect(@process.state).not_to eq("above_cpu_limit")
              end

              it "should not send restart" do
                expect(@process).to receive(:alive?).and_return(true)
                expect(@process).to receive(:above_cpu_limit?).and_return(true)
                allow(@process).to receive(:above_ram_limit?).and_return(false)
                expect(@process).not_to receive(:restart!)
                @process.watch!
              end
            end

            context "when the process is processable" do
              before :each do
                allow(@process).to receive(:processable?).with("above_cpu_limit").and_return(true)
              end

              it "should not update the process state to above_cpu_limit if there is a pending grace time" do
                @process.update_state("started")
                expect(@process.state).not_to eq("above_cpu_limit")
                allow(@process).to receive(:processable?).with("restarted").and_return(false)
                allow(@process).to receive(:alive?).and_return(true)
                allow(@process).to receive(:above_cpu_limit?).and_return(true)
                allow(@process).to receive(:above_ram_limit?).and_return(false)

                @process.watch!
                expect(@process.state).not_to eq("above_cpu_limit")
              end

              it "should update the process state to above_cpu_limit if there is no pending grace time" do
                @process.update_state("above_ram_limit")
                expect(@process.state).not_to eq("above_cpu_limit")
                allow(@process).to receive(:processable?).with("restarted").and_return(false)
                allow(@process).to receive(:alive?).and_return(true)
                allow(@process).to receive(:above_cpu_limit?).and_return(true)
                allow(@process).to receive(:above_ram_limit?).and_return(false)

                @process.watch!
                expect(@process.state).to eq("above_cpu_limit")
              end

              it "should send restart" do
                expect(@process).to receive(:alive?).and_return(true)
                expect(@process).to receive(:above_cpu_limit?).and_return(true)
                allow(@process).to receive(:above_ram_limit?).and_return(false)
                expect(@process).to receive(:restart!)
                @process.watch!
              end

            end
          end

          context "when the ram usage is above limit" do
            context "when the process is not processable" do
              before :each do
                allow(@process).to receive(:processable?).with("above_ram_limit").and_return(false)
              end

              it "should not update the process state to above_ram_limit if there is a pending grace time" do
                @process.update_state("started")
                expect(@process.state).not_to eq("above_ram_limit")
                allow(@process).to receive(:alive?).and_return(true)
                allow(@process).to receive(:above_ram_limit?).and_return(true)
                allow(@process).to receive(:above_cpu_limit?).and_return(false)

                @process.watch!
                expect(@process.state).not_to eq("above_ram_limit")
              end

              it "should update the process state to above_ram_limit if there is no pending grace time" do
                @process.update_state("above_cpu_limit")
                expect(@process.state).not_to eq("above_ram_limit")
                allow(@process).to receive(:alive?).and_return(true)
                allow(@process).to receive(:above_ram_limit?).and_return(true)
                allow(@process).to receive(:above_cpu_limit?).and_return(false)

                @process.watch!
                expect(@process.state).to eq("above_ram_limit")
              end

              it "should not send restart" do
                expect(@process).to receive(:alive?).and_return(true)
                expect(@process).to receive(:above_ram_limit?).and_return(true)
                allow(@process).to receive(:above_cpu_limit?).and_return(false)
                expect(@process).not_to receive(:restart!)
                @process.watch!
              end
            end

            context "when the process is processable" do
              before :each do
                allow(@process).to receive(:processable?).with("above_ram_limit").and_return(true)
              end

              it "should not update the process state to above_ram_limit if there is a pending grace time" do
                @process.update_state("started")
                expect(@process.state).not_to eq("above_ram_limit")
                allow(@process).to receive(:processable?).with("restarted").and_return(false)
                allow(@process).to receive(:alive?).and_return(true)
                allow(@process).to receive(:above_ram_limit?).and_return(true)
                allow(@process).to receive(:above_cpu_limit?).and_return(false)

                @process.watch!
                expect(@process.state).not_to eq("above_ram_limit")
              end

              it "should update the process state to above_ram_limit if there is no pending grace time" do
                @process.update_state("above_cpu_limit")
                expect(@process.state).not_to eq("above_ram_limit")
                allow(@process).to receive(:processable?).with("restarted").and_return(false)
                allow(@process).to receive(:alive?).and_return(true)
                allow(@process).to receive(:above_ram_limit?).and_return(true)
                allow(@process).to receive(:above_cpu_limit?).and_return(false)

                @process.watch!
                expect(@process.state).to eq("above_ram_limit")
              end

              it "should send restart" do
                expect(@process).to receive(:alive?).and_return(true)
                expect(@process).to receive(:above_ram_limit?).and_return(true)
                allow(@process).to receive(:above_cpu_limit?).and_return(false)
                expect(@process).to receive(:restart!)
                @process.watch!
              end

            end
          end
        end

      end

    end
  end
end