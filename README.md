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
* P1: 1 extra core/cog for the PASM SPI driver

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.1.10-beta)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction or outright fail to build
* No working TX or RX code yet

## TODO

- [x] Get CarrierFreq working
- [ ] Verify simple transmission
