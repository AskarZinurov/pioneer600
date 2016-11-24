module Pioneer600
  class Pin
    EXPORT_PATH = '/sys/class/gpio/export'
    UNEXPORT_PATH = '/sys/class/gpio/unexport'
    PIN_PATH = '/sys/class/gpio/gpio'

    attr_reader :address, :direction

    def initialize(address, direction = :out)
      @address = address
      @direction = direction

      Pin.open address
    end

    def close
      Pin.close(address)
    end

    def write(value)
      IO.write(value_path, value)
    end

    def read
      IO.read(value_path).to_i
    end

    def set_direction!(new_direction = nil)
      @direction = new_direction if new_direction
      IO.write(File.join(path, 'direction'), direction.to_s)
      direction
    end

    class << self
      def open(address)
        IO.write(EXPORT_PATH, address)
      end

      def close(address)
        IO.write(UNEXPORT_PATH, address)
      end
    end

    private

    def value_path
      File.join(path, 'value')
    end

    def path
      PIN_PATH + address.to_s
    end
  end
end
