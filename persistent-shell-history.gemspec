# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "persistent-shell-history/version"

Gem::Specification.new do |s|
  s.name        = "persistent-shell-history"
  s.version     = Persistent::Shell::VERSION
  s.authors     = ["Vincent Batts"]
  s.email       = ["vbatts@hashbangbash.com"]
  s.homepage    = ""
  s.summary     = %q{bash shell history collection}
  s.description = %q{
This is a quick job, to have a local database, to collect _all_ commands
from ~/.bash_history
See README for other implementation helpers.
}

  s.rubyforge_project = "persistent-shell-history"
  s.add_dependency("json")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
