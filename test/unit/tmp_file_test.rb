require 'test_helper'

class TmpFileTest < Test::Unit::TestCase
  context "Downspout" do
    context "Tmpfile" do
      setup do
        @explicit_name = "explicit.txt"
        @explicit_path = File.join( Downspout::Config.tmp_dir, @explicit_name )
        FileUtils.rm( @explicit_path ) if File.exist?( @explicit_path )
      end

      should "work similar to Ruby tempfile" do
        jltf = Downspout::Tmpfile.new()
        assert jltf
        assert jltf.path =~ /#{Downspout::Config.tmp_dir}/
      end
      
      should "create tempfile in configured directory" do
        assert Downspout::Tmpfile.new.path =~ /#{Downspout::Config.tmp_dir}/
      end

      should "create file with given basename in configured directory" do       
        dstf = Downspout::Tmpfile.new( :name => @explicit_name )

        assert_equal @explicit_name, File.basename( dstf.path )

        assert dstf.path =~ /#{Downspout::Config.tmp_dir}/
      end
      
    end
  end
end
