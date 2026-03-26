all:	GENCRC.CO

# ORG is the address where the programs are assembled to load.
ORG=61024

# Generic CRC-16 routine that can be CALLed from BASIC
GENCRC.CO: GENCRC.ASM
	asmx -e -w -b$(ORG) GENCRC.ASM && mv GENCRC.ASM.bin GENCRC.CO

clean:
	rm GENCRC.CO \
	   *~ 2>/dev/null || true

