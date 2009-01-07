require 'rubygems'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name     = "Helipad"
  s.version  = "1.0.0"
  s.author   = "Lonnon Foster"
  s.email    = "lonnon.foster@gmail.com"
  s.homepage = "http://nyerm.com/helipad"
  s.platform = Gem::Platform::RUBY
  s.summary  = "Ruby interface to the excellent Helipad online notepad"
  s.files    = FileList["{lib,test,doc}/**/*"].to_a
  s.require_path = "lib"
  s.autorequire  = "helipad"
  s.test_file    = "test/test_helipad.rb"
  s.has_rdoc = true
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

desc "Remove all generated files"
task :clobber => [:clobber_rdoc, :clobber_package]

desc "Remove rdoc generated files"
task :clobber_rdoc do |t|
  FileUtils.rm_rf "doc"
end

desc "Build the rdoc HTML files"
task :rdoc do |t|
  sh "rdoc lib --main lib/helipad.rb --title 'Helipad Documentation' --inline-source"
end

desc "Force a rebuild of the rdoc files"
task :rerdoc do |t|
  sh "rdoc lib --main lib/helipad.rb --title 'Helipad Documentation' --inline-source --force-update"
end

desc "Run tests"
task :test, [:email, :password] do |t, args|
  if args.email.nil? or args.password.nil?
    raise(ArgumentError, 'Usage: rake "test[email, password]"', caller)
  end
  sh "ruby test/test_helipad.rb -- #{args.email} #{args.password}"
end

