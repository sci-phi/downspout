require 'test_helper'

class DownloaderTest < Test::Unit::TestCase

 context "Downspout" do
    context "Downloader" do

      should "respond to URL" do
        assert Downspout::Downloader.new.respond_to?(:url)
      end

      should "respond to URI" do
        assert Downspout::Downloader.new.respond_to?(:uri)
      end

      should "respond to Scheme" do
        assert Downspout::Downloader.new.respond_to?(:scheme)
      end

      should "respond to Path" do
        assert Downspout::Downloader.new.respond_to?(:path)
      end

      should "respond to Basename" do
        assert Downspout::Downloader.new.respond_to?(:basename)
      end

      should "respond to Response" do
        assert Downspout::Downloader.new.respond_to?(:response)
      end

      should "respond to Response Headers" do
        assert Downspout::Downloader.new.respond_to?(:response_headers)
      end

      should "respond to download!" do
        assert Downspout::Downloader.new.respond_to?("download!")
      end

      should "support explicitly using Net:::HTTP for downloads" do
        assert Downspout::Config.curb_available?

        dlx = Downspout::Downloader.new()
        assert dlx.use_curb?

        dlx.disable_curb!

        assert !(dlx.use_curb?)
        assert dlx.use_net_http?
      end

      should "default to using Curb for downloads when available" do
        assert Downspout::Config.curb_available?

        dlx = Downspout::Downloader.new
        assert dlx.use_curb?
        assert !(dlx.use_net_http?)
      end

      should "support configuration to switch default to Net:::HTTP for downloads" do
        assert Downspout::Config.curb_available?
        assert Downspout::Config.use_curb?
        begin
          Downspout::Config.disable_curb!

          assert !(Downspout::Config.use_curb?)
          
          dlx = Downspout::Downloader.new()
          assert !(dlx.use_curb?)
          assert dlx.use_net_http?
        ensure
          Downspout::Config.enable_curb!
        end
      end
      
      context "with HTTP URL" do
        setup do
          @obj = Downspout::Downloader.new( :url => "http://machine.local/downspout.test" )
        end

        should "populate URL" do
          assert_not_nil @obj.url
        end

        should "automatically parse URI from given URL" do
          assert_not_nil @obj.uri
        end

        should "determine download scheme" do
          assert_not_nil @obj.scheme
          assert_equal "http", @obj.scheme
        end

        should "populate basename" do
          assert_not_nil @obj.basename
          assert_equal "downspout.test", @obj.basename
        end

      end

      context "with URL for unsupported scheme (protocol)" do
        should "fail on invalid scheme (Gopher)" do
          assert_raise Downspout::UnsupportedScheme do
            @obj = Downspout::Downloader.new( :url => "gopher://umn.edu/" )
            @obj.download!
          end
        end
        should "fail on invalid scheme (SMB)" do
          assert_raise Downspout::UnsupportedScheme do
            @obj = Downspout::Downloader.new( :url => "smb://windows.microsoft.com/" )
            @obj.download!
          end
        end
      end

      context "over-writing an existing file" do
        setup do
          dts = Time.now.utc.strftime("%Y%m%d_%H%M%S")
          @tmp_conflict_path = File.join( Test::App.root , 'tmp', "#{dts}.tmp" )

          FileUtils.touch( @tmp_conflict_path )
          
          @ds_url = "http://machine.local/folder/file.txt"

          Downspout::Config.disable_networking!
        end

        should "remove the conflict file before the download" do
          assert File.exist?( @tmp_conflict_path )
          
          @df = Downspout.download_url_to_path( @ds_url, @tmp_conflict_path )
          # note: due to disabled networking, the download is not actually performed,
          # but the method otherwise operates as normal

          assert !( File.exist?( @tmp_conflict_path ) )
        end
        
        teardown do
          FileUtils.rm( @tmp_conflict_path) if (@tmp_conflict_path && File.exist?( @tmp_conflict_path ))
          Downspout::Config.enable_networking!
        end
      end

    end

    context "faking net/http response" do
      should "map 302 code to Found" do
        assert_equal Net::HTTPFound, Net::HTTPResponse.send('response_class','302')
      end
      should "map 301 code to Moved" do
        assert_equal Net::HTTPMovedPermanently, Net::HTTPResponse.send('response_class','301')
      end
    end
    
    context "with FTP URL" do
      setup do
        @obj = Downspout::Downloader.new( :url => "ftp://ftp.machine.local/directory/image.jpg" )
      end

      should "populate URL" do
        assert_not_nil @obj.url
      end

      should "automatically parse URI from given URL" do
        assert_not_nil @obj.uri
      end

      should "determine download scheme" do
        assert_not_nil @obj.scheme
        assert_equal "ftp", @obj.scheme
      end

      should "populate basename" do
        assert_not_nil @obj.basename
        assert_equal "image.jpg", @obj.basename
      end

    end

  end

  should 'download google index page via curb' do
    g = Downspout.fetch_url( 'http://www.google.com/' )

    assert_not_nil g
    assert File.exist?( g.path )
    assert_equal Downspout::Downloader, g.class
    assert g.response.is_a?(Net::HTTPResponse)
    assert_equal Net::HTTPOK, g.response.class
    assert g.response_headers.keys.include?('Content-Type')
  end

  should 'download google index page via net/http' do
    g = Downspout::Downloader.new( :url => 'http://www.google.com/' )
    assert g.use_curb?

    g.disable_curb!

    assert g.use_net_http?

    g.download!

    assert_not_nil g
    assert File.exist?( g.path )
    assert_equal Downspout::Downloader, g.class
    assert g.response.is_a?(Net::HTTPResponse)
    assert_equal Net::HTTPOK, g.response.class
    assert g.response_headers.keys.include?('content-type') # Note case difference for Net/HTTP vs Curb
  end

  context "with content disposition header defining file name" do
    setup do
      @dlx = Downspout::Downloader.new()
      @faux_headers = File.read( File.join( Test::App.root, "test", "fixtures", "faux_headers.txt" ) )

      @dlx.send("parse_headers_from_string!", @faux_headers )
    end

    should "have expected keys parsed from headers" do
      all_keys = @dlx.response_headers.keys
      assert_equal 10, all_keys.size
    end

    should "have a key for the content dispositon header" do
      all_keys = @dlx.response_headers.keys
      the_key = all_keys.select{|k| k =~ /content-disposition/i }.first
      assert the_key
    end
    
    should "extract the expected file name" do
      assert_equal "0123456789_X.pdf", @dlx.send("generate_file_name")
    end

    should "extract the expected file name (even when quoted)" do
      @dlx.response_headers["Content-Disposition"].gsub!("0123456789_X.pdf", "\"0123456789_X.pdf\"")
      assert_equal "0123456789_X.pdf", @dlx.send("generate_file_name")
    end

    should "extract the expected file name (followed by size)" do
      @dlx.response_headers["Content-Disposition"].gsub!("0123456789_X.pdf", "2c2afa1c-1b47-422e-bf2d-9848373381bc.pdf;size=5524642")
      assert_equal "2c2afa1c-1b47-422e-bf2d-9848373381bc.pdf", @dlx.send("generate_file_name")
    end

  end

  context "last location for curb redirects" do
    setup do
      @expected_url = "https://download.github.com/rails-rails-v2.3.11-0-gb0c3d45.tar.gz"
      @header_str = "HTTP/1.1 302 Found
