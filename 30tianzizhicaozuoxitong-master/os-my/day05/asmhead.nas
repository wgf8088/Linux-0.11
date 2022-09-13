; haribote-os boot asm
; TAB=4

BOTPAK	EQU		0x00280000		; bootpackのロード先
DSKCAC	EQU		0x00100000		; ディスクキャッシュの場所
DSKCAC0	EQU		0x00008000		; ディスクキャッシュの場所（リアルモード）disk cache  real mode

; BOOT_INFO
CYLS	EQU		0x0ff0			; 设定启动区
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			; 颜色的位数
SCRNX	EQU		0x0ff4			; 分辨率x
SCRNY	EQU		0x0ff6			; 分辨率y
VRAM	EQU		0x0ff8			; 图像缓冲区的开始地址

		ORG		0xc200			; 内存位置 0x8000 + 0x4200

; 画面模式设定

		MOV		AL, 0x13
		MOV		AH, 0x00
		INT		0x10			; 设置显卡模式函数，0x13表示VGA图形模式 320x200x8bit 彩色
		MOV		BYTE [VMODE], 8	; 记录画面模式
		MOV		WORD [SCRNX], 320			;分辨率x
		MOV		WORD [SCRNY], 200			;分辨率y
		MOV		DWORD [VRAM], 0x000a0000	;图像缓冲区的开始地址（根据内存分布图得出）

; 通过 BIOS 取得键盘上各种 LED 指示灯的状态

		MOV		AH, 0x02
		INT		0x16 			;键盘中断函数，0x02表示普通键盘的移位标致
		MOV		[LEDS], AL

; PICが一切の割り込みを受け付けないようにする  割り込み=中断
;	AT互換機の仕様では、PICの初期化をするなら、 at互换机的方法 
;	こいつをCLI前にやっておかないと、たまにハングアップする 这个要是不在cli之前， 偶尔会hang up
;	PICの初期化はあとでやる  之后再初始化pic

		MOV		AL, 0xff
		OUT		0x21, AL
		NOP						; OUT命令を連続させるとうまくいかない機種があるらしいので 有不能连续进行out指令的机器
		OUT		0xa1, AL

		CLI						; さらにCPUレベルでも割り込み禁止 cpu等级 禁止中断

; CPUから1MB以上のメモリにアクセスできるように、A20GATEを設定   从 cpu access 1mb 以上的memory 需要设定A20GATE

		CALL	waitkbdout
		MOV		AL, 0xd1
		OUT		0x64, AL
		CALL	waitkbdout
		MOV		AL, 0xdf			; enable A20
		OUT		0x60, AL
		CALL	waitkbdout

; プロテクトモード移行 protect mode 

[INSTRSET "i486p"]				; 486の命令まで使いたいという記述

		LGDT	[GDTR0]			; 暫定GDTを設定
		MOV		EAX, CR0
		AND		EAX, 0x7fffffff	; bit31を0にする（ページング禁止のため） paging
		OR		EAX, 0x00000001	; bit0を1にする（プロテクトモード移行のため）
		MOV		CR0, EAX
		JMP		pipelineflush
pipelineflush:
		MOV		AX, 1*8			;  読み書き可能セグメント32bit      读写可能segment 
		MOV		DS, AX
		MOV		ES, AX
		MOV		FS, AX
		MOV		GS, AX
		MOV		SS, AX

; bootpackの転送

		MOV		ESI, bootpack	; 転送元
		MOV		EDI, BOTPAK		; 転送先
		MOV		ECX, 512*1024/4
		CALL	memcpy

; ついでにディスクデータも本来の位置へ転送  顺便 disk data 也传送到原来的位置

; まずはブートセクタから 先从boot sector

		MOV		ESI, 0x7c00		; 転送元
		MOV		EDI, DSKCAC		; 転送先
		MOV		ECX, 512/4
		CALL	memcpy

; 残り全部

		MOV		ESI, DSKCAC0+512	; 転送元
		MOV		EDI, DSKCAC+512	; 転送先
		MOV		ECX, 0
		MOV		CL, BYTE [CYLS]
		IMUL	ECX, 512*18*2/4	; シリンダ数からバイト数/4に変換  
		SUB		ECX, 512/4		; IPLの分だけ差し引く
		CALL	memcpy

; asmheadでしなければいけないことは全部し終わったので、
;	あとはbootpackに任せる

; bootpackの起動

		MOV		EBX, BOTPAK
		MOV		ECX, [EBX+16]
		ADD		ECX, 3			; ECX += 3;
		SHR		ECX, 2			; ECX /= 4;
		JZ		skip			; 転送するべきものがない
		MOV		ESI, [EBX+20]	; 転送元
		ADD		ESI, EBX
		MOV		EDI, [EBX+12]	; 転送先
		CALL	memcpy
skip:
		MOV		ESP, [EBX+12]	; スタック初期値 stack
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		AL, 0x64
		AND		AL, 0x02
		JNZ		waitkbdout		; ANDの結果が0でなければwaitkbdoutへ and结果不为0 去wait。。
		RET

memcpy:
		MOV		EAX, [ESI]
		ADD		ESI, 4
		MOV		[EDI], EAX
		ADD		EDI, 4
		SUB		ECX, 1
		JNZ		memcpy			; 引き算した結果が0でなければmemcpyへ
		RET 
; memcpyはアドレスサイズプリフィクスを入れ忘れなければ、ストリング命令でも書ける address size prifix输入，  string命令可写

		ALIGNB	16
GDT0:
		RESB	8				; ヌルセレクタ
		DW		0xffff, 0x0000, 0x9200, 0x00cf	; 読み書き可能セグメント32bit    segment
		DW		0xffff, 0x0000, 0x9a28, 0x0047	; 実行可能セグメント32bit（bootpack用）

		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

		ALIGNB	16
bootpack:
