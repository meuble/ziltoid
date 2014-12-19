#encoding: utf-8

require File.join(File.dirname(__FILE__), 'spec_helpers')

describe Ziltoid::EmailNotifier do
  describe "#initialisation" do
    before :each do
      @via_options = {
        :address        => 'smtp-out.bearstech.com',
        :port           => '25',
        :domain         => "banqyou.appliz.com"
      }
      @email_notifier = Ziltoid::EmailNotifier.new({
        :via_options => @via_options,
        :subject => "email subject",
        :to => ['stephane.akkaoui@sociabliz.com'],
        :from => 'ziltoid@appliz.com',
      })
    end

    it "should set via_options" do
      expect(@email_notifier.via_options).to eq(@via_options)
    end

    it "should set to parameter" do
      expect(@email_notifier.to).to eq(['stephane.akkaoui@sociabliz.com'])
    end

    it "should set from parameter" do
      expect(@email_notifier.from).to eq("ziltoid@appliz.com")
    end

    it "should set subject parameter" do
      expect(@email_notifier.subject).to eq("email subject")
    end
  end

  describe "#send" do
    before :each do
      @email_notifier = Ziltoid::EmailNotifier.new({
        :via_options => {},
        :subject => "email subject",
        :to => ['stephane.akkaoui@sociabliz.com'],
        :from => 'ziltoid@appliz.com',
      })
    end

    it "should send an email with given message and parameters" do
      message = "mail message"
      expect(Pony).to receive(:mail).with(:to => @email_notifier.to, :via => :smtp, :via_options => @email_notifier.via_options, :from => @email_notifier.from, :subject => @email_notifier.subject, :body => message)
      @email_notifier.send(message)
    end
  end
end