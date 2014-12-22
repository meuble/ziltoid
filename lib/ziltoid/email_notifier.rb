require 'pony'

module Ziltoid
  class EmailNotifier
    attr_accessor :via_options, :from, :to, :subject

    def initialize(options)
      self.via_options = options[:via_options]
      self.to = options[:to]
      self.from = options[:from]
      self.subject = options[:subject]
    end

    def send(message)
      Pony.mail(
        :to => self.to,
        :via => :smtp,
        :via_options => self.via_options,
        :from => self.from,
        :subject => self.subject, :body => message
      )
    end
  end
end