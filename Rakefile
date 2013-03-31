require "bundler/gem_tasks"
require 'rake/testtask'
require 'rubygems/package_task'

task :default => :test
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = true
  t.verbose = true
end

namespace :test do
  Rake::TestTask.new(:isolated) do |t|
    t.pattern = 'test/ts_isolated.rb'
  end
end

