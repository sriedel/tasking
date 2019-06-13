Gem::Specification.new do |s|
  s.version = "0.1.0"
  s.author = "Sven Riedel"
  s.files = %w[ README.rdoc ] +
             Dir.glob( "bin/**/*" ) +
             Dir.glob( "lib/**/*" )
  s.name = "sideq"
  s.bindir = "bin"
  s.executables = []

  s.platform = Gem::Platform::RUBY
  s.require_paths = [ "lib" ]
  s.summary = "A lightweight task runner DSL"
  s.email = "sr@gimp.org"
  s.homepage = "https://github.com/sriedel/tasker"
  s.description = "A lightweight DSL for task definition and execution"
  s.licenses = [ "GPL-2.0" ]

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-its'
end
