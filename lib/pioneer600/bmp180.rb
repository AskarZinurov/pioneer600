module Pioneer600
  class Bmp180 < I2cDevice
    attr_reader :calibration
    attr_accessor :mode

    # BMP085 default address.
    def address
      0x77
    end

    # Operating Modes
    ULTRALOWPOWER     = 0
    STANDARD          = 1
    HIGHRES           = 2
    ULTRAHIGHRES      = 3

    # BMP085 Registers
    CAL_AC1           = 0xAA
    CAL_AC2           = 0xAC
    CAL_AC3           = 0xAE
    CAL_AC4           = 0xB0
    CAL_AC5           = 0xB2
    CAL_AC6           = 0xB4
    CAL_B1            = 0xB6
    CAL_B2            = 0xB8
    CAL_MB            = 0xBA
    CAL_MC            = 0xBC
    CAL_MD            = 0xBE
    CONTROL           = 0xF4
    TEMPDATA          = 0xF6
    PRESSUREDATA      = 0xF6

    # Commands
    READTEMPCMD       = 0x2E
    READPRESSURECMD   = 0x34

    def initialize(mode = STANDARD)
      @mode = mode
      @calibration = {}
      read_calibration
    end

    def read_pressure
      ut = raw_temperature
      up = raw_pressure
      # Datasheet values for debugging:
      #ut = 27898
      #up = 23843

      x1 = ((ut - calibration[:AC6]) * calibration[:AC5]) >> 15
      x2 = (calibration[:MC] << 11) / (x1 + calibration[:MD])
      b5 = x1 + x2

      # Pressure Calculations
      b6 = b5 - 4000
      x1 = (calibration[:B2] * (b6 ** 2) >> 12) >> 11
      x2 = (calibration[:AC2] * b6) >> 11
      x3 = x1 + x2
      b3 = (((calibration[:AC1] * 4 + x3) << mode) + 2) / 4

      x1 = (calibration[:AC3] * b6) >> 13
      x2 = (calibration[:B1] * ((b6 ** 2) >> 12)) >> 16
      x3 = ((x1 + x2) + 2) >> 2
      b4 = (calibration[:AC4] * (x3 + 32768)) >> 15
      b7 = (up - b3) * (50000 >> mode)

      if b7 < 0x80000000
        c = (b7 * 2) / b4
      else
        c = (b7 / b4) * 2
      end

      x1 = (c >> 8) * (c >> 8)
      x1 = (x1 * 3038) >> 16
      x2 = (-7357 * c) >> 16

      c + ((x1 + x2 + 3791) >> 4)
    end

    def read_altitude(sealevel_pa = 101325.0)
  		44330.0 * (1.0 - (read_pressure.to_f / sealevel_pa) ** (1.0 / 5.255))
    end

    def read_sealevel_pressure(altitude_m = 0.0)
  		read_pressure.to_f / ((1.0 - altitude_m / 44330.0) ** 5.255)
    end

    def read_temperature
      raw = raw_temperature
      x1 = ((raw - calibration[:AC6]) * calibration[:AC5]) >> 15
  		x2 = (calibration[:MC] << 11) / (x1 + calibration[:MD])
  		b5 = x1 + x2
  		((b5 + 8) >> 4) / 10.0
    end

    def read_calibration
      calibration[:AC1] = read(CAL_AC1, 2)   # INT16
  		calibration[:AC2] = read(CAL_AC2, 2)   # INT16
  		calibration[:AC3] = read(CAL_AC3, 2)   # INT16
  		calibration[:AC4] = read(CAL_AC4, 2, 'S>')   # UINT16
  		calibration[:AC5] = read(CAL_AC5, 2, 'S>')   # UINT16
  		calibration[:AC6] = read(CAL_AC6, 2, 'S>')   # UINT16
  		calibration[:B1]  = read(CAL_B1, 2)     # INT16
  		calibration[:B2]  = read(CAL_B2, 2)     # INT16
  		calibration[:MB]  = read(CAL_MB, 2)     # INT16
  		calibration[:MC]  = read(CAL_MC, 2)     # INT16
  		calibration[:MD]  = read(CAL_MD, 2)     # INT16
      calibration
    end

    def raw_temperature
      write(CONTROL, READTEMPCMD)
      sleep 0.005
      read(TEMPDATA, 2, 'S>')
    end

    def raw_pressure
      write(CONTROL, READPRESSURECMD + (mode << 6))
      sleep({ ULTRALOWPOWER => 0.005, HIGHRES => 0.014, ULTRAHIGHRES => 0.026 }[mode] || 0.008)
      read(PRESSUREDATA, 3, 'C*') >> (8 - mode)
    end
  end
end
