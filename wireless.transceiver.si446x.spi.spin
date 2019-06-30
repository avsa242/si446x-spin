{
    --------------------------------------------
    Filename: wireless.transceiver.si446x.spi.spin
    Author: Jesse Burt
    Description: Driver for Silicon Labs Si446x series transceivers
    Copyright (c) 2019
    Started Jun 22, 2019
    Updated Jun 29, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Clear-to-send status
    CLEAR                   = $FF
    NOT_CLEAR               = $00

' Fast-Response Registers
    FRR_A                   = 0
    FRR_B                   = 1
    FRR_C                   = 2
    FRR_D                   = 3

    FRRMODE_DISABLED        = 0
    FRRMODE_INT_STATUS      = 1
    FRRMODE_INT_PEND        = 2
    FRRMODE_INT_PH_STATUS   = 3
    FRRMODE_INT_PH_PEND     = 4
    FRRMODE_INT_MODEM_STATUS= 5
    FRRMODE_INT_MODEM_PEND  = 6
    FRRMODE_INT_CHIP_STATUS = 7
    FRRMODE_INT_CHIP_PEND   = 8
    FRRMODE_CURRENT_STATE   = 9
    FRRMODE_LATCHED_RSSI    = 10

' Operating states
    STATE_NOCHANGE          = 0
    STATE_SLEEP             = 1
    STATE_SPI_ACTIVE        = 2
    STATE_READY             = 3
    STATE_TX_TUNE           = 5
    STATE_RX_TUNE           = 6
    STATE_TX                = 7
    STATE_RX                = 8

' Flags for the Clear-to-Send method
    DESELECT_AFTER          = TRUE
    NO_DESELECT_AFTER       = FALSE

VAR

    byte _CS, _MOSI, _MISO, _SCK

OBJ

    spi : "com.spi.4w"                                             'PASM SPI Driver
    core: "core.con.si446x"
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
'            if lookdown(PartID: $4460, $4461, $4463, $4464)
            if PowerUp(core#OSC_FREQ_NOMINAL) == $FF
                return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    spi.stop

PUB ClearInts

    readReg(core#GET_INT_STATUS, 0, @result)

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

PUB FastRespRegCfg(reg, mode) | tmp
' Configure the information available in the Fast-Response Registers A, B, C, D
'   Valid values:
'       reg: FRR_A (0), FRR_B (1), FRR_C (2), FRR_D (3)
'       mode:
'           DISABLED (0): Disabled. Will always read back 0.
'           INT_STATUS (1): Global status
'           INT_PEND (2): Global interrupt pending
'           INT_PH_STATUS (3): Packet Handler status
'           INT_PH_PEND (4): Packet Handler interrupt pending
'           INT_MODEM_STATUS (5): Modem status
'           INT_MODEM_PEND (6): Modem interrupt pending
'           INT_CHIP_STATUS (7): Chip status
'           INT_CHIP_PEND (8): Chip status interrupt pending
'           CURRENT_STATE (9): Current state
'           LATCHED_RSSI (10): Latched RSSI value
    case reg
        FRR_A..FRR_D:
        OTHER:
            return

    getProperty(core#GROUP_FRR_CTL, 1, reg, @tmp)

    case mode
        FRRMODE_DISABLED..FRRMODE_LATCHED_RSSI:
        OTHER:
            return tmp

    setProperty(core#GROUP_FRR_CTL, 1, reg, mode)

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

PUB InterruptStatus(buff_addr) | tmp[2]
' Read interrupt status into buffer at buff_addr
'   NOTE: Buffer must be at least 8 bytes
    tmp.byte[core#ARG_PH_CLR_PEND] := %1111_1111
    tmp.byte[core#ARG_MODEM_CLR_PEND] := %1111_1111
    tmp.byte[core#ARG_CHIP_CLR_PEND] := %0111_1111
    readReg(core#GET_INT_STATUS, 8, @tmp)
    longmove(buff_addr, @tmp, 2)

PUB PartID | tmp
' Read the Part ID from the device
'   Returns: 4-digit part ID
    readReg(core#PART_INFO, 8, @tmp)
    return (tmp.byte[core#REPL_PARTMSB] << 8) | tmp.byte[core#REPL_PARTLSB]

PUB PowerUp(osc_freq) | tmp[2]
' Perform device powerup, and specify oscillator frequency, in Hz
'   Valid values: 25_000_000 to 32_000_000
'   Any other value sets the nominal 30_000_000
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

PUB Preamble(bytes) | tmp
' Set preamble length, in bytes
'   Valid values: 0..255
'   Any other value polls the chip and returns the current setting
'   NOTE: 0 effectively disables transmitting the preamble. In this case, the sync word will be the first
'       transmitted field.
    getProperty(core#GROUP_PREAMBLE, 1, 0, @tmp)
    case bytes
        0..255:
        OTHER:
            return @tmp

    setProperty(core#GROUP_PREAMBLE, 1, 0, @bytes)

PUB NoOp

    return readReg(core#NOOP, 0, @result)

PUB RXData(nr_bytes, buff_addr)
' Read nr_bytes from RX FIFO into buff_addr
'   NOTE: Buffer must be large enough to hold nr_bytes
    readReg(core#READ_RX_FIFO, nr_bytes, @buff_addr)

PUB SPIActive | tmp

    tmp.byte[0] := 2
    result := writeReg( core#CHANGE_STATE, 1, @tmp)

PUB State(new_state) | tmp
' Manually switch chip to desired operating state
'   Valid values:
'       STATE_SLEEP (1): Put chip in SLEEP or STANDBY state
'       STATE_SPI_ACTIVE (2): SPI_ACTIVE state
'       STATE_READY (3): READY state
'       STATE_TX_TUNE (5): TX_TUNE state
'       STATE_RX_TUNE (6): RX_TUNE state
'       STATE_TX (7): TX state
'       STATE_RX (8): RX state
'   Any other value polls the chip and returns the current state
    readReg(core#FAST_RESP_C, 1, @tmp)
    case new_state
        STATE_SLEEP, STATE_SPI_ACTIVE, STATE_READY, STATE_TX_TUNE, STATE_RX_TUNE, STATE_TX, STATE_RX:
        OTHER:
            return tmp

    result := writeReg(core#CHANGE_STATE, 1, @new_state)

PRI clearToSend(deselect)
' Check the CTS (Clear-to-Send) status from the device
'   Valid values:
'       DESELECT_AFTER (-1): Raise CS after checking
'       NO_DESELECT_AFTER (0): Don't raise CS after checking - needed for reads where the data read must be in the same CS "frame" as the
'                               CTS check.
'   Returns: TRUE if clear to send, FALSE otherwise
    repeat
        outa[_CS] := 0
        spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, core#READ_CMD_BUFF)
        result := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
        if result <> $FF
            outa[_CS] := 1
    until result == $FF
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
            if clearToSend(DESELECT_AFTER) == CLEAR
                outa[_CS] := 0
                spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
                repeat i from 0 to 2
                    spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buff_addr][i])
                outa[_CS] := 1
                result := clearToSend(NO_DESELECT_AFTER)
                if result == CLEAR
                    repeat i from 0 to nr_bytes-1
                        byte[buff_addr][i] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
                    outa[_CS] := 1
                else
                    outa[_CS] := 1
                    return $E000_0002

        core#GET_INT_STATUS:
            result := clearToSend(DESELECT_AFTER)
            if result == CLEAR
                outa[_CS] := 0
                spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
                case nr_bytes
                    0:              'Clear interrupts if no args given
                        outa[_CS] := 1
                        return
                    OTHER:
                        repeat i from 0 to 2
                            spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buff_addr][i])
                            byte[buff_addr][i] := 0
                        outa[_CS] := 1

                result := clearToSend(NO_DESELECT_AFTER)
                if result == CLEAR
                    repeat i from 0 to nr_bytes-1
                        byte[buff_addr][i] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
                    outa[_CS] := 1
                else
                    outa[_CS] := 1
                    return $E000_0003

        $01..$02, $10..$11, $13..$17, $1A, $20..$23, $31..$34, $36..$37, $44:
            if clearToSend(DESELECT_AFTER) == CLEAR
                outa[_CS] := 0
                spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
                outa[_CS] := 1

                result := clearToSend(NO_DESELECT_AFTER)
                if result == CLEAR
                    repeat i from 0 to nr_bytes-1
                        byte[buff_addr][i] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
                    outa[_CS] := 1
                else
                    outa[_CS] := 1
                    return $E000_0001
            else
                return $E000_0000

        core#WRITE_TX_FIFO:

        core#READ_RX_FIFO:
            outa[_CS] := 0
            spi.SHIFTOUT (_MOSI, _SCK, core#MISO_BITORDER, 8, reg)
            repeat i from 0 to nr_bytes-1
                byte[buff_addr][i] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
            outa[_CS] := 1

        core#FAST_RESP_A, core#FAST_RESP_B, core#FAST_RESP_C, core#FAST_RESP_D:         'Fast-response registers (FRR's) don't require checking the CTS flag
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
