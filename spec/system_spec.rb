#encoding: utf-8

require File.join(File.dirname(__FILE__), 'spec_helpers')

describe Ziltoid::System do
  let :ps_aux_res do
    "43060   3,3  0,8  2657220\n43065   3,1  2,8  1503208"
  end

  let :ps_aux_res_with_children do
    "43060   3,3  0,8  2657220\n43065   3,1  2,8  1503208\n43066  43060  2,2  72039\n43067  43060  1,0  123456"
  end

  let :ps_aux_res_with_grand_children do
    "43060   3,3  0,8  2657220\n43065   3,1  2,8  1503208\n43066  43060  2,2  72039\n43067  43060  1,0  123456\n43068  43067  1,0  123456"
  end

  describe "::pid_alive?" do
    it 'should be true if process responds to zero signal' do
      expect(Process).to receive(:kill).with(0, 555).and_return(0)
      expect(Ziltoid::System).to be_pid_alive(555)
    end

    it 'should be true if process is not accessible but definitely exists' do
      expect(Process).to receive(:kill).with(0, 555).and_raise(Errno::EPERM)
      expect(Ziltoid::System).to be_pid_alive(555)
    end

    it 'should be false if process throws exception on zero signal' do
      expect(Process).to receive(:kill).with(0, 555).and_raise(Errno::ESRCH)
      expect(Ziltoid::System).not_to be_pid_alive(555)
    end
  end

  describe "::ps_aux" do
    it "should be a Hash" do
      expect(Ziltoid::System).to receive(:`).at_least(:once).and_return(ps_aux_res)
      expect(Ziltoid::System.ps_aux).to be_kind_of(Hash)
    end

    it "should have the correct information with no parent" do
      expect(Ziltoid::System).to receive(:`).at_least(:once).and_return(ps_aux_res)
      res = Ziltoid::System.ps_aux
      first_res = res[43060]
      expect(first_res[:pid]).to eq("43060")
      expect(first_res[:cpu]).to eq("0.8")
      expect(first_res[:ram]).to eq("2657220")
    end

    it "should have the correct information with a parent" do
      expect(Ziltoid::System).to receive(:`).at_least(:once).and_return(ps_aux_res_with_children)
      res = Ziltoid::System.ps_aux
      first_res = res[43067]
      expect(first_res[:pid]).to eq("43067")
      expect(first_res[:ppid]).to eq("43060")
      expect(first_res[:cpu]).to eq("1.0")
      expect(first_res[:ram]).to eq("123456")
    end
  end

  describe "::cpu_usage(pid, include_children = true)" do
    it "should return the correct cpu_usage including the children" do
      expect(Ziltoid::System).to receive(:`).at_least(:once).and_return(ps_aux_res_with_children)
      expect(Ziltoid::System.cpu_usage(43060)).to eq(4.0)
    end

    it "should return the correct cpu_usage excluding the children" do
      expect(Ziltoid::System).to receive(:`).at_least(:once).and_return(ps_aux_res)
      expect(Ziltoid::System.cpu_usage(43060, false)).to eq(0.8)
    end
  end

  describe "::ram_usage(pid, include_children = true)" do
    it "should return the correct ram_usage including the children" do
      expect(Ziltoid::System).to receive(:`).at_least(:once).and_return(ps_aux_res_with_children)
      expect(Ziltoid::System.ram_usage(43060)).to eq(2852715)
    end

    it "should return the correct ram_usage excluding the children" do
      expect(Ziltoid::System).to receive(:`).at_least(:once).and_return(ps_aux_res)
      expect(Ziltoid::System.ram_usage(43060, false)).to eq(2657220)
    end
  end

  describe "::get_children(parent_pid)" do
    it "should return an empty array" do
      expect(Ziltoid::System).to receive(:`).at_least(:once).and_return(ps_aux_res)
      expect(Ziltoid::System.get_children(43060)).to be_empty
    end

    it "should return all children pids" do
      expect(Ziltoid::System).to receive(:`).at_least(:once).and_return(ps_aux_res_with_children)
      expect(Ziltoid::System.get_children(43060)).to eq([43066, 43067])
    end

    it "should return all children and grand children pids" do
      expect(Ziltoid::System).to receive(:`).at_least(:once).and_return(ps_aux_res_with_grand_children)
      expect(Ziltoid::System.get_children(43060)).to eq([43066, 43067, 43068])
    end
  end

end
