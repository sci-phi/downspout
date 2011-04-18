if !(defined?( $logger )) then
  if ( defined?( Rails ) && !(Rails.logger.nil?) ) then
    $logger = Rails.logger
  else
    require 'logger'
    $logger = Logger.new( STDERR )
    $logger.level = Logger::WARN
  end
end

$logger.debug "initialized logging facility..."
