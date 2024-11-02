{
----------------------------------------------------------------------------------------------------
    Filename:       wireless.transceiver.si446x.spin
    Description:    Driver for Silicon Labs Si446x series transceivers
    Author:         Jesse Burt
    Started:        Jun 22, 2019
    Updated:        Nov 2, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    { default I/O settings; these can be overridden in the parent object }
    { SPI }
    CS                      = 0
    SCK                     = 1
    MOSI                    = 2
    MISO                    = 3
    SDN                     = 0

    F_XOSC                  = core.OSC_FREQ_NOMINAL ' SI446x oscillator freq
    ' --

' Some constants used in various calculations
    NPRESC                  = 2                 ' Prescaler divider - do not change
    F_XOSC_PRESCALE         = F_XOSC * NPRESC
    NINETN                  = 1 << 19
    FP_SCALE                = 1_000_000         ' Scale for fixed-point math


    FRAC_MSB                = 2                 ' Byte indexes within the
    FRAC_MID                = 1                 ' fractional-N PLL property
    FRAC_LSB                = 0
    INTE_S                  = 3                 ' and integer property

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
    byte _CS
    byte _SDN


OBJ

    spi:    "com.spi.1mhz"                      ' SPI engine
    core:   "core.con.si446x"                   ' HW-specific constants
    time:   "time"                              ' timekeeping methods
    u64:    "math.unsigned64"                   ' unsigned 64-bit math


PUB null()
' This is not a top-level object


PUB start(): status
' Start the driver using default I/O settings
    return startx(CS, SCK, MOSI, MISO, SDN)


PUB startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN, SDN_PIN): status
' Start the driver with custom I/O settings
'   CS_PIN:     chip select, 0..31
'   SCK_PIN:    serial clock, 0..31
'   MOSI_PIN:   master-out slave-in, 0..31
'   MISO_PIN:   master-in slave-out, 0..31
'   SDN_PIN:    shutdown, 0..31
'   Returns:
'       cog ID+1 of SPI engine on success (= calling cog ID+1, if the bytecode SPI engine is used)
'       0 on failure
    if ( status := spi.init(SCK_PIN, MOSI_PIN, MISO_PIN, core.SPI_MODE) )
        time.usleep(core.T_POR)
        _CS := CS_PIN
        _SDN := SDN_PIN
        outa[_CS]:=1
        dira[_CS]:=1
        if ( lookdown(dev_id(): $4460, $4461, $4463, $4464) )
            power_up(core.OSC_FREQ_NOMINAL)
                return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE


PUB stop()
' Stop the driver
    spi.deinit()


PUB carrier_freq(freq=-2): c | tmp_fc, tmp_band, plldiv, pfd_freq, inte, ratio, rest, frac
' Set carrier frequency, in Hz
'   Valid values:
'       SI4460, 4461, 4463:
'           142_000_000..175_000_000
'           284_000_000..350_000_000
'           425_000_000..525_000_000
'           850_000_000..1_050_000_000
'   Any other value is ignored
'   NOTE: This setting takes effect only when transitioning to TX or RX state
    tmp_fc := tmp_band := 0
    tmp_fc := get_property(core.GROUP_FREQ, 4, core.FREQ_CONTROL_INTE)
    tmp_band := get_property(core.GROUP_MODEM, 1, core.MODEM_CLKGEN_BAND)
    case freq
        142_000_000..175_000_000:
            plldiv := 24
        284_000_000..350_000_000:
            plldiv := 12
        420_000_000..525_000_000:
            plldiv := 8
        850_000_000..1_050_000_000:
            plldiv := 4                         ' SI446x internal PLL is ~3.6GHz
        other:
            inte := tmp_fc.byte[INTE_S]
            frac := (tmp_fc.byte[FRAC_MSB] << 16) | (tmp_fc.byte[FRAC_MID] << 8) | tmp_fc.byte[FRAC_LSB]
            tmp_band &= core.BAND_BITS
            plldiv := lookupz(tmp_band: 4, 6, 8, 12, 16, 24, 24, 24)
            inte *= FP_SCALE
            rest := u64.multdiv(frac, FP_SCALE, NINETN)
            return u64.multdiv( (inte + rest), (F_XOSC_PRESCALE / plldiv), FP_SCALE)

    tmp_band := lookdownz(plldiv: 4, 6, 8, 12, 16, 24, 24, 24)
    tmp_band |= (1 << core.SY_SEL)              ' Make sure the SY_SEL field is set
                                                ' (calcs below only valid if so)
    pfd_freq := F_XOSC_PRESCALE / plldiv
    inte := (freq / pfd_freq) - 1
    inte *= FP_SCALE
    ratio := u64.multdiv(freq, FP_SCALE, pfd_freq)
    rest := ratio - inte
    frac := u64.multdiv(rest, 524_288, FP_SCALE)

    tmp_fc.byte[FRAC_MSB] := frac >> 16
    tmp_fc.byte[FRAC_MID] := (frac - tmp_fc.byte[FRAC_MSB] << 16) >> 8
    tmp_fc.byte[FRAC_LSB] := (frac - tmp_fc.byte[FRAC_MSB] << 16 - tmp_fc.byte[FRAC_MID] << 8)
    tmp_fc.byte[INTE_S] := inte / FP_SCALE

    set_property(core.GROUP_MODEM, 1, core.MODEM_CLKGEN_BAND, tmp_band)
    set_property(core.GROUP_FREQ, 4, core.FREQ_CONTROL_INTE, tmp_fc)


