rm -rf /root/bochs/hd60M.img
/root/bochs/bin/bximage -hd -mode="flat" -size=60 -q /root/bochs/hd60M.img

nasm -I include/ -o mbr.bin mbr.S
dd if=./mbr.bin of=/root/bochs/hd60M.img bs=512 count=1 conv=notrunc

nasm -I include/ -o loader.bin loader.S
dd if=./loader.bin of=/root/bochs/hd60M.img bs=512 count=1 seek=2 conv=notrunc

cd /root/bochs
bin/bochs -f bo.disk
