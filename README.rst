###########################
reMarkable Calendar Creator
###########################

.. image:: https://github.com/koenvervloesem/remarkable-calendar-creator/workflows/Tests/badge.svg
   :target: https://github.com/koenvervloesem/remarkable-calendar-creator/actions
   :alt: Continuous integration

.. image:: https://img.shields.io/badge/rM1-supported-green
   :target: https://remarkable.com/store/remarkable
   :alt: reMarkable 1 is supported

.. image:: https://img.shields.io/badge/rM2-supported-green
   :target: https://remarkable.com/store/remarkable-2
   :alt: reMarkable 2 is supported

.. image:: https://img.shields.io/github/license/koenvervloesem/remarkable-calendar-creator.svg
   :target: https://github.com/koenvervloesem/remarkable-calendar-creator/blob/main/LICENSE
   :alt: License

This tool creates calendars to display on a reMarkable device. You can create:

- a PNG image to use instead of the default suspend screen (in ``/usr/share/remarkable/suspended.png``)
- a PDF document to write your notes on

You can also add events from an iCalendar (ics) file to your calendar.

*******************************
Installation on your reMarkable
*******************************

First install `Toltec <https://toltec-dev.org/>`_. Then install the latest release of reMarkable Calendar Creator, including its dependencies, on your reMarkable:

.. code-block:: console

  opkg install coreutils-date coreutils-install column make pcal ghostscript
  wget https://github.com/koenvervloesem/remarkable-calendar-creator/archive/refs/heads/main.zip
  unzip main.zip
  cd remarkable-calendar-creator-main
  make install

This installs the binary in ``/opt/bin``, as well as a systemd service and timer that replaces your splash screen ``/usr/share/remarkable/suspended.png`` every day with a calendar of the current month.

.. note::

  The first time you run ``make install``, it makes a backup of your original splash screen to ``/opt/etc/remarkable-calendar-creator/suspended.png.backup``, which is copied back when you run ``make uninstall`` later.

Then copy the example environment file to the location that the service consults:

.. code-block:: console

  cp /opt/etc/remarkable-calendar-creator/remarkable-calendar-creator.env.example /opt/etc/remarkable-calendar-creator/remarkable-calendar-creator.env

*************
Configuration
*************

If you want to change the type of calendar or other options, change the environment variables in ``/opt/etc/remarkable-calendar-creator/remarkable-calendar-creator.env``. Have a look at the `default configuration <https://github.com/koenvervloesem/remarkable-calendar-creator/blob/main/remarkable-calendar-creator.env.example>`_, which is commented with some interesting options you can add.

Especially pcal has a lot of possible customizations. For instance you can add moon phases or custom images. See `pcal's man page <https://manpages.ubuntu.com/manpages/xenial/man1/pcal.1.html>`_ for the full list of options you can add to the variable ``PCAL_OPTS``.

**********************
Adding calendar events
**********************

If you want to add events from your own calendar, just enter the URL of your ICS file in the file ``/opt/etc/remarkable-calendar-creator/remarkable-calendar-creator.env``. This should be something like ``ICS_URL=https://www.google.com/calendar/ical/feestdagenbelgie%40gmail.com/public/basic.ics`` (an example for Google's calendar file for the Belgian public holidays). Note that ``ICS_URL`` should be a publicly accessible but secret address of the ICS file of your iCalendar calendar. Make sure to remove the ``#`` before ``ICS_URL`` in the configuration file.

After this, the systemd timer downloads this file daily and updates your calendar suspend screen. If you want to see the result immediately, run the systemd script manually with:

.. code-block:: console

  systemctl start remarkable-calendar-creator.service

Have a look at the `example with Belgian public holidays <https://github.com/koenvervloesem/remarkable-calendar-creator/blob/main/examples/public-holidays-belgium.png>`_ for the result.

This only works for month calendars, as there's not enough room on the year calendar to add events.

*************************
Using on a Linux computer
*************************

You can also use reMarkable Calendar Creator on a Linux computer. Obviously it won't make sense to install the systemd service and timer because your computer doesn't use the reMarkable's suspend screen. However, you can run the script manually to create a PDF file with a calendar. Then you can send the PDF to your reMarkable device to draw notes on it.

The reMarkable Calendar Creator is essentially a light wrapper around `pcal <http://pcal.sourceforge.net/>`_ (which generates calendars in PostScript output) and `GhostScript <https://www.ghostscript.com/>`_ (to convert the PostScript to PNG or PDF). Both programs are available in all major Linux distributions. For instance on Ubuntu you can install them as:

.. code-block:: console

  sudo apt install pcal ghostscript

After this, you can run the script ``remarkable-calendar-creator.sh``.

You can create a calendar of the current month, for instance as a PNG image:

.. code-block:: console

  ./remarkable-calendar-creator.sh calendar.png

Every argument that you add after the filename is forwarded to ``pcal``. This means that you can also create a calendar for a specific month:

.. code-block:: console

  ./remarkable-calendar-creator.sh calendar.png 1 2021

Or a calendar with all months of the current year on one sheet in a PNG file:

.. code-block:: console

  ./remarkable-calendar-creator.sh calendar.png -w

Or you can create a PDF with a page for every monthly calendar of 2021:

.. code-block:: console

  ./remarkable-calendar-creator.sh calendar.pdf 2021

For portrait mode, add the option ``-p`` after the file name.

You can find generated PNG and PDF files for all months of 2021 for landscape and portrait mode in the `examples <https://github.com/koenvervloesem/remarkable-calendar-creator/tree/main/examples>`_ directory.

If you want to add events from your calendar, you first have to download an ICS file for your calendar and convert it to the pcal format that reMarkable Calendar Creator uses. This goes like this:

.. code-block:: console

  ./remarkable-calendar-downloader.sh URL events

The ``URL`` should be a publicly accessible but secret address of the ICS file of your iCalendar calendar. The ``events`` is the filename of the calendar file that reMarkable Calendar Creator uses by default.

After this, run ``remarkable-calendar-creator.sh`` again and it will automatically pick up your events and put them on your calendar. Have a look at the `example with Belgian public holidays <https://github.com/koenvervloesem/remarkable-calendar-creator/blob/main/examples/public-holidays-belgium.png>`_ for the result.

This only works for month calendars, as there's not enough room on the year calendar to add events.

**********
Disclaimer
**********

This project isn't affiliated to, nor endorsed by, `reMarkable AS <https://remarkable.com/>`_.

**I assume no responsibility for any damage done to your device due to the use of this software.**

*******
License
*******

This project is provided by `Koen Vervloesem <http://koen.vervloesem.eu>`_ as open source software with the MIT license. See the `LICENSE file <LICENSE>`_ for more information.

The file `ical2pcal.sh <https://github.com/koenvervloesem/remarkable-calendar-creator/blob/main/ical2pcal.sh>`_ comes from the MIT licensed `ical2pcal <https://github.com/pmarin/ical2pcal>`_ project by Francisco José Marín Pérez.
