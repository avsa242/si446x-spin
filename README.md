# si4463-spin 
-------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for Silicon Labs Si446x-series transceivers

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.


## Salient Features

* SPI connection at up to 1MHz (P1), _TBD_ (P2)
* Set common RF parameters: carrier frequency, TX bitrate, modulation (2/4FSK, GFSK, 2/4GFSK, OOK, and CW for TX testing), frequency deviation
* Supports on-air bit rates from 100bps to 1Mbps
* Options for increasing transmission robustness: Syncword, preamble
* Supports setting preamble length


## Requirements

P1/SPIN1:
* spin-standard-library
* P1: 1 extra core/cog for the PASM SPI engine

P2/SPIN2:
* p2-spin-standard-library


## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.9.4)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (6.9.4)       | Native/PASM  | OK                    |
| P2        | SPIN2    | FlexSpin (6.9.4)       | NuCode       | Not yet implemented   |
| P2        | SPIN2    | FlexSpin (6.9.4)       | Native/PASM2 | Not yet implemented   |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Limitations

* RX reception unverified

