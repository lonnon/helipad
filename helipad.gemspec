# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{Helipad}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lonnon Foster"]
  s.date = %q{2009-03-06}
  s.email = %q{lonnon.foster@gmail.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["lib/helipad.rb", "test/test_helipad.rb", "README"]
  s.has_rdoc = true
  s.homepage = %q{http://nyerm.com/helipad}
  s.rdoc_options = ["--title", "Helipad Documentation", "--main", "README", "--inline-source", "--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{helipad}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Ruby interface to the excellent Helipad online notepad}
  s.test_files = ["test/test_helipad.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
