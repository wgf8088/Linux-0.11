; hello-os
; TAB=4
; ������ 80 �����棬2 ����ͷ�� 18 ���������� 1440 KB

CYLS	EQU		10				; ���泣��

		ORG		0x7c00			; ������ص��ڴ�� 0x7c00 ���λ��
		
; FAT12��ʽ����ר��

		JMP		entry
		DB		0x90
		DB		"HELLOIPL"		; ���������ƣ�8�ֽڣ�
		DW		512				; ÿ��������С������Ϊ512�ֽڣ�
		DB		1				; �ش�С������Ϊ1��������
		DW		1				; FAT����ʼλ�ã�һ��ӵ�һ��������ʼ��
		DB		2				; FAT�ĸ���������Ϊ2��
		DW		224				; ��Ŀ¼��С��һ��Ϊ224�
		DW		2880			; �ô��̵Ĵ�С������Ϊ2880������
		DB 		0xf0			; ���̵����ࣨ������0xf0��
		DW		9				; FAT�ĳ��ȣ�������9������
		DW		18				; 1���ŵ��м�������������Ϊ18��
		DW		2				; ��ͷ����������2��
		DD		0				; ��ʹ�÷�����������0
		DD		2880			; ��дһ�δ��̴�С
		DB		0,0,0x29		; ���岻�����̶�
		DD		0xffffffff		; ������
		DB		"HELLO-OS   "	; ���̵����ƣ�11�ֽڣ�
		DB		"FAT12   "		; ���̸�ʽ���ƣ�8�ֽڣ�
		RESB 	18				; �ճ�18���ֽ�

; ��������

entry:
		MOV		AX,0			; ��ʼ���Ĵ���
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX			; �μĴ�����ʼ��Ϊ 0
		
	; ��ȡ����
	
		MOV		AX,0x0820
		MOV		ES,AX
		MOV		CH,0			; ���� 0
		MOV		DH,0			; ��ͷ 0
		MOV		CL,2			; ���� 2	
readloop:
		MOV		SI,0			; ��¼ʧ�ܴ���
retry:
		MOV		AH,0x02			; ����ָ���
		MOV		AL,1			; 1 ������
		MOV		BX,0			; ES:BX Ϊ�����ַ���� 0x8200
		MOV		DL,0x00			; A ������
		INT		0x13			; ���ô��� BIOS
		JNC		next			; jump if not carry û������ fin
		ADD		SI,1
		CMP		SI,5
		JAE		error			; jump if above or equal >5 ��ת
		MOV		AH,0x00
		MOV		DL,0x00
		INT		0x13			; ������������ϵͳ��λ��
		JMP		retry
next:
		MOV		AX,ES
		ADD		AX,0x0020
		MOV		ES,AX
		ADD		CL,1
		CMP		CL,18			; �� 18 ������
		JBE		readloop
		MOV		CL,1
		ADD		DH,1
		CMP		DH,2			; �� 2 ����ͷ
		JB		readloop
		MOV		DH,0
		ADD		CH,1
		CMP		CH,CYLS			; �� 10 ������
		JB		readloop
		
		MOV		[0x0ff0],CH		; ����ȡ������������д���ڴ��ַ 0x0ff0
		JMP		0xc200

error:
		MOV		SI,msg
putloop:
		MOV		AL,[SI]
		ADD		SI,1
		CMP		AL,0			; ������� 0 ��β�ģ�������ѭ�����ٴ�ӡ���ַ�
		JE		fin
		MOV		AH,0x0e			; ָ������
		MOV		BX,15			; ָ����ɫ
		INT		0x10			; ���� BIOS ��ʾ�ַ�����
		JMP		putloop
fin:
		HLT
		JMP		fin
msg:
		DB		0x0a,0x0a		; ���С�����
		DB		"load error"
		DB		0x0a			; ����
		DB		0				; 0 ��β
	
		RESB 0x7dfe-$			; ���0��512�ֽ�
		DB	0x55, 0xaa			; �������豸��ʶ