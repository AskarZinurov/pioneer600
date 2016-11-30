module Pioneer600::Ssd1306
  class Point
    attr_accessor :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def outside?(area)
      x > area.down_right_point.x ||
        y > area.down_right_point.y
    end
  end
end
