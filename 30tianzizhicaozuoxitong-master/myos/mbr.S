;主引导程序
;------------------------------------------------------------
%include "boot.inc"

SECTION MBR vstart=0x7c00



; FAT12格式软盘专用

		JMP		.main
		DB		0x90	;
		DB		"HELLOIPL"		;启动区名称（8字节）
		DW		512				;每个扇区大小（必须为512字节）
		DB		1				;簇大小（必须为1个扇区）
		DW		1				;FAT的起始位置（一般从第一个扇区开始）
		DB		2				;FAT的个数（必须为2）
		DW		224				;根目录大小（一般为224项）
		DW		2880			;该磁盘的大小（必须为2880扇区）
		DB 		0xf0			;磁盘的种类（必须是0xf0）
		DW		9				;FAT的长度（必须是9扇区）
		DW		18				;1个磁道有几个扇区（必须为18）
		DW		2				;磁头数（必须是2）
		DD		0				;不使用分区，必须是0
		DD		2880			;重写一次磁盘大小
		DB		0,0,0x29		;意义不明，固定
		DD		0xffffffff		;卷标号码
		DB		"HELLO-OS   "	;磁盘的名称（11字节）
		DB		"FAT12   "		;磁盘格式名称（8字节）
		DB 	"000000111111222222"				;空出18个字节

.main:
mov ax,cs
mov ds,ax
mov es,ax
mov ss,ax
mov fs,ax
mov sp,0x7c00
mov ax,0xb800
mov gs,ax

;mov ax,0x600
;mov bx,0x700
;mov cx,0
;mov dx,0x184f
;int 0x10

;MOV AL,0x11			; VGA显卡，320*200*8位彩色
;MOV AH,0x00
;INT 0x10

; 输出背景色绿色，前景色红色，并且跳动的字符串"1 MBR"
mov byte [gs:0x00],'4'
mov byte [gs:0x01],0x02 ; A 表示绿色背景闪烁， 4 表示前景色为红色

mov byte [gs:0x02],' '
mov byte [gs:0x03],0x02

mov byte [gs:0x04],'M'
mov byte [gs:0x05],0x02

mov byte [gs:0x06],'B'
mov byte [gs:0x07],0x02

mov byte [gs:0x08],'R'
mov byte [gs:0x09],0x02

;mov eax,LOADER_START_SECTOR; 起始扇区 lba 地址
;mov bx,LOADER_BASE_ADDR; 写入的地址

call readimg
mov byte [gs:0x10],'N'
mov byte [gs:0x11],0x02

MOV	SP,0
jmp 0x8200

readimg:

		MOV		AX,0			;初始化寄存器
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX			;段寄存器初始化为 0
		
	;读取磁盘
		MOV		AX,0x820
		MOV		ES,AX
		MOV		CH,0			;柱面 0
		MOV		DH,0			;磁头 0
		MOV		CL,2			;扇区 2
		
.readloop:
		MOV		SI,0			;记录失败次数
.retry:
		MOV		AH,0x02			;读盘指令号
		MOV		AL,1			;1 个扇区
		MOV		BX,0			;ES:BX 为缓冲地址，即 0x8200
		MOV		DL,0x00			;A 驱动器
		INT		0x13			;调用磁盘 BIOS
		JNC		.next			;jump if not carry 没错跳到 fin
		ADD		SI,1
		CMP		SI,5
		MOV		AH,0x00
		MOV		DL,0x00
		INT		0x13			;重置驱动器（系统复位）
		JMP		.retry
.next:
		MOV		AX,ES
		ADD		AX,0x0020
		MOV		ES,AX
		ADD		CL,1
		CMP		CL,18			;读 18 个扇区
		JBE		.readloop
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2			;读 2 个磁头
		JB		.readloop
		MOV		DH,0
		ADD		CH,1
		CMP		CH,10		;读 10 个柱面
		JB		.readloop
		
		mov byte [gs:0x10],'N'
mov byte [gs:0x11],0x02

		ret

msg:
		DB		0x0a,0x0a		;换行、换行
		DB		"load error"
		DB		0x0a			;换行
		DB		0				;0 结尾

times 510-($-$$) db 0
db 0x55,0xaa