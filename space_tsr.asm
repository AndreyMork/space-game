code_seg	segment
	assume	CS:	code_seg,	DS:	code_seg,	SS:	code_seg
	org 100h

;-------------------------------------------------------

;-------------------------------------------------------	
start:
		jmp		begin
	
;=======================================================
new_09h			proc	far
		pushf
		push	AX
		in		AL,		060h ; порт клавиатуры 
		cmp		AL,		01Dh ; 01dh скан-код lctrl
		je		_flag
		cmp		flag_on, 1		
		jne		pass_09h
		
		cmp		AL,		1Eh
		jne		right
		call	clr_plr
		call	prnt_char
		cmp		x_plr,	0
		je		move
		dec		x_plr
		jmp		move
		
	right:
		cmp		AL,		20h
		jne		_end
		call	clr_plr
		call	prnt_char
		cmp		x_plr,	79
		je		move
		inc		x_plr
	move:
		call	player	
		call	prnt_char
		jmp		_end
		
	_flag:

		cmp		flag_on,	0
		je 		set_flag_on	

		dec		flag_on
		mov		AX,		03h
		int		10h
		jmp		_end
		
	set_flag_on:
		inc		flag_on
		
		mov		AX,		0010h
		int		10h
		
		call	player	
		call	prnt_char
		

	
	_end:			
		sti						; вот эта часть из его примера, я не знаю, что она делает.		
		in      AL,		61h		; Введем содержимое порта B
		or      AL,		80h		; Установим старший бит
		out     61h,	AL		; и вернем в порт B.
		and     AL,		7Fh		; Снова разрешим работу клавиатуры,
		out     61h,	AL	
		cli
		
		
		
		mov 	AL,		20h  ; 20h - EOI (end of interruption)		
		out		20h,	AL   ;
		
		pop		AX
		popf
		iret
		

	pass_09h:
		pop		AX
		popf
		jmp		dword ptr cs:[old_09h]
new_09h			endp


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
new_1Ch			proc	far				; прерывание таймера
		pushf
		push	AX
		
		cmp		flag_on,	0
		je		pass_1Ch	

		inc		count
		mov		AH,		count
		cmp		AH,		delay
		jne		pass_1Ch
		
		mov		count,	0
		call	rand
		call	bomb
		call	prnt_char		

		call	scrl_dwn

				
	pass_1Ch:
		pop		AX
		popf
		jmp		dword ptr cs:[old_1Ch]
new_1Ch			endp


prnt_char	proc	near
		mov		AH,		02h	; cursor position
		mov		DH,		y	; y
		mov		DL,		x	; x
		int		10h

		mov		AH,		09h	; print char
		mov		BL,		color	; color

		mov		AL,		char	; char
		mov		CX,		1	; number
		int		10h
		ret
prnt_char		endp


player		proc	near
		mov		char,	plr		; символ фигурки игрока
		mov		color,	09h		; синий
		mov		y,		22		; координата y игрока
		push	BX
		mov		BL,		x_plr	; координата х игрока
		mov		x,		BL
		pop		BX
		ret
player			endp


bomb		proc	near
		mov		char,	bmb		; символ звезды
		mov		color,	0Eh		; жёлтый 
		mov		y,		0		; координата y
		push	BX
		mov		BL,		x_bmb	; координата x     
		mov		x,		BL
		pop		BX
		ret
bomb			endp	


boom		proc	near  ; рисует взрыв
		mov		y,		21	  
		mov		char,	'#'
		mov		color,	0Ch
		mov		CX,		3
	y_loop:
		push	BX
		mov		BL,		x_plr
		mov		x,		BL
		pop		BX

		dec		x
		push	CX
		mov		CX,		3
	x_loop:
		push	CX
		call	prnt_char
		inc		x
		pop		CX
		loop	x_loop

		pop		CX
		inc		y
		loop	y_loop

		ret
boom			endp


clr_plr 	proc	near
		mov		char,	0h	; пробел
		mov		color,	0h	; чёрный
		mov		y,		22
		push	BX
		mov		BL,		x_plr
		mov		x,		BL
		pop		BX
		ret
clr_plr			endp


