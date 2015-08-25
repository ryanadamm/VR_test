require 'RMagick'
include Magick
include Math

conf.return_format = "=> %.512s\n"


out_dir = "/Users/ryandamm/Desktop/RMagick_test"

X_RES = 3840
Y_RES = 3840
IMAGE_CENTER = [X_RES/2.0 - 0.5, Y_RES/2.0 - 0.5]    # 0.5 pix offset because it's even, minus because it's zero indexed
PIXEL_SIZE = 0.00625    # in mm, always in mm / pixel
FOCAL_LENGTH = 8.0      # also in mm
OUTPUT_X = 3840
OUTPUT_Y = 3840
MAX_THETA = PI / 2.0
MAX_X_DISPLACEMENT = 1000.0
MAX_Y_DISPLACEMENT = 1000.0
PIXELS_PER_RADIAN = 3840.0 / PI



# derived values from constants above

x_center = IMAGE_CENTER[0]
y_center = IMAGE_CENTER[1]

x_output_scale = OUTPUT_X / (2.0 * MAX_THETA) # divided by two because range is min to max
y_output_scale = OUTPUT_Y / (2.0 * MAX_THETA) # unit is pixels / radians

red_scale = 10 * 65535.0 / (2.0 * MAX_X_DISPLACEMENT)
green_scale = 10 * 65535.0 / (2.0 * MAX_Y_DISPLACEMENT)


color_scale = 25.0

half_color_value = 32768
max_color_value = 65535.0
min_color_value = 0.0


def radians_to_degrees(radians)
  radians * 180 / PI
end


# distortion equation for lens:
# r = FOCAL_LENGTH * theta
# r is in mm, theta is in radians
# from here: http://wiki.panotools.org/Fisheye_Projection
# solving for theta:
# theta = r / FOCAL_LENGTH (both in mm)

# this is backwards; the image starts with output pixel and 'finds' input pixel

img = Image.new(X_RES,Y_RES) # defaults to 16-bit image

x_size = img.columns
y_size = img.rows
start_time = Time.now
(0...x_size).each do |x|
  puts "row:#{x}"
  (0...y_size).each do |y|
    dx = x - x_center       # find distance from distortion center
    dy = y - y_center
    r = sqrt(dx**2 + dy**2)    # r in pixels
    r_in_mm = r * PIXEL_SIZE
    theta = r_in_mm / FOCAL_LENGTH
    if theta > MAX_THETA
      img.pixel_color(x,y, Pixel.new(half_color_value, half_color_value, 0.0) )
      # all pixels outside of range set to gray
      next
    end
    # not entirely certain of this next transform!
    # I think it's just similar triangles in the rotation space
    # but, uh, not sure it's euclidean, frankly
    azimuth = theta * dx / r
    polar = theta * dy / r
    raw_x_out = azimuth * x_output_scale + x_center
    raw_y_out = polar * y_output_scale + y_center
    x_diff = raw_x_out - x
    y_diff = raw_y_out - y
    red = red_scale * x_diff + half_color_value
    green = green_scale * y_diff + half_color_value
    img.pixel_color(raw_x_out, raw_y_out, Pixel.new(red, green, half_color_value) )
  end
end

img.write(out_dir + "/color_test.tiff")


runtime = Time.now - start_time



####### for rapid testing ##########



def test(x,y)
  x_center = IMAGE_CENTER[0]
  y_center = IMAGE_CENTER[1]
  x_output_scale = OUTPUT_X / (2.0 * MAX_THETA) # divided by two because range is min to max
  y_output_scale = OUTPUT_Y / (2.0 * MAX_THETA) # unit is pixels / radians

  red_scale = 65535.0 / (2.0 * MAX_X_DISPLACEMENT)
  green_scale = 65535.0 / (2.0 * MAX_Y_DISPLACEMENT)
  half_color_value = 32768
  max_color_value = 65535.0
  min_color_value = 0.0


  dx = x - x_center       # find distance from distortion center
  dy = y - y_center
  r = sqrt(dx**2 + dy**2)    # r in pixels
  r_in_mm = r * PIXEL_SIZE
  theta = r_in_mm / FOCAL_LENGTH
  if theta > MAX_THETA
    puts "theta > MAX_THETA; #{theta}"
    return
  end
  # not entirely certain of this next transform!
  # I think it's just similar triangles in the rotation space
  # but, uh, not sure it's euclidean, frankly
  azimuth = theta * dx / r
  polar = theta * dy / r
  puts "azimuth: #{azimuth}\npolar: #{polar}"
  raw_x_out = azimuth * x_output_scale + x_center
  raw_y_out = polar * y_output_scale + y_center
  puts "raw x out #{raw_x_out}"
  puts "raw y out #{raw_y_out}"
  x_diff = raw_x_out - x
  y_diff = raw_y_out - y
  red = red_scale * x_diff + half_color_value
  green = green_scale * y_diff + half_color_value
  puts "red: #{red}\ngreen:#{green}"
end



###################


img = Image.new(X_RES,Y_RES) # defaults to 16-bit image

x_size = img.columns
y_size = img.rows
start_time = Time.now
(0...x_size).each do |x|
  puts "row:#{x}"
  (0...y_size).each do |y|
    dx = x - x_center       # find distance from distortion center
    dy = y - y_center
    # convert to angular values in spherical coords
    azimuth = (dx / OUTPUT_X ) * PI     # fraction of total range, convert from pixels to radians
    polar = (dy / OUTPUT_Y ) * PI
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
    input_x = x_center + r * cos(psi)
    input_y = y_center + r * sin(psi)
    delta_x = x - input_x
    delta_y = y - input_y
    red = color_scale * delta_x + half_color_value
    green = color_scale * delta_y + half_color_value
    img.pixel_color(x, y, Pixel.new(red, green, half_color_value) )
  end
end

img.write(out_dir + "/color_test.tiff")


runtime = Time.now - start_time

# NOTE scale to use in AE is half_color_value / color_scale; in this case ~1311.1