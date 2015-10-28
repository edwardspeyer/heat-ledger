# Ruby for the BlueTherm Duo

This project provides a library for communicating with an ETI Thermoworks
[BlueTherm  Duo](http://thermometer.co.uk/bluetooth-temperature-probes/1002-bluetooth-thermometer-bluetherm-duo.html)
using a pre-established Bluetooth serial connection.

The code is based on Dan Elbert's
[pi-b-q](https://github.com/DanElbert/pi-b-q/tree/master)
Ruby on Rails project.  I have simplified his code into a rails-independent library provided in a single file.

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

Included in this library is a simple daemon to read T1 and T2 and to `STDOUT`
and/or an SQLite3 database.  Running `bluetooth.rb` directly will run the daemon.
Also included is a systemd service file which will launch the daemon as a
service when it is installed in `/opt/bluetherm/bluetherm.rb`.
