require "fluby"
require 'rake/packagetask'

Rake::PackageTask.new("flvplayer", :noversion) do |p|
  p.need_zip = true
  p.name = Time.now.strftime("%Y%m%d") + "-" + "flvplayer"
  p.package_files.include("README.mdown",'app.rb',Dir["deploy/*"].reject { |file| file.include? '.flv'})
  p.package_files.exclude(".DS_Store")
end

task :monitor do
  command = "rake"
  files = {}

  Dir["*.as","*.rxml","*.rhtml","Rakefile"].each { |file|
    files[file] = File.mtime(file)
  }

  loop do
    sleep 1
    changed_file, last_changed = files.find { |file, last_changed|
      File.mtime(file) > last_changed
    }
    if changed_file
      files[changed_file] = File.mtime(changed_file)
      puts "=> #{changed_file} changed, running #{command}"
      system(command)
      puts "=> done"
    end
  end
end

task :test => [:build] do
  %x(open deploy/index.html)
end

desc "Build flvplayer"
task :build do
  system('fluby build')
end

desc "Build a release version of flvplayer (with trace() disabled)"
task :release do
  system('fluby release')
  system('rake package')
end

task :default => [:build]