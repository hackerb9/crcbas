1 'Example of using CRC-16 from BASIC
2 'hackerb9 2026 
10 A$="^#V#N#F#Â~#fo!ö¨g’!ñ!à)“!Z|Ó!êg}Ó!°o!ï¬!B—!ì!ãx±¬!4Î·s#r…"
25 'See GENCRC.ASM for source code.
20 S$=SPACE$(LEN(A$)):V=VARPTR(S$):S=PEEK(V+1)+PEEK(V+2)*256
25 'M/L is relocated into S$ at addr S.
30 I=S: FOR A=1 TO LEN(A$): P=ASC(MID$(A$,A,1))
40 IF P<>33 THEN POKE I,P: GOTO 90
50 A=A+1: P=ASC(MID$(A$,A,1))
60 IF P>=128 THEN POKE I,P-128:GOTO 90
70 B=I-1+P-79:H=INT(B/256):L=B-H*256
80 POKE I,L:I=I+1:POKE I,H
90 I=I+1: NEXT A
100 '
110 I%[0]=12345	' Address of buffer
120 I%[1]=256	' Length of buffer
130 I%[2]=0	' Initial sum / result
140 PRINT"CRC-16/xmodem checksum for "
145 PRINT"address "I%[0]"to "I%[0]+I%[1]": ";
150 CALL S, 0, VARPTR(I%[0])
160 X=I%[2]: IF X<0 THEN X=X+65536
170 PRINT X
200 'Running sums: a large file can be
210 'processed in blocks by simply
220 'leaving the result in i%[2]
230 'instead of resetting it to 0.

