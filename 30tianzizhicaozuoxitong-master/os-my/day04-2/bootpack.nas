[FORMAT "WCOFF"]
[INSTRSET "i486p"]
[OPTIMIZE 1]
[OPTION 1]
[BITS 32]
	EXTERN	_io_hlt
[FILE "bootpack.c"]
[SECTION .text]
	GLOBAL	_HariMain
_HariMain:
	PUSH	EBP
	MOV	EAX,655360
	MOV	EBP,ESP
L6:
	MOV	BYTE [EAX],14
	INC	EAX
	CMP	EAX,720895
	JLE	L6
L7:
	CALL	_io_hlt
	JMP	L7
