'' =================================================================================================
'' Defcon 2012 (20) Badge LED Demo
''
'' Works on all Defcon 2012 badges.
'' Can you find the easter egg?  Careful, it's easy to crack :)
'' =================================================================================================


con

  _clkmode = xtal1 + pll4x                                      ' run @ 20MHz in XTAL mode
  _xinfreq = 5_000_000                                          ' use 5MHz crystal

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000

con
'' Propeller pin definitions
''
'' LEDs share with VGA
''
  RX1  = 31                                                     ' programming / terminal
  TX1  = 30

  SDA  = 29                                                     ' eeprom / i2c
  SCL  = 28

  MS_D = 27                                                     ' ps/2 mouse
  MS_C = 26

  KB_D = 25                                                     ' ps/2 keyboard
  KB_C = 24

  LED8 = 23                                                     ' leds / vga
  LED7 = 22
  LED6 = 21
  LED5 = 20
  LED4 = 19
  LED3 = 18
  LED2 = 17
  LED1 = 16

  VGA  = 16                                                     ' base pin for vga dac

  IRTX = 13                                                     ' ir led
  IRRX = 12                                                     ' ir demodulator


con

  #0, NO, YES

  ALL       = -1

  FORWARD   =  1
  REVERSE   = -1

  EEPROM    = $A0
  NV_SWITCH = $7F30

  MAX_MODES     = 6


obj

  rr    : "realrandom"                                          ' hardware random
  prng  : "jm_prng"                                             ' pseudo-random

  leds  : "jm_pwm8"                                             ' led modulation

' * not used in non-human badge

var

  long  broadcasts

  byte  playlist                                                ' for LO57 animations
  byte  last

  byte  mode

pub main | check, delay, i, temp, t, dt


  ' seed pseudo-random number generator with hardware
  ' -- hardware randomizer cog released after
  ' -- allows for true random on power-up without using full-time cog

  rr.start                                                      ' start hardware random
  prng.seed(rr.random, rr.random, rr.random, $DEFC01, 0)        ' seed prng (no cog)
  'rr.stop                                                       ' unload hardware random cog

  leds.start(8, LED1)                                         ' start drivers


  pause(5)                                                    ' give all drivers a moment to stablize


  ' main program loop
  repeat


    play_animation(@richo, 50, FORWARD)
    'fade_animation(@lolololol, 100, FORWARD)

    'give your eyes a chance to come back from being blinded :)
    pause(4)


con

  { =================== }
  {                     }
  {  L E D   S T U F F  }
  {                     }
  { =================== }


pub fade_in(ch, ms) | t, cycletix

'' Fades LED(s) from current brightness to full on
'' -- ch is -1 for all channels, 0..7 for single channel
'' -- ms is milliseconds for complete fade sequence

  cycletix := ms * MS_001 / 255                                 ' pre-calc for short events

  t := cnt
  case ch
    ALL:
      repeat 255
        leds.inc_all
        waitcnt(t += cycletix)

    0..7:                                                       ' single channel?
      repeat 255
        leds.inc(ch)
        waitcnt(t += cycletix)


pub larsen(idx, cycles, ms) | t

'' Larsen scanner
'' -- idx is starting point in cycle, 0..13
'' -- scans is # of complete cycles
'' -- ms is timing for one complete cycle

  if ((idx < 0) or (idx > 13))                                  ' reset if bogus
    idx := 0

  t := cnt
  repeat cycles
    repeat 14
      leds.dcd(lookupz(idx : 0,1,2,3,4,5,6,7,6,5,4,3,2,1))      ' sequence from wake-up led
      if (--idx < 0)                                            ' at end?
        idx := 13                                               '  yes, reset
      waitcnt(t += (ms * MS_001 / 14))                          ' hold


pub fade_out(ch, ms) | t, cycletix