PUB int_clear() | l
' Clear interrupts
    l := command(core.GET_INT_STATUS)
    return @_response


PUB clk_test(clkdiv): r | tmp[2]
' Test system clock output, divided by clkdiv
'   Valid values: 1, 2, 3, 7_5 (7.5), 10, 15, 30
'   Any other value sets the divisor to 1
    tmp := $00
    case clkdiv
        1, 2, 3, 7_5, 10, 15, 30:
            clkdiv := lookdownz(clkdiv: 1, 2, 3, 7_5, 10, 15, 30)
        other:
            clkdiv := core.DIV_1

    tmp.byte[core.ARG_GPIO0] := core.PULL_EN | core.GPIO_DIV_CLK
    tmp.byte[core.ARG_GPIO1] := core.PULL_EN | core.GPIO_CTS
    tmp.byte[core.ARG_GPIO2] := core.PULL_EN | core.GPIO_TRISTATE
    tmp.byte[core.ARG_GPIO3] := core.PULL_EN | core.GPIO_TRISTATE
    tmp.byte[core.ARG_NIRQ] := core.PULL_EN | core.GPIO_NIRQ
    tmp.byte[core.ARG_SDO] := core.PULL_EN | core.GPIO_SDO
    tmp.byte[core.ARG_GEN_CONFIG] := core.DRV_STRENGTH_HIGH

    command(core.GPIO_PIN_CFG, @tmp, 7)
    tmp[0] := 0
    tmp[1] := 0
    tmp := (1 << core.DIV_CLK_EN) | (clkdiv << core.DIV_CLK_SEL)
    r := set_property(core.GROUP_GLOBAL, 1, core.GLOBAL_CLK_CFG, tmp)


PUB data_rate(rate=-2): c | MODEM_DATA_RATE, NCO_CLK_FREQ, TXOSR, NCOMOD
' NCO_CLK_FREQ = (MODEM_DATA_RATE*Fxtal_Hz/MODEM_TX_NCO_MODE)
' curr_rate=(NCO_CLK_FREQ/TXOSR)
' Defaults:
' NCO_CLK_FREQ = (1_000_000*30_000_000/30_000_000
' curr_rate=(1000000/10)
' Data rate=100_000 rate
    MODEM_DATA_RATE := NCO_CLK_FREQ := TXOSR := NCOMOD := 0
    MODEM_DATA_RATE := get_property(core.GROUP_MODEM, 3, core.MODEM_DATA_RATE)
    TXOSR := get_property(core.GROUP_MODEM, 4, core.MODEM_TX_NCO_MODE)
    case rate
        'TODO: Case for 40x?
        100..199_999:
            TXOSR := TXOSR_10X << 26
            MODEM_DATA_RATE := rate'*10  299.300 303.500
            NCOMOD := _fxtal/10
            TXOSR |= NCOMOD
        200_000..1_000_000:
            TXOSR := TXOSR_10X << 26
            MODEM_DATA_RATE := rate*10
            NCOMOD := _fxtal
            TXOSR |= NCOMOD
        other:
            NCOMOD := TXOSR & $3_FF_FF_FF
            TXOSR := lookupz((TXOSR >> 26): 10, 40, 20)