scrl_dwn	proc	near
		call	clr_plr
		call	prnt_char
		
		mov		AX,		0701h	; 06h in AH for func, 00h in AL for clear the screen
		mov		CX,		0h	; ru corner
		mov		DX,		0184Fh	; ld corner
		mov 	BH,		0h
		int		10h		
		
		mov		AH,		02h		; устанавливает курсор
		mov		DH,		22		; строка 21
		mov		DL,		x_plr	; столбец x игрока
		int		10h	    
		
		mov		AH,		08h		; считывает символ над позицией, куда движется игрок
		int		10h
		
		cmp		AL,		bmb		; есть ли там звезда?
		jne		_ok			; если нет, то прыжок на метку _ok

		call	boom			; взрыв
		dec		flag_on
		ret
	_ok:
		call	player
		call	prnt_char

		ret
scrl_dwn		 endp


rand		proc	near	; генерирует псевдослучайную последовательность
		push	CX
	rnd_strt: 
		mov		AL,		a
		mov		BL,		x_bmb
		mul		BL
		add		AX,		c
		mov		CL,		m
		div		CL	   
		mov		x_bmb,	AH

		cmp		x_bmb,	79
		jg		rnd_strt

		pop		CX    
		ret    
rand			endp

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
plr		equ		06h		; ASCII код фигурки игрока
bmb		equ		0Fh		; ASCII код падающих фигурок

a		equ		142		; переменные для генератора случайных чисел
c		equ		1283
m		equ		0FFh


; game_over_mes	db	'Game over!'
x_plr			db	25
x_bmb			db	0

y			db	?
x			db	?
char		db	?
color		db	?

		
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
new_2Fh			proc	far
		cmp		AH,		0C7h	; наша программа?
		jne		pass_2Fh
		
		cmp		AL,		00h		; запрос на установку? 
		je		installed		; уже установлена
		
		cmp		AL,		01h     ; запрос на удаление?
		je		_uninstall      ; удалить
		
	pass_2Fh:
		jmp		dword ptr cs:[old_2Fh] ; перейти в стандартное прерывание 2Fh
	
	installed:
		mov		AL,		0FFh	; отправить код 0FFh - уже установлена
		iret
	
	_uninstall:
		push	BX
		push	CX
		push	DX
		push	es
		
		mov		CX,		cs		; переместим cs в CX для дальнейшего сравнения
		mov		AX,		3509h	; получить адрес прерывания 09h
		int		21h
		
		mov		DX,		ES		; es:BX == cs:[new_09h] ?
		cmp		CX,		DX		; т.е. проверяем это наше прерывание или нет
		jne		not_remove		; т.к. другая программа могла заменить вектор прерывания

		cmp		BX,		offset cs:[new_09h]
		jne		not_remove
		
		mov		AX,		352Fh	; то же самое для прерывания 2Fh
		int		21h
		
		mov		DX,		ES
		cmp		CX,		DX
		jne		not_remove

		cmp		BX,		offset cs:[new_2Fh]
		jne		not_remove
		
		mov		AX,		351Ch	; то же самое для прерывания 1Ch
		int		21h
		
		mov		DX,		ES
		cmp		CX,		DX
		jne		not_remove

		cmp		BX,		offset cs:[new_1Ch]
		jne		not_remove
;-------------------------------------------------------

		push	ds
		
		
		lds		DX,		cs:[old_09h]  ; возвращаем старые значения 09h
		mov		AX,		2509h
		int		21h
		
		lds		DX,		cs:[old_2Fh]  ; возвращаем старые значения 2Fh
		mov		AX,		252Fh
		int		21h	

		lds		DX,		cs:[old_1Ch]  ; возвращаем старые значения 2Fh
		mov		AX,		251Ch
		int		21h	
		
		pop		ds
		
		mov		es,		cs:[2Ch] ; поле 9 PSP ???
		mov		AH,		49h
		int		21h
		
		mov		AX,		cs		; удаление ????
		mov		es,		AX
		mov		AH,		49h
		int		21h
		
		mov		AL,		0Fh      ; успешное удаление
		jmp		pop_ret
		
	not_remove:
		mov		AL,		0F0h	; нельзя удалять
		
	pop_ret:
		pop		es
		pop		DX
		pop		CX
		pop		BX
		
		iret	