Server: nginx/0.7.67
Date: Mon, 18 Apr 2011 01:53:16 GMT
Content-Type: text/html; charset=utf-8
Connection: keep-alive
Status: 302 Found
Location: https://nodeload.github.com/rails/rails/tarball/v2.3.11
X-Runtime: 3ms
Content-Length: 121
Cache-Control: no-cache
Strict-Transport-Security: max-age=2592000

HTTP/1.1 302 Moved Temporarily
Server: nginx/0.7.67
Date: Mon, 18 Apr 2011 01:53:17 GMT
Transfer-Encoding: chunked
Connection: keep-alive
Location: https://download.github.com/rails-rails-v2.3.11-0-gb0c3d45.tar.gz

HTTP/1.1 200 OK
Server: nginx/0.7.67
Date: Mon, 18 Apr 2011 01:53:17 GMT
Content-Type: application/octet-stream
Content-Length: 3416081
Last-Modified: Mon, 18 Apr 2011 01:45:25 GMT
Connection: keep-alive
Accept-Ranges: bytes"
    end

    should "grep last location header" do
      last_location = @header_str.scan(/Location\:\s?(.*)\W/).last.first

      assert_equal @expected_url, last_location
    end

    should "match last_location method" do
      @obj = Downspout::Downloader.new( :url => "http://bad.url/path" )
      last_location = @obj.send('curb_last_location', @header_str )

      assert_equal String, last_location.class
      assert_equal @expected_url, last_location
    end
  end

  should "select credential regardless of case of HOST" do
    Downspout::Config.add_credential( :scheme => 'ftp', 
      :host => "down-case.capitalized-domain.net",
      :user_name => "better-tester",
      :pass_word => "S3v3nT7"
      )

    test_url = "ftp://down-case.CAPITALIZED-DOMAIN.net/path/to/no-where.xls"
    
    @obj = Downspout::Downloader.new( :url => test_url )
    assert_not_nil @obj.send('get_ftp_credential')
  end
  
end
