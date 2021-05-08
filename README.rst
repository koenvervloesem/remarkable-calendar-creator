###########################
reMarkable Calendar Creator
###########################

.. image:: https://github.com/koenvervloesem/remarkable-calendar-creator/workflows/Build/badge.svg
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

************
Requirements
************

The reMarkable Calendar Creator is essentially a light wrapper around `pcal <http://pcal.sourceforge.net/>`_ (which generates calendars in PostScript output) and `GhostScript <https://www.ghostscript.com/>`_ (to convert the PostScript to PNG or PDF). Both programs are available in all major Linux distributions. For instance on Ubuntu you can install them as:

.. code-block:: console

  sudo apt install pcal ghostscript

You can also install both programs on your reMarkable, after you have installed `Toltec <https://toltec-dev.org/>`_:

.. code-block:: console

  opkg install pcal ghostscript

*******************************
Installation on your reMarkable
*******************************

You can just run the shell script as ``remarkable-calendar-creator.sh``, or you can install this on your reMarkable from source:

.. code-block:: console

  opkg install coreutils-install column make
  wget https://github.com/koenvervloesem/remarkable-calendar-creator/archive/refs/heads/main.zip
  unzip main.zip
  cd remarkable-calendar-creator-main
  make install

This installs the binary in ``/opt/bin``, as well as a systemd script and timer that replaces your splash screen ``/usr/share/remarkable/suspended.png`` every day with a calendar. If you want to change the type of calendar, change the environment variables in ``/opt/etc/remarkable-calendar-creator/remarkable-calendar-creator.env``.

.. note::

  The ``make install`` command makes a backup of your original splash screen to ``/opt/etc/remarkable-calendar-creator/suspended.png.backup``, which is copied back when you run ``make uninstall``.

*****
Usage
*****

You can create a calendar of the current month, for instance as a PNG image:

.. code-block:: console

  remarkable-calendar-creator calendar.png

You can also create a calendar for a specific month:

.. code-block:: console

  remarkable-calendar-creator calendar.png 1 2021

Or a calendar with all months of the current year on one sheet in a PNG file:

.. code-block:: console

  remarkable-calendar-creator calendar.png -w

Or you can create a PDF with a page for every monthly calendar of 2021:

.. code-block:: console

  remarkable-calendar-creator calendar.pdf 2021

For portrait mode, add the option ``-p`` after the file name.

You can find generated PNG and PDF files for all months of 2021 for landscape and portrait mode in the `examples <https://github.com/koenvervloesem/remarkable-calendar-creator/tree/main/examples>`_ directory.

*************
Configuration
*************

You can find the default configuration for pcal and GhostScript in `remarkable-calendar-creator.env <https://github.com/koenvervloesem/remarkable-calendar-creator/blob/main/remarkable-calendar-creator.env>`_. If you want to override this configuration, export particular environment variables. Moreover, every argument for ``remarkable-calendar-creator`` that you add after the filename is forwarded to ``pcal``.

Especially pcal has a lot of possible customizations. For instance you can add moon phases or custom images. You can even include a data file (in `calendar <https://github.com/koenvervloesem/remarkable-calendar-creator/blob/main/calendar>`_) with events shown on the calendar, such as holidays or birthdays. Have a look at ``man pcal`` for all possibilities.

**********
Disclaimer
**********

This project isn't affiliated to, nor endorsed by, `reMarkable AS <https://remarkable.com/>`_.

**I assume no responsibility for any damage done to your device due to the use of this software.**

*******
License
*******

This project is provided by `Koen Vervloesem <http://koen.vervloesem.eu>`_ as open source software with the MIT license. See the `LICENSE file <LICENSE>`_ for more information.
