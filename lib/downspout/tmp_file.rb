require 'fileutils'
require 'tempfile'

module Downspout

  class Tmpfile < File

    # accepts an options hash which can include either or both of :name and :prefix
    # then creates a Tempfile with the optionally given name in a unique sub-folder
    # of the configured directory, optionally named with the prefix string. 
    # The unique folder name includes the prefix, a sortable date, the PID of
    # the download process, and a randomly generated sequence of characters.
    #
    #   => "/tmp/downloads/my-app-20110203-59488-1run8k2-0/desired-file-name.txt"
    #
    # call-seq:
    # Downspout::Tmpfile.new( :name => 'desired-file-name.txt', :prefix => 'my-app' )
    #
    def initialize( options = nil )
      # make sure the configured directory exists
      FileUtils.mkdir_p( Downspout::Config.tmp_dir )

      defaults = {:prefix => Downspout::Config.default_prefix, :name => "downloaded_file.tmp"}

      # overwrite defaults with given options
      defaults.merge!( options ) unless options.nil?

      # create a unique file path from the given options
      unique_path = File.join( Downspout::Config.tmp_dir, tmp_dir_name( defaults[:prefix] ), defaults[:name] )

      # make sure the unique directory exists
      $logger.debug("downspout | tmpfile | initialize | Creating unique directory : #{File.dirname(unique_path)}")
      FileUtils.mkdir_p( File.dirname( unique_path ) )
      raise "MakeDir Error" unless File.exist?( File.dirname( unique_path ) )
      
      super( unique_path, File::CREAT, 0644 )

    end

    def self.clean_dir( dir_path, delay=30 ) #:nodoc:
      # remove files older than DELAY (in minutes) from configured folder
      delay = 30 unless (delay.class == Fixnum)
      t0 = Time.now - ( delay * 60 )

      return false unless File.exist?( dir_path )
      the_dir = Dir.new( dir_path )
    
      $logger.debug( "downspout | tmpfile | clean_dir | start | Entries : #{the_dir.entries.size}" )
    
      the_dir.entries.each do |item|
        next if item == "."
        next if item == ".."
      
        $logger.debug( "downspout | tmpfile | clean_dir | sub item : #{item}" )
      
        item_path = File.join( dir_path, item )
      
        tx = File.mtime( item_path ).utc
      
        # skip files with modtime changed less than sixty minutes ago
        next unless (tx < t0)

        if File.directory?( item_path ) then
          $logger.debug( "downspout | tmpfile | clean_dir | Removing Directory : #{item}/*" )
          
          clean_dir( item_path, delay )
          
          begin
            FileUtils.rmdir( item_path )
          rescue Exception => e
            $logger.debug( "downspout | tmpfile | clean_dir | Exception : #{e}" )
            return false
          end
        else
          $logger.debug( "downspout | tmpfile | clean_dir | Removing Item : #{item}" )

          FileUtils.rm( item_path )
        end
      end

      $logger.debug( "downspout | tmpfile | clean_download_dir | finish | Entries : #{the_dir.entries.size}" )
      return true
    end
    
    private
    
    def tmp_dir_name( prefix, n=rand(9) )
      t = Time.now.strftime("%Y%m%d")
      path = "#{prefix}-#{t}-#{$$}-#{rand(0x100000000).to_s(36)}-#{n}"
    end

  end


  # Utility method for periodically removing download files from the configured directory.
  # Expects an integer as the number of minutes 'old' a file should be before removal.
  def self.clean_download_dir( delay=30 )
    Tmpfile.clean_dir( Downspout::Config.tmp_dir, delay )
  end

end
