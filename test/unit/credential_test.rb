require 'test_helper'

class CredentialTest < Test::Unit::TestCase
  context "Downspout" do
    context "Credential" do

      context "object" do
  
        should "respond to scheme" do
          assert Downspout::Credential.new.respond_to?(:scheme)
        end
  
        should "respond to host" do
          assert Downspout::Credential.new.respond_to?(:host)
        end
  
        should "respond to port" do
          assert Downspout::Credential.new.respond_to?(:port)
        end
  
        should "respond to user_name" do
          assert Downspout::Credential.new.respond_to?(:user_name)
        end
  
        should "respond to pass_word" do
          assert Downspout::Credential.new.respond_to?(:pass_word)
        end
  
      end


      context "created from URL" do
  
        should "return nil if no credential extractable from otherwise valid URL" do
          @my_url = "ftp://ftp-test.domain.tld/path/2011-04-01_13-42-52/file.ext"
  
          @no_cred = Downspout::Credential.create_from_url( @my_url )
  
          assert_nil @no_cred
        end
  
        should "create credential from URL with embedded info" do
          @my_url = "ftp://test-name:test-secret@ftp-test.domain.tld/path/2011-04-01_13-42-52/file.ext"
  
          @my_cred = Downspout::Credential.create_from_url( @my_url )
  
          assert_not_nil @my_cred
  
          assert_equal Downspout::Credential, @my_cred.class
  
          assert_equal 'ftp', @my_cred.scheme
          assert_equal 'ftp-test.domain.tld', @my_cred.host
          assert_equal 21, @my_cred.port
          assert_equal 'test-name', @my_cred.user_name
          assert_equal 'test-secret', @my_cred.pass_word
        end
  
        should "raise error when parsing invalid URL [partially encoded]" do
          @bad_url = "ftp:%20%20test-name:test-secret@ftp-test.domain.tld/path/2011-04-01_13-42-52/file.ext"
  
          assert_raise URI::InvalidURIError do
            @bad_cred = Downspout::Credential.create_from_url( @bad_url )
          end        
        end
  
        should "raise error when parsing invalid URL [inserted space]" do
          @bad_url = "ft p://test-name:test-secret@ftp-test.domain.tld/path/2011-04-01_13-42-52/file.ext"
  
          assert_raise URI::InvalidURIError do
            @bad_cred = Downspout::Credential.create_from_url( @bad_url )
          end        
        end
        
      end
    end
  end

end
