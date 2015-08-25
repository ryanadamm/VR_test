require 'RMagick'
include Magick
include Math

conf.return_format = "=> %.512s\n"


out_dir = "/Users/ryandamm/Desktop/FOV_test_5-2015/A6000/A6000_rokinon/distortion_map"

# note that pixels per radian is for full raster
# must apply conversion based on shooting resolution!

def create_rokinon_distortion_map(tilt_offset, output_basename, output_dir)
  output_x = 1920    # output resolution
  output_y = 1080    # output resolution
  max_theta = PI / 2.0    # sets half width of output warp file
# THIS ONLY WORKS WHEN THE OUTPUT IMAGE IS SQUARE!!! SEE LINES BELOW
# THAT USE THIS VALUE FOR AZIMUTH AND POLAR CALCULATION
# changed this so it's 360 in yaw and 180 in pitch, yikes, hardcoded below

  pixels_per_radian = 613.14
  radian_offset = tilt_offset * PI / 180.0
  half_color_value = 32768
  color_scale = 25.0
  x_center, y_center = [output_x/2.0 - 0.5, output_y/2.0 - 0.5]
  img = Image.new(output_x,output_y) # defaults to 16-bit image
  x_size = img.columns
  y_size = img.rows
  (0...x_size).each do |x|
    puts "column:#{x}"
    (0...y_size).each do |y|
      puts "row:#{y}"
      # x, y is the output pixel coordinates
      dx = x - x_center       # find distance from distortion center
      dy = y - y_center
      # convert to angular values in spherical coords
      azimuth = (dx / output_x ) * 4 * max_theta + radian_offset     # fraction of total range, convert from pixels to radians
      polar = (dy / output_y ) * 2 * max_theta
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
      r = theta * pixels_per_radian
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
  # NOTE scale to use in AE is half_color_value / color_scale; in this case ~1311.1
  img.write(output_dir + "/" + output_basename + "_" + tilt_offset + ".tiff")
end


# create_rokinon_distortion_map(-60.0, "tilt_test", out_dir)