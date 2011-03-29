require 'test_helper'

class ConfigTest < Test::Unit::TestCase
  context "Downspout" do
    context "Config" do

      should "respond to tmp_dir" do
        assert Downspout::Config.respond_to?(:tmp_dir)
      end

      should "default to '/tmp/downloads/' for Downspout::Config#tmp_dir" do
        assert_equal "/tmp/downloads/", Downspout::Config.tmp_dir
      end

      should "respond to Network Enabled" do
        assert Downspout::Config.respond_to?("network_enabled?")
      end

      should "default to Network Enabled" do
        assert Downspout::Config.network_enabled?
      end

      should "respond to Disable Networking" do
        assert Downspout::Config.respond_to?("disable_networking!")
      end

      should "support disabling network operations" do
        assert Downspout::Config.network_enabled?
        assert Downspout::Config.disable_networking!
        assert !(Downspout::Config.network_enabled?)
      end

      should "respond to Enable Networking" do
        assert Downspout::Config.respond_to?("enable_networking!")
      end

      should "detect whether Curb is available" do
        assert Downspout::Config.curb_available?
      end

      should "enable Curb if library is available" do
        assert Downspout::Config.curb_available?
        assert Downspout::Config.enable_curb!
      end

      should "support enabling network operations" do
        assert !(Downspout::Config.network_enabled?)
        assert Downspout::Config.enable_networking!
        assert Downspout::Config.network_enabled?
      end

      context "Host-Based Credentials" do
        should "respond to Credentials" do
          assert Downspout::Config.respond_to?(:credentials)
          assert_not_nil Downspout::Config.credentials
        end
  
        should "support adding Credentials" do
          assert Downspout::Config.respond_to?("add_credential")        
        end

        should "add FTP Credential" do
          assert_equal 0, Downspout::Config.credentials.size

          ftp_url = "ftp://ftp-intake.vitalbook.com/hammer.rb"
          ftp_host = URI.parse( ftp_url ).host
          
          Downspout::Config.add_credential( :scheme => 'ftp', 
            :host => ftp_host,
            :user_name => "deploy",
            :pass_word => "m@keitRUUN!"
            )

          assert_equal 1, Downspout::Config.credentials.size

          assert_equal ftp_host, Downspout::Config.credentials.first.host
        end

      end

    end
  end

  context "with stubbed-out curb detection" do
    setup do
      Downspout::Config.stubs('curb_available?').returns(false)    
    end

    should "fail to enable Curb when library is unavailable" do
      assert !(Downspout::Config.curb_available?)
      assert !(Downspout::Config.enable_curb!)
    end

    teardown do
      # this is pretty heinous...
      Downspout::Config.stubs('curb_available?').returns(true)
      Downspout::Config.enable_curb!
    end
  end

end
