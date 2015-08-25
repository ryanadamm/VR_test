
def avchd_converter

  puts "enter input dir:"
  input_dir = gets.chomp!
  dir_name = File.basename(input_dir)

  puts "enter output dir:"
  output_dir = gets.chomp!


  ts_folder = input_dir + '/BDMV/STREAM/'
  input_files = Dir.entries(ts_folder)
  input_files.delete_if {|x| !x.include?("MTS") }

  Dir.chdir(ts_folder)
  input_files.each do |input_filename|
    output_filename = dir_name + "_" + input_filename.gsub("MTS","mp4")
    output_pathname = output_dir + "/" + output_filename
    `ffmpeg -i #{input_filename} -vcodec copy -acodec copy #{output_pathname}`
  end

  puts "all done rewrapping...."
end