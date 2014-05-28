require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'

begin
  require 'redgreen'
rescue LoadError
  # nice to have, aesthetic, not functional
end

begin
  require 'curb'
rescue LoadError => e
  puts ""
  puts "The Curb library is required for development & testing"
  puts ""
  raise e
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

begin
  require 'simplecov'
  SimpleCov.start
rescue LoadError
  puts "Coverage disabled, enable by installing 'simplecov'"
end

class Test::Unit::TestCase
end

module Test
  module App
    def self.root
      return File.expand_path( File.dirname( File.dirname( __FILE__ ) ) )
    end
  end
end

# test_logger must be loaded before downspout
require 'test_logger'
require 'test_servlet'

# The object of our affections
require 'downspout'
