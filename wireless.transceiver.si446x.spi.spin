{
    --------------------------------------------
    Filename: wireless.transceiver.si446x.spi.spin
    Author: Jesse Burt
    Description: Driver for Silicon Labs Si446x series transceivers
    Copyright (c) 2019
    Started Jun 22, 2019
    Updated Jul 3, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Clear-to-send status
    CLEAR                   = $FF
    NOT_CLEAR               = $00

' TX Gaussian Filter oversampling ratio
    TXOSR_10X               = 0
    TXOSR_20X               = 2
    TXOSR_40X               = 1

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

' Modulation types
    MOD_CW                  = 0
    MOD_OOK                 = 1
    MOD_2FSK                = 2
    MOD_2GFSK               = 3
    MOD_4FSK                = 4
    MOD_4GFSK               = 5

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

    long _fxtal
    byte _CS, _MOSI, _MISO, _SCK

OBJ

    spi : "com.spi.4w"                                             'PASM SPI Driver
    core: "core.con.si446x"
    time: "time"
    u64 : "math.unsigned64"
    f32 : "math.float.extended"

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
                if PowerUp(core#OSC_FREQ_NOMINAL) == $FF
                   return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    spi.stop

PUB CenterFreq(freq) | outdiv, band, xtal_frequency, f_pfd, n, ratio, rest, m, m0, m1, m2, freq_control, modem_clkgen

'   return setProperty(core#GROUP_FREQ, 4, core#FREQ_CONTROL_INTE, @freq_control)
    getProperty(core#GROUP_FREQ, 4, core#FREQ_CONTROL_INTE, @freq_control)
    case PartID
        $4460, $4461, $4463:
            case freq
                850..1050:
                    outdiv := 4
                    band := 0
                425..525:
                    outdiv := 8
                    band := 2
                284..350:
                    outdiv := 12
                    band := 3
                142..175:
                    outdiv := 24
                    band := 5
                OTHER:
                    return freq_control
        $4464:
            case freq
                675..960:
                    outdiv := 4
                    band := 1
                450..674:
                    outdiv := 6
                    band := 2
                338..449:
                    outdiv := 8
                    band := 3
                225..337:
                    outdiv := 12
                    band := 4
                169..224:
                    outdiv := 16
                    band := 4
                119..168:
                    outdiv := 24
                    band := 5
                OTHER:
                    return FALSE

' Set the MODEM_CLKGEN_BAND (not documented)
    modem_clkgen := (band + 8)
    setProperty(core#GROUP_MODEM, 1, core#MODEM_CLKGEN_BAND, @modem_clkgen)
'	    return false

    freq *= 1000000 ' Convert to Hz

'Now generate the RF frequency properties
'Need the Xtal/XO freq from the radio_config file:
    freq := f32.FFloat (freq)
'Now generate the RF frequency properties
'Need the Xtal/XO freq from the radio_config file:
    xtal_frequency := core#OSC_FREQ_NOMINAL
    f_pfd := 2 * xtal_frequency / outdiv
    n := (f32.FTrunc (freq) / f_pfd) - 1
    ratio := f32.FDiv (freq, f32.FFloat (f_pfd))
    rest := f32.FSub (ratio, f32.FFloat (n))
    m := f32.FTrunc (f32.FMul (rest, 524288.0))
    m2 := m / $10000
    m1 := (m - m2 * $10000) / $100
    m0 := (m - m2 * $10000 - m1 * $100)

' PROP_FREQ_CONTROL_GROUP
    freq_control.byte[0] := m0
    freq_control.byte[1] := m1
    freq_control.byte[2] := m2
    freq_control.byte[3] := n
    return setProperty(core#GROUP_FREQ, 4, core#FREQ_CONTROL_INTE, @freq_control)

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
'           FRRMODE_DISABLED (0): Disabled. Will always read back 0.
'           FRRMODE_INT_STATUS (1): Global status
'           FRRMODE_INT_PEND (2): Global interrupt pending
'           FRRMODE_INT_PH_STATUS (3): Packet Handler status
'           FRRMODE_INT_PH_PEND (4): Packet Handler interrupt pending
'           FRRMODE_INT_MODEM_STATUS (5): Modem status
'           FRRMODE_INT_MODEM_PEND (6): Modem interrupt pending
'           FRRMODE_INT_CHIP_STATUS (7): Chip status
'           FRRMODE_INT_CHIP_PEND (8): Chip status interrupt pending
'           FRRMODE_CURRENT_STATE (9): Current state
'           FRRMODE_LATCHED_RSSI (10): Latched RSSI value
    tmp := 0
    case reg
        FRR_A..FRR_D:
        OTHER:
            return

    getProperty(core#GROUP_FRR_CTL, 1, reg, @tmp)

    case mode
        FRRMODE_DISABLED..FRRMODE_LATCHED_RSSI:
        OTHER:
            return tmp

    setProperty(core#GROUP_FRR_CTL, 1, reg, @mode)

PUB FIFORXBytes
' Returns: number of bytes in the RX FIFO
    readReg(core#FIFO_INFO, 1, @result)

PUB FIFOTXBytes
' Returns: number of bytes in the TX FIFO
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

PUB Modulation(type) | tmp
' Set modulation type
'   Valid values:
'       MOD_CW (0): Continuous Wave
'       MOD_OOK (1): On-Off Keying
'       MOD_2FSK (2): 2-level Frequency Shift Keying
'       MOD_2GFSK (3): 2-level Gaussian Frequency Shift Keying
'       MOD_4FSK (4): 4-level Frequency Shift Keying
'       MOD_4GFSK (5): 4-level Gaussian Frequency Shift Keying
'   Any other value polls the chip and returns the current setting
    tmp := 0
    getProperty(core#GROUP_MODEM, 1, core#MODEM_MOD_TYPE, @tmp)
    case type
        MOD_CW, MOD_OOK, MOD_2FSK, MOD_2GFSK, MOD_4FSK, MOD_4GFSK:
        OTHER:
            return (tmp & core#BITS_MOD_TYPE)

    tmp &= core#MASK_MOD_TYPE
    tmp := (tmp | type) & core#MASK_MODEM_MOD_TYPE
    setProperty(core#GROUP_MODEM, 1, core#MODEM_MOD_TYPE, @tmp)

PUB PartID | tmp
' Read the Part ID from the device
'   Returns: 4-digit part ID
    tmp := 0
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
            _fxtal := osc_freq
        OTHER:
            tmp.byte[core#ARG_XO_FREQ_MSB] := $01
            tmp.byte[core#ARG_XO_FREQ_MSMB] := $C9
            tmp.byte[core#ARG_XO_FREQ_LSMB] := $C3
            tmp.byte[core#ARG_XO_FREQ_LSB] := $80
            _fxtal := 30_000_000
    result := writeReg(core#POWER_UP, 6, @tmp)

PUB Preamble(bytes) | tmp
' Set preamble length, in bytes
'   Valid values: 0..255
'   Any other value polls the chip and returns the current setting
'   NOTE: 0 effectively disables transmitting the preamble. In this case, the sync word will be the first transmitted field.
    tmp := 0
    getProperty(core#GROUP_PREAMBLE, 1, core#PREAMBLE_TX_LENGTH, @tmp)
    case bytes
        0..255:
        OTHER:
            return tmp

    setProperty(core#GROUP_PREAMBLE, 1, core#PREAMBLE_TX_LENGTH, @bytes)

PUB NoOp

    return readReg(core#NOOP, 0, @result)

PUB RXData(nr_bytes, buff_addr)
' Read nr_bytes from RX FIFO into buff_addr
'   NOTE: Buffer must be large enough to hold nr_bytes
    readReg(core#READ_RX_FIFO, nr_bytes, @buff_addr)

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
    tmp := 0
    readReg(core#FAST_RESP_C, 1, @tmp)
    case new_state
        STATE_SLEEP, STATE_SPI_ACTIVE, STATE_READY, STATE_TX_TUNE, STATE_RX_TUNE, STATE_TX, STATE_RX:
        OTHER:
            return tmp

    result := writeReg(core#CHANGE_STATE, 1, @new_state)

PUB SyncWord(syncbits) | tmp
' Set sync word for TX and RX operation
'   Valid values: $00_00_00_01..$FF_FF_FF_FF
'   Any other value polls the chip and returns the current setting
    tmp := 0
    getProperty(core#GROUP_SYNC, 4, core#SYNC_BITS_MSB, @tmp)
    case syncbits
        $00000001..$7FFFFFFF, $80000000..$FFFFFFFF:
            syncbits := swap(syncbits)
        OTHER:          ' Disallow all zeroes for sync word to accomodate querying
            return swap(tmp)

    result := setProperty(core#GROUP_SYNC, 4, core#SYNC_BITS_MSB, @syncbits)

PUB SyncWordLen(length) | tmp
' Set sync word length, in bytes
'   Valid values: 1..4
'   Any other value polls the chip and returns the current setting
    tmp := 0
    getProperty(core#GROUP_SYNC, 1, core#SYNC_CONFIG, @tmp)
    case length
        1..4:
            length -= 1
        OTHER:
            return (tmp & core#BITS_LENGTH) + 1

    tmp &= core#MASK_LENGTH
    tmp := (tmp | length) & core#MASK_SYNC_CONFIG
    result := setProperty(core#GROUP_SYNC, 1, core#SYNC_CONFIG, @tmp)

PUB TXRate(bps): TX_DATA_RATE | MODEM_DATA_RATE, NCO_CLK_FREQ, TXOSR, NCOMOD
' NCO_CLK_FREQ = (MODEM_DATA_RATE*Fxtal_Hz/MODEM_TX_NCO_MODE)
' TX_DATA_RATE=(NCO_CLK_FREQ/TXOSR)
' Defaults: 
' NCO_CLK_FREQ = (1_000_000*30_000_000/30_000_000
' TX_DATA_RATE=(1000000/10)
' Data rate=100_000 bps
    MODEM_DATA_RATE := NCO_CLK_FREQ := TXOSR := NCOMOD := 0
    getProperty(core#GROUP_MODEM, 3, core#MODEM_DATA_RATE, @MODEM_DATA_RATE)
    getProperty(core#GROUP_MODEM, 4, core#MODEM_TX_NCO_MODE, @TXOSR)
    case bps
        'TODO: Case for 40x?
        100..199_999:
            TXOSR := TXOSR_10X << 26
            MODEM_DATA_RATE := bps*10
            NCOMOD := _fxtal/10
            TXOSR |= NCOMOD

        200_000..1_000_000:
            TXOSR := TXOSR_10X << 26
            MODEM_DATA_RATE := bps*10
            NCOMOD := _fxtal
            TXOSR |= NCOMOD

        OTHER:
            NCOMOD := TXOSR & $3_FF_FF_FF
            TXOSR := lookupz((TXOSR >> 26): 10, 40, 20)
'            NCO_CLK_FREQ := (MODEM_DATA_RATE * _fxtal) / NCOMOD
            if NCOMOD < _fxtal
                NCO_CLK_FREQ := u64.MultDiv (MODEM_DATA_RATE, _fxtal/10, NCOMOD)
            else
                NCO_CLK_FREQ := u64.MultDiv (MODEM_DATA_RATE, _fxtal, NCOMOD)'(x, num, denom)
            TX_DATA_RATE := NCO_CLK_FREQ / TXOSR

    setProperty( core#GROUP_MODEM, 3, core#MODEM_DATA_RATE, @MODEM_DATA_RATE)
    setProperty( core#GROUP_MODEM, 4, core#MODEM_TX_NCO_MODE, @TXOSR)

PRI swap(swp_long) | i

    repeat i from 0 to 3
        result.byte[i] := swp_long.byte[3-i]

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

PRI getProperty (group, nr_props, start_prop, buff_addr) | tmp, i
' Read one or more properties from the device into buffer at buff_addr
    tmp.byte[0] := core#GET_PROPERTY
    tmp.byte[1] := group
    tmp.byte[2] := nr_props
    tmp.byte[3] := start_prop
    clearToSend (DESELECT_AFTER)
    outa[_CS] := 0
    repeat i from 0 to 3
        spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, tmp.byte[i])
    outa[_CS] := 1
    clearToSend (NO_DESELECT_AFTER) ' Check CTS, but leave the chip selected afterwards, because
    repeat i from nr_props-1 to 0   '   the data needs to be read in the same transaction as the check.
        byte[buff_addr][i] := spi.SHIFTIN (_MISO, _SCK, core#MISO_BITORDER, 8)
    outa[_cs] := 1

PRI setProperty (group, nr_props, start_prop, buff_addr) | tmp, i
' Write one or more properties to the device from buffer at buff_addr
    clearToSend (DESELECT_AFTER)
    tmp.byte[0] := core#SET_PROPERTY
    tmp.byte[1] := group
    tmp.byte[2] := nr_props
    tmp.byte[3] := start_prop
    outa[_CS] := 0
    repeat i from 0 to 3
        spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, tmp.byte[i])
    repeat i from nr_props-1 to 0
        spi.SHIFTOUT (_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buff_addr][i])
    outa[_CS] := 1
    clearToSend (DESELECT_AFTER)

PRI readReg(reg, nr_bytes, buff_addr) | tmp, i

    case reg
{        core#GET_PROPERTY:
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
}
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
    if result == CLEAR
        outa[_CS] := 0
        spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg)
    
        case nr_bytes
            1..64:
                repeat i from 0 to nr_bytes-1
                    spi.SHIFTOUT(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[buf_addr][i])
            OTHER:
        outa[_CS] := 1
        return
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
