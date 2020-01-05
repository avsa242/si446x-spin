# si4463-spin 
---------------

This is a P8X32A/Propeller driver object for Silicon Labs Si446x-series transceivers

## Salient Features

* SPI connection at up to 1MHz (P1), _TBD_ (P2)
* Set common RF parameters: carrier frequency, TX bitrate, modulation (2/4FSK, GFSK, 2/4GFSK, OOK, and CW for TX testing)
* Supports on-air bit rates from 100bps to 1Mbps
* Options for increasing transmission robustness: Syncword
* Supports setting preamble length

## Requirements

* P1: 1 extra core/cog for the PASM SPI driver
* P2: N/A

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.1.0-beta)

## Limitations

* Very early in development - may malfunction or outright fail to build
* No working TX or RX code yet

## TODO

- [x] Get CarrierFreq working
- [ ] Verify simple transmission
