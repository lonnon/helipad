begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name     = "Helipad"
    s.author   = "Lonnon Foster"
    s.email    = "lonnon.foster@gmail.com"
    s.homepage = "http://nyerm.com/helipad"
    s.platform = Gem::Platform::RUBY
    s.summary  = "Ruby interface to the excellent Helipad online notepad"
    s.require_path = "lib"
    s.files    = ["lib/helipad.rb"]
    s.test_file    = "test/test_helipad.rb"
    s.has_rdoc     = true
    s.rdoc_options << "--title" << "Helipad Documentation" <<
                      "--main"  << "README" <<
                      "--inline-source"
    s.extra_rdoc_files << "README"
    s.rubyforge_project = "helipad"
  end
rescue LoadError
  puts "Jeweler not available. Install it with:"
  puts "sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

desc "Remove all generated files"
task :clobber => [:clobber_rdoc, :clobber_package]

desc "Remove rdoc generated files"
task :clobber_rdoc do |t|
  FileUtils.rm_rf "doc"
end

desc "Remove generated package"
task :clobber_package do |t|
  FileUtils.rm_rf "pkg"
end

desc "Build the rdoc HTML files"
task :rdoc do |t|
  sh "rdoc #{quote_options(spec.rdoc_options).join(" ")} lib README"
end

desc "Force a rebuild of the rdoc files"
task :rerdoc do |t|
  sh "rdoc #{quote_options(spec.rdoc_options).join(" ")} --force-update lib README"
end

desc "Run tests"
task :test, [:email, :password] do |t, args|
  if args.email.nil? or args.password.nil?
    raise(ArgumentError, 'Usage: rake "test[email, password]"', caller)
  end
  sh "ruby test/test_helipad.rb -- #{args.email} #{args.password}"
end


def quote_options(options)
  options.collect do |option|
    if option =~ /\s/
      %{"#{option}"}
    else
      option
    end
  end
end