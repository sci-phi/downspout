require 'test_servlet'

ws_root = File.expand_path( File.dirname( File.dirname( __FILE__ ) ) )

ws_app = WEBrick::HTTPServer.new(:Port => 8899,
     :DocumentRoot => @test_ws_root,
     :Logger => Log.new(nil, BasicLog::WARN), # Log/BasicLog from WEBrick - reduces spam in tests
#     :Logger => $logger,
     :AccessLog => [])

ws_app.mount(TestServlet.path, TestServlet)

two_deep_proc = Proc.new { |req, resp|
  resp.body = '2-deep redirector proc mounted on #{req.script_name}'
  resp.set_redirect( HTTPStatus::MovedPermanently, '/one/deep')
}

ws_app.mount('/two/deep/', HTTPServlet::ProcHandler.new(two_deep_proc) )

redir_proc = Proc.new { |req, resp|
  resp.body = 'redirector proc mounted on #{req.script_name}'
  resp.set_redirect( HTTPStatus::MovedPermanently, '/READ_ME.rdoc')
}

ws_app.mount('/one/deep/', HTTPServlet::ProcHandler.new(redir_proc) )

ws_thread = Thread.new { ws_app.start }    
    
read_me_url = "#{TestServlet.url}/READ_ME.doc"

puts "Request #{read_me_url}"

