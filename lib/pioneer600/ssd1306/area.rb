module Pioneer600::Ssd1306
  class Area
    extend Forwardable

    PAGE_SIZE = 8

    attr_reader :top_left_point, :down_right_point

    def_delegator :buffer, :[]

    def initialize(top_left_corner, down_right_corner)
      @top_left_point = top_left_corner
      @down_right_point = down_right_corner
    end

    def rows
      @down_right_point.y - @top_left_point.y + 1
    end

    def columns
      @down_right_point.x - @top_left_point.x + 1
    end

    def page
      top_left_corner.y / PAGE_SIZE
    end

    def pages
      (rows / PAGE_SIZE.to_i).ceil
    end

    def buffer
      @buffer ||= empty_buffer
    end

    def clear
      @buffer = empty_buffer
    end

    def bytes
      buffer.transpose.flatten
    end

    def fill_with_image(image)
  		raise ArgumentError.new('Image must be a chunky image.') unless image.is_a?(ChunkyPNG::Image)

      if image.width != columns || image.height != rows
        raise ArgumentError.new('Image must be same dimensions as display (%d x %d).' % [columns, rows])
      end

      for page in (0...pages) do
        # Iterate through all x axis columns.
        for x in (0...columns) do
          bits = 0
          8.times do |bit|
            bits = bits << 1
            bits |= (image[x, page * 8 + 7 - bit] == ChunkyPNG::Color::BLACK ? 0 : 1)
          end
          buffer[x][page] = bits
        end
      end
      self
    end

    class << self
      def from_image(image, a = Point.new(0, 0))
        b = Point.new(image.width, image.height)
        new(a, b).fill_with_image(image)
      end
    end

    private

    def empty_buffer
      buff = []
      buff << [0] * pages while buff.size < columns
      buff
    end
  end
end
