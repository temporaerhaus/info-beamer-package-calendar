# Frab Event Calendar

[![Import](https://cdn.infobeamer.com/s/img/import.png)](https://info-beamer.com/use?url=https://github.com/verschwoerhaus/info-beamer-package-calendar)

* Shows currently running and upcoming events from a frab compatible event source

# Adding this package to your existing setups

First of all you have to install this package. The easiest way is probably to visit the package gallery, select the package and click on __Import package__ in the top right corner.

# Event source
We're using [ical2schedule](https://github.com/verschwoerhaus/ical2schedule) in the [verschwörhaus](https://verschwoerhaus.de) hackspace to convert a public google ical file to a slighly frab compatible `schedule.xml`.  
This is something that could be integrated as a [service into this package](https://info-beamer.com/doc/package-services), feel free to submit a pull request.

# Thanks
* This package is based on the frab module already included in [Scheduled Player](https://info-beamer.com/raspberry-pi-digital-signage-scheduled-player-4765.html)
* The layout is based on [stks modifications](https://github.com/verschwoerhaus/info-beamer-vsh/blob/vsh/module_events.lua) of the [upcoming talks visualization for the 32c3 conference screens](https://github.com/info-beamer/package-32c3-screens)