require 'test_helper'

class DownspoutTest < Test::Unit::TestCase
  context "Downspout" do
    context "Base" do

      should "respond to supported_protocol?" do
        assert Downspout.respond_to?("supported_protocol?")
      end

      should "respond to supported_protocols" do
        assert Downspout.respond_to?("supported_protocols")
      end

      should "respond to viable_url?" do
        assert Downspout.respond_to?("viable_url?")
      end

      should "respond to download_url_to_path for backwards compatibility" do
        assert Downspout.respond_to?(:download_url_to_path)
      end

      should "respond to fetch_url" do
        assert Downspout.respond_to?(:download_url_to_path)
      end
    end

    context "protocols" do

      should "not support SFTP" do
        assert !( Downspout.supported_protocol?( "sftp" ) )
      end

      should "not support AFP" do
        assert !( Downspout.supported_protocol?( "afp" ) )
      end

      should "not support SCP" do
        assert !( Downspout.supported_protocol?( "scp" ) )
      end

      should "support all secret herbs and spices" do
        assert_not_nil Downspout.supported_protocols
        assert_equal Array, Downspout.supported_protocols.class
        assert_equal 3, Downspout.supported_protocols.size
        $logger.info "List of supported protocols : #{Downspout.supported_protocols.join(", ")}"
      end

      should "support HTTP" do
        assert Downspout.supported_protocol?( "http" )
      end

      should "support HTTPS" do
        assert Downspout.supported_protocol?( "https" )
      end

      should "support URI::HTTP" do
        assert Downspout.supported_protocol?( URI::HTTP )
      end

      should "support URI::HTTPS" do
        assert Downspout.supported_protocol?( URI::HTTPS )
      end

      should "support FTP" do
        assert Downspout.supported_protocol?( "ftp" )
      end

      should "support URI::FTP" do
        assert Downspout.supported_protocol?( URI::FTP )
      end

    end

    context "URLs" do
      context "which are bad" do
        should "be rejected with unknown protocols" do
          assert !( Downspout.viable_url?( "protocol://host.domain.tld/resource/file.format" ) )
        end

        should "be rejected with SCP protocol" do
          assert !( Downspout.viable_url?( "scp://host.domain.tld/resource/file.format" ) )
        end

        should "be rejected with SFTP protocol" do
          assert !( Downspout.viable_url?( "sftp://host.domain.tld/resource/file.format" ) )
        end

        should "be accepted with FTPS protocol" do
          assert Downspout.viable_url?( "ftps://host.domain.tld/resource/file.format" )
        end

      end

      context "which are good" do
        should "be accepted with HTTP protocol" do
          assert Downspout.viable_url?( "http://host.domain.tld/resource/file.format" )
        end

        should "be accepted with HTTPS protocol" do
          assert Downspout.viable_url?( "https://host.domain.tld/resource/file.format" )
        end

        should "be accepted to PDF file" do
          assert Downspout.viable_url?( "http://host.domain.tld/resource/file.pdf" )
        end

        should "be accepted to PHP file with arbitrary parameters" do
          assert Downspout.viable_url?( "http://host.domain.tld/resource/file.php?doc_id=A1B2C3&vendor=xyz" )
        end

        should "be accepted with FTP protocol" do
          assert Downspout.viable_url?( "ftp://host.domain.tld/resource/file.format" )
        end

        should "be accepted with FTP protocol containing user & password" do
          num = Downspout::Config.credentials.size

          assert Downspout.viable_url?( "ftp://uzer:passw0rd@host.domain.tld/resource/file.format" )

          assert_equal num + 1, Downspout::Config.credentials.size

          assert_equal 'host.domain.tld', Downspout::Config.credentials.last.host
        end

      end
    end

    should "clean URLs with user & password via extract credentials" do
      test_url = "ftp://uzer:passw0rd@host.domain.tld/resource/file.format"

      new_url = Downspout.extract_credentials_from_url!( test_url )

      assert !(new_url == test_url)
      assert_equal URI::parse( test_url ).host, URI::parse( new_url ).host
      assert_equal URI::parse( test_url ).path, URI::parse( new_url ).path
    end

  end
end
