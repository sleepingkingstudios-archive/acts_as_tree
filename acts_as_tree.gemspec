$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "acts_as_tree/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "acts_as_tree"
  s.version     = SleepingKingStudios::ActsAsTree::VERSION
  s.authors     = ["Rob Smith"]
  s.email       = ["merlin@sleepingkingstudios.com"]
  s.homepage    = "http://www.sleepingkingstudios.com"
  s.summary     = "Model a tree structure for Rails models with parent and child associations"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.1"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-rails"
end # gem specification
