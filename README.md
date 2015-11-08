# Heat Ledger

Heat Ledger is a toolkit for logging temperatures and visualising their
change over time, specifically in the context of smoking, grilling and roasting
meat and poultry.

The main components are:

* `plot-heat-ledger` renders the database graphically in real-time.
* `tail-heat-ledger` prints changes to the database on the command-line.
* `bluethermd` is a daemon for logging temperatures from an ETI Thermoworks
  [BlueTherm Duo](
  http://thermometer.co.uk/bluetooth-temperature-probes/1002-bluetooth-thermometer-bluetherm-duo.html).

![plot-heat-ledger screenshot](/examples/plot.png?raw=true "plot-heat-ledger screenshot")

# Logging Data

Heat Ledger is currently based around logging data from a BlueTherm Duo thermometer
accessed via a Bluetooth serial connection.  The [`bluetherm.rb`](/lib/ruby/bluetherm.rb)
library and [`bluethermd`](/bin/bluethermd) daemon poll the thermometer and log readings
to an SQLite database.

In OS X, once you have paired with your BlueTherm, you can them launch the daemon by pointing
it at the thermometer's device in `/dev`:

    $ bluethermd --device /dev/cu.<BlueTherm-serial-number> --sqlite ~/.bluethermdb.sqlite

Linux pairing is of course very complicated.  I use Debian 8's `bluetoothctl`:

    $ sudo bluetoothctl
    [bluetooth]# agent on
    [bluetooth]# default-agent
    [bluetooth]# power on
    [bluetooth]# scan on
    [CHG] Device 00:06:66:55:55:55 1536555 BlueTherm
    [bluetooth]# pair 00:06:66:55:55:55
    [CHG] Device 00:06:66:72:77:C1 Connected: yes
    [agent] Enter PIN code: 1234
    [bluetooth]# connect 00:06:66:55:55:55   # maybe not needed? throws errors even when working!
    [bluetooth]# ^D

Once you have done the pairing you shouldn't have to pair again, even after rebooting.
However, (re-)creating the serial device does need to be done after every reboot,
and after the first pairing:

    $ sudo rfcomm bind rfcomm0 00:06:66:55:55:55


# I want to write my own logger!

`bluetherm.rb` provides an API that should make
it easy to interact with the BlueTherm Duo.  It is based on the protocol
specification in Dan Elbert's
[pi-b-q](https://github.com/DanElbert/pi-b-q/tree/master)
ruby-on-rails project.

```ruby
#
# Read temperatures in an infinite loop, every 10 seconds:
#
BlueTherm.poll("/dev/rfcomm0") do |t1, t2|
  puts t1.round(1) # e.g. 20.1
end

#
# Make your own connection and poll for custom fields (see BlueTherm::Field):
#
connection = BlueTherm::Connection.new("/dev/rfcomm0")
fields = [
  BlueTherm::Field::BATTERY_TEMPERATURE,
  BlueTherm::Field::BATTERY_LEVEL,
]
connection.poll(fields) do |bt, bl|
  puts bt
  puts bl
end

#
# Build your own packets (see BlueTherm::Command) in order to:
#   * change your BlueTherm's serial number to 31337;
#   * reset your BlueTherm's carefully calibrated sensor circuit; or
#   * render your BlueTherm permanently inoperable.
#
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


# Visualizing Data

`plot-heat-ledger` will plot your most recent cooking session.  It looks for
the most recent continuous set of temperature readings that have no more than an hour's
gap between readings.

Guidelines and estimated cooking times are shown for roasting rare meat, rare and done poultry
and tougher smoking cuts (with connective tissue.)  The model is very simplistic -- currently it is
simply a linear model of the last 5 minutes of data.

`plot-heat-ledger` has a few of dependencies:
the modelling and plotting is done by [R](https://www.r-project.org/)
and the UI itself is rendered with [pygame](https://www.pygame.org/)
and [SDL](https://www.libsdl.org/).
It works in (at least!) OS X and Linux, via the console framebuffer.
Finally, ensure that you have the *Eurostile* font installed on your system
in order to optimize the sci-fi look of `plot-heat-ledger`'s output!

Some example cooking sessions can be found in `examples/`
which can be replayed by `plot-heat-ledger`:

    $ bin/plot-heat-ledger --sqlite examples/roast-chicken.sqlite --speedup 120



## Dependencies for OS X

You can install R by using the [R for Mac OS X](https://cran.r-project.org/bin/macosx/) installer.
If you have [Homebrew](http://brew.sh/) then you can install SDL and python-Mercurial support with:

    $ brew install python3 hg sdl sdl_image sdl_mixer sdl_ttf portmidi

and then pygame with:

    $ pip3 install hg+http://bitbucket.org/pygame/pygame

## Linux Requirements

The following will probably work for any Debian or Ubuntu type distribution.  In any case, you
will want to compile pygame from source if you don't already have it
(the stable release of R (`1.9.1release`) is far too old.)

I put mine in `/opt`:

    # apt-get install r-base
    # apt-get install mercurial
    # apt-get install python3-dev libsdl1.2-dev libsdl-image1.2-dev libsdl-ttf2.0-dev
    # mkdir -p /opt/pygame/src
    # cd /opt/pygame/src
    # hg clone https://bitbucket.org/pygame/pygame
    # cd pygame
    # python3 setup.py install --prefix=/opt/pygame

You can then start the plotter as follows:

    $ sudo env PYTHONPATH=/opt/pygame/lib/python3.4/site-packages bin/plot-heat-ledger

Note in particular that modern Debian installations won't pass environment variables around,
hence the call to `env`.

Make sure you install Eurostile!:

    $ cp ~/Downloads/Eurostile.ttf ~/.fonts/


# License

The MIT License.  The LICENSE file has full license and copyright information.
