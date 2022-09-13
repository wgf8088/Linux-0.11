; haribote-os boot asm
; TAB=4

BOTPAK	EQU		0x00280000		; bootpack�Υ�`����
DSKCAC	EQU		0x00100000		; �ǥ���������å���Έ���
DSKCAC0	EQU		0x00008000		; �ǥ���������å���Έ������ꥢ���`�ɣ�disk cache  real mode

; BOOT_INFO
CYLS	EQU		0x0ff0			; �趨������
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			; ��ɫ��λ��
SCRNX	EQU		0x0ff4			; �ֱ���x
SCRNY	EQU		0x0ff6			; �ֱ���y
VRAM	EQU		0x0ff8			; ͼ�񻺳����Ŀ�ʼ��ַ

		ORG		0xc200			; �ڴ�λ�� 0x8000 + 0x4200

; ����ģʽ�趨

		MOV		AL, 0x13
		MOV		AH, 0x00
		INT		0x10			; �����Կ�ģʽ������0x13��ʾVGAͼ��ģʽ 320x200x8bit ��ɫ
		MOV		BYTE [VMODE], 8	; ��¼����ģʽ
		MOV		WORD [SCRNX], 320			;�ֱ���x
		MOV		WORD [SCRNY], 200			;�ֱ���y
		MOV		DWORD [VRAM], 0x000a0000	;ͼ�񻺳����Ŀ�ʼ��ַ�������ڴ�ֲ�ͼ�ó���

; ͨ�� BIOS ȡ�ü����ϸ��� LED ָʾ�Ƶ�״̬

		MOV		AH, 0x02
		INT		0x16 			;�����жϺ�����0x02��ʾ��ͨ���̵���λ����
		MOV		[LEDS], AL

; PIC��һ�Фθ���z�ߤ��ܤ������ʤ��褦�ˤ���  ����z��=�ж�
;	AT���Q�C���˘��Ǥϡ�PIC�γ��ڻ��򤹤�ʤ顢 at�������ķ��� 
;	�����Ĥ�CLIǰ�ˤ�äƤ����ʤ��ȡ����ޤ˥ϥ󥰥��åפ��� ���Ҫ�ǲ���cli֮ǰ�� ż����hang up
;	PIC�γ��ڻ��Ϥ��ȤǤ��  ֮���ٳ�ʼ��pic

		MOV		AL, 0xff
		OUT		0x21, AL
		NOP						; OUT������B�A������Ȥ��ޤ������ʤ��C�N������餷���Τ� �в�����������outָ��Ļ���
		OUT		0xa1, AL

		CLI						; �����CPU��٥�Ǥ����z�߽�ֹ cpu�ȼ� ��ֹ�ж�

; CPU����1MB���ϤΥ���˥��������Ǥ���褦�ˡ�A20GATE���O��   �� cpu access 1mb ���ϵ�memory ��Ҫ�趨A20GATE

		CALL	waitkbdout
		MOV		AL, 0xd1
		OUT		0x64, AL
		CALL	waitkbdout
		MOV		AL, 0xdf			; enable A20
		OUT		0x60, AL
		CALL	waitkbdout

; �ץ�ƥ��ȥ�`������ protect mode 

[INSTRSET "i486p"]				; 486������ޤ�ʹ�������Ȥ���ӛ��

		LGDT	[GDTR0]			; ����GDT���O��
		MOV		EAX, CR0
		AND		EAX, 0x7fffffff	; bit31��0�ˤ��루�ک`���󥰽�ֹ�Τ��ᣩ paging
		OR		EAX, 0x00000001	; bit0��1�ˤ��루�ץ�ƥ��ȥ�`�����ФΤ��ᣩ
		MOV		CR0, EAX
		JMP		pipelineflush
pipelineflush:
		MOV		AX, 1*8			;  �i�ߕ������ܥ�������32bit      ��д����segment 
		MOV		DS, AX
		MOV		ES, AX
		MOV		FS, AX
		MOV		GS, AX
		MOV		SS, AX

; bootpack��ܞ��

		MOV		ESI, bootpack	; ܞ��Ԫ
		MOV		EDI, BOTPAK		; ܞ����
		MOV		ECX, 512*1024/4
		CALL	memcpy

; �Ĥ��Ǥ˥ǥ������ǩ`���Ȿ����λ�ä�ܞ��  ˳�� disk data Ҳ���͵�ԭ����λ��

; �ޤ��ϥ֩`�ȥ��������� �ȴ�boot sector

		MOV		ESI, 0x7c00		; ܞ��Ԫ
		MOV		EDI, DSKCAC		; ܞ����
		MOV		ECX, 512/4
		CALL	memcpy

; �Ф�ȫ��

		MOV		ESI, DSKCAC0+512	; ܞ��Ԫ
		MOV		EDI, DSKCAC+512	; ܞ����
		MOV		ECX, 0
		MOV		CL, BYTE [CYLS]
		IMUL	ECX, 512*18*2/4	; ������������Х�����/4�ˉ�Q  
		SUB		ECX, 512/4		; IPL�η֤��������
		CALL	memcpy

; asmhead�Ǥ��ʤ���Ф����ʤ����Ȥ�ȫ�����K��ä��Τǡ�
;	���Ȥ�bootpack���Τ���

; bootpack������

		MOV		EBX, BOTPAK
		MOV		ECX, [EBX+16]
		ADD		ECX, 3			; ECX += 3;
		SHR		ECX, 2			; ECX /= 4;
		JZ		skip			; ܞ�ͤ���٤���Τ��ʤ�
		MOV		ESI, [EBX+20]	; ܞ��Ԫ
		ADD		ESI, EBX
		MOV		EDI, [EBX+12]	; ܞ����
		CALL	memcpy
skip:
		MOV		ESP, [EBX+12]	; �����å����ڂ� stack
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		AL, 0x64
		AND		AL, 0x02
		JNZ		waitkbdout		; AND�νY����0�Ǥʤ����waitkbdout�� and�����Ϊ0 ȥwait����
		RET

memcpy:
		MOV		EAX, [ESI]
		ADD		ESI, 4
		MOV		[EDI], EAX
		ADD		EDI, 4
		SUB		ECX, 1
		JNZ		memcpy			; �����㤷���Y����0�Ǥʤ����memcpy��
		RET 
; memcpy�ϥ��ɥ쥹�������ץ�ե��������������ʤ���С����ȥ������Ǥ������ address size prifix���룬  string�����д

		ALIGNB	16
GDT0:
		RESB	8				; �̥륻�쥯��
		DW		0xffff, 0x0000, 0x9200, 0x00cf	; �i�ߕ������ܥ�������32bit    segment
		DW		0xffff, 0x0000, 0x9a28, 0x0047	; �g�п��ܥ�������32bit��bootpack�ã�

		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

		ALIGNB	16
bootpack:
