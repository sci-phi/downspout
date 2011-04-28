module Downspout

  class Credential
    attr_accessor :scheme
    attr_accessor :host
    attr_accessor :port
    attr_accessor :user_name
    attr_accessor :pass_word

    def initialize( options = nil )
      if options && options.respond_to?(:keys) then
        options.each do |key, value|
          self.send("#{key}=", value) if self.respond_to?("#{key}=")
        end
      end
    end

    def self.create_from_url( some_url )
      cred_hash = {}

      begin
        some_uri = URI::parse( some_url )
      rescue NoMethodError => e
        # convert to Invalid URI as that's the more pertinent issue
        raise URI::InvalidURIError, e.to_s
      end

      return Credential.create_from_uri( some_uri )
    end

    def self.create_from_uri( some_uri )

      if some_uri.userinfo.nil? then
        return nil
      end

      cred_hash = {}
      cred_hash[:scheme] = some_uri.scheme
      cred_hash[:host] = some_uri.host
      cred_hash[:port] = some_uri.port
      cred_hash[:user_name] = some_uri.user
      cred_hash[:pass_word] = some_uri.password

      cred = Credential.new( cred_hash )
      
      return cred
    end
  end

end
