require 'webrick'
include WEBrick

class TestServlet < WEBrick::HTTPServlet::AbstractServlet
  #
  # Simple server for integration tests
  #

  def self.port
    8899
  end

  def self.path
    '/'
  end

  def self.url
    "http://127.0.0.1:#{port}#{path}"
  end

  def respond_with(method,req,res)
    res.body = method.to_s
    res['Content-Type'] = "text/plain"
  end

  def do_GET(req,res)
    respond_with(:GET,req,res)
  end

  def do_POST(req,res)
    respond_with(:POST,req,res)
  end

  def do_PUT(req,res)
    respond_with(:PUT,req,res)
  end

  def do_DELETE(req,res)
    respond_with(:DELETE,req,res)
  end

end
