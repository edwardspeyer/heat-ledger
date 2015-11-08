# Heat Ledger

Heat Ledger is a suite of tools for logging temperatures and visualising their
change over time, specifically in the context of smoking, grilling and roasting
meat and poultry.

The main components are:

* `plot-heat-ledger` renders the database graphically in real-time.
* `tail-heat-ledger` prints changes to the database on the command-line.
* `bluethermd` is a daemon for logging temperatures from an ETI Thermoworks
  [BlueTherm Duo](http://thermometer.co.uk/bluetooth-temperature-probes/1002-bluetooth-thermometer-bluetherm-duo.html).

# Visualizing Data

`plot-heat-ledger` will plot your most recent cooking session by looking for
the most recent continuous set of temperature readings with no more than an hour's
gap between readings.

![plot-heat-ledger screenshot](/examples/plot.png?raw=true "plot-heat-ledger screenshot")

Guidelines and estimated cooking times are shown for roasting rare meat, rare and done poultry
and tougher cuts with connective tissue.  The model is very simplistic -- currently it is
simply a linear model of the last 5 minutes of data.

The tool has a number of dependencies
The UI is rendered with [pygame](https://www.pygame.org/) and [SDL](https://www.libsdl.org/)
and works in (at least!) OS X and on the Linux framebuffer.
The modelling and plotting is done by [R](https://www.r-project.org/).

## Dependencies for OS X

You can install R by using the [R for Mac OS X](https://cran.r-project.org/bin/macosx/) installer.
If you have [Homebrew](http://brew.sh/) then you can install SDL and python Mercurial support with:

    $ brew install python3 hg sdl sdl_image sdl_mixer sdl_ttf portmidi

and then pygame with:

    $ pip3 install hg+http://bitbucket.org/pygame/pygame

## Linux Requirements

The following will probably work for any Debian or Ubuntu type distribution.  In any case, you
will want to compile pygame from source if you don't already have it
(the stable release of R (`1.9.1release`) is far too old.)

I put mine in `/opt`:

    # apt-get install r-base
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


# License

The MIT License.  The LICENSE file has full license and copyright information.
