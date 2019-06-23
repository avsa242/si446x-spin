{
    --------------------------------------------
    Filename: core.con.si4463.spin
    Author:
    Description:
    Copyright (c) 2019
    Started Jun 22, 2019
    Updated Jun 22, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    CPOL                        = 0
    CLK_DELAY                   = 1
    MOSI_BITORDER               = 5             ' MSBFIRST
    MISO_BITORDER               = 0             ' MSBPRE

    TPOR                        = 5             ' tPOR - Power-On Reset time

    NOT_CLEAR                   = $00
    CLEAR                       = $FF           ' Value returned by the device if it is Clear to Send/ready for commands

' Register definitions

    NOOP                        = $00
    PART_INFO                   = $01
        REPL_CHIPREV            = 0
        REPL_PARTMSB            = 1
        REPL_PARTLSB            = 2
        REPL_PBUILD             = 3
        REPL_IDMSB              = 4
        REPL_IDLSB              = 5
        REPL_CUSTOMER           = 6
        REPL_ROMID              = 7

    POWER_UP                    = $02
    FUNC_INFO                   = $10
    SET_PROPERTY                = $11
    GET_PROPERTY                = $12
    GPIO_PIN_CFG                = $13
    GET_ADC_READING             = $14
    FIFO_INFO                   = $15
    PACKET_INFO                 = $16
    IRCAL                       = $17
    IRCAL_MANUAL                = $1A
    GET_INT_STATUS              = $20
    GET_PH_STATUS               = $21
    GET_MODEM_STATUS            = $22
    GET_CHIP_STATUS             = $23
    START_TX                    = $31
    START_RX                    = $32
    REQUEST_DEVICE_STATE        = $33
    CHANGE_STATE                = $34
    RX_HOP                      = $36
    TX_HOP                      = $37
    READ_CMD_BUFF               = $44
    WRITE_TX_FIFO               = $66
    READ_RX_FIFO                = $77
    
    FAST_RESP_A                 = $50
    FAST_RESP_B                 = $51
    FAST_RESP_C                 = $53
    FAST_RESP_D                 = $57
    
PUB Null
' This is not a top-level object
