# BlueTherm Duo Toolkit

This project provides a tools for communicating with an ETI Thermoworks
[BlueTherm  Duo](http://thermometer.co.uk/bluetooth-temperature-probes/1002-bluetooth-thermometer-bluetherm-duo.html)
using a pre-established Bluetooth serial connection.

The Ruby code is based on Dan Elbert's
[pi-b-q](https://github.com/DanElbert/pi-b-q/tree/master)
Ruby on Rails project.  I have simplified his code into a rails-independent
library provided in a single file.

The BlueTherm module provides for three use cases:

## Polling for temperatures

Read temperatures in an infinite loop, every 10 seconds:

```ruby
BlueTherm.poll("/dev/rfcomm0") do |t1, t2|
  puts t1.round(1) # e.g. 20.1
end
```


## Generic polling 

You can make your own connection and poll for any of the data-fields supported
by the BlueTherm.  See `BlueTherm::Field` for details on the available fields.

```ruby
connection = BlueTherm::Connection.new("/dev/rfcomm0")
fields = [
  BlueTherm::Field::BATTERY_TEMPERATURE,
  BlueTherm::Field::BATTERY_LEVEL,
]
connection.poll(fields) do |bt, bl|
  puts bt
  puts bl
end
```


## Individual requests

You can also build and send individual requests.  See `BlueTherm::Command` for
information on other types of commands.

```ruby
connection = BlueTherm::Connection.new("/dev/rfcomm0")
request = BlueTherm::Packet.from_command(BlueTherm::Command::GET)
request.set_data_flags(
  BlueTherm::Field::SERIAL_NUMBER,
  BlueTherm::Field::FIRMWARE_VERSION,
)
response = connection.poll_once(req)
puts response.get(BlueTherm::Field::SERIAL_NUMBER)
puts response.get(BlueTherm::Field::FIRMWARE_VERSION)
```

## Daemon

Included in this library is a simple daemon to read each sensor to `STDOUT`
and optionally to an SQLite3 database.
Running `bluetooth.rb` directly will run the daemon.
It can also be installed as a systemd service on Debian and Ubuntu.
The `install` script automatically installs the daemon and `.service` file.
