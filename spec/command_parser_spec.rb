#encoding: utf-8

require File.join(File.dirname(__FILE__), 'spec_helpers')

describe Ziltoid::CommandParser do
  describe "::parse(args)" do
    it "should instantiate a new option_parser" do
      expect(OptionParser).to receive(:new).and_call_original
      Ziltoid::CommandParser.parse(["watch"])
    end

    it "should return an OpenStruct" do
      expect(Ziltoid::CommandParser.parse(["watch"])).to be_instance_of(OpenStruct)
    end

    it "should parse arguments" do
      args = ["watch"]
      expect_any_instance_of(OptionParser).to receive(:parse!).with(args).and_call_original
      Ziltoid::CommandParser.parse(args)
    end

    context "when the command is valid" do
      it "should set command" do
        command_parser = Ziltoid::CommandParser.parse(["watch"])
        expect(command_parser.command).to eq("watch")
      end

      it "should take the first of several commands" do
        command_parser = Ziltoid::CommandParser.parse(["start", "watch", "stop"])
        expect(command_parser.command).to eq("start")
      end

      it "should print help and exit with -h" do
        expect(Ziltoid::CommandParser).to receive(:exit)
        Ziltoid::CommandParser.parse(["watch", "-h"])
      end

      it "should print help and exit with --help" do
        expect(Ziltoid::CommandParser).to receive(:exit)
        Ziltoid::CommandParser.parse(["watch", "--help"])
      end
    end

    context "when the command is not valid" do
      context "and when the command is empty" do
        it "should print help and exit" do
          expect_any_instance_of(OptionParser).to receive(:help)
          expect(Ziltoid::CommandParser).to receive(:exit)
          cp = Ziltoid::CommandParser.parse([])
        end

        it "should not set the command" do
          allow(OptionParser).to receive(:help)
          allow(Ziltoid::CommandParser).to receive(:exit)
          cp = Ziltoid::CommandParser.parse([])
          expect(cp.command).to be_nil
        end

        it "should print help and exit with -h" do
          expect_any_instance_of(OptionParser).to receive(:help)
          expect(Ziltoid::CommandParser).to receive(:exit).twice
          Ziltoid::CommandParser.parse(["-h"])
        end

        it "should print help and exit with --help" do
          expect_any_instance_of(OptionParser).to receive(:help)
          expect(Ziltoid::CommandParser).to receive(:exit).twice
          Ziltoid::CommandParser.parse(["--help"])
        end
      end

      context "and when the command is not in the ALLOWED_COMMANDS" do
        it "should print help and exit" do
          expect_any_instance_of(OptionParser).to receive(:help)
          expect(Ziltoid::CommandParser).to receive(:exit)
          cp = Ziltoid::CommandParser.parse(["oui"])
        end

        it "should not set the command" do
          allow(OptionParser).to receive(:help)
          allow(Ziltoid::CommandParser).to receive(:exit)
          cp = Ziltoid::CommandParser.parse(["oui"])
          expect(cp.command).to be_nil
        end

        it "should print help and exit with -h" do
          expect_any_instance_of(OptionParser).to receive(:help)
          expect(Ziltoid::CommandParser).to receive(:exit).twice
          Ziltoid::CommandParser.parse(["oui", "-h"])
        end

        it "should print help and exit with --help" do
          expect_any_instance_of(OptionParser).to receive(:help)
          expect(Ziltoid::CommandParser).to receive(:exit).twice
          Ziltoid::CommandParser.parse(["--help"])
        end
      end

    end
  end
end