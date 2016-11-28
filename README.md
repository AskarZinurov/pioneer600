# Pioneer600

Swiss knife ruby tool for http://www.waveshare.com/wiki/Pioneer600.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pioneer600'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pioneer600

## Usage

```ruby
require 'pioneer600'

# Pressure - Temperature
Pioneer600::I2cConnection.establish('/dev/i2c-1')

b = Pioneer600::Bmp180.new
b.read_temperature
b.read_pressure

# Beeper
p = Pioneer600::Pcf8574.new
p.beep_on
p.beep_off

p.led2_on
p.led2_off

# Pin - GPIO pins manipulation
pin = Pioneer600::Pin.new(26) # led1
pin.direction!(:out)
pin.write 1
pin.read
pin.close
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/AskarZinurov/pioneer600.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
