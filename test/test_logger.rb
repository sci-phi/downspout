require 'logger'

if !defined?( RAILS_DEFAULT_LOGGER ) then
  root_dir = File.dirname( File.dirname(__FILE__) )
  test_log_path = File.join( root_dir, 'tmp', 'log', 'test.log')

  begin
    require 'fileutils'
    # creates the log directory if possible
    FileUtils.mkdir_p( File.dirname( test_log_path ) )
  
    # touching the file ensures it is writable
    FileUtils.touch( test_log_path )
  
    if File.exist?( File.dirname( test_log_path ) ) then
      $logger = Logger.new( test_log_path )
    else
      $logger = Logger.new( STDERR )
    end
  
  rescue Exception => e
    # ignore the error and try to carry on...  
    $logger = Logger.new( STDERR )
    $logger.warn "Failed to create log file due to exception : #{e}"
  end
end

$logger.level = Logger::DEBUG