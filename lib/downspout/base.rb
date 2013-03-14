module Downspout

  class Base
    class << self
    end
  end

  class UnsupportedScheme < StandardError
  end

  class ExcessiveRedirects < StandardError
  end

  class BadURL < StandardError
  end

=begin rdoc
  Download a file from a given URL. The path is optional and will default to a generated temporary file.
=end
  def self.fetch_url( some_url, some_path = nil )
    $logger.debug("downspout | fetch_url |  URL : #{some_url}")
    $logger.debug("downspout | fetch_url |  Download Path : #{some_path}")

    begin
      d = Downspout::Downloader.new( :url => some_url, :path => some_path )
    rescue Exception => e
      $logger.error("downspout | fetch_url | Exception : '#{e}'")
      return nil if e.class == Downspout::UnsupportedScheme
      raise e
    end

    fetched = d.download!

    if !(fetched) then
      $logger.error("downspout | fetch_url |  Fetch Failed : #{d.url} ")
      return nil
    end

    $logger.debug("downspout | fetch_url |  Local File : #{d.path} ")
    return d
  end

  def self.download_url_to_path( the_url, the_path ) #:nodoc:
    return self.fetch_url( the_url, the_path )
  end

=begin rdoc
  Utility method for validating a URL without initiating a download
=end
  def self.viable_url?( url_string )
    $logger.info("downspout | viable_url? |  URL : #{url_string} ")

    begin
      # remove user/password prefix if provided
      clean_url = self.extract_credentials_from_url!( url_string )

      uri = URI.parse( clean_url )
    rescue URI::InvalidURIError
      $logger.warn("downspout | viable_url? | The format of the url is not valid : #{url_string}")
      return false
    end

    return false unless self.supported_protocol?( uri.scheme )

    return true
  end

=begin rdoc
  Utility method for checking the support for URLs of the given network protocol or 'scheme'
=end
  def self.supported_protocol?( some_protocol )
    $logger.debug("downspout | supported_protocol? |  protocol : #{some_protocol} ")

    protocol_string = some_protocol.to_s.upcase

    return true if self.supported_protocols.include?( protocol_string )

    case protocol_string
    when "HTTP"
      return true
    when "URI::HTTP"
      return true
    when "HTTPS"
      return true
    when "URI::HTTPS"
      return true
    when "FTP"
      return true
    when "URI::FTP"
      return true
    when "FTPS"
      return true
    when "URI::FTPS"
      return true
    else
      $logger.warn("downspout | supported_protocol? | #{protocol_string} is not supported by Downspout.")
    end

    return false
  end

  private

  def self.supported_protocols
    return ["HTTP", "HTTPS", "FTP"]
  end

  def self.extract_credentials_from_url!( some_url )

    begin
      some_uri = URI::parse( some_url )
    rescue NoMethodError => e
      # convert to Invalid URI as that's the more pertinent issue
      raise URI::InvalidURIError, e.to_s
    end

    cred = Downspout::Credential.create_from_uri( some_uri )

    if cred.nil? then
      return some_url
    end

    Downspout::Config.add_credential( cred )

    # zero out the user info
    some_uri.user = nil
    some_uri.password = nil

    # return sanitized URL string
    return some_uri.to_s
  end

end
