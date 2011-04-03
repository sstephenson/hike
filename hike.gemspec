spec = Gem::Specification.new do |s|
  s.name         = "hike"
  s.version      = "0.7.0"
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Sam Stephenson"]
  s.email        = ["sstephenson@gmail.com"]
  s.homepage     = "http://github.com/sstephenson/hike"
  s.summary      = "Find files in a set of paths"
  s.description  = "A Ruby library for finding files in a set of paths."
  s.files        = Dir["lib/**/*.rb"]
  s.require_path = "lib"
end
