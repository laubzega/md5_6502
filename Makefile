CC65PATH=/home/laubzega/code/cc65/bin
CA65=$(CC65PATH)/ca65
CL65=$(CC65PATH)/cl65
LD65=$(CC65PATH)/ld65
SIM65=$(CC65PATH)/sim65

md5: md5.s tests.s
	$(CL65) -t sim6502 -C sim6502.cfg $^

md5.prg: md5.s main.c
	$(CL65) -o $@ -t c64 -u __EXEHDR__ $^

test: md5
	$(SIM65) -v -c $< || (echo "FAILED TEST: $$?"; exit 1) && echo "ALL PASS"

clean:
	rm -f md5 md5.prg md5.o tests.o main.o
