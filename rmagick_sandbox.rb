require 'RMagick'
include Magick

conf.return_format = "=> %.512s\n"


out_dir = "/Users/ryandamm/Desktop/RMagick_test"

size = 6400
img = Image.new(size,size) # defaults to 16-bit image


start_time = Time.now
(0...img.columns).each do |x|
  (0...img.rows).each do |y|
    red = x * 65535 / size
    green = y * 65535 / size
    img.pixel_color(x, y, Pixel.new(red, green, 65535/2) )
  end
end
runtime = Time.now - start_time

img.write(out_dir + "/color_test.tiff")
