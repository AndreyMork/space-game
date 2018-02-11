code_seg	segment
	assume  CS: code_seg, DS: code_seg, SS: code_seg
	org 100h

;-------------------------------



;-------------------------------

start:
		call	clr_scrn	; подготавливает экран
		call	player		; подготавливает данные для вывода игрока 
		call	prnt_char	; выводит игрока
	_loop:			
		call	rand	    ; устанавливает случайную координату х для звезды
		call	bomb	    ; подготавливает данные для вывода звезды
		call	prnt_char   ; выводит звезду


		call	delay		; устанавливает задержку для замедления движения звёздl 

		call	plr_mov 	; процедура управляет движением игрока
	scroll:
		call	scrl_dwn    ; прокручивает экран на строку вниз (звёзды двигаются вниз)

		jmp		_loop		; повторение


	game_over:
		mov		AH,		08h		; ждёт нажатия клавиши для продолжения
		int		21h
    
		call	clr_scrn		; очищает экран
		mov		BX,		0Eh		; должно задавать жёлтый цвет надписи 
		mov		AH,		13h		; функция вывода строки на экран
		mov		AL,		0h		; не трогать курсор 
		mov		DX,		1012h	; строка и колонка
		mov		CX,		10		; длина строки
		lea		BP,		game_over_mes	; адрес строки
		int		10h						; прерывания видео_сервиса


		int		20h				; завершение программы

;--------------------------------


plr_mov 	proc	near
	_strt:
		mov		AH,		06h		; консольный ввод-вывод
		mov		DL,		0FFh	; без ожидания
		int		21h				; прерывания DOS
		jz		move			; не было нажатия
	
		cmp		AL,		'a'		; нажата 'a' движение влево
		je		left
	
		cmp		AL,		'd'		; нажата 'd' движение вправо
		je		right
	
		cmp		AL,		quit	; выход по нажатию клавишии, назначенной в переменную quit(не совсем работает)	   
		je		game_over		
	
		jmp		_strt		
	
    left:
		call	clr_plr 		; очищение фигурки игрока на предыдущей координате
		call	prnt_char
	
		cmp		x_plr,	0		; левая граница
		je		_exit
		dec		x_plr			; координата х игрока - 1
		jmp		move
    
    right:
		call	clr_plr 		; очищение фигурки игрока на предыдущей координате
		call	prnt_char
	
		cmp		x_plr,	79		; правая граница
		je		_exit
		inc		x_plr			; координата игрока + 1
		
    move:
		mov		AH,		02h		; устанавливает курсор
		mov		DH,		21		; строка 21
		mov		DL,		x_plr	; столбец x игрока
		int		10h	    

		mov		AH,		08h		; считывает символ над позицией, куда движется игрок
		int		10h
	
		cmp		AL,		bmb		; есть ли там звезда?
		jne		_ok			; если нет, то прыжок на метку _ok

		call	boom			; взрыв
		jmp		game_over

	_ok:	
		call	player			; движение ( если есть)
		call	prnt_char
 
	_exit:
		ret
plr_mov 		endp

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			     
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

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

clr_plr 	proc	near
		mov		char,	020h	; пробел
		mov		color,	0h		; чёрный
		mov		y,		22
		push	BX
		mov		BL,		x_plr
		mov		x,		BL
		pop		BX
		ret
clr_plr			endp

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

clr_scrn	proc	near	   
		mov		AX,		0600h	; 06h in AH for func, 00h in AL for clear the screen
		mov		CX,		0h	; ru corner
		mov		DX,		0184Fh	; ld corner
		int		10h

		ret
clr_scrn		endp

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

scrl_dwn	proc	near
		call	clr_plr
		call	prnt_char

		mov		AX,		0701h	; 06h in AH for func, 00h in AL for clear the screen
		mov		CX,		0h	; ru corner
		mov		DX,		0184Fh	; ld corner
		int		10h

		call	player
		call	prnt_char

		ret
scrl_dwn		 endp

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

delay		proc	near	; имитация времени через зацикливание nop
		mov		CX,		speed
	_1wait:
		push	CX
		mov		CX,		0FFFFh
	_2wait:
		nop
		loop	_2wait
		pop	CX
		loop	_1wait

		ret
delay			endp

;--------------------------------

quit	equ		'q'		; клавиша для  выхода
plr		equ		06h		; ASCII код фигурки игрока
bmb		equ		0Fh		; ASCII код падающих фигурок

a		db		106				; переменные для генератора случайных чисел
c		dw		1283
m		db		0FFh

speed	dw		04h				; для DOS 04h, для Windows ~ 0FFh

game_over_mes	db	'Game over!'
x_plr			db	25
x_bmb			db	0

y			db	?
x			db	?
char		db	?
color		db	?

code_seg	ends
	end		start