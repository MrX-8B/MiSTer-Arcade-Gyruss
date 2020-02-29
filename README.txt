---------------------------------------------------------------------------------
-- 
-- Arcade: Gyruss  for MiSTer by MiSTer-X
-- 29 February 2020
-- 
---------------------------------------------------------------------------------
-- T80/T80s - Z80 compatible microprocessor core  Version 0242
-- Copyright (c) 2001-2002 Daniel Wallner (jesus@opencores.org)
---------------------------------------------------------------------------------
-- SYNTHEZIABLE CPU09 - 6809 compatible CPU Core  Version 1.4 (Modified)
-- Author: John E. Kent (dilbert57@opencores.org)
---------------------------------------------------------------------------------
-- T8039 Microcontroller System
-- Copyright (c) 2004, Arnim Laeuger (arniml@opencores.org)
---------------------------------------------------------------------------------
-- YM2149 (AY-3-8910)
-- Copyright (c) MikeJ - Jan 2005
---------------------------------------------------------------------------------
--
-- Keyboard inputs :
--
--   F2          : Coin + Start 2 players
--   F1          : Coin + Start 1 player
--   UP,DOWN,LEFT,RIGHT arrows : Movements
--   SPACE       : Fire
--
-- MAME/IPAC/JPAC Style Keyboard inputs:
--   5           : Coin 1
--   6           : Coin 2
--   1           : Start 1 Player
--   2           : Start 2 Players
--   R,F,D,G     : Player 2 Movements
--   A           : Player 2 Fire
--
-- Joystick support.
--
---------------------------------------------------------------------------------

                                *** Attention ***

ROM is not included. In order to use this arcade, you need to provide a correct ROM file.

Find this zip file somewhere. You need to find the file exactly as required.
Do not rename other zip files even if they also represent the same game - they are not compatible!
The name of zip is taken from M.A.M.E. project, so you can get more info about
hashes and contained files there.


How to install:
  0. Update MiSTer binary to v200106 or later
  1. copy releases/*.mra to /media/fat/_Arcade
  2. copy releases/*.rbf to /media/fat/_Arcade/cores
  3. copy ROM zip files  to /media/fat/_Arcade/mame


Be sure to use the MRA file in "releases" of this repository.
It does not guarantee the operation when using other MRA files.

