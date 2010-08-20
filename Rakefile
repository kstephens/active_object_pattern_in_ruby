
task :default => 
  [ 
   :slides,
  ]

task :test do
  sh "ruby active_object.rb"
end

task :slides => 
  [ 
   'active_object.slides',
  ]

ENV['SCARLET'] ||= File.expand_path("../../scarlet/bin/scarlet", __FILE__)
ENV['RITERATE'] ||= File.expand_path("../../riterate/bin/riterate", __FILE__)

file 'active_object.slides' => [ 'active_object.rb' ] do
  sh "$RITERATE active_object.rb"
end
