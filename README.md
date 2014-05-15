Farabi
======

[![Build Status](https://api.travis-ci.org/azawawi/farabi.png?branch=master)](https://travis-ci.org/azawawi/farabi)

This is a modern web-based Perl IDE that runs inside your favorite browser.

To start Farabi, please type the following command:

    farabi

And then open http://127.0.0.1:4040/ in your favourite modern browser.

To run it on a different port, please use:

    farabi --port 5050

Supported Browsers
==================
Farabi needs a modern browser that supports HTML 5 and websockets.

My current test setup is Firefox 20, Chrome 26 and IE 10.

The following browsers could be theoritically supported:

- Firefox 16 and later
- Chrome 23 and later
- IE 10 and later

Installation
============

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

Support and Documentation
=========================

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Farabi

You can also look for information at:

    Project issue list:
	https://github.com/azawawi/farabi/issues

    CPAN Ratings
        http://cpanratings.perl.org/d/Farabi

Copyright and License
=====================

Copyright (C) 2012-2014 Ahmad M. Zawawi

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
