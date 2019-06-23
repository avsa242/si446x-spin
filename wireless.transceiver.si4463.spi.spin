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
    time: "time"

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

PUB ClkTest(clkdiv)| tmp[2]
' Test system clock output, divided by clkdiv
'   Valid values: 1, 2, 3, 7_5 (7.5), 10, 15, 30
'   Any other value sets the divisor to 1
    case clkdiv
        1, 2, 3, 7_5, 10, 15, 30:
            clkdiv := lookdownz(clkdiv: 1, 2, 3, 7_5, 10, 15, 30)
        OTHER:
            clkdiv := core#DIV_1

    tmp.byte[core#ARG_GPIO0] := core#PULL_EN | core#GPIO_DIV_CLK
    tmp.byte[core#ARG_GPIO1] := core#PULL_EN | core#GPIO_CTS
    tmp.byte[core#ARG_GPIO2] := core#PULL_EN | core#GPIO_TRISTATE
    tmp.byte[core#ARG_GPIO3] := core#PULL_EN | core#GPIO_TRISTATE
    tmp.byte[core#ARG_NIRQ] := core#PULL_EN | core#GPIO_NIRQ
    tmp.byte[core#ARG_SDO] := core#PULL_EN | core#GPIO_SDO
    tmp.byte[core#ARG_GEN_CONFIG] := core#DRV_STRENGTH_HIGH

    result := writeReg(core#GPIO_PIN_CFG, 7, @tmp)
    tmp[0] := 0
    tmp[1] := 0
    tmp := (1 << core#FLD_DIV_CLK_EN) | (clkdiv << core#FLD_DIV_CLK_SEL)
    result := setProperty(core#GROUP_GLOBAL, 1, core#GLOBAL_CLK_CFG, @tmp)

PUB FIFORXBytes | tmp
' Number of bytes in the RX FIFO
    tmp := %00
    readReg(core#FIFO_INFO, 1, @result)

PUB FIFOTXBytes | tmp
' Number of bytes in the TX FIFO
    tmp := %00
    readReg(core#FIFO_INFO, 2, @result)
    result >>= 8

PUB FlushRX | tmp
' Flush the RX FIFO
    tmp := %1 << core#FLD_RX
    result := writeReg(core#FIFO_INFO, 1, @tmp)

PUB FlushTX | tmp
' Flush the TX FIFO
    tmp := %1
    result := writeReg(core#FIFO_INFO, 1, @tmp)

PUB PartID | tmp
' Read the Part ID from the device
'   Returns: 4-digit part ID
    readReg(core#PART_INFO, 8, @tmp)
    return (tmp.byte[core#REPL_PARTMSB] << 8) | tmp.byte[core#REPL_PARTLSB]

PUB PowerUp(osc_freq) | tmp[2]
' Perform device powerup, and specify oscillator frequency
    tmp.byte[core#ARG_BOOT_OPTIONS] := core#EZRADIO_PRO
    tmp.byte[core#ARG_XTAL_OPTIONS] := core#XTAL
    case osc_freq
        25_000_000..32_000_000:
            tmp.byte[core#ARG_XO_FREQ_MSB] := osc_freq.byte[3]
            tmp.byte[core#ARG_XO_FREQ_MSMB] := osc_freq.byte[2]
            tmp.byte[core#ARG_XO_FREQ_LSMB] := osc_freq.byte[1]
            tmp.byte[core#ARG_XO_FREQ_LSB] := osc_freq.byte[0]
        OTHER:
            tmp.byte[core#ARG_XO_FREQ_MSB] := $01
            tmp.byte[core#ARG_XO_FREQ_MSMB] := $C9
            tmp.byte[core#ARG_XO_FREQ_LSMB] := $C3
            tmp.byte[core#ARG_XO_FREQ_LSB] := $80
    
    result := writeReg(core#POWER_UP, 6, @tmp)

PUB NoOp

    return readReg(core#NOOP, 0, @result)

PUB SPIActive | tmp

    tmp.byte[0] := 2
    result := writeReg( core#CHANGE_STATE, 1, @tmp)

PUB State

    readReg(core#FAST_RESP_C, 1, @result)

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

    return' (result == $FF)

PRI getProperty(group, nr_props, start_prop, buff_addr) | tmp[4], i

    tmp.byte[0] := group
    tmp.byte[1] := nr_props
    tmp.byte[2] := start_prop
    readReg(core#GET_PROPERTY, nr_props, @tmp)

PRI setProperty(group, nr_props, start_prop, buff_addr) | tmp[4], i

    tmp.byte[0] := group
    tmp.byte[1] := nr_props
    tmp.byte[2] := start_prop
    repeat i from 0 to nr_props-1
        tmp.byte[3+i] := byte[buff_addr][i]
    result := writeReg(core#SET_PROPERTY, 3+nr_props, @tmp)

PRI readReg(reg, nr_bytes, buff_addr) | tmp, i

    case reg
        core#GET_PROPERTY:
            if clearToSend(DESELECT_AFTER)
                outa[_CS] := 0
                spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
                repeat i from 0 to 2
                    spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buff_addr][i])
                outa[_CS] := 1
                result := clearToSend(NO_DESELECT_AFTER)
                if result
                    repeat i from 0 to nr_bytes-1
                        byte[buff_addr][i] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
                    outa[_CS] := 1
                else
                    outa[_CS] := 1
                    return $E000_0002
        $01..$02, $10..$11, $13..$17, $1A, $20..$23, $31..$34, $36..$37, $44, $66, $77:
            if clearToSend(DESELECT_AFTER)
                outa[_CS] := 0
                spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
                outa[_CS] := 1

                result := clearToSend(NO_DESELECT_AFTER)
                if result
                    repeat i from 0 to nr_bytes-1
                        byte[buff_addr][i] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
                    outa[_CS] := 1
                else
                    outa[_CS] := 1
                    return $E000_0001
            else
                return $E000_0000
        $50, $51, $53, $57:                 'Fast-response registers (FRR's) don't require checking the CTS flag
            outa[_CS] := 0
            spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
            repeat i from 0 to nr_bytes-1
                byte[buff_addr][i] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
            outa[_CS] := 1
        OTHER:
            return FALSE

PRI writeReg(reg, nr_bytes, buf_addr) | i, tmp[3]
' Write nr_bytes to register 'reg' stored at buf_addr
    result := clearToSend(DESELECT_AFTER)
    if result
        outa[_CS] := 0
        spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
    
        case nr_bytes
            1..64:
                repeat i from 0 to nr_bytes-1
                    spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buf_addr][i])
            OTHER:
        outa[_CS] := 1
    else
        return $E000_0000

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
