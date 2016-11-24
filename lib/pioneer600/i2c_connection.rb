require 'i2c'

module Pioneer600
  class I2cConnection
    class << self
      def read(address, command, size = 1, pack = 's>')
        @@socket.read(address, size, command).unpack(pack)
      end

      def write(address, *data)
        @@socket.write(address, *data)
      end

      def read_byte(address)
        @@socket.read_byte(address).unpack('C')
      end

      def establish(bus)
        @@socket ||= I2C.create(bus)
      end

      def close
        @@socket.instance_variable_get(:@device).close
        @@socket = nil
      end
    end
  end
end
