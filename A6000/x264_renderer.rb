def x264_renderer

  puts "enter input dir:"
  input_dir = gets.chomp!

  input_files = Dir.entries(input_dir)
  input_files.delete_if {|x| !x.include?(".mov") }
  input_files.map! {|x| input_dir + "/" + x }

  input_files.each do |input_filename|
    output_pathname = input_filename.gsub("mov","mp4")
    `ffmpeg -i #{input_filename} -c:v libx264 -b:v 40000k -pix_fmt yuv420p -an #{output_pathname}`
  end

  puts "all done compressing...."
end