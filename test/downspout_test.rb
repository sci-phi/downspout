require 'test_helper'
require 'test_servlet'

class DownspoutTest < Test::Unit::TestCase

  def setup
    $test_ws_root ||= Test::App.root
    $test_read_me_url = "http://127.0.0.1:8899/READ_ME.rdoc"
    $test_image_url = "http://127.0.0.1:8899/images/ruby.png"

    $test_ws ||= WEBrick::HTTPServer.new(:Port => 8899,
     :DocumentRoot => @test_ws_root,
#     :Logger => Log.new(nil, BasicLog::WARN), # TODO : Use Log/BasicLog from WEBrick to reduce spam in tests
     :Logger => $logger,
     :AccessLog => [])


    $test_ws.mount(TestServlet.path, TestServlet)

    two_deep_proc = Proc.new { |req, resp|
      resp.body = '2-deep redirector proc mounted on #{req.script_name}'
      resp.set_redirect( HTTPStatus::MovedPermanently, '/one/deep')
    }

    $test_ws.mount('/two/deep/', HTTPServlet::ProcHandler.new(two_deep_proc) )

    redir_proc = Proc.new { |req, resp|
      resp.body = 'redirector proc mounted on #{req.script_name}'
      resp.set_redirect( HTTPStatus::MovedPermanently, '/READ_ME.rdoc')
    }

    $test_ws.mount('/one/deep/', HTTPServlet::ProcHandler.new(redir_proc) )

    $test_ws.mount("/images", HTTPServlet::FileHandler,
      File.join( Test::App.root, "test", "fixtures"), {:FancyIndexing => true} )

    $test_ws_thread = Thread.new { $test_ws.start }
  end
      
  def test_download_rdoc_from_servlet
    some_url = $test_read_me_url

    dl = Downspout.fetch_url( some_url )

    assert_not_nil dl

    assert File.exist?( dl.path )
  end

  def test_by_fetching_image_from_w3c
    some_url = "http://www.w3.org/wiki/images/2/2e/Ruby01.png"

    dl = Downspout.fetch_url( some_url )

    assert_not_nil dl

    assert File.exist?( dl.path )
  end

  context "Downspout" do
    should "define the test URL" do
      assert_not_nil $test_read_me_url
    end

    context "for HTTP URLs" do
      should "download file via HTTP from local TestServlet" do
        assert Downspout.fetch_url( $test_read_me_url )
      end
    end

    should "fail with Curb error in case of excessive redirects" do
      two_deep_url = "http://127.0.0.1:8899/two/deep?curby"

      assert_raise Curl::Err::TooManyRedirectsError do
        dl = Downspout.fetch_url( two_deep_url )
      end
    end

    context "with Curb disabled" do
      setup do
        Downspout::Config.disable_curb!
      end

      should "fail with Downspout error in case of excessive redirects" do
        two_deep_url = "http://127.0.0.1:8899/two/deep?no-curb"
  
        assert_raise Downspout::ExcessiveRedirects do
          dl = Downspout.fetch_url( two_deep_url )
        end

      end

      teardown do
        Downspout::Config.enable_curb!
      end
    end

    teardown do
     Downspout.clean_download_dir( 0 )
    end

  end

  should "fail due to excessive redirects" do
    @obj = Downspout::Downloader.new( :url => "http://127.0.0.1:8899/two/deep?over-draft" )

    assert_raise Downspout::ExcessiveRedirects do
     @obj.send('net_http_fetch', @obj.url, 1 )  # uses send to bypass Curb and force Net::HTTP
    end
  end

  should "fail due to DNS error" do
    @obj = Downspout::Downloader.new( :url => "http://fu.man.chu/deep/nested/resource?over-draft" )

    assert_raise SocketError do
     @obj.send('net_http_fetch', @obj.url) # uses send to bypass Curb and force Net::HTTP
    end
  end

  should "download to custom path" do
    gfx_path = File.join( Test::App.root, "tmp", "download-test", "image.png" )
    FileUtils.mkdir_p( File.dirname( gfx_path ) )
    
    dl = Downspout.download_url_to_path( $test_image_url, gfx_path )
  end

end