'            NCO_CLK_FREQ := (MODEM_DATA_RATE * _fxtal) / NCOMOD
            if ( NCOMOD < _fxtal )
                NCO_CLK_FREQ := u64.multdiv (MODEM_DATA_RATE, _fxtal/10, NCOMOD)
            else
                NCO_CLK_FREQ := u64.multdiv (MODEM_DATA_RATE, _fxtal, NCOMOD)'(x, num, denom)
            c := NCO_CLK_FREQ / TXOSR
            return ( c * 10 )

    set_property(core.GROUP_MODEM, 3, core.MODEM_DATA_RATE, MODEM_DATA_RATE)
    set_property(core.GROUP_MODEM, 4, core.MODEM_TX_NCO_MODE, TXOSR)


PUB dev_id(): id
' Read the Part ID from the device
'   Returns: 4-digit part ID
    command(core.PART_INFO)
    return (_response[core.REPL_PARTMSB] << 8) | _response[core.REPL_PARTLSB]


PUB fast_resp_reg_cfg(reg_nr, mode): resp | tmp
' Configure the information available in the Fast-Response Registers A, B, C, D
'   Valid values:
'       reg_nr: FRR_A (0), FRR_B (1), FRR_C (2), FRR_D (3)
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
    ifnot ( lookdown(reg_nr: FRR_A..FRR_D) )
        return

    case mode
        FRRMODE_DISABLED..FRRMODE_LATCHED_RSSI:
            set_property(core.GROUP_FRR_CTL, 1, reg, mode)
        other:
            tmp := 0
            return get_property(core.GROUP_FRR_CTL, 1, reg)



PUB fifo_rx_bytes(): r
' Returns: number of bytes in the RX FIFO
    command(core.FIFO_INFO)
    return _response[0]


PUB fifo_tx_bytes(): t
' Returns: number of bytes in the TX FIFO
    command(core.FIFO_INFO)
    return _response[1]


PUB flush_rx()
' Flush the RX FIFO
    command(core.FIFO_INFO, (1 << core.RX), 1)


PUB flush_tx()
' Flush the TX FIFO
    command(core.FIFO_INFO, 1, 1)


PUB freq_dev(freq=-2): c | tmp, outdiv, tmp1, tmp2
' Set carrier frequency deviation, in Hz
'   Valid values: 29..1_500_000
'   Any other value polls the chip and returns the current setting
'   NOTE: The resolution of the Si446x synthesizer is 28.6Hz. Value set will be nearest multiple.
    outdiv := 0
    outdiv := get_property(core.GROUP_MODEM, 1, core.MODEM_CLKGEN_BAND)
    outdiv := lookupz(outdiv & core.BAND_BITS: 4, 6, 8, 12, 16, 24, 24, 24)
    case freq
        29..1_500_000:'28.6hz res
            tmp1 := NINETN * outdiv
            tmp2 := NPRESC * F_XOSC
            freq := u64.multdiv(tmp1, freq, tmp2)
            set_property(core.GROUP_MODEM, 3, core.MODEM_FREQ_DEV, freq)
        other:
            tmp := 0
            tmp := get_property(core.GROUP_MODEM, 3, core.MODEM_FREQ_DEV)
            tmp1 := NPRESC * F_XOSC
            tmp2 := NINETN * outdiv
            return u64.multdiv(tmp, tmp1, tmp2)



PUB idle()
' Change transceiver to idle state
    opmode(STATE_SPI_ACTIVE)


