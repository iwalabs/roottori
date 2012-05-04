require "spec_helper"

describe Roottori do
  
  describe Roottori::Configs do
    it "should have username" do
      c = Roottori::Configs.new :username => "username"
      c.username.should eq "username"
    end
    it "should have password" do
      c = Roottori::Configs.new :password => "password"
      c.password.should eq "password"
    end
    describe "url" do
      it "is settable" do
        c = Roottori::Configs.new :url => "url"
        c.url.should eq "url"
      end
      it "has default value of: http://gw1.roottori.fi/eapi/push" do
        c = Roottori::Configs.new
        c.url.should eq "http://gw1.roottori.fi/eapi/push" 
      end
    end
    it "should have from" do
      c = Roottori::Configs.new :from => "from"
      c.from.should eq "from"
    end
  end
  
  describe "forming the query uri" do
    it "should have Config.url as base url" do
      Roottori.configs.url = "http://www.example.com/path"
      uri = Roottori.configs.generate_fully_parameterized_uri(Roottori::SmsMessage.new)
      uri.host.should eq "www.example.com"
      uri.path.should eq "/path"
    end
    describe "query params" do
      it "should set username as query param l" do
        Roottori.configs.username = "foobar"
        uri = Roottori.configs.generate_fully_parameterized_uri Roottori::SmsMessage.new
        uri.query.should match("l=foobar")
      end
      
      it "should set password as query param p" do
        Roottori.configs.password = "password"
        uri = Roottori.configs.generate_fully_parameterized_uri Roottori::SmsMessage.new
        uri.query.should match("p=password")
      end
      
      it "should set from as query param from" do
        Roottori.configs.from = "Rspec"
        uri = Roottori.configs.generate_fully_parameterized_uri Roottori::SmsMessage.new
        uri.query.should match("from=Rspec")
      end
      
      it "should set msisdn query params according to recipients" do
        uri = Roottori.configs.generate_fully_parameterized_uri Roottori::SmsMessage.new :recipients => ["first", "second"]
        uri.query.should match("msisdn=first")
        uri.query.should match("msisdn=second")
      end
    end
  end
  
  describe Roottori::SmsMessage do
    describe "status" do
      it "should be settable" do
        m = Roottori::SmsMessage.new :status => Roottori::SmsMessage::Status::FAILED
        m.status.should eq "failed"
      end
      it "should have default value of unsent" do
        m = Roottori::SmsMessage.new
        m.status.should eq Roottori::SmsMessage::Status::UNSENT
      end
    end
    
    describe "succesfully sending an sms message" do
      before :each do
        Net::HTTP.stub!(:start).and_return(Net::HTTPSuccess)
        @time_now = Time.now
        Time.stub(:now).and_return(@time_now)
        @sms = Roottori::SmsMessage.new
        @sms.deliver
      end
      it "should set status to sent" do
        @sms.status.should eq Roottori::SmsMessage::Status::SENT
      end
      it "should set deliverd_at to current time" do
        @sms.delivered_at.should eq @time_now 
      end
    end
    
    describe "when sending an sms message fails" do
      before :each do
        Net::HTTP.stub!(:start).and_return(Net::HTTPError)
        @sms = Roottori::SmsMessage.new
        @sms.deliver
      end
      it "should set status to failed" do
        @sms.status.should eq Roottori::SmsMessage::Status::FAILED
      end
    end
  end
end
