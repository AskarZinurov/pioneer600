class Dht11
  attr_reader :pin

  class Result < Struct.new(:temperature, :humidity)
  end

  def initialize(pin)
    @pin = pin
  end

  def read
    Bcm2835::GPIO.output pin
    # send initial high
    send_and_sleep(true, 0.018) #0.05
    # pull down to low
    send_and_sleep(false, 0.040) #0.02
    # change to input using pull up
    Bcm2835::GPIO.input pin

    # collect data into an array
    data = collect_input
    # parse lengths of all data pull up periods
    pull_up_lengths = parse_data_pull_up_lengths(data)

    # if bit count mismatch, return error (4 byte data + 1 byte checksum)
    return nil if pull_up_lengths.length != 40

    # we have the bits, calculate bytes
    the_bytes = bits_to_bytes(calculate_bits(pull_up_lengths))

    return nil if the_bytes[4] != calculate_checksum(the_bytes)

    Result.new(bytes_to_f(the_bytes[2], the_bytes[3]), bytes_to_f(the_bytes[0], the_bytes[1]))
  end

  private

  def bytes_to_f(integer, decimal)
    integer + decimal.to_f / 0xFF
  end

  def send_and_sleep(output, time)
    Bcm2835::GPIO.write(pin, output)
    sleep time
  end

  def collect_input
    # collect the data while unchanged found
    unchanged_count = 0

    # this is used to determine where is the end of the data
    max_unchanged_count = 100

    last = -1
    data = []
    while true do
      current = Bcm2835::GPIO.read(pin) ? 1 : 0
      data << current
      if last != current
        unchanged_count = 0
        last = current
      else
        unchanged_count += 1
        break if unchanged_count > max_unchanged_count
       end
     end
    data
  end

  def parse_data_pull_up_lengths(data)
    state = :init_pull_down
    lengths = [] # will contain the lengths of data pull up periods
    current_length = 0 # will contain the length of the previous period

    data.length.times do |i|
      current = data[i]
      current_length += 1

      case state
      when :init_pull_down
        if current == 0
          # ok, we got the initial pull down
          state = :init_pull_up
        end
      when :init_pull_up
        if current == 1
          # ok, we got the initial pull up
          state = :data_first_pull_down
        end
      when :data_first_pull_down
        if current == 0
          # we have the initial pull down, the next will be the data pull up
          state = :data_pull_up
        end
      when :data_pull_up
        if current == 1
          # data pulled up, the length of this pull up will determine whether it is 0 or 1
          current_length = 0
          state = :data_pull_down
        end
      when :data_pull_down
        if current == 0
          # pulled down, we store the length of the previous pull up period
          lengths << current_length
          state = :data_pull_up
         end
       end
    end

    lengths
  end

  def calculate_bits(pull_up_lengths)
    # find shortest and longest period
    shortest_pull_up, longest_pull_up = pull_up_lengths.minmax

    # use the halfway to determine whether the period it is long or short
    halfway = shortest_pull_up + (longest_pull_up - shortest_pull_up) / 2.0

    bits = []
    pull_up_lengths.length.times do |i|
      bit = 0
      if pull_up_lengths[i] > halfway
        bit = 1
       end
      bits << bit
     end
    bits
  end

  def bits_to_bytes(bits)
    bits.each_slice(8).map do |slice|
      slice.join.to_i(2)
     end
  end

  def calculate_checksum(the_bytes)
    (the_bytes[0] + the_bytes[1] + the_bytes[2] + the_bytes[3]) & 255
  end
end
