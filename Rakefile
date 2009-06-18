require "erb"
require 'rake/packagetask'

WIDTH = 725
HEIGHT = 480
FPS = 31
PLAYER = 8
BGCOLOR = "#ffffff"
APP = "flvplayer"

def render_template(file)
  filename = File.basename(file).split(".")[0]
  case File.basename(file).split(".")[1]
  when "rhtml"
    extension = "html"
  when "rxml"
    extension = "xml"
  end
  to_file = filename + "." + extension
  puts "Rendering #{file}"
  open(to_file,"w") do |f|
    f << ERB.new(IO.read(file)).result
  end
end

task :assets do
  mkdir_p 'deploy'
  Dir.glob(['assets/*.js','assets/*.xml']).each do |file|
    cp file, "deploy/#{File.basename(file)}", :verbose => true
  end
end

task :compile => [:assets] do
  if @nodebug
    puts "Trace disabled"
    trace = " -trace no"
  else
    trace = ""
  end
  @start = Time.now
  ["*.rhtml","*.rxml"].each do |list|
    Dir[list].each do |tpl|
      render_template(tpl)
    end
  end
  puts %x(swfmill simple #{APP}.xml #{APP}.swf)
  rm "#{APP}.xml", {:verbose => false}
  puts %x(mtasc -strict -swf #{APP}.swf -main -mx -version #{PLAYER} #{trace} #{APP}.as)
  @end = Time.now

  ["*.html","*.swf"].each do |list|
    Dir[list].each do |file|
      mv file, "deploy/#{file}", {:verbose => false}
    end
  end
end

Rake::PackageTask.new(APP, :noversion) do |p|
  p.need_zip = true
  p.name = Time.now.strftime("%Y%m%d") + "-" + APP
  p.package_files.include("README.mdown",'app.rb',Dir["deploy/*"].reject { |file| file.include? 'flv'})
end


task :notify do
  msg = "Finished compiling in #{@end - @start}s."
  if @nodebug
    msg += "\ntrace() disabled"
  end
  %x(growlnotify --name Rake -m '#{msg}' 'Rake')
end


task :nodebug do
  @nodebug = true
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


desc "Test the SWF file in your default browser"
task :test => [:compile] do
  %x(open deploy/index.html)
end



desc "Build a release version of flvplayer (with trace() disabled)"
task :release => [:nodebug,:compile]
task :default => [:compile]
