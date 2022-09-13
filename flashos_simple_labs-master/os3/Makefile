include Rules.make

OBJECTS = boot/head.o init/main.o debug/debug.o

all: Image

Image: boot/bootsect.bin boot/setup.bin init/main.bin
	@bximage -mode=create -hd=60 -q $(BOCHS_HOME)/os.raw
	@dd if=boot/bootsect.bin of=$(BOCHS_HOME)/os.raw bs=512 count=1
	@dd if=boot/setup.bin of=$(BOCHS_HOME)/os.raw bs=512 count=4 seek=1
	@dd if=init/main.bin of=$(BOCHS_HOME)/os.raw bs=512 count=100 seek=5

######### �������ļ���������(bootsect)��������(setup)���ں�(main) #########
	
boot/bootsect.bin: boot/bootsect.s
	@echo �������������� bootsect.bin
	@nasm -I include/ -o boot/bootsect.bin boot/bootsect.s -l boot/bootsect.lst
	
boot/setup.bin: boot/setup.s
	@echo �������ɼ����� setup.bin
	@nasm -I include/ -o boot/setup.bin boot/setup.s -l boot/setup.lst

init/main.bin: $(OBJECTS)
	@echo ���������ں� main.bin
	@$(LD) $(OBJECTS) -Ttext 0x0 -e startup_32 -o init/main.bin.large
	@objcopy -O binary init/main.bin.large init/main.bin


######### �ں˲��ֵĸ���Ŀ���ļ� #########
	
boot/head.o: boot/head.s
	@echo ���������ں˵�ͷ��Ŀ���ļ� head.o
	@nasm -f elf -I include/ -o boot/head.o boot/head.s -l boot/head.lst

init/main.o: init/main.c
	@echo ���������ں�Ŀ���ļ� main.o
	@gcc -c -fno-builtin -I include -o init/main.o init/main.c
	
debug/debug.o:
	@echo �������ɵ���ģ�� debug
	@cd debug && @make

######### �������� #########

run: Image
	@bochs -f bochsrc.disk -q
	
brun: Image
	@bochsdbg -f bochsrc.disk -q
	
clean:
	@echo ��������.....
	@del /q others\bochs\os.raw*
	@cd boot && make clean
	@cd debug && make clean
	@cd init && make clean