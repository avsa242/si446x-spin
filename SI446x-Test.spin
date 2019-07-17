{
    --------------------------------------------
    Filename: SI446x-Test.spin
    Author: Jesse Burt
    Description: Test object for the Si446x driver
    Copyright (c) 2019
    Started Jun 22, 2019
    Updated Jul 3, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    CS_PIN      = 5
    SCK_PIN     = 1
    MOSI_PIN    = 0
    MISO_PIN    = 2

    COL_REG     = 0
    COL_SET     = COL_REG+25
    COL_READ    = COL_SET+17
    COL_PF      = COL_READ+17

    LED         = cfg#LED1

OBJ

    cfg : "core.con.boardcfg.flip"
    ser : "com.serial.terminal"
    time: "time"
    rf  : "wireless.transceiver.si446x.spi"

VAR

    long _fails, _expanded
    byte _ser_cog, _row

PUB Main

    Setup
    _row := 1

    SYNC_CONFIG (1)
    SYNC_BITS (1)
    PREAMBLE_TX_LENGTH (1)
    MODEM_MOD_TYPE (1)
    FRR_D (1)
    FRR_C (1)
    FRR_B (1)
    FRR_A (1)
    ser.NewLine
    ser.Str (string("Total failures: "))
    ser.Dec (_fails)
    Flash (cfg#LED1, 100)

PUB SYNC_CONFIG(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 1 to 4
            rf.SyncWordLen (tmp)
            read := rf.SyncWordLen (-2)
            Message (string("SYNC_CONFIG"), tmp, read)

PUB SYNC_BITS(reps) | tmp, read

'    _expanded := FALSE
    _row++
    repeat reps
        repeat tmp from $01_01_01_01 TO $7F_FF_FF_FF step $01_01_01_01
            rf.SyncWord (tmp)
            read := rf.SyncWord (0)
            Message (string("SYNC_BITS"), tmp, read)

PUB PREAMBLE_TX_LENGTH(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 255
            rf.Preamble (tmp)
            read := rf.Preamble (-2)
            Message (string("PREAMBLE_TX_LENGTH"), tmp, read)

PUB MODEM_MOD_TYPE(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 5
            rf.Modulation (tmp)
            read := rf.Modulation (-2)
            Message (string("MODEM_MOD_TYPE"), tmp, read)

PUB FRR_D(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 7
            rf.FastRespRegCfg (rf#FRR_D, tmp)
            read := rf.FastRespRegCfg (rf#FRR_D, -2)
            Message (string("FRR_D"), tmp, read)

PUB FRR_C(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 7
            rf.FastRespRegCfg (rf#FRR_C, tmp)
            read := rf.FastRespRegCfg (rf#FRR_C, -2)
            Message (string("FRR_C"), tmp, read)

PUB FRR_B(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 7
            rf.FastRespRegCfg (rf#FRR_B, tmp)
            read := rf.FastRespRegCfg (rf#FRR_B, -2)
            Message (string("FRR_B"), tmp, read)

PUB FRR_A(reps) | tmp, read

'    _expanded := TRUE
    _row++
    repeat reps
        repeat tmp from 0 to 7
            rf.FastRespRegCfg (rf#FRR_A, tmp)
            read := rf.FastRespRegCfg (rf#FRR_A, -2)
            Message (string("FRR_A"), tmp, read)

PUB Message(field, arg1, arg2)

    case _expanded
        TRUE:
            ser.PositionX (COL_REG)
            ser.Str (field)

            ser.PositionX (COL_SET)
            ser.Str (string("SET: "))
            ser.Dec (arg1)

            ser.PositionX (COL_READ)
            ser.Str (string("READ: "))
            ser.Dec (arg2)
            ser.Chars (32, 3)
            ser.PositionX (COL_PF)
            PassFail (arg1 == arg2)
            ser.NewLine

        FALSE:
            ser.Position (COL_REG, _row)
            ser.Str (field)

            ser.Position (COL_SET, _row)
            ser.Str (string("SET: "))
            ser.Dec (arg1)
            ser.Chars (32, 10)

            ser.Position (COL_READ, _row)
            ser.Str (string("READ: "))
            ser.Dec (arg2)
            ser.Chars (32, 10)

            ser.Position (COL_PF, _row)
            PassFail (arg1 == arg2)
            ser.NewLine
        OTHER:
            ser.Str (string("DEADBEEF"))

PUB PassFail(num)

    case num
        0:
            ser.Str (string("FAIL"))
            _fails++

        -1:
            ser.Str (string("PASS"))

        OTHER:
            ser.Str (string("???"))

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    time.MSleep(500)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL, ser#LF))
    if rf.Start (CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN)
        ser.Str (string("SI446x driver started", ser#NL, ser#LF))
    else
        ser.Str (string("SI446x driver failed to start - halting", ser#NL, ser#LF))
        rf.Stop
        time.MSleep (500)
        ser.Stop
        Flash (LED, 500)

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
