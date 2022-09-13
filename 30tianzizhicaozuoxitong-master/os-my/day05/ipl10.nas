; hello-os
; TAB=4
; 软盘有 80 个柱面，2 个磁头， 18 个扇区，共 1440 KB

CYLS	EQU		10				; 柱面常数

		ORG		0x7c00			; 程序加载到内存的 0x7c00 这个位置
		
; FAT12格式软盘专用

		JMP		entry
		DB		0x90
		DB		"HELLOIPL"		; 启动区名称（8字节）
		DW		512				; 每个扇区大小（必须为512字节）
		DB		1				; 簇大小（必须为1个扇区）
		DW		1				; FAT的起始位置（一般从第一个扇区开始）
		DB		2				; FAT的个数（必须为2）
		DW		224				; 根目录大小（一般为224项）
		DW		2880			; 该磁盘的大小（必须为2880扇区）
		DB 		0xf0			; 磁盘的种类（必须是0xf0）
		DW		9				; FAT的长度（必须是9扇区）
		DW		18				; 1个磁道有几个扇区（必须为18）
		DW		2				; 磁头数（必须是2）
		DD		0				; 不使用分区，必须是0
		DD		2880			; 重写一次磁盘大小
		DB		0,0,0x29		; 意义不明，固定
		DD		0xffffffff		; 卷标号码
		DB		"HELLO-OS   "	; 磁盘的名称（11字节）
		DB		"FAT12   "		; 磁盘格式名称（8字节）
		RESB 	18				; 空出18个字节

; 程序主体

entry:
		MOV		AX,0			; 初始化寄存器
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX			; 段寄存器初始化为 0
		
	; 读取磁盘
	
		MOV		AX,0x0820
		MOV		ES,AX
		MOV		CH,0			; 柱面 0
		MOV		DH,0			; 磁头 0
		MOV		CL,2			; 扇区 2	
readloop:
		MOV		SI,0			; 记录失败次数
retry:
		MOV		AH,0x02			; 读盘指令号
		MOV		AL,1			; 1 个扇区
		MOV		BX,0			; ES:BX 为缓冲地址，即 0x8200
		MOV		DL,0x00			; A 驱动器
		INT		0x13			; 调用磁盘 BIOS
		JNC		next			; jump if not carry 没错跳到 fin
		ADD		SI,1
		CMP		SI,5
		JAE		error			; jump if above or equal >5 跳转
		MOV		AH,0x00
		MOV		DL,0x00
		INT		0x13			; 重置驱动器（系统复位）
		JMP		retry
next:
		MOV		AX,ES
		ADD		AX,0x0020
		MOV		ES,AX
		ADD		CL,1
		CMP		CL,18			; 读 18 个扇区
		JBE		readloop
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2			; 读 2 个磁头
		JB		readloop
		MOV		DH,0
		ADD		CH,1
		CMP		CH,CYLS			; 读 10 个柱面
		JB		readloop
		
		MOV		[0x0ff0],CH		; 将读取到的柱面数量写入内存地址 0x0ff0
		JMP		0xc200

error:
		MOV		SI,msg
putloop:
		MOV		AL,[SI]
		ADD		SI,1
		CMP		AL,0			; 如果遇到 0 结尾的，就跳出循环不再打印新字符
		JE		fin
		MOV		AH,0x0e			; 指定文字
		MOV		BX,15			; 指定颜色
		INT		0x10			; 调用 BIOS 显示字符函数
		JMP		putloop
fin:
		HLT
		JMP		fin
msg:
		DB		0x0a,0x0a		; 换行、换行
		DB		"load error"
		DB		0x0a			; 换行
		DB		0				; 0 结尾
	
		RESB 0x7dfe-$			; 填充0到512字节
		DB	0x55, 0xaa			; 可启动设备标识