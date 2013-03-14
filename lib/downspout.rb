#require 'rubygems'

# common dependencies
require 'fileutils'
require 'uri'
require 'net/http'
require 'net/https'
require 'net/ftp'

# customized logger
require 'downspout/logger'

# required components
require 'downspout/base'
require 'downspout/config'
require 'downspout/credential'
require 'downspout/tmp_file'
require 'downspout/downloader'