new_2Fh			endp	


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
flag_on			db		0
count			db		0
delay			equ		3


old_09h			dd		?
old_2Fh			dd		?
old_1Ch			dd		?

;=======================================================
begin:	

		
		mov		CL,		es:[80h] ; поле 17 PSP - длина параметров
		cmp		CL,		0		 ; длина 0 => нет параметров
		je		check_install	 ; переходим к установке
		
		xor		CH,		CH     	 ; CX = CL  
		cld						 ; флаг направления вперёд DF = 0 
		mov		di,		81h		 ; поле 18 PSP - параметры
		mov		AL,		' '		 ; scasb сравнивает es:di с AL b устанавливает флаг
		repe	scasb			 ; повторять пока равны и CX != 0
		dec		di				 ; установить di на первый не пробел
		
		lea		si,		off      ; адрес параметра удаления
		mov		CX,		4	     ; его длина
		repe	cmpsb			 ; сравнивает es:di и es:si пока равны и CX != 4
		
		je		set_flag         ; неизвестный параметр
		lea		DX,		msg4
		call	print
		int		20h
	
	set_flag:
		inc		flag_off		 ; параметры совпали, устанавливаем флаг удаления	
		
	check_install:
		mov		AX,		0C700h   ; 2Fh - мультиплексное прерывание. AH = номер прерывания (80h-0ffh - свободны)
		int		2Fh				 ; AL - номер подфункции. 00h - запрос статуса установки процесса. 
								 ; на выходе в AL: 
								 ; 00h - не установлен (устанавливать можно)
								 ; 01h - не установлен (устанавливать нельзя)
		cmp		AL,		0FFh     ; 0FFh - установлен
		je		already_installed
		
		cmp		flag_off,	1
		je 		not_installed
		
		call 	setup
			
		lea		DX,		begin	 ; адрес первого байта, который не надо оставлять в памяти
		int		27h			     ; завершить и оставить резидентной

		
	already_installed:
		cmp		flag_off,	1	 ; запущенна с параметром '/off'?
		je		uninstall
		lea		DX,		msg0
		call	print
		int		20h
		
	uninstall:
		mov		AX,		0C701h	; AL = 01h - запрос на удаление
		int		2Fh
		
		cmp		AL,		0F0h    ; 0F0h - удалние не удалось
		je		fail
		
		cmp		AL,		0Fh		; 0Fh - удаление удалось
		jne		fail
		
		lea		DX,		msg2
		call	print
		int		20h
		
	fail:
		lea		DX,		msg3
		call	print
		int		20h
		
	not_installed:
		lea		DX,		msg3
		call	print
		int		20h
		
		
;=======================================================
setup			proc	near
		mov 	AX,		352Fh
		int		21h
		
		mov		word ptr old_2Fh, BX
		mov		word ptr old_2Fh + 2, ES
		
		lea		DX,		new_2Fh
		mov 	AX,		252Fh
		int		21h
;-------------------------------------------------------		
		mov 	AX,		3509h
		int		21h
		
		mov		word ptr old_09h, BX
		mov		word ptr old_09h + 2, ES
		
		lea		DX,		new_09h
		mov 	AX,		2509h
		int		21h	
;-------------------------------------------------------		
		mov 	AX,		351Ch
		int		21h
		
		mov		word ptr old_1Ch, BX
		mov		word ptr old_1Ch + 2, ES
		
		lea		DX,		new_1Ch
		mov 	AX,		251Ch
		int		21h			
;-------------------------------------------------------

		lea			DX,		msg1
		call		print
		
		ret		
setup			endp


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
print		proc	near
		mov		AH,		09h
		int		21h
		ret
print			endp


;=======================================================
off				db		'/off'
flag_off		db		0

msg0			db		'already '
msg1			db		'installed',13,10,'$'
msg2			db		'uninstalled',13,10,'$'
msg3			db		'error: programm is not installed',13,10,'$'
msg4			db		'unknown parameter',13,10,'$'
;=======================================================

code_seg	ends
			end		start