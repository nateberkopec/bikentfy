require "standard/rake"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test_check_rain.rb"]
  t.verbose = true
end

task default: :test
