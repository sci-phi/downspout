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
  Download a file from a given URL to a given Path on the local system
  The path is optional and will default to a generated temporary file
=end
  def self.download_url_to_path( some_url, some_path = nil )
    $logger.debug("downspout | download_url_to_path |  URL : #{some_url}")
    $logger.debug("downspout | download_url_to_path |  Download Path : #{some_path}")

    begin
      d = Downspout::Downloader.new( :url => some_url, :path => some_path )
    rescue Exception => e
      $logger.error("downspout | download_url_to_path | Exception : '#{e}'")
      return nil if e.class == Downspout::UnsupportedScheme
      raise e
    end

    fetched = d.download!

    if !(fetched) then
      $logger.error("downspout | download_url_to_path |  Fetch Failed : #{d.url} ")
      return nil
    end

    $logger.debug("downspout | download_url_to_path |  Local File : #{d.path} ")
    return d
  end

=begin rdoc
  Convenience method for downloading a file from an URL without specifying a path for storage.
=end
  def self.fetch_url( the_url )
    return self.download_url_to_path( the_url )
  end

=begin rdoc
  Utility method for validating a URL without initiating a download
=end
  def self.viable_url?( url_string )
    $logger.info("downspout | supported_protocol? |  URL : #{url_string} ")

    # remove user/password prefix if provided
    clean_url = self.extract_credentials_from_url!( url_string )

    begin
      uri = URI.parse( clean_url )
    rescue URI::InvalidURIError
      $logger.warn("downspout | supported_protocol? | The format of the url is not valid : #{url_string}")
      return false
    end

    return false unless self.supported_protocol?( uri.scheme )

    # TODO : do more in-depth checks on URL validity

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
    the_uri = URI.parse( some_url )

    if the_uri.userinfo.nil? then
      return some_url
    end

    begin
      Downspout::Config.add_credential( :scheme => the_uri.scheme,
        :host => the_uri.host,
        :user_name => the_uri.user,
        :pass_word => the_uri.password
        )
    ensure
      the_uri.user = nil
      the_uri.password = nil
    end
    
    return the_uri.to_s
  end

end
