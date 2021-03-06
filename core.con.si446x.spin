{
    --------------------------------------------
    Filename: core.con.si446x.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2020
    Started Jun 22, 2019
    Updated May 3, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    CPOL                        = 0
    SCK_DELAY                   = 1
    SCK_MAX_FREQ                = 10_000_000
    MOSI_BITORDER               = 5             ' MSBFIRST
    MISO_BITORDER               = 0             ' MSBPRE

    OSC_FREQ_NOMINAL            = 30_000_000    ' 30MHz nominal oscillator freq
    TPOR                        = 5             ' tPOR - Power-On Reset time

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
            FLD_PATCH           = 7
            FLD_FUNC            = 0
            BITS_FUNC           = %111111
            EZRADIO_PRO         = 1
            NO_PATCH            = 0 << FLD_PATCH
            PATCH               = 1 << FLD_PATCH
        ARG_XTAL_OPTIONS        = 1
            FLD_TCXO            = 0
            XTAL                = 0 << FLD_TCXO
            TCXO                = 1 << FLD_TCXO
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
            FLD_PULL_CTL        = 6
            PULL_DIS            = 0 << FLD_PULL_CTL
            PULL_EN             = 1 << FLD_PULL_CTL
        ARG_GEN_CONFIG          = 6
            FLD_DRV_STRENGTH    = 5
            BITS_DRV_STRENGTH   = %11
            DRV_STRENGTH_HIGH   = 0
            DRV_STRENGTH_MEDHIGH= 1
            DRV_STRENGTH_MEDLOW = 2
            DRV_STRENGTH_LOW    = 3

    GET_ADC_READING             = $14

    FIFO_INFO                   = $15
        ARG_FIFO                = 0
        FLD_TX                  = 0
        FLD_RX                  = 1

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
    START_RX                    = $32

    REQUEST_DEVICE_STATE        = $33
        BITS_MAIN_STATE         = %1111

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
        MASK_GLOBAL_CLK_CFG     = $7B
            FLD_CLK_32K_SEL     = 0
            FLD_DIV_CLK_SEL     = 3
            FLD_DIV_CLK_EN      = 6
            BITS_CLK_32K_SEL    = %11
            BITS_DIV_CLK_SEL    = %111
            BITS_DIV_CLK_EN     = %111
            MASK_CLK_32K_SEL    = MASK_GLOBAL_CLK_CFG ^ (BITS_CLK_32K_SEL << FLD_CLK_32K_SEL)
            MASK_DIV_CLK_SEL    = MASK_GLOBAL_CLK_CFG ^ (BITS_DIV_CLK_SEL << FLD_DIV_CLK_SEL)
            MASK_DIV_CLK_EN     = MASK_GLOBAL_CLK_CFG ^ (BITS_DIV_CLK_EN << FLD_DIV_CLK_EN)
            DIV_1               = 0
    GROUP_INT_CTL               = $01
    GROUP_FRR_CTL               = $02

    GROUP_PREAMBLE              = $10
        PREAMBLE_TX_LENGTH      = $00

    GROUP_SYNC                  = $11
        SYNC_CONFIG             = $00
        MASK_SYNC_CONFIG        = $FF
            FLD_LENGTH          = 0
            FLD_MANCH           = 2
            FLD_4FSK            = 3
            FLD_RX_ERRORS       = 4
            FLD_SKIP_TX         = 7
            BITS_LENGTH         = %11
            BITS_RX_ERRORS      = %111
            MASK_LENGTH         = MASK_SYNC_CONFIG ^ (BITS_LENGTH << FLD_LENGTH)
            MASK_MACH           = MASK_SYNC_CONFIG ^ (1 << FLD_MANCH)
            MASK_4FSK           = MASK_SYNC_CONFIG ^ (1 << FLD_4FSK)
            MASK_RX_ERRORS      = MASK_SYNC_CONFIG ^ (BITS_RX_ERRORS << FLD_RX_ERRORS)
            MASK_SKIP_TX        = MASK_SYNC_CONFIG ^ (1 << FLD_SKIP_TX)

        SYNC_BITS_MSB           = $01
        SYNC_BITS_MMB           = $02
        SYNC_BITS_LMB           = $03
        SYNC_BITS_LSB           = $04

    GROUP_PKT                   = $12

    GROUP_MODEM                 = $20
        MODEM_MOD_TYPE          = $00
        MASK_MODEM_MOD_TYPE     = $FF
            FLD_MOD_TYPE        = 0
            FLD_MOD_SOURCE      = 3
            FLD_TX_DIRECT_MODE_GPIO = 5
            FLD_TX_DIRECT_MODE_TYPE = 7
            BITS_MOD_TYPE       = %111
            BITS_MOD_SOURCE     = %11
            BITS_TX_DIRECT_MODE_GPIO    = %11
            MASK_MOD_TYPE       = MASK_MODEM_MOD_TYPE ^ (BITS_MOD_TYPE << FLD_MOD_TYPE)
            MASK_MOD_SOURCE     = MASK_MODEM_MOD_TYPE ^ (BITS_MOD_SOURCE << FLD_MOD_SOURCE)
            MASK_TX_DIRECT_MODE_GPIO    = MASK_MODEM_MOD_TYPE ^ (BITS_TX_DIRECT_MODE_GPIO << FLD_TX_DIRECT_MODE_GPIO)
            MASK_TX_DIRECT_MODE_TYPE    = MASK_MODEM_MOD_TYPE ^ (1 << FLD_TX_DIRECT_MODE_TYPE)

        MODEM_DATA_RATE         = $03   '$03..$05
        MODEM_TX_NCO_MODE       = $06   '$06..$09
            FLD_NCOMOD          = 0
            FLD_TXOSR           = 2
            BITS_TXOSR          = %11

        MODEM_FREQ_DEV          = $0A
        MODEM_FREQ_DEV_MASK     = $1FFFF

        MODEM_CLKGEN_BAND       = $51
        MODEM_CLKGEN_BAND_MASK  = $1F
            FLD_FORCE_SY_RECAL  = 4
            FLD_SY_SEL          = 3
            FLD_BAND            = 0
            BITS_BAND           = %111
            MASK_FORCE_SY_RECAL = MODEM_CLKGEN_BAND_MASK ^ (1 << FLD_FORCE_SY_RECAL)
            MASK_SY_SEL         = MODEM_CLKGEN_BAND_MASK ^ (1 << FLD_SY_SEL)
            MASK_BAND           = MODEM_CLKGEN_BAND_MASK ^ (BITS_BAND << FLD_BAND)

    GROUP_MODEM_CHFLT           = $21

    GROUP_PA                    = $22
        PA_POWER_LEVEL          = $01
        PA_POWER_LEVEL_MASK     = $7F
            FLD_DDAC            = 0
            BITS_DDAC           = %1111111

    GROUP_SYNTH                 = $23
    GROUP_MATCH                 = $30

    GROUP_FREQ                  = $40
        FREQ_CONTROL_INTE       = $00
    GROUP_RX                    = $50
    
PUB Null
' This is not a top-level object
