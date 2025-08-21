$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "limited_sessions/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "limited_sessions"
  spec.version     = LimitedSessions::VERSION
  spec.authors     = ["t.e.morgan"]
  spec.email       = ["tm@iprog.com"]
  spec.homepage    = "https://iprog.com/projects#limited_sessions"
  spec.summary     = "Server-side session expiry via either Rack Middleware or ActiveRecord extension"
  spec.description = "LimitedSessions provides two core features to handle cookie-based session expiry: 1) Rack Middleware for most session stores and 2) an ActiveRecord extension for AR-based session stores. Sessions can be expired on inactivity and/or overall session length. Works with and without Rails."
  spec.license     = 'MIT'

  spec.metadata = {
    'source_code_uri' => 'https://github.com/zarqman/limited_sessions',
    'changelog_uri' => 'https://github.com/zarqman/limited_sessions/blob/master/CHANGELOG.md'
  }

  spec.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE.txt", "Rakefile", "README.md", "CHANGELOG.md"]
  spec.test_files = Dir["test/**/*"]

  spec.add_dependency 'rack', '>= 2.0.9', '< 4'

  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'rails', '>= 5.2', '< 8.1'
end
