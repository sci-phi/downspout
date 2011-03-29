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

  end

end
