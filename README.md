# Heat Ledger

Heat Ledger is a toolkit for logging temperatures and visualising their
change over time, specifically in the context of smoking, grilling and roasting
meat and poultry.

The main components are:

* `bluethermd`: logs temperatures from a
  [BlueTherm Duo](
  http://thermometer.co.uk/bluetooth-temperature-probes/1002-bluetooth-thermometer-bluetherm-duo.html)
  to Heat Ledger's database.
* `plot-heat-ledger`: renders the database graphically, in real-time.
* `tail-heat-ledger`: watches the database for changes, and prints them to STDOUT.


![plot-heat-ledger screenshot](/examples/plot.png?raw=true "plot-heat-ledger screenshot")

# Logging Data

Heat Ledger is currently based around logging data from a BlueTherm Duo thermometer, 
accessing it via a Bluetooth serial connection.
The [`bluethermd`](/bin/bluethermd) daemon polls the thermometer and logs readings
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

Once you have paired with your BlueTherm Duo you shouldn't ever have to
pair again, even after a reboot.
However, after the first pairing and after every reboot you *will* have to 
set up the serial connnection again, using the following call to `rfcomm`:

    $ sudo rfcomm bind rfcomm0 00:06:66:55:55:55


## I want to write my own logger!

[`bluetherm.rb`](/lib/ruby/bluetherm.rb) provides an API that makes
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

`plot-heat-ledger` works fine in OS X and Linux, but it has a few of dependencies:
* the modelling and plotting is done by [R](https://www.r-project.org/);
* the UI is rendered with [pygame](https://www.pygame.org/);
* while not necessary, you will want the *Eurostile* font for making your dashboard look super sci-fi!

Some example cooking sessions can be found in `examples/`
and these can be replayed by `plot-heat-ledger` to test everything is working:

    $ bin/plot-heat-ledger --sqlite examples/roast-chicken.sqlite --speedup 120



## Dependencies for OS X

You can install R by using the [R for Mac OS X](https://cran.r-project.org/bin/macosx/) installer.
If you have [Homebrew](http://brew.sh/) then you can first install SDL and python-Mercurial support:

    $ brew install python3 hg sdl sdl_image sdl_mixer sdl_ttf portmidi

and then install pygame itself:

    $ pip3 install hg+http://bitbucket.org/pygame/pygame


## Linux Requirements

You will want to compile pygame from source if you don't already have it
(the stable `1.9.1release` of pygame is far too old.)
The following will probably work for any Debian or Ubuntu type distribution.
I installed my copy of pygame in `/opt`:

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

If you can download a copy, make sure you install Eurostile as well!:

    $ cp ~/Downloads/Eurostile.ttf ~/.fonts/


# License

The MIT License.  The LICENSE file has full license and copyright information.