PUB interrupt(): i | tmp
' Read interrupt status
'   Returns: interrupt states
'   b23..0:
'       22: CAL_PEND
'       21: FIFO_UNDERFLOW_OVERFLOW_ERROR_PEND
'       20: STATE_CHANGE_PEND
'       19: CMD_ERROR_PEND
'       18: CHIP_READY_PEND
'       17: LOW_BATT_PEND
'       16: WUT_PEND
'       15: RSSI_LATCH_PEND
'       14: POSTAMBLE_DETECT_PEND
'       13: INVALID_SYNC_PEND
'       12: RSSI_JUMP_PEND
'       11: RSSI_PEND
'       10: INVALID_PREAMBLE_PEND
'       9:  PREAMBLE_DETECT_PEND
'       8:  SYNC_DETECT_PEND
'       7:  FILTER_MATCH_PEND
'       6:  FILTER_MISS_PEND
'       5:  PACKET_SENT_PEND
'       4:  PACKET_RX_PEND
'       3:  CRC_ERROR_PEND
'       2:  ALT_CRC_ERROR_PEND
'       1:  TX_FIFO_ALMOST_EMPTY_PEND
'       0:  RX_FIFO_ALMOST_FULL_PEND
    ' set bits in the command args to ensure the corresponding interrupts don't get cleared;
    '   we just want to read their current state
    tmp.byte[core.ARG_PH_CLR_PEND] := %1111_1111
    tmp.byte[core.ARG_MODEM_CLR_PEND] := %1111_1111
    tmp.byte[core.ARG_CHIP_CLR_PEND] := %0111_1111
    command(core.GET_INT_STATUS, tmp, 3)
    i.byte[0] := _response[2]                   ' PH_PEND
    i.byte[1] := _response[4]                   ' MODEM_PEND
    i.byte[2] := _response[6]                   ' CHIP_PEND


PUB modulation(mode=-2): c | tmp
' Set modulation mode
'   Valid values:
'       MOD_CW (0): Continuous Wave
'       MOD_OOK (1): On-Off Keying
'       MOD_2FSK (2): 2-level Frequency Shift Keying
'       MOD_2GFSK (3): 2-level Gaussian Frequency Shift Keying
'       MOD_4FSK (4): 4-level Frequency Shift Keying
'       MOD_4GFSK (5): 4-level Gaussian Frequency Shift Keying
'   Any other value polls the chip and returns the current setting
    tmp := get_property(core.GROUP_MODEM, 1, core.MODEM_MOD_TYPE)
    case mode
        MOD_CW, MOD_OOK, MOD_2FSK, MOD_2GFSK, MOD_4FSK, MOD_4GFSK:
            tmp &= core.MOD_TYPE_MASK
            tmp := (tmp | mode) & core.MODEM_MOD_TYPE_MASK
            set_property(core.GROUP_MODEM, 1, core.MODEM_MOD_TYPE, tmp)
        other:
            return (tmp & core.MOD_TYPE_BITS)


PUB opmode(st=-2): c
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
    case st
        STATE_SLEEP, STATE_SPI_ACTIVE, STATE_READY, STATE_TX_TUNE, STATE_RX_TUNE, STATE_TX, ...
        STATE_RX:
            command(core.CHANGE_STATE, st, 1)
        other:
            command(core.FRR_C_READ)
            return _response[0]


PUB payld_len(len=-2): c
' Set payload length, in bytes
'   Valid values: 0..8191
'   Any other value polls the chip and returns the current setting
    case len
        0..8191:
            set_property(core.GROUP_PKT, 2, core.PKT_FIELD_1_LENGTH, len)
        other:
            return get_property(core.GROUP_PKT, 2, core.PKT_FIELD_1_LENGTH)


PUB power_up(osc_freq=-2): r | tmp[2]
' Perform device powerup, and specify oscillator frequency, in Hz
'   Valid values: 25_000_000 to 32_000_000
'   Any other value sets the nominal 30_000_000
    tmp.byte[core.ARG_BOOT_OPTIONS] := core.EZRADIO_PRO
    tmp.byte[core.ARG_XTAL_OPTIONS] := core.XO_XTAL
    case osc_freq
        25_000_000..32_000_000:
            tmp.byte[core.ARG_XO_FREQ_MSB] := osc_freq.byte[3]
            tmp.byte[core.ARG_XO_FREQ_MSMB] := osc_freq.byte[2]
            tmp.byte[core.ARG_XO_FREQ_LSMB] := osc_freq.byte[1]
            tmp.byte[core.ARG_XO_FREQ_LSB] := osc_freq.byte[0]
            _fxtal := osc_freq
        other:
            tmp.byte[core.ARG_XO_FREQ_MSB] := $01
            tmp.byte[core.ARG_XO_FREQ_MSMB] := $C9
            tmp.byte[core.ARG_XO_FREQ_LSMB] := $C3
            tmp.byte[core.ARG_XO_FREQ_LSB] := $80
            _fxtal := 30_000_000
    command(core.POWER_UP, @tmp, 6)


