require 'RMagick'
include Magick
include Math

conf.return_format = "=> %.512s\n"


out_dir = "/Users/ryandamm/Desktop/FOV_test_5-2015/A6000/distortion_maps"

X_RES = 1440
Y_RES = 1920
IMAGE_CENTER = [X_RES/2.0 - 0.5, Y_RES/2.0 - 0.5]    # 0.5 pix offset because it's even, minus because it's zero indexed



OUTPUT_X = 1440    # output resolution
OUTPUT_Y = 1920    # output resolution
MAX_THETA = PI / 2.0    # sets half width of output warp file
MAX_X_DISPLACEMENT = 1000.0
MAX_Y_DISPLACEMENT = 1000.0

PIXELS_PER_RADIAN = 1870.2
# note that pixels per radian is for full raster
# must apply conversion based on shooting resolution!

pixel_scale = 0.48   # this is for 1440 only! adjust based on shooting input

half_color_value = 32768
color_scale = 25.0


x_center, y_center = [X_RES/2.0 - 0.5, Y_RES/2.0 - 0.5]



img = Image.new(X_RES,Y_RES) # defaults to 16-bit image

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
    r = theta * PIXELS_PER_RADIAN * pixel_scale
    if theta > MAX_THETA
      img.pixel_color(x,y, Pixel.new(half_color_value, half_color_value, half_color_value) )
      next
    end
    input_x = x_center + r * cos(psi)
    input_y = y_center + r * sin(psi)
    delta_x = x - input_x
    delta_y = y - input_y
    max_delta_x = delta_x > max_delta_x ? delta_x : max_delta_x
    min_delta_x = delta_x < min_delta_x ? delta_x : min_delta_x
    max_delta_y = delta_y > max_delta_y ? delta_y : max_delta_y
    min_delta_y = delta_y < min_delta_y ? delta_y : min_delta_y
    red = color_scale * delta_x + half_color_value
    green = color_scale * delta_y + half_color_value
    img.pixel_color(x, y, Pixel.new(red, green, half_color_value) )
  end
end
runtime = Time.now - start_time

# NOTE scale to use in AE is half_color_value / color_scale; in this case ~1311.1

img.write(out_dir + "/vert_color_test.tiff")


runtime = Time.now - start_time
