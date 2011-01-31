# Ferrante

Ferrante is a locative app for Android. It provides you with a link
which you then send to a friend via instant message, SMS, etc. Your
friend clicks on the link, and if he accepts then your phones will
show arrows pointing at the other person's location.

Instead of the Java programming language, it's written in
[Mirah](http://mirah.org), a newer language that's very fast and
lightweight but offers some advanced features still lacking in Java.

There is also a small server-side web service under <tt>server/</tt>
(also written in Mirah) that runs on the Google App Engine to act as
an mediator between the two devices since they generally cannot
communicate directly; see http://ferrante-della-griva.appspot.com.

## Compiling

You'll need the [Android SDK](http://d.android.com/sdk/) installed
with the tools/ and platform-tools/ directories on your $PATH. For the
time being you will also need [ant](http://ant.apache.org). Finally be
sure to have [JRuby](http://jruby.org) installed with bin/ on your $PATH.

    $ jruby -S gem install mirah

Then you can compile:

    $ ant debug

This will place <tt>Ferrante-debug.apk</tt> in <tt>bin</tt>, which you
can install if your device is connected or your emulator is running:

    $ adb install -r bin/Ferrante-debug.apk

If you're running the emulator, you can fake out the GPS:

    $ adb emu geo fix 43.0 -122.1

For more details see [Pindah](http://github.com/technomancy/pindah), a
tool for Mirah Android apps.

Have fun!

## License

Copyright (C) 2010-2011 Phil Hagelberg

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs; see the file COPYING.  If not, write to the
Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
Boston, MA 02110-1301, USA.

