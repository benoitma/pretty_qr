require "pretty_qr/version"
require 'rqrcode-rails3'
require "rmagick"
require 'tempfile'

module PrettyQr

  class QRCodeArgumentError < ArgumentError; end
  class QRCodeRunTimeError < RuntimeError; end

  class QrCode
    attr_reader :original_qr_code, :qr_code, :qr_code_size
    attr_reader :foreground_color, :background_color, :corners_color
    attr_reader :block_size, :image_size
    attr_reader :image, :canvas

    def initialize(string, options = {})
      if !string.is_a? String
        raise QRCodeArgumentError, "The passed data is #{string.class}, not String"
      end

      @original_qr_code       = ::RQRCode::QRCode.new(string , size: minimum_qr_size_from_string(string), level: :h)
      @qr_code_size           = original_qr_code.modules.count

      # Defining the different colors used into the QR code
      @foreground_color       = options[:foreground_color]    || 'black'
      @background_color       = options[:background_color]    || 'white'
      @corners_color          = options[:corners_color]       || self.foreground_color

      # Defining the final block_size and image_size are linked
      if options[:image_size].present? && options[:image_size].is_a?(Fixnum)
        @block_size           = options[:image_size] / qr_code_size
      else
        @block_size           = options[:block_size]          || 16
      end

      # The final image size is defined from the size of a block
      # Not exactly the size provided in the options
      @image_size             = @block_size * qr_code_size

      # We keep in memory the original qr_code
      @qr_code                = @original_qr_code

      # Processing the image to canvas
      self.process
      
    end # initialize

    def process

      @canvas = ::Magick::Draw.new

      switch_color = lambda { |color|
        canvas.stroke(color)
        canvas.fill(color)
      }

      is_dark = lambda { |x, y| 
        begin
          qr_code.is_dark(y,x)
        rescue IndexError, RQRCode::QRCodeRunTimeError
          return false
        end
      }

      # First condition : x or y in the good column or row
      # Second condition : we're not in the bottom right corner
      # Third condition : we're not in the middle
      change_colors_for_black_corners = lambda { |x, y|
        ([0, 6, qr_code_size-1, qr_code_size-7] & [x, y]).count > 0 and  x + y < qr_code_size + 6 and ((7..qr_code_size-8).to_a & [x, y]).count == 0
      }

      # First condition : x or y is 1 or 5
      # Second condition : we're not in the middle
      change_color_for_white_corners = lambda { |x, y|
        ([1, 5] & [x, y]).count > 0 and ((7..qr_code_size-8).to_a & [x, y]).count == 0
      }

      switch_color.call(background_color)
      canvas.rectangle(0, 0, image_size, image_size)
      switch_color.call(foreground_color)
      canvas.fill_opacity(1)
      canvas.stroke_width(1)

      bs = block_size
      hbs = block_size / 3

      qr_code.modules.each_index do |x|
        qr_code.modules.each_index do |y|
          if is_dark.call(x,y)
            switch_color.call(corners_color) if change_colors_for_black_corners.call(x, y)

            canvas.roundrectangle(x * bs, y * bs, (x+1) * bs, (y+1) * bs, hbs, hbs)
            if (is_dark.call(x,y+1))
              canvas.rectangle(x * bs, y * bs + hbs, (x+1) * bs, (y+1) * bs + hbs)
            end
            if (is_dark.call(x+1,y))
              canvas.rectangle(x * bs + hbs, y * bs, (x+1) * bs + hbs, (y+1) * bs)
            end
            switch_color.call(foreground_color)
          end
        end
      end

      qr_code.modules.each_index do |x|
        qr_code.modules.each_index do |y|
          if (not is_dark.call(x,y))
            # I am white

            switch_color.call(corners_color) if change_color_for_white_corners.call(x, y)

            # upper right corner should be round
            if (is_dark.call(x+1,y) and is_dark.call(x,y-1) and is_dark.call(x+1, y-1))
              canvas.rectangle(x * bs + hbs, y * bs, (x+1) * bs, y * bs + hbs)
            end

            # lower right corner should be round
            if (is_dark.call(x+1,y) and is_dark.call(x+1,y+1) and is_dark.call(x, y+1))
              canvas.rectangle(x * bs + hbs, y * bs + hbs, (x+1) * bs, (y+1) * bs)
            end

            # lower left corner should be round
            if (is_dark.call(x-1,y) and is_dark.call(x-1,y+1) and is_dark.call(x, y+1))
              canvas.rectangle(x * bs, y * bs + hbs, x * bs + hbs, (y+1) * bs)
            end

            # upper left corner should be round
            if (is_dark.call(x-1,y-1) and is_dark.call(x-1,y) and is_dark.call(x, y-1))
              canvas.rectangle(x * bs, y * bs, x * bs + hbs, y * bs + hbs)
            end

            switch_color.call(background_color)
            canvas.roundrectangle(x * bs + 1, y * bs + 1, (x+1) * bs - 1, (y+1) * bs - 1, hbs, hbs)
            switch_color.call(foreground_color)

          end
        end
      end
     
    end # process

    def render_to_file(string)
      @image = ::Magick::Image.new(image_size, image_size) do
        self.background_color = 'transparent'
        self.format = "png"
      end

      canvas.draw(image)

      return image.write(string)
    end # render_to_file

    def minimum_qr_size_from_string(str)
      sizes =  [7, 14, 24, 34, 44, 58, 64, 84, 98, 119, 137, 155, 177, 194]
      sizes.each_index do |i|
        if str.length <= sizes[i]
          return i+1
        end
      end
      return -1
    end # minimum_qr_size_from_string

  end # QrCode

end # PrettyQr
