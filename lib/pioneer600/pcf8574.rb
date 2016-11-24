module Pioneer600
  class Pcf8574 < I2cDevice
    def address
      0x20
    end

    def beep_on
      write(0x7F & read_byte)
    end

    def beep_off
      write(0x80 | read_byte)
    end

    def led2_on
      write(0xEF & read_byte)
    end

    def led2_off
      write(0x10 | read_byte)
    end
  end
end
