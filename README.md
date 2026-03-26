# crcbas

A fast, small, and general purpose CRC-16/xmodem checksum algorithm
that can be called from BASIC on the TRS-80 Model 100 computer and
the like.

## QUICK USAGE:

Download [crcbas.do](crcbas.do) to your Model-T and run it. Usage is
meant to be simple and self-explanatory.

## Overview

* [crcbas.do](crcbas.do) (1 KB) is a BASIC program which loads GENCRC
  (see below) and demonstrates how to execute it. It relocates the
  code into a string and does not interfere with any .CO program
  loaded in ALTLCD or high memory.
  
* [GENCRC.CO](GENCRC.CO) (55 Bytes) is GENCRC.ASM assembled to run at
  memory location 61024. Usage:

  ``` BASIC
  CLEAR 256,61024
  LOADM "GENCRC.CO"
  i%[0] = 12345                     REM buffer start address
  i%[1] = 256                       REM buffer length
  i%[2] = 0                         REM (initial checksum / result) 
  CALL 61024, 0, VARPTR(i%[0])
  PRINT "Result:" i%[2]
  ```
  
  A large file can be processed in blocks by simply leaving the result
  in `i%[2]` instead of resetting it to zero. The final checksum will be
  the same as if it had been processed as a single piece.

* [GENCRC.ASM](GENCRC.ASM) is the source code for GENCRC.CO. It is
  merely a BASIC interface wrapped around
  [crc16-pushpop.asm][pushpop], an implementation of CRC-16 in 34
  bytes of 8080 machine language. The push-pop algorithm is relatively
  fast, requiring an eighth of a second per kilobyte. (See
  [crc16-8080][crc16-8080] for faster, larger alternatives.)
  
  [pushpop]: https://github.com/hackerb9/crc16-8080/blob/main/crc16-pushpop.asm
  [crc16-8080]: https://github.com/hackerb9/crc16-8080/

____

## Discussion & Digressions

### About CRC-16

The CRC-16/Xmodem algorithm is a Cyclic Redundancy Checksum from the
8-bit era of computing. There are actually many CRC-16 variations, and
this one happens to be the flavor used by the Xmodem protocol. 

If the calculated CRC-16 matches the published value for a file, then
there is 99.9985% certainty that the file was received without error.
CRC-16 checks for accidental changes, unlike modern message digests,
such as [SHA-3][sha3], which are secure against malicious adversaries.
Please see [crc16-8080][crc16-8080] for a better understanding of the
algorithm.

[sha3]: https://en.wikipedia.org/wiki/SHA-3

### Peculiarities of crcbas.do

The crcbas.do version loads GENCRC to a BASIC string buffer, which
has two benefits:

* Coexists with any binary blobs you may have loaded into high memory
  (or ALTLCD).
* All code is kept in one file for easy distribution and use.

But that comes at a cost: 

* crcbas.do adds about 400 bytes to your program, which seems
  excessive when GENCRC.CO is a 55 byte file. However, see the section
  on GENCRC below for why crcbas.do may still come out ahead.

Note that the non-ASCII characters in crcbas.do are treated as text by
the Kyotronic sisters (the M100 et al.) and can be loaded as a normal
BASIC program over the serial port (`RUN "COM:98N1E"`). 

The string is encoded in a custom variant of [bang-code][bangcode]
that hijacks the `!` (bang) character to encode addresses as relative
offsets (±32) in the following byte. [_Offset byte_ = _Target_ -
_Current_ + 80 (decimal), where _Current_ is the address of the opcode
before the address.]

[bangcode]: https://github.com/hackerb9/co2do/blob/main/bangcode.md

### Peculiarities of GENCRC.CO

GENCRC is meant to be used from a BASIC program, so if one decides to
use GENCRC.CO directly, instead of from a loader like crcbas.do, both
the BASIC program and GENCRC.CO will need to be distributed to end
users. The program should start with `CLEAR 256, 61024` and `LOADM
"GENCRC.CO"`. 

