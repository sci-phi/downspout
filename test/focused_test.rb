require 'test_helper'

class FocusedTest < Test::Unit::TestCase
  context "Downspout" do
    context "Focus" do
      setup do
        @test_string = "foo"
      end

      should "behave properly" do
        assert_equal @test_string, "foo"
      end
    end
  end
end
