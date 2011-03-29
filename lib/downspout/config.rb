module Downspout

  class Config
    # Default Values
    @@tmp_dir = "/tmp/downloads/"
    @@network_enabled = true
    @@credentials = []
    @@curb_allowed = true
    @@curb_enabled = true

    def self.tmp_dir
      return @@tmp_dir
    end

    def self.tmp_dir=( some_path )
      @@tmp_dir = some_path
    end

    def self.credentials
      return @@credentials
    end

    def self.network_enabled?
      return @@network_enabled
    end

    def self.disable_networking!
      @@network_enabled = false
      return !(@@network_enabled)
    end

    def self.enable_networking!
      @@network_enabled = true
    end

    def self.curb_available?
      begin
        require 'curb'
        return true
      rescue LoadError
        return false
      end
    end

    def self.use_curb?
      @@curb_enabled
    end

    def self.enable_curb!
      if self.curb_available? then
        @@curb_enabled = true
      else
        @@curb_enabled = false
      end
    end

    def self.disable_curb!
      $logger.debug("downspout | config | disable_curb! | will fall back to Net/HTTP.")
      @@curb_enabled = false
    end

    def self.add_credential( options = nil )
      return nil unless options && options.respond_to?(:keys)
      options = {:scheme => 'ftp'}.merge!( options )

      c = Credential.new( options )

      $logger.debug("downspout | config | add_credential | #{c.host}, #{c.user_name}, #{c.scheme} ")

      @@credentials << c      

      return c
    end

  end

end
