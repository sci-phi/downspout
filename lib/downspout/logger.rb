if !(defined?( $logger )) then
  if defined?( RAILS_DEFAULT_LOGGER ) then
    $logger = RAILS_DEFAULT_LOGGER
  else
    require 'logger'
    $logger = Logger.new( STDERR )
    $logger.level = Logger::INFO
  end
end

$logger.debug "initialized logging facility..."
