# -*- encoding: utf-8 -*-
require File.expand_path('../lib/downspout/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "downspout"
  gem.license       = "MIT"
  gem.authors       = ["Phi.Sanders"]
  gem.email         = ["phi.sanders@sciphi.me"]
  gem.homepage      = "http://github.com/sci-phi/downspout"
  gem.summary       = %Q{Downspout is an easy-to-use ruby library for downloading files from URLs.}
  gem.description   = %Q{Downspout is an easy-to-use ruby library for downloading files from URLs, supporting both HTTP & FTP protocols. HTTP downloads can use either Net::HTTP, or libcurl (via the Curb gem)}

  #gem.files        = FileList['lib/**/*.rb', '[A-Z]*', 'test/**/*'].to_a
  gem.files         = `git ls-files`.split($\)

  gem.require_paths = ["lib"]

  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})

  gem.version       = Downspout::VERSION

  gem.add_development_dependency "rake", ">= 0.9.6"
  gem.add_development_dependency "rdoc", ">= 2.4.2"
  gem.add_development_dependency "shoulda", ">= 2.11.3"
  gem.add_development_dependency "mocha", ">= 0.9.12"
  gem.add_development_dependency "curb", ">= 0.7.15"
  gem.add_development_dependency "simplecov"
end
