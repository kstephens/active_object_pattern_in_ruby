
task :default => 
  [ 
   :slides,
  ]

task :test do
  sh "ruby example.rb"
end

task :slides => 
  [ 
   'active_object.slides/index.html',
  ]

ENV['SCARLET'] ||= File.expand_path("../../scarlet/bin/scarlet", __FILE__)
ENV['RITERATE'] ||= File.expand_path("../../riterate/bin/riterate", __FILE__)

file 'active_object.slides/index.html' => [ 'active_object.rb', 'example_class.rb', 'examples.rb' ] do
  sh "$RITERATE active_object.rb example_class.rb examples.rb"
end

task :publish => [ :slides ] do
  sh "rsync $RSYNC_OPTS -aruzv --delete-excluded --exclude='.git' --exclude='.riterate' ./ kscom:kurtstephens.com/pub/#{File.basename(File.dirname(__FILE__))}/"
end

task :clean do
  sh "rm -rf *.slides* .riterate"
end




