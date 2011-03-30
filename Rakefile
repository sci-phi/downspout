# Rakefile
require 'rubygems'

$LOAD_PATH.unshift('lib')

require 'rake'
require 'jeweler'

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... 
  # see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "downspout"
  gem.homepage = "http://github.com/sci-phi/downspout"
  gem.license = "MIT"
  gem.summary = %Q{Downspout is an easy-to-use ruby library for downloading files from URLs.}
  gem.description = %Q{Downspout is an easy-to-use ruby library for downloading files from URLs, supporting both HTTP & FTP protocols. HTTP downloads can use either Net::HTTP, or libcurl (via the Curb gem)}
  gem.email = "phi.sanders@sciphi.me"
  gem.authors = ["Phi.Sanders"]
  gem.files = FileList['lib/**/*.rb', '[A-Z]*', 'test/**/*'].to_a
  gem.add_development_dependency "jeweler", "~> 1.5.2"
  gem.add_development_dependency "rcov", ">= 0.9.9"
  gem.add_development_dependency "shoulda", ">= 2.11.3"
  gem.add_development_dependency "mocha", ">= 0.9.12"
  gem.add_development_dependency "curb", ">= 0.7.15"
end
Jeweler::RubygemsDotOrgTasks.new

require 'rdoc'
require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "downspout #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

task :default => :test

namespace :basic do
  desc "Basic Steps to take when updating this gem via GemCutter"
  task :steps do
    puts "rake version:bump:patch"
    puts "rake gemspec"
    puts ">>> write code <<<"
    puts "rake test"
    puts "rake build"
    puts "gem install pkg/downspout-{version}.gem"
    puts ">>> manual tests <<<"
    puts "git commit"
    puts "gem push pkg/downspout-{version}.gem"
  end
end
