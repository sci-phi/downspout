module Downspout
# The object returned by a call to fetch_url() or download_url_to_disk().
  class Downloader < Base

    # returns the path to the downloaded file
    attr_accessor :path

    # returns the remote response as the appropriate Net::HTTPResponse
    attr_reader :response

    # returns the headers parsed from the remote response
    attr_reader :response_headers

    # returns the URI parsed from the URL
    attr_reader :uri

    # returns the URL initially given
    attr_accessor :url

    def initialize( options=nil ) #:nodoc:
      @basename = nil
      @curb_enabled = Downspout::Config.use_curb?
      @response_headers = {}
      @started_at = nil
      @finished_at = nil
      
      if options.respond_to?(:keys) then
        options.each do |key, value|
          self.send("#{key}=", value)
        end
      end

      @uri = URI.parse( @url ) unless @url.nil?
    end

    def to_s #:nodoc:
      return @path
    end

    #  returns the protocol or 'scheme' of the URL
    def scheme
      return @uri.scheme unless @uri.nil?
      return nil
    end

    #  returns the time taken to download the file
    def duration
      return nil unless @started_at
      return nil unless @finished_at
      
      return @finished_at - @started_at
    end

    #  Extracts the file name from the URL or uses a default name based on the content-type header
    def basename
      return @basename unless @basename.nil?
      
      if !(@path.nil?) then
        @basename = File.basename( @path )
      else
        if !(@uri.path.nil? || @uri.path.empty? || uri.path == '/')
          @basename = File.basename( @uri.path ) 
        else
          $logger.debug("downspout | downloader | basename | Bad URI path") 
          @basename = 'file.downspout'
        end
      end
            
      $logger.debug("downspout | downloader | basename | #{@basename} ")

      return @basename
    end

    #  will this download use the Curb library?
    def use_curb?
      return @curb_enabled
    end

    #  will this download use the default Net/HTTP library?
    def use_net_http?
      return false if use_curb?
      return true
    end

    #  configure this download to use the Curb library (will fail if Curb is unavailable.)
    def enable_curb!
      @curb_enabled = true if Downspout::Config.curb_available?

      return @curb_enabled
    end

    #  configure this download NOT to use the Curb library
    def disable_curb!
      @curb_enabled = false
    end

    def download! #:nodoc:
      $logger.debug("downspout | downloader | download! | URL : #{@url} ")
      @started_at = Time.now

      raise UnsupportedScheme if @uri.nil?
      raise UnsupportedScheme unless Downspout.supported_protocol?( @uri.scheme )

      if @path.nil? then
        tf = Downspout::Tmpfile.new( :name => self.basename )
        @path = tf.path
      end
      $logger.debug("downspout | downloader | download! | Path : #{@path} ")

      remove_file_at_target_path

      if Downspout::Config.network_enabled? then
        case self.scheme
        when /ftp/
          net_ftp_download
        when /http[s]?/
          if use_curb? then
            curb_http_download
          else
            net_http_download
          end
        else
          $logger.error("downspout | downloader | download! | Unknown URL Scheme : '#{self.scheme}'")
          raise UnsupportedScheme
        end
      else
        $logger.warn("downspout | downloader | download! | >>>>>   Networking Disabled   <<<<<")
      end

      downloaded = File.exist?( @path )

      $logger.debug("downspout | downloader | download! | #{self.basename} downloaded? : #{downloaded} ")
      @finished_at = Time.now
      
      if (tf && @basename == 'file.downspout') then
        # rename file more appropriately
        new_name = generate_file_name
        if !(new_name.nil?) then
          $logger.debug("downspout | downloader | download! | Renaming #{@basename} to #{new_name} ...")
          new_path = File.join( File.dirname( tf.path ), new_name)
          FileUtils.mv( tf.path, new_path )
          @path = new_path
        end
      end

      $logger.debug("downspout | downloader | download! | Started: #{@started_at.utc}, Finished: #{@finished_at.utc}, Duration: #{duration}")
      
      return downloaded
    end

    private

    def remove_file_at_target_path
      if File.exist?( @path ) then
        $logger.debug("downspout | downloader | remove_file_at_target_path | Removing #{@path} ... ")
        FileUtils.rm( @path )
      end
    end

    def net_ftp_download
      $logger.debug("downspout | downloader | net_ftp_download | Downloading #{@url} ...")

      # look up the credentials for this host
      cred = Downspout::Config.credentials.select{|c| c.scheme == 'ftp' }.select{ |c| c.host == @uri.host }.first
      if cred.nil? then
        $logger.warn("downspout | downloader | net_ftp_download | No credentials found for '#{@uri.host}'.")
        # proceed anyway - slight possibility it's an un-authorized FTP account...
      else
        $logger.debug("downspout | downloader | net_ftp_download | Loaded credentials for #{cred.host} ...")
      end
      
      begin
        ftp = Net::FTP.open( @uri.host ) do |ftp|
          ftp.login( cred.user_name, cred.pass_word ) unless cred.nil?
          ftp.passive
          ftp.chdir( File.dirname( @uri.path ) )
          
          $logger.debug("downspout | downloader | net_ftp_download | Local Path : #{@path} ...")
          ftp.getbinaryfile( self.basename, @path )
        end
      rescue Exception => e
        $logger.error("downspout | downloader | net_ftp_download | Exception : #{e}")
        raise e
      end

      done = File.exist?( @path )
      $logger.debug("downspout | downloader | net_ftp_download | #{basename} downloaded? : #{done}.")

      return done
    end

    def net_http_download
      $logger.debug("downspout | downloader | net_http_download | Downloading #{@url} ...")

      begin
        response = net_http_fetch( @url , 1)
        open( @path, "wb" ) do |file|
        
          file.write(response.body)
        end

       $logger.debug("downspout | downloader | net_http_download | Response Body : #{response.body[0..5].strip}")

      rescue SocketError => dns_err
        $logger.error("downspout | downloader | net_http_download | Net/HTTP DNS Error | #{@uri.host} | #{dns_err.inspect}")
        remove_file_at_target_path
        raise dns_err
      end
      
      $logger.debug("downspout | downloader | net_http_download | Response Code : #{response.code}")

      # populate the response headers from net/http headers...
      new_header_str = "HTTP/1.1 #{@response.code} #{@response.message}\r\n"
      @response.each_header do |k,v|
        new_header_str += "#{k}: #{v}\r\n"
      end
      @response_headers = parse_headers_from_string( new_header_str )

  
      if ((response.code.to_i != 200) and (response.code.to_i != 202)) then
        # missing file, failed download - delete the response body [if downloaded]
        remove_file_at_target_path
        return false
      end

      $logger.debug("downspout | downloader | net_http_download | Headers : #{response.header}")
    
      if !( File.exist?( @path ) ) then
        $logger.error("downspout | downloader | net_http_download | Missing File at download path : #{@path}")
        return false
      end
      
      $logger.debug("downspout | downloader | net_http_download | Successful.")
      return true
    end

    def net_http_fetch( url_str, limit = 10 )
      $logger.debug("downspout | downloader | net_http_fetch | URL: #{url_str}, Redirects: #{limit}.")
      raise Downspout::BadURL, 'URL is missing' if url_str.nil?
      raise Downspout::ExcessiveRedirects, 'HTTP redirect too deep' if limit == 0

      u = URI.parse( url_str )

      my_request = Net::HTTP::Get.new( "#{u.path}?#{u.query}" )

      # TODO : implement credentials for downloads via net_http_fetch
      my_request.basic_auth 'account', 'p4ssw0rd'

      $logger.debug("downspout | downloader | net_http_fetch | Firing...")
      @response = Net::HTTP.start( u.host, u.port ) do |http|
        http.request( my_request )
      end

      $logger.debug("downspout | downloader | net_http_fetch | Response : #{@response}")
      
      case @response
      when Net::HTTPSuccess
        @response
      when Net::HTTPRedirection
        net_http_fetch( @response['location'], limit - 1 )
      else
        @response.error!
      end
    end
    
    def curb_http_download
      $logger.debug("downspout | downloader | curb_http_download | Downloading #{@url} ...")

      begin
        curb = Curl::Easy.download( @url, @path) {|c| c.follow_location=true; c.max_redirects=1;}
      rescue Curl::Err::HostResolutionError
        $logger.error("downspout | downloader | curb_http_download | Curb/Curl DNS Error | #{@uri.host}")
        return false
      end
      
      $logger.debug("downspout | downloader | curb_http_download | Response Code : #{curb.response_code}")

      if ((curb.response_code != 200) and (curb.response_code != 202)) then
        # missing file, failed download - delete the response body [if downloaded]
        remove_file_at_target_path
      end

      $logger.debug("downspout | downloader | curb_http_download | Headers : #{curb.header_str}")

      # populate the response headers from curb header string
      @response_headers = parse_headers_from_string( curb.header_str )

      # populate a 'proxy' HTTPResponse object with the Curb data...
      hr_klass = Net::HTTPResponse.send('response_class', curb.response_code.to_s)
      $logger.debug("downspout | downloader | curb_http_download | Response Type : #{hr_klass.name}")
      
      @response = hr_klass.new( @response_headers["HTTP"][:version],
        curb.response_code,
        @response_headers["HTTP"][:message] )
        
      $logger.debug("downspout | downloader | curb_http_download | Response : #{@response.inspect}")

      if !( File.exist?( @path ) ) then
        $logger.error("downspout | downloader | curb_http_download | Missing File at download path : #{@path}")
        return false
      end
      
      $logger.debug("downspout | downloader | curb_http_download | Successful.")
      return true
    end

    def parse_headers_from_string( header_str )
      $logger.debug("downspout | downloader | parse_headers_from_string | String : #{header_str}")
      header_hash = {}
      http_hash = {}
      headers = header_str.split("\r\n")
  
      http_info = headers[0]
      http_hash[:header] = http_info
      http_hash[:version] = http_info.split(" ")[0].match("HTTP/([0-9\.]+)")[1]
      http_hash[:code] = (http_info.split("\r\n")[0].split(" ")[1]).to_i
      http_hash[:message] = http_info.split("\r\n")[0].split(" ")[2]
      
      $logger.debug("downspout | downloader | parse_headers_from_string | Response : #{http_hash[:version]}, #{http_hash[:code]}, #{http_hash[:message]}")
      header_hash["HTTP"] = http_hash
      
      headers[1..-1].each do |line|
        header_name, header_value = line.match(/([\w\-\s]+)\:\s?(.*)/)[1..2]
        header_hash[header_name] = header_value
      end
  
      return header_hash
    end

    def generate_file_name
      file_type = @response_headers['Content-Type'] if use_curb?
      file_type = @response_headers['Content-Type'] if use_net_http?
      return nil unless file_type

      return "default.html" if file_type =~ /text\/html/
      # TODO : smarter file name generation

      return nil
    end
    
  end

  
end