Because the MAXRAM (highest usable RAM address, plus one) varies on
different models, the GENCRC.ASM file is "ORG'd" to run at memory
location 61024. On a Tandy 200, where MAXRAM is 61104, an extra 25
bytes are reserved and unused. However, on a Model 100 or Tandy 102,
where MAXRAM is 62960, 1881 bytes are wasted — a consequential amount
on 8K machines. For this reason, crcbas.do's BASIC loader taking 400
bytes compared to GENCRC.CO's 55 is a non-issue.

### On the use of an array of signed integers

The choice was made to use an array of integers to pass the three
input arguments instead of the original design of multiple calls to
different addresses. This greatly simplified usage and saved many
bytes. There are two costs to this choice:

1. Any program that CALLs GENCRC must use VARPTR to get the address of
   the array. That makes it trickier to use on the NEC PC-8201 and
   PC-8300 which do not have a built-in VARPTR function.

2. BASIC integers (signified by `%`) are signed, and it is a fatal
   error to assign a value over 32767.
   
   ```BASIC
   i%=32768
   ?OV Error
   Ok
   ```
   
   To refer to memory addresses above 32767, one must subtract 65536.
   For instance,
  
   ```BASIC
   READ P$
   V=VARPTR(P$): P=PEEK(V+1)+256*PEEK(V+2)
   IF P>=32768 THEN P=P-65536
   i%[0] = P
   i%[1] = LEN(P$)
   i%[2] = 0
   CALL S, 0, P
   ```

### NEC PC-8201 and PC-8300 support

The GENCRC.CO works on a NEC, but the method of calling it from BASIC
is different.

1. As noted above, N82 BASIC lacks VARPTR, so a shim could be used,
   such as this one from Gary Weber:

   ``` BASIC
   39999 'VARPTR by Gary Weber for NEC 8201/8300
   40000 A=64448
   40010 POKEA,205:POKEA+1,175:POKEA+2,73:POKEA+3,235
   40020 POKEA+4,58:POKEA+5,139:POKEA+6,250:POKEA+8,201
   40030 IFVY$=""THENPRINT"VY$ not defined!":STOP
   40035 A=64457 ' HL register for EXEC = 201/251
   40040 FORH=1TOLEN(VY$):POKEA,ASC(MID\$(VY$,H,1)):A=A+1:NEXT:POKEA,0:POKE64464,0
   40050 POKE63912,201:POKE63913,251:EXEC64448
   40060 L=PEEK(63912):H=PEEK(63913):TY=PEEK(63911)
   40070 RETURN
   ```

2. As an alternative, POKE to reserved memory instead of trying to
   find the address the address of an array of BASIC integers. For
   example, the memory addresses from 61096 to 61101 are available. If
   we set the HL register 61096, then we'd have:

   | Variable      | L     | H     |
   |---------------|-------|-------|
   | Start address | 61096 | 61097 |
   | Length        | 61098 | 61099 |
   | Init/Result   | 61100 | 61101 |

3. HL is set via POKE for N82's `EXEC`:

   | Register | Location |
   |----------|----------|
   | A        | 63911    |
   | L        | 63912    |
   | H        | 63913    |

	For example, `POKE 63912, 168: POKE 63913, 238` configures HL to
    contain the number 61096.

   A theoretical advantage of this method is that one can also PEEK
   those locations to see results, but it is moot for this program as
   we return the results by writing directly into the BASIC variable.

Here is an example that performs a CRC check of the first 32K of ROM:

```BASIC
CLEAR 256,61024
BLOAD "GENCRC"
POKE 63912, 168: POKE 63913, 238
POKE 61096, 0: POKE 61097, 0
POKE 61098, 0: POKE 61099, 128
POKE 61100, 0: POKE 61101, 0
EXEC 61024
?PEEK(61100)+256*PEEK(61101)
```

_____

TODO: Create a NEC version of crcbas.do.

