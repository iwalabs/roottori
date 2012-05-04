require "roottori/version"
require "net/http"

module Roottori
  class BaseModel
    def initialize(attrs={})
      attrs.each do |k, v|
        self.send "#{k.to_s}=", v
      end
    end
  end
  
  class Configs < BaseModel
    attr_accessor :username, :password, :url, :from
    def initialize(attrs={})
      super
      @url ||= "http://gw1.roottori.fi/eapi/push"
    end
    def generate_fully_parameterized_uri(sms_message)
      s_url = Roottori.configs.url.clone
      s_url << "?"
      s_url << URI.encode_www_form(:l      => username,
                                   :p      => password,
                                   :from   => from,
                                   :msisdn => sms_message.recipients)
      
      puts s_url
      URI.parse s_url
    end
  end
  
  def self.configs
    @@configs ||= Configs.new
  end
  
  def self.configs=(configs) 
    @@configs = configs
  end
  
  class SmsMessage < BaseModel
    #TODO: Add support for clientid
    attr_accessor :status, :message, :recipients, :from, :message, :delivered_at#, :clientid
    def initialize(attrs={})
      super
      @status ||= Status::UNSENT
    end
    
    def deliver
      uri = Roottori.configs.generate_fully_parameterized_uri(self)
      req = Net::HTTP::Post.new(uri.to_s)
      req.set_content_type('text/plain', {"charset" => 'UTF-8'})
      req.body = self.message.to_s
      res = Net::HTTP.start(uri.host, 80) do |http|
        http.request(req)
      end
      self.delivered_at = Time.now
      if res == Net::HTTPSuccess
        self.status = Status::SENT
      else
        self.status = Status::FAILED
      end
    end
    
    def self.well_formed_phone_number(number)
      number.to_s.gsub(" ", "")
    end
    
    module Status
      UNSENT = "unsent"
      SENT = "sent"
      FAILED = "failed"
    end
  end
  
  module SmsMessageModule
  #validates_presence_of :phone_number, :message
  
  #TODO: Add support for deliver notifications, udh and dcs
  
  
  def send_sms
    
  end

  def self.send_automatic_sms(contact_info, contact = nil)
    url = URI.parse(URL)
    sender = (contact.nil? ? SENDER : contact.sms_template.sender)
    req = Net::HTTP::Post.new(url.path + "?l=" + USERNAME + "&p=" + PASSWORD +
        "&msisdn=" + contact_info.phone.to_s.gsub(" ","") + "&from=" + sender)
    req.set_content_type('text/plain', {"charset" => 'UTF-8'})
    if contact.debt.debtor.company?
      req.body = contact.sms_template.message.to_s unless contact.
        nil? or contact.sms_template.nil?
    else
      req.body = contact.sms_template.consumer_message.to_s unless contact.
        nil? or contact.sms_template.nil?
    end
    res = Net::HTTP.start(url.host, 80) {|http|
      http.request(req)
    }
    case res
    when Net::HTTPSuccess then
      create_sms_message_after_send(contact_info, 'sent', req)
      set_contact_sent_status(contact, true)
      return true
    else
      create_sms_message_after_send(contact_info, 'sent_error', req)
      set_contact_sent_status(contact, false)
      return false
    end
  end

  private
  def self.create_sms_message_after_send(contact_info, response, req)
    SmsMessage.create!(:message_sent => Time.now,
      :contact_info_id => contact_info.id,
      :phone_number => contact_info.phone.to_s.gsub(" ",""),
      :rest_response => response, :message => req.body.to_s + " ")
  end

  def self.set_contact_sent_status(contact, ok)
    contact.sent_status = (ok ? 'OK' : 'ERROR')
    contact.save!
  end

end
end