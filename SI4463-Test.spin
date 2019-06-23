{
    --------------------------------------------
    Filename: SI4463-Test.spin
    Author:
    Description:
    Copyright (c) 2019
    Started Jun 22, 2019
    Updated Jun 22, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    CS_PIN      = 7
    SCK_PIN     = 3
    MOSI_PIN    = 4
    MISO_PIN    = 5

    LED         = cfg#LED1

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    rf      : "wireless.transceiver.si4463.spi"
    time    : "time"

VAR

    byte _ser_cog, _rf_cog

PUB Main | tmp[2], i

    Setup

    ser.Hex (rf.PowerUp(30_000_000), 8)
    ser.NewLine
    ser.Hex (rf.ClkTest(1), 8)
    ser.NewLine
    ser.Hex (rf.State (rf#STATE_SPI_ACTIVE), 8)
    ser.NewLine
    ser.Dec (rf.State (rf#STATE_NOCHANGE))
    ser.NewLine
    ser.NewLine
    rf.InterruptStatus (@tmp)

    repeat i from 0 to 7
        ser.Bin (tmp.byte[i], 8)
        ser.NewLine
    Flash (LED, 100)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if _rf_cog := rf.Start (CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.Str(string("SI446x driver started (Si"))
        ser.Hex (rf.PartID, 4)
        ser.Str (string(" found)", ser#NL))
    else
        ser.Str(string("SI446x driver failed to start", ser#NL))
        Stop
        Flash (LED, 500)

PUB Stop

    time.MSleep (5)
    ser.Stop
    rf.Stop

PUB Flash(pin, delay_ms)

    dira[pin] := 1
    repeat
        !outa[pin]
        time.MSleep (delay_ms)
DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
