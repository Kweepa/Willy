# Willy
Jet Set Willy for the unexpanded Vic-20 with disk drive.

Jet Set Willy is a classic game for the ZX Spectrum that has had more or less faithful ports to nearly every British home computer. VIC owners, though, missed out, because the system is low on memory and in the UK disk drives were rare.

This port started with the Manic Miner port I did some time ago. It originally worked with one screen on an unexpanded machine, so I knew the VIC was capable, if the levels were loaded from disk.

Like with Manic Miner, the challenge was to make the game work with a reduced screen width. I was able to fit all 20 Manic Miner screens into a 22 column wide screen easily, so I wasn't worried about doing the same here. The biggest extra wrinkle is that there are ramps in Jet Set Willy, and long ramps take up more of the room horizontally, so I had to make some edits to the rooms to make them work from screen to screen.

Ropes were a challenge to fit in memory, and the rope delta tables had to be reworked for the reduced screen width.