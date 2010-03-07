require 'rubygems' unless ENV['NO_RUBYGEMS']
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'
require 'spec/rake/spectask'

spec = Gem::Specification.new do |s|
  s.name = "rubots"
  s.version = "0.0.1"
  s.author = "Jordi Polo"
  s.email = "mumismo@gmail.com"
  s.homepage = "http://rubots.blogspot.com"
  s.description = s.summary = "Rubots: a programming game for robots"
  
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE", 'TODO']
  
  # Uncomment this to add a dependency
  # s.add_dependency "foo"
  
  s.require_path = 'lib'
  s.files = %w(LICENSE README Rakefile TODO) + Dir.glob("{lib,spec}/**/*")
end

task :default => :spec

desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = %w(-fs --color)
end


Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end


desc "generate classes from UI files"
task :ui do
 sh %{rbuic4 ./lib/rubots/gameconfigui.ui -o ./lib/rubots/gameconfiggui.rb}
 sh %{rbuic4 ./lib/rubots/gameoverui.ui -o ./lib/rubots/gameoverui.rb}
end


desc "run rubots"
task :run do
  sh %{ruby lib/rubots.rb}
end
