task :clean do |t|
  FileUtils.rm_rf "doc"
end

task :docs do |t|
  sh "rdoc lib --main lib/helipad.rb --title 'Helipad Documentation' --inline-source --force-update"
end

task :test, [:email, :password] do |t, args|
  if args.email.nil? or args.password.nil?
    raise(ArgumentError, 'Usage: rake "test[email, password]"', caller)
  end
  sh "ruby test/test_helipad.rb -- #{args.email} #{args.password}"
end

