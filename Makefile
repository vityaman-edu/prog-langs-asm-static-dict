
LD = ld
ASM = nasm
ASMFLAGS = -felf64 -g

bin/app: bin/main.o bin/dict.o bin/lib.o 
  $(LD) -o $@ $^

bin/main.o: src/main.asm src/dict/dict.inc
    $(ASM) $(ASMFLAGS) -o $@ $<

bin/dict.o: src/dict/dict.asm
    $(ASM) $(ASMFLAGS) -o $@ $<

bin/lib.o: src/lib/lib.asm
    $(ASM) $(ASMFLAGS) -o $@ $<

.PHONY: clean
clean: 
	$(RM) 
