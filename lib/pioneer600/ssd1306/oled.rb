module Pioneer600::Ssd1306
  class Oled
    SETCONTRAST = 0x81
    DISPLAYALLON_RESUME = 0xA4
    DISPLAYALLON = 0xA5
    NORMALDISPLAY = 0xA6
    INVERTDISPLAY = 0xA7
    DISPLAYOFF = 0xAE
    DISPLAYON = 0xAF
    SETDISPLAYOFFSET = 0xD3
    SETCOMPINS = 0xDA
    SETVCOMDETECT = 0xDB
    SETDISPLAYCLOCKDIV = 0xD5
    SETPRECHARGE = 0xD9
    SETMULTIPLEX = 0xA8
    SETLOWCOLUMN = 0x00
    SETHIGHCOLUMN = 0x10
    SETSTARTLINE = 0x40
    MEMORYMODE = 0x20
    COLUMNADDR = 0x21
    PAGEADDR = 0x22
    COMSCANINC = 0xC0
    COMSCANDEC = 0xC8
    SEGREMAP = 0xA0
    CHARGEPUMP = 0x8D
    EXTERNALVCC = 0x1
    SWITCHCAPVCC = 0x2

    # Scrolling constants
    ACTIVATE_SCROLL = 0x2F
    DEACTIVATE_SCROLL = 0x2E
    SET_VERTICAL_SCROLL_AREA = 0xA3
    RIGHT_HORIZONTAL_SCROLL = 0x26
    LEFT_HORIZONTAL_SCROLL = 0x27
    VERTICAL_AND_RIGHT_HORIZONTAL_SCROLL = 0x29
    VERTICAL_AND_LEFT_HORIZONTAL_SCROLL = 0x2A

    attr_reader :rst, :dc, :spi

    def initialize(rst, dc, spi)
      @width = 128
      @height = 64
      @pages = 8
      @buffer = [0] * (@width * @pages)
      @dc = dc
      @rst = rst
      @spi = spi

      #GPIO.setmode(GPIO.BCM)
      #GPIO.setwarnings(False)
      Bcm2835::GPIO.output(dc)
      Bcm2835::GPIO.output(rst)
    end

    # Send command byte to display
    def command(cmd)
  		Bcm2835::GPIO.write(dc, false)
  		spi.write(cmd)
    end

    # Send byte of data to display
    def data(val)
  		Bcm2835::GPIO.write(dc, true)
  		spi.write(val)
    end

    # Initialize dispaly
    def begin(vccstate = SWITCHCAPVCC)
      @vccstate = vccstate
      reset
      command(DISPLAYOFF)                    # 0xAE
      command(SETDISPLAYCLOCKDIV)            # 0xD5
      command(0x80)                          # the suggested ratio 0x80
      command(SETMULTIPLEX)                  # 0xA8
      command(0x3F)
      command(SETDISPLAYOFFSET)              # 0xD3
      command(0x0)                           # no offset
      command(SETSTARTLINE | 0x0)            # line #0
      command(CHARGEPUMP)                    # 0x8D
      @vccstate == EXTERNALVCC ? command(0x10) : command(0x14)
      command(MEMORYMODE)                    # 0x20
      command(0x00)                          # 0x0 act like ks0108
      command(SEGREMAP | 0x1)
      command(COMSCANDEC)
      command(SETCOMPINS)                    # 0xDA
      command(0x12)
      command(SETCONTRAST)                   # 0x81
      @vccstate == EXTERNALVCC ? command(0x9F) : command(0xCF)
      command(SETPRECHARGE)                  # 0xd9
      @vccstate == EXTERNALVCC ? command(0x22) : command(0xF1)
      command(SETVCOMDETECT)                 # 0xDB
      command(0x40)
      command(DISPLAYALLON_RESUME)           # 0xA4
      command(NORMALDISPLAY)                 # 0xA6
      command(DISPLAYON)
    end

    # Reset the display
    def reset
      Bcm2835::GPIO.write(rst, true)
      sleep 0.001
      Bcm2835::GPIO.write(rst, false)
      sleep 0.010
      Bcm2835::GPIO.write(rst, true)
    end

    # Write display buffer to physical display
    def display(column: 0, page: 0)
      command(COLUMNADDR)
      command(column)                  #Cloumn start address
      command(@width - 1)         #Cloumn end address
      command(PAGEADDR)
      command(page)                  #Page start address
      command(@pages - 1)         #Page end address
      #Write buffer data
      Bcm2835::GPIO.write(dc, true)
      spi.write(@buffer)
    end

    def write(font, text)
      @buffer = []
      text.split(//).each do |ch|
        @buffer << font[ch]
      end
    end

    def image(image)
  		raise ArgumentError.new('Image must be a chunky image.') unless image.is_a?(ChunkyPNG::Image)

      if image.width != @width || image.height != @height
        raise ArgumentError.new('Image must be same dimensions as display (%d x %d).' % [@width, @height])
      end

      @buffer = []
      for page in (0...@pages) do
        # Iterate through all x axis columns.
        for x in (0...@width) do
          bits = 0
          8.times do |bit|
            bits = bits << 1
            bits |= (image[x, page * 8 + 7 - bit] == ChunkyPNG::Color::BLACK ? 0 : 1)
          end
          @buffer << bits
        end
      end
    end

    # Clear contents of image buffer
    def clear
      @buffer = [0] * (@width * @pages)
    end

    def clear!
      clear
      display
    end

    # Sets the contrast of the display.
    # Contrast should be a value between 0 and 255.
    def set_contrast(contrast)
      raise ArgumentError('Contrast must be a value from 0 to 255.') if contrast < 0 || contrast > 255
      command(SETCONTRAST)
      command(contrast)
    end

    # Adjusts contrast to dim the display if dim is True,
    # otherwise sets the contrast to normal brightness if dim is False.
    def dim(dim)
      # Assume dim display.
      contrast = 0
      # Adjust contrast based on VCC if not dimming.
      if !dim
        if @vccstate == EXTERNALVCC
          contrast = 0x9F
        else
          contrast = 0xCF
        end
      end
    end
  end
end
