---
layout: post
title: "Getting Started with Raspberry Pi"
date: 2013-12-13
comments: true
tags: [Hardware]
---

I ordered a Raspberry Pi to understand what it does, try a hobby project, and learn about GPIO pins. I thought the easiest way to set it up at home would be to order the pre-installed NOOBS SD card, so I did that. In the end I didn't use the NOOBS card because I wanted to be able to SSH in to the Raspberry Pi without connecting a mouse and keyboard. What did end up working was to flash the SD card with the Raspbian OS.

Raspberry Pi expects a keyboard and mouse on first boot. From the NOOBS screen, with a keyboard and mouse, the user can choose one of several operating systems to install. `sshd` is not running at this point so I could not ssh in on my home LAN.

Customizing NOOBS by removing all the operating systems, except one to install, is supposed to automatically install the one left on the card, however this didn't work for me.

## Flashing the SD card with Raspbian
Flashing the SD card with the Raspbian OS worked on my Macbook Pro with a built-in SD card slot, but the flashing process seemed quite slow while it was happening (around 30 minutes).

Once the SD card was ready, booting up the Raspberry Pi with Raspbian started `sshd` so I was able to SSH to the Pi on my home LAN. I checked my router DHCP clients table to figure out the internal IP address, and used the default login information. 

Now that I can log in to the Raspberry Pi, the next step is to figure out a project to try!
