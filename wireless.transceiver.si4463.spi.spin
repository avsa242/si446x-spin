{
    --------------------------------------------
    Filename: wireless.transceiver.si4463.spi.spin
    Author:
    Description:
    Copyright (c) 2019
    Started Jun 22, 2019
    Updated Jun 22, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Flags for the Clear-to-Send method
    DESELECT_AFTER      = TRUE
    NO_DESELECT_AFTER   = FALSE

VAR

    byte _CS, _MOSI, _MISO, _SCK

OBJ

    spi : "com.spi.4w"                                             'PASM SPI Driver
    core: "core.con.si4463"
    time: "time"                                                'Basic timing functions

PUB Null
''This is not a top-level object

PUB Start(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN) : okay

    okay := Startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, core#CLK_DELAY, core#CPOL)

PUB Startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, SCK_DELAY, SCK_CPOL): okay

    if SCK_DELAY => 1 and lookdown(SCK_CPOL: 0, 1)
        if okay := spi.start (SCK_DELAY, SCK_CPOL)              'SPI Object Started?
            time.MSleep (core#TPOR)
            _CS := CS_PIN
            _MOSI := MOSI_PIN
            _MISO := MISO_PIN
            _SCK := SCK_PIN

            outa[_CS] := 1
            dira[_CS] := 1
            if lookdown(PartID: $4460, $4461, $4463, $4464)
                return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    spi.stop

PUB PartID | tmp

    readReg(core#PART_INFO, 8, @tmp)
    return (tmp.byte[core#REPL_PARTMSB] << 8) | tmp.byte[core#REPL_PARTLSB]

PUB OutClk | tmp

    tmp := 6
    result := writeReg( core#GPIO_PIN_CFG, 1, @tmp)

PUB PowerUp | tmp

    tmp.byte[0] := $00  'BOOT_OPTIONS
    tmp.byte[1] := $00  'XTAL_OPTIONS

    tmp.byte[2] := $01  'XO_FREQ (U32)
    tmp.byte[3] := $C9
    tmp.byte[4] := $C3
    tmp.byte[5] := $80
    
    result := writeReg(core#POWER_UP, 6, @tmp)

PUB NoOp

    return readReg(core#NOOP, 0, @result)

PUB readCmdBuff

    readReg(core#READ_CMD_BUFF, 0, @result)

PRI clearToSend(deselect)
' Check the CTS (Clear-to-Send) status from the device
'   Valid values:
'       DESELECT_AFTER (-1): Raise CS after checking
'       NO_DESELECT_AFTER (0): Don't raise CS after checking - needed for reads where the data read must be in the same CS "frame" as the
'                               CTS check.
'   Returns: TRUE if clear to send, FALSE otherwise
    outa[_CS] := 0
    spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, core#READ_CMD_BUFF)
    result := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
    if deselect
        outa[_CS] := 1

    return (result == $FF)

PRI readReg(reg, nr_bytes, buff_addr) | tmp, i

    if clearToSend(DESELECT_AFTER)
        outa[_CS] := 0
        spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
        outa[_CS] := 1

        if clearToSend(NO_DESELECT_AFTER)
            repeat i from 0 to nr_bytes-1
                byte[buff_addr][i] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
            outa[_CS] := 1
        else
            outa[_CS] := 1
            return FALSE
    else
        return FALSE

PRI writeReg(reg, nr_bytes, buf_addr) | i
' Write nr_bytes to register 'reg' stored at buf_addr
    if clearToSend(DESELECT_AFTER)
        outa[_CS] := 0
        spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
    
        case nr_bytes
            1..64:
                repeat i from 0 to nr_bytes
                    spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buf_addr][i])
            OTHER:
        outa[_CS] := 1
    return clearToSend(DESELECT_AFTER)

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