PUB preamble_len(len=-2): c
' Set preamble length, in bytes
'   Valid values: 0..255
'   Any other value polls the chip and returns the current setting
'   NOTE: 0 effectively disables transmitting the preamble. In this case, the sync word will be the first transmitted field.
    case len
        0..255:
            set_property(core.GROUP_PREAMBLE, 1, core.PREAMBLE_TX_LENGTH, len)
        other:
            return get_property(core.GROUP_PREAMBLE, 1, core.PREAMBLE_TX_LENGTH)


PUB rx_bw(bw=-2)
'XXX WIP
    bw &= $F0
    set_property(core.GROUP_MODEM, 1, core.MODEM_DECIMATION_CFG1, bw)


PUB rx_mode() | cmd_pkt[2]
' Change chip state to receive
    cmd_pkt.byte[0] := 0                        ' Channel
    cmd_pkt.byte[1] := 0                        ' Update, Start
    cmd_pkt.byte[2] := 0                        ' Length MSB
    cmd_pkt.byte[3] := 0                        '   LSB (use payld_len() )
    cmd_pkt.byte[4] := 0                        ' Post-timeout state
    cmd_pkt.byte[5] := 0                        ' Post-valid packet state
    cmd_pkt.byte[6] := 0                        ' Post-invalid packet state
    command(core.START_RX, @cmd_pkt, 7)


