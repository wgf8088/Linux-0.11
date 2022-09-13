cd out
del /q *
cd ../

nasm -o zero.bin zero.S
nasm -I include/ -o out/loader.bin loader.S
nasm -o out/mbr.bin mbr.S

dd if=out/mbr.bin of=out/myos.img bs=512 count=1 conv=notrunc
dd if=out/loader.bin of=out/myos.img bs=512 count=1 seek=2 conv=notrunc
dd if=zero.bin of=out/myos.img bs=512 count=2877 seek=3 conv=notrunc

copy /y out\myos.img qemu\

cd qemu
qemu-win.bat

pause