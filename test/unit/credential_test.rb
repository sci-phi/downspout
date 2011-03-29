require 'test_helper'

class CredentialTest < Test::Unit::TestCase
  context "Downspout" do
    context "Credential" do

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

  end

end
