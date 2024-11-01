{
----------------------------------------------------------------------------------------------------
    Filename:       core.con.si446x.spin
    Description:    SI446x-specific constants
    Author:         Jesse Burt
    Started:        Jun 22, 2019
    Updated:        Nov 1, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

' SPI Configuration
    SCK_MAX_FREQ                = 10_000_000
    SPI_MODE                    = 0

    OSC_FREQ_NOMINAL            = 30_000_000    ' 30MHz nominal oscillator freq
    T_POR                       = 5_000         ' uSec

    NOT_CLEAR                   = $00
    CLEAR                       = $FF           ' Value returned by the device if it is Clear to Send/ready for commands

' Register definitions

    NOOP                        = $00
    PART_INFO                   = $01
        REPL_CHIPREV            = 0             ' Byte Index
        REPL_PARTMSB            = 1
        REPL_PARTLSB            = 2
        REPL_PBUILD             = 3
        REPL_IDMSB              = 4
        REPL_IDLSB              = 5
        REPL_CUSTOMER           = 6
        REPL_ROMID              = 7

    POWER_UP                    = $02
        ARG_BOOT_OPTIONS        = 0
            PATCH               = 7
            FUNC                = 0
            FUNC_BITS           = %111111
            EZRADIO_PRO         = 1
            NO_PATCH            = 0 << PATCH
            DO_PATCH            = 1 << PATCH
        ARG_XTAL_OPTIONS        = 1
            TCXO                = 0
            XO_XTAL             = 0 << TCXO
            XO_TCXO             = 1 << TCXO
        ARG_XO_FREQ_MSB         = 2
        ARG_XO_FREQ_MSMB        = 3
        ARG_XO_FREQ_LSMB        = 4
        ARG_XO_FREQ_LSB         = 5

    FUNC_INFO                   = $10
    SET_PROPERTY                = $11
    GET_PROPERTY                = $12

    GPIO_PIN_CFG                = $13
        GPIO_DONOTHING          = 0
        GPIO_TRISTATE           = 1
        GPIO_DRIVE0             = 2
        GPIO_DRIVE1             = 3
        GPIO_INPUT              = 4
        GPIO_DIV_CLK            = 7
        GPIO_CTS                = 8
        GPIO_SDO                = 11
        GPIO_POR                = 12
        GPIO_EN_PA              = 15
        GPIO_TX_DATA_CLK        = 16
        GPIO_RX_DATA_CLK        = 17
        GPIO_EN_LNA             = 18
        GPIO_TX_DATA            = 19
        GPIO_RX_DATA            = 20
        GPIO_RX_RAW_DATA        = 21
        GPIO_ANTENNA_1_SW       = 22
        GPIO_ANTENNA_2_SW       = 23
        GPIO_VALID_PREAMBLE     = 24
        GPIO_INVALID_PREAMBLE   = 25
        GPIO_SYNC_WORD_DETECT   = 26
        GPIO_CCA                = 27
        GPIO_PKT_TRACE          = 29
        GPIO_TX_RX_DATA_CLK     = 31
        GPIO_NIRQ               = 39
        ARG_GPIO0               = 0
        ARG_GPIO1               = 1
        ARG_GPIO2               = 2
        ARG_GPIO3               = 3
        ARG_NIRQ                = 4
        ARG_SDO                 = 5
            PULL_CTL            = 6
            PULL_DIS            = 0 << PULL_CTL
            PULL_EN             = 1 << PULL_CTL
        ARG_GEN_CONFIG          = 6
            DRV_STRENGTH        = 5
            DRV_STRENGTH_BITS   = %11
            DRV_STRENGTH_HIGH   = 0
            DRV_STRENGTH_MEDHIGH= 1
            DRV_STRENGTH_MEDLOW = 2
            DRV_STRENGTH_LOW    = 3

    GET_ADC_READING             = $14

    FIFO_INFO                   = $15
        ARG_FIFO                = 0
        TX                      = 0
        RX                      = 1

    PACKET_INFO                 = $16
    IRCAL                       = $17
    IRCAL_MANUAL                = $1A

    GET_INT_STATUS              = $20
        ARG_PH_CLR_PEND         = 0
        ARG_MODEM_CLR_PEND      = 1
        ARG_CHIP_CLR_PEND       = 2

    GET_PH_STATUS               = $21
    GET_MODEM_STATUS            = $22
    GET_CHIP_STATUS             = $23

    START_TX                    = $31
    CONDITION_MASK              = $FF
        TXCOMPLETE_STATE        = 4
        UPDATE                  = 3
        RETRANSMIT              = 2
        START                   = 0
        TXCOMPLETE_STATE_BITS   = %1111
        START_BITS              = %11
        TXCOMPLETE_STATE_MASK   = (TXCOMPLETE_STATE_BITS << TXCOMPLETE_STATE) ^ CONDITION_MASK
        UPDATE_MASK             = (1 << UPDATE) ^ CONDITION_MASK
        RETRANSMIT_MASK         = (1 << RETRANSMIT) ^ CONDITION_MASK
        START_MASK              = (START_BITS << START) ^ CONDITION_MASK

    START_RX                    = $32

    REQUEST_DEVICE_STATE        = $33
        MAIN_STATE_BITS         = %1111

    CHANGE_STATE                = $34
    STATE_SLEEP                 = 1     ' Applicable to REQUEST_DEVICE_STATE and CHANGE_STATE
    STATE_SPI_ACTIVE            = 2
    STATE_READY                 = 3
    STATE_READY2                = 4     ' Not used in CHANGE_STATE
    STATE_TX_TUNE               = 5
    STATE_RX_TUNE               = 6
    STATE_TX                    = 7
    STATE_RX                    = 8

    RX_HOP                      = $36
    TX_HOP                      = $37
    READ_CMD_BUFF               = $44
    WRITE_TX_FIFO               = $66
    READ_RX_FIFO                = $77
    
    FAST_RESP_A                 = $50
    FAST_RESP_B                 = $51
    FAST_RESP_C                 = $53
    FAST_RESP_D                 = $57

' Properties
'   Properties are organized together with related functionality in 'Groups'
'   Multiple individual properties within a group
    GROUP_GLOBAL                = $00   'XXX combine group numbers and index numbers into one 16bit num? simpler?
        GLOBAL_CLK_CFG          = $01
        GLOBAL_CLK_CFG_MASK     = $7B
            CLK_32K_SEL         = 0
            DIV_CLK_SEL         = 3
            DIV_CLK_EN          = 6
            CLK_32K_SEL_BITS    = %11
            DIV_CLK_SEL_BITS    = %111
            DIV_CLK_EN_BITS     = %111
            CLK_32K_SEL_MASK    = (CLK_32K_SEL_BITS << CLK_32K_SEL) ^ GLOBAL_CLK_CFG
            DIV_CLK_SEL_MASK    = (DIV_CLK_SEL_BITS << DIV_CLK_SEL) ^ GLOBAL_CLK_CFG
            DIV_CLK_EN_MASK     = (DIV_CLK_EN_BITS << DIV_CLK_EN) ^ GLOBAL_CLK_CFG
            DIV_1               = 0
    GROUP_INT_CTL               = $01
    GROUP_FRR_CTL               = $02

    GROUP_PREAMBLE              = $10
        PREAMBLE_TX_LENGTH      = $00

    GROUP_SYNC                  = $11
        SYNC_CONFIG             = $00
        SYNC_CONFIG_MASK        = $FF
            LENGTH              = 0
            MANCH               = 2
            FSK4                = 3
            RX_ERRORS           = 4
            SKIP_TX             = 7
            LENGTH_BITS         = %11
            RX_ERRORS_BITS      = %111
            LENGTH_MASK         = (LENGTH_BITS << LENGTH) ^ SYNC_CONFIG
            MANCH_MASK          = (1 << MANCH) ^ SYNC_CONFIG
            FSK4_MASK           = (1 << FSK4) ^ SYNC_CONFIG
            RX_ERRORS_MASK      = (RX_ERRORS_BITS << RX_ERRORS) ^ SYNC_CONFIG
            SKIP_TX_MASK        = (1 << SKIP_TX) ^ SYNC_CONFIG

        SYNC_BITS_MSB           = $01
        SYNC_BITS_MMB           = $02
        SYNC_BITS_LMB           = $03
        SYNC_BITS_LSB           = $04

    GROUP_PKT                   = $12
        PKT_FIELD_1_LENGTH      = $0D   '..$0E (b12..0)
        PKT_FIELD_2_LENGTH      = $11   '..$12 (b12..0)
        PKT_FIELD_3_LENGTH      = $15   '..$16 (b12..0)
        PKT_FIELD_4_LENGTH      = $19   '..$1A (b12..0)
        PKT_FIELD_5_LENGTH      = $1D   '..$1E (b12..0)

    GROUP_MODEM                 = $20
        MODEM_MOD_TYPE          = $00
        MODEM_MOD_TYPE_MASK     = $FF
            MOD_TYPE            = 0
            MOD_SOURCE          = 3
            TX_DIRECT_MODE_GPIO = 5
            TX_DIRECT_MODE_TYPE = 7
            MOD_TYPE_BITS       = %111
            MOD_SOURCE_BITS     = %11
            TX_DIRECT_MODE_GPIO_BITS    = %11
            MOD_TYPE_MASK       = (MOD_TYPE_BITS << MOD_TYPE) ^ MODEM_MOD_TYPE_MASK
            MOD_SOURCE_MASK     = (MOD_SOURCE_BITS << MOD_SOURCE) ^ MODEM_MOD_TYPE_MASK
            TX_DIRECT_MODE_GPIO_MASK = (TX_DIRECT_MODE_GPIO_BITS << TX_DIRECT_MODE_GPIO) ^ MODEM_MOD_TYPE_MASK
            TX_DIRECT_MODE_TYPE_MASK = (1 << TX_DIRECT_MODE_TYPE) ^ MODEM_MOD_TYPE_MASK

        MODEM_DATA_RATE         = $03   '$03..$05
        MODEM_TX_NCO_MODE       = $06   '$06..$09
            NCOMOD              = 0
            TXOSR               = 2
            TXOSR_BITS          = %11

        MODEM_FREQ_DEV          = $0A
        MODEM_FREQ_DEV_MASK     = $1FFFF

        MODEM_DECIMATION_CFG1   = $1E
        MODEM_DECIMATION_CFG1_MASK  = $FE
            NDEC0               = 1
            NDEC1               = 4
            NDEC2               = 6
            NDEC0_BITS          = %111
            NDEC1_BITS          = %11
            NDEC2_BITS          = %11
            NDEC0_MASK          = (NDEC0_BITS << NDEC0) ^ MODEM_DECIMATION_CFG1_MASK
            NDEC1_MASK          = (NDEC1_BITS << NDEC1) ^ MODEM_DECIMATION_CFG1_MASK
            NDEC2_MASK          = (NDEC2_BITS << NDEC2) ^ MODEM_DECIMATION_CFG1_MASK

        MODEM_CLKGEN_BAND       = $51
        MODEM_CLKGEN_BAND_MASK  = $1F
            FORCE_SY_RECAL      = 4
            SY_SEL              = 3
            BAND                = 0
            BAND_BITS           = %111
            FORCE_SY_RECAL_MASK = (1 << FORCE_SY_RECAL) ^ MODEM_CLKGEN_BAND_MASK
            SY_SEL_MASK         = (1 << SY_SEL) ^ MODEM_CLKGEN_BAND_MASK
            BAND_MASK           = (BAND_BITS << BAND) ^ MODEM_CLKGEN_BAND_MASK

    GROUP_MODEM_CHFLT           = $21

    GROUP_PA                    = $22
        PA_POWER_LEVEL          = $01
        PA_POWER_LEVEL_MASK     = $7F
            DDAC                = 0
            DDAC_BITS           = %1111111

    GROUP_SYNTH                 = $23
    GROUP_MATCH                 = $30

    GROUP_FREQ                  = $40
        FREQ_CONTROL_INTE       = $00
    GROUP_RX                    = $50
    

PUB null()
' This is not a top-level object


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