PUB rx_payld(nr_bytes, p_buff)
' Read data from the RX FIFO
'   nr_bytes:   number of bytes to read (1..64; clamped to range)
'   p_buff:     pointer to destination buffer (must be sized nr_bytes or larger)
    outa[_CS] := 0
        spi.wr_byte(core.READ_RX_FIFO)
        spi.wrblock_lsbf(p_buff, 1 #> nr_bytes <# 64)
    outa[_CS] := 1


PUB set_syncwd(p_swd): r
' Set transmitted (TX) or expected (RX) syncword
'   swd: pointer to syncword data
    p_swd := long[p_swd]
    return set_property(core.GROUP_SYNC, 4, core.SYNC_BITS_MSB, p_swd)


PUB syncwd(p_swd=0): r
' Get current syncword
'   p_swd: pointer to buffer to copy syncword data to (must be at least 4 bytes in length)
    r := get_property(core.GROUP_SYNC, 4, core.SYNC_BITS_MSB)
    if ( p_swd )
        long[p_swd] := r
    return


PUB syncwd_len(length=-2): c
' Set sync word length, in bytes
'   Valid values: 1..4
'   Any other value polls the chip and returns the current setting
    c := get_property(core.GROUP_SYNC, 1, core.SYNC_CONFIG)
    case length
        1..4:
            length -= 1
            c &= core.LENGTH_MASK
            c := (c | length) & core.SYNC_CONFIG_MASK
            c := set_property(core.GROUP_SYNC, 1, core.SYNC_CONFIG, c)
        other:
            return (c & core.LENGTH_BITS) + 1


PUB tx_mode() | byte cmd_pkt[6]
' Change chip state to transmit
    cmd_pkt[0] := 0                             ' Channel
    cmd_pkt[1] := (STATE_TX_TUNE << core.TXCOMPLETE_STATE)   ' Condition
    cmd_pkt[2] := 0                             ' Length MSB
    cmd_pkt[3] := 0                             '   LSB
    cmd_pkt[4] := 0                             ' Inter-packet delay (uS)
    cmd_pkt[5] := 0                             ' Repeat packet nr_times
    command(core.START_TX, @cmd_pkt, 6)


PUB tx_payld(nr_bytes, p_buff)
' Queue data to be transmitted
'   nr_bytes:   number of bytes to queue (1..64; clamped to range)
'   p_buff:     pointer to source buffer of data
    outa[_CS] := 0
        spi.wr_byte(core.WRITE_TX_FIFO)
        spi.wrblock_lsbf(p_buff, 1 #> nr_bytes <# 64)
    outa[_CS] := 1


PUB tx_pwr(pwr=-255): c
' Set transmit power level, in dBm
'   Valid values: 0..127
'   Any other value polls the chip and returns the current setting
'   NOTE: XXX This is currently not taken in pwr, but register value, as the datasheet doesn't provide a formula for calculating power level.
    case pwr
        0..127:
            set_property(core.GROUP_PA, 1, core.PA_POWER_LEVEL, pwr)
        other:
            c := get_property(core.GROUP_PA, 1, core.PA_POWER_LEVEL)
            return (c & core.DDAC_BITS)


PRI cleartosend(deselect=false)
' Check the CTS (Clear-to-Send) status from the device
'   Valid values:
'       DESELECT_AFTER (non-zero):  Raise CS after checking
'       NO_DESELECT_AFTER (0):      Don't raise CS after checking - needed for reads where the data
'           read must be in the same CS "frame" as the CTS check.
'   Returns: TRUE if clear to send, FALSE otherwise
    repeat
        outa[_CS] := 0
        spi.wr_byte(core.READ_CMD_BUFF)
        result := spi.rd_byte()
        if ( result <> $FF )
            outa[_CS] := 1
    until (result == $FF)
    if ( deselect )
        outa[_CS] := 1

    return


PRI get_property(grp, n_props, s_prop): val | tmp
' Read one or more properties from the device
'   grp:        group ID
'   n_props:    number of properties to read
'   s_prop:     first property ID
'   Returns:
'       value read from property
    tmp.byte[0] := core.GET_PROPERTY
    tmp.byte[1] := grp
    tmp.byte[2] := n_props
    tmp.byte[3] := s_prop
    outa[_CS] := 0
        spi.wrblock_lsbf(@tmp, 4)
    outa[_CS] := 1
    ' check CTS, but leave the chip selected afterwards, because the data needs to be read in
    '   the same transaction as the check.
    cleartosend(NO_DESELECT_AFTER)
    spi.rdblock_msbf(@val, n_props)
    outa[_CS] := 1


PRI set_property(grp, n_props, s_prop, val) | tmp
' Write one or more properties to the device from buffer at ptr_buff
'   grp:        group ID
'   n_props:    number of properties to read
'   s_prop:     first property ID
'   val:        value to write (1..4 bytes; MSByte-first)
    cleartosend(DESELECT_AFTER)
    tmp.byte[0] := core.SET_PROPERTY
    tmp.byte[1] := grp
    tmp.byte[2] := n_props
    tmp.byte[3] := s_prop
    outa[_CS] := 0
        spi.wrblock_lsbf(@tmp, 4)
        spi.wrblock_msbf(@val, n_props)
    outa[_CS] := 1
    cleartosend(DESELECT_AFTER)


VAR

    byte _response[15]                          ' command response buffer

PRI command(cmd, p_args=0, n_args=0): r
' Issue command to the chip
'   cmd:    command
'   p_args:
'       value to write as argument(s) to command
'       pointer to source buffer containing arguments
'   n_args: number of arguments (0..n)
    cleartosend(DESELECT_AFTER)                 ' wait for chip to be ready (and raise CS after)
    outa[_CS] := 0
        spi.wr_byte(cmd)
        if ( n_args > 0 )                       ' any args to write? (also protect against neg #'s)
            if ( n_args =< 4 )                  ' arg cnt <= 4: read directly
                spi.wrblock_lsbf(@p_args, n_args)
            else                                ' arg cnt >4:   read by pointer
                spi.wrblock_lsbf(p_args, n_args)
    outa[_CS] := 1

    return read_resp(cmd)


PRI read_resp(r): l
' Read response from the chip to a command
'   r:  command to read response from
    case r                                      ' set length of response data to read based on cmd
        core.PART_INFO, core.GET_MODEM_STATUS, core.GET_INT_STATUS:
            l := 8
        core.GPIO_PIN_CFG:
            l := 7
        core.FUNC_INFO, core.GET_ADC_READING:
            l := 6
        core.FRR_A_READ..core.FRR_D_READ, core.GET_CHIP_STATUS:
            l := 4
        core.FIFO_INFO, core.REQUEST_DEVICE_STATE, core.IRCAL_MANUAL, core.PACKET_INFO, ...
        core.GET_PH_STATUS:
            l := 2

    repeat
    until cleartosend(NO_DESELECT_AFTER)        ' leave the line open after checking CTS
    bytefill(@_response, 0, 15)                 ' clear the response buffer
    spi.rdblock_lsbf(@_response, l)
    outa[_CS] := 1


DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