'' Fades LED(s) from current brightness to off
'' -- ch is -1 for all channels, 0..7 for single channel
'' -- ms is milliseconds for complete fade sequence

  cycletix := ms * MS_001 / 255                                 ' pre-calc for short events

  t := cnt
  case ch
    ALL:
      repeat 255
        leds.dec_all
        waitcnt(t += cycletix)

    0..7:                                                       ' single channel?
      repeat 255
        leds.dec(ch)
        waitcnt(t += cycletix)


pub scramble(cycles, ms) | t

'' Randomize LEDs
'' -- event is milliseconds between changes
'' -- ms is milliseconds per cycle

  t := cnt
  repeat cycles
    leds.digital(prng.random, %1111_1111)
    waitcnt(t += (ms * MS_001))


pub fade_animation(pntr, ms, direction) | steps, t
  steps := byte[pntr]

  if (direction == FORWARD)
    pntr += 1
    direction := 1
  else
    pntr += steps
    direction := -1

  t := cnt
  'leds.digital(byte[pntr], $FF)
  repeat steps
    if byte[pntr] & %10000000
        fade_in(1, 500)
    if byte[pntr] & %01000000
        fade_in(1, 500)
    if byte[pntr] & %00100000
        fade_in(2, 500)
    if byte[pntr] & %01010000
        fade_in(3, 500)
    if byte[pntr] & %01001000
        fade_in(4, 500)
    if byte[pntr] & %01000100
        fade_in(5, 500)
    if byte[pntr] & %01000010
        fade_in(6, 500)
    if byte[pntr] & %01000001
        fade_in(7, 500)
    pause(1)
    leds.digital(%00000000, $FF)
    pntr += direction
    waitcnt(t += (ms * MS_001))
con

pub play_animation(pntr, ms, direction) | steps, t

'' Play byte-wide animation at pointer
'' -- ms is millseconds per step
'' -- direction is 0 for forward, 1 for reverse

  steps := byte[pntr]

  leds.digital(%11111111, $FF)
  pause(20)
  leds.digital(%00000000, $FF)
  pause(250)

  if (direction == FORWARD)
    pntr += 1
    direction := 1
  else
    pntr += steps
    direction := -1

  t := cnt
  repeat steps
    leds.digital(byte[pntr], $FF)
    pntr += direction
    waitcnt(t += (ms * MS_001))
  leds.digital(%00000000, $FF)
  pause(2000)


con

  { ===================== }
  {                       }
  {  A N I M A T I O N S  }
  {                       }
  { ===================== }

dat
Richo                   byte    24
                        byte    %11111111
                        byte    %00010001
                        byte    %00001010
                        byte    %11110100
                        byte    %00000000
                        byte    %11111001
                        byte    %11111001
                        byte    %00000000
                        byte    %01111110
                        byte    %10000001
                        byte    %10000001
                        byte    %00000000
                        byte    %11111111
                        byte    %11111111
                        byte    %00011000
                        byte    %00011000
                        byte    %11111111
                        byte    %11111111
                        byte    %00000000
                        byte    %00111100
                        byte    %01000010
                        byte    %10000001
                        byte    %01000010
                        byte    %00111100
con

dat
Lolololol               byte    6
                        byte    %00000000
                        byte    %00000000
                        byte    %11111111
                        byte    %00000000
                        byte    %11111111
                        byte    %00000000



con

  { ===================== }
  {                       }
  {  E S S E N T I A L S  }
  {                       }
  { ===================== }


pub pause(ms) | t

'' Delay program in milliseconds
'' -- use only in full-speed mode

  if (ms < 1)                                                   ' delay must be > 0
    return
  else
    t := cnt - 1792                                             ' sync with system counter
    repeat ms                                                   ' run delay
      waitcnt(t += MS_001)


pub high(pin)

'' Makes pin output high

  outa[pin] := 1
  dira[pin] := 1


pub low(pin)

'' Makes pin output low

  outa[pin] := 0
  dira[pin] := 1


pub toggle(pin)

'' Toggles pin state and makes output

  !outa[pin]
  dira[pin] := 1


pub input(pin)

'' Makes pin input and returns current state

  dira[pin] := 0

  return ina[pin]


dat

{{

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

}}
