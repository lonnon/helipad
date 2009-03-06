require 'rubygems'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name     = "Helipad"
  s.version  = "0.0.1"
  s.author   = "Lonnon Foster"
  s.email    = "lonnon.foster@gmail.com"
  s.homepage = "http://nyerm.com/helipad"
  s.platform = Gem::Platform::RUBY
  s.summary  = "Ruby interface to the excellent Helipad online notepad"
  s.files    = FileList["{lib,test}/**/*", "README"].to_a
  s.require_path = "lib"
  s.test_file    = "test/test_helipad.rb"
  s.has_rdoc     = true
  s.rdoc_options << "--title" << "Helipad Documentation" <<
                    "--main"  << "README" <<
                    "--inline-source"
  s.extra_rdoc_files << "README"
  s.rubyforge_project = "helipad"
  s.signing_key = "/Volumes/STUFF/gem-certs/gem-private_key.pem"
  s.cert_chain  = "/Volumes/STUFF/gem-certs/gem-public_cert.pem"
end
