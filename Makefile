all:	gencrc.co

# ORG is the address where the programs are assembled to load.
ORG=61024

# Generic CRC-16 routine that can be CALLed from BASIC
gencrc.co: gencrc.asm
	asmx -e -w -b$(ORG) gencrc.asm && mv gencrc.asm.bin gencrc.co

clean:
	rm gencrc.co \
	   *~ 2>/dev/null || true

