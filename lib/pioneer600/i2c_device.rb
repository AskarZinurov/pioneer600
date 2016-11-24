module Pioneer600
  class I2cDevice
    def address
      raise NotImplementedError
    end

    protected

    def read_byte
      parse I2cConnection.read_byte(address)
    end

    def read(*args)
      parse I2cConnection.read(address, *args)
    end

    def write(*args)
      I2cConnection.write address, *args
    end

    private

    def parse(bytes)
      bytes.inject { |r, n| r << 8 | n }
    end
  end
end
