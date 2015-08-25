require 'RMagick'
include Magick
include Math

conf.return_format = "=> %.512s\n"


out_dir = "/Users/ryandamm/Desktop/FOV_test_5-2015/A6000/A6000_rokinon/distortion_map"

OUTPUT_X = 1080    # output resolution
OUTPUT_Y = 1080    # output resolution
MAX_THETA = PI / 2.0    # sets half width of output warp file
# THIS ONLY WORKS WHEN THE OUTPUT IMAGE IS SQUARE!!! SEE LINES BELOW
# THAT USE THIS VALUE FOR AZIMUTH AND POLAR CALCULATION
MAX_X_DISPLACEMENT = 1000.0
MAX_Y_DISPLACEMENT = 1000.0

PIXELS_PER_RADIAN = 613.14
# note that pixels per radian is for full raster
# must apply conversion based on shooting resolution!



half_color_value = 32768
color_scale = 25.0


x_center, y_center = [OUTPUT_X/2.0 - 0.5, OUTPUT_Y/2.0 - 0.5]



img = Image.new(OUTPUT_X,OUTPUT_Y) # defaults to 16-bit image

max_delta_x = 0.0
min_delta_x = 0.0
max_delta_y = 0.0
min_delta_y = 0.0

x_size = img.columns
y_size = img.rows
start_time = Time.now
(0...x_size).each do |x|
  puts "column:#{x}"
  (0...y_size).each do |y|
    # x, y is the output pixel coordinates
    dx = x - x_center       # find distance from distortion center
    dy = y - y_center
    # convert to angular values in spherical coords
    azimuth = (dx / OUTPUT_X ) * 2 * MAX_THETA     # fraction of total range, convert from pixels to radians
    polar = (dy / OUTPUT_Y ) * 2 * MAX_THETA
    # convert to 3D cartesian space
    # point is unit vector at x,y,z
    # on surface of unit sphere
    # x vector is azimuth = PI/2 polar = 0
    # y vector is azimuth = 0 polar = 0
    # z vector is polar = PI/2
    cart_x = sin(azimuth) * cos(polar)
    cart_y = cos(azimuth) * cos(polar)
    cart_z = sin(polar)
    # calculate pixel coords in fisheye space
    psi = atan2(cart_z, cart_x)
    x_z_hyp = sqrt(cart_x**2 + cart_z**2)
    theta = atan(x_z_hyp/cart_y)
    # calculate pixels / degree
    # this is where fisheye distortion equation matters
    # we're using an equisolid angle projection, though
    # so it's linear
    r = theta * PIXELS_PER_RADIAN
    if theta > MAX_THETA
      img.pixel_color(x,y, Pixel.new(half_color_value, half_color_value, half_color_value) )
      next
    end
    input_x = x_center + r * cos(psi)  # note that using x_center / y_center implies source image is centered
    input_y = y_center + r * sin(psi)  # makes no assumptions about absolute source resolution, though
    delta_x = x - input_x
    delta_y = y - input_y
    # max calculation values for debugging
    max_delta_x = delta_x > max_delta_x ? delta_x : max_delta_x
    min_delta_x = delta_x < min_delta_x ? delta_x : min_delta_x
    max_delta_y = delta_y > max_delta_y ? delta_y : max_delta_y
    min_delta_y = delta_y < min_delta_y ? delta_y : min_delta_y
    # color calculations
    red = color_scale * delta_x + half_color_value
    green = color_scale * delta_y + half_color_value
    img.pixel_color(x, y, Pixel.new(red, green, half_color_value) )
  end
end
runtime = Time.now - start_time

# NOTE scale to use in AE is half_color_value / color_scale; in this case ~1311.1

img.write(out_dir + "/a6000_rokinon.tiff")


runtime = Time.now - start_time
