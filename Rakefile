task :test, [:email, :password] do |t, args|
  sh "ruby test/test_helipad.rb -- #{args.email} #{args.password}"
end

task :docs do |t|
  sh "rdoc lib --main lib/helipad.rb --title 'Helipad Documentation' --inline-source --force-update"
end