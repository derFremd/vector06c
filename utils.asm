	; ********************************************	
	; Various subroutines-utilities in the assembly 
	; language for the Vector 06c personal computer.
	; @autor Sergey S. (der.fremd@gmail.com)
 	; @version 1.0
	; ********************************************

	; ***************************	
	; Процедура clear_scr - очистка экрана
	; Используется маска запрещенных плоскостей по адресу (scr_mask)
	; ***************************
clear_scr:
	push hl
	ld l,0
	ld a,(scr_mask)

	ld h,$00
	rrca	
	call c,clear_scr_plane
	ld h,$e0
	rrca	
	call c,clear_scr_plane	
	ld h,$c0
	rrca	
	call c,clear_scr_plane	
	ld h,$a0
	rrca
	call c,clear_scr_plane	

	pop hl
	ret

	; ***************************	
	; Очистка одной плоскости экрана 8K.
	; hl - адрес начала
	; ***************************
clear_scr_plane:
	di						; запрет прерываний
	push af
	push hl					; сохраняем используемые регистры
	push de
	push bc
	ex de,hl				; временно hl -> de
	ld hl,0					; сохраняем значение sp в de 
	add hl,sp
	ex de,hl				; возвращаем hl <- de
	ld sp,hl				; в sp адрес начало очистки
	ld bc,0					; заполняем нулями
	xor a					; счетчик 256 раз (a=0)
_clear_scr_plane:
REPT 16
	push bc					; 16T * 16 раз
ENDM
	dec a					; +8T
	jp nz,_clear_scr_plane	; +12T
	ex de,hl				; восстанавливает sp из de
	ld sp,hl
	pop bc					; восстанавливаем используемые регистры
	pop de
	pop hl
	pop af
	ei						; разрешние прерываний
	ret

	; ***************************
	; Процедура set_color - устанавливает цвет и фона символа 
	; входные параметры: A = (цвет_символа + 16 * цвет_фона)
	; ***************************	
set_color:
	ld (char_color),a
	ret

	; ***************************
	; Процедура set_color_char - устанавливает только цвет самих символов
	; Вход: A - цвет (0-15)
	; ***************************
set_color_char:
	push bc
	and $0f
	ld c,a
	ld a,(char_color)
	and $f0
	or c
	ld (char_color),a
	pop bc
	ret	

	; ***************************
	; Процедура set_color_bg - устанавливает только цвет фона символов
	; Вход: A - цвет (0-15)
	; ***************************
set_color_bg:
	push bc
	and $0f
	rlca
	rlca	
	rlca
	rlca
	ld c,a
	ld a,(char_color)
	and $0f
	or c
	ld (char_color),a
	pop bc
	ret		

get_color:
	ld a,(char_color)
	ret	

	; ***************************
	; Процедура set_cur - устанавливает курсор символов
	; входные параметры: h - гориз., l - вертик. координаты
	; ***************************
set_cur:
	ld a,h							; корректируем макс. значения x (0-31)
	and $1f
	ld h,a
	ld a,l							; корректируем макс. значения y (0-31)
	and $1f
	ld l,a	
	ld (cur_char_pos),hl			; сохранить текущую координату
	ret

	; ***************************
	; Процедура print_str - печать строки на экране. конец строки $0 
	; входные параметры: de - адрес начала строки 
	; выходные параметры: de - адрес конца строки строки 
	; Служебные символы:
	; $10 - изменить цвет (2 байта),
	; $11 - изменить фон (2 байта)
	; $16 - новое положение (3 байта)
	; $08 - забой (1 байт)
	; $0A - перевод строки (1 байт)
	; TODO 
	; $17 - табуляция (1 байт), см. tab_length:
	; ***************************	
print_str:
	push hl
	; -----------------------
	ld hl,(cur_char_pos) 			; загрузить текущую координату
_print_str_cur_to_scr_addr:	
	call char_coord_to_scr_addr		; конвертировать в адрес на экране
	; -----------------------
_print_str_repeat:	
	ld a,(de)						; текущий символ
	inc de							; указатель на след. символ
	or a							; конец строки?
	jp nz,_print_str_no_term		; нет, это не конец строки
	call scr_addr_to_char_coord		; адрес экрана в координату
	ld (cur_char_pos),hl			; сохранить 
	pop hl
	ret								; выход
	; -----------------------
_print_str_no_term:
	cp $20							; символ с кодом меньше $20?
	jp c,_print_str_spec_char		; да
_print_str_one_char:
	call print_char					; печать обычного символа
	; -----------------------	
	inc h							; курсор вправо
	jp nz,_print_str_repeat			; повтор, если не вышли за границу
	ld h,$e0						; вышли, восстановить H
	ld a,l							; спускаемся ниже на 8 пикселей	
	sub $08							
	ld l,a
	jp _print_str_repeat
	; -----------------------	
	; проверяем возможные служебные символы
_print_str_spec_char:
	cp $10						
	jp z,_print_str_new_fg			
	cp $11						
	jp z,_print_str_new_bg		
	cp $16
	jp z,_print_str_at_cur
	cp $08
	jp z,_print_str_backspace
	cp $0a
	jp z,_print_str_cr
	
	ld a,$7f						; нет такого кода, печатаем символ $7f
	jp _print_str_one_char
	; -----------------------	
	; установка цвет символа (код $10)
_print_str_new_fg:
	ld a,(de)						
	inc de
	call set_color_char
	jp _print_str_repeat
	; -----------------------	
	; установка цвет фона символа (код $11)
_print_str_new_bg:
	ld a,(de)						
	inc de
	call set_color_bg
	jp _print_str_repeat
	; -----------------------
	; новая координата (CUR x,y)
_print_str_at_cur:
	ex de,hl						
	ld d,(hl)
	inc hl
	ld e,(hl)
	inc hl
	ex de,hl
	jp _print_str_cur_to_scr_addr
	; -----------------------
	; символ backspace (BS)
_print_str_backspace:	
	dec h
	ld a,$df
	cp h
	jp nz,_print_str_bs_char
	ld h,$ff
	ld a,l							; поднимаемся выше на 8 пикселей	
	add a,$08							
	ld l,a	
_print_str_bs_char:	
	ld a,$20						; напечатать пробел
	call print_char
	jp _print_str_repeat
	; -----------------------
	; перевод строки (LF)
_print_str_cr:
	ld h,$e0
	ld a,l							; спускаемся ниже на 8 пикселей	
	sub $08							
	ld l,a
	jp _print_str_repeat		


	; ***************************
	; Процедура char_coord_to_scr_addr переводит коодинаты
	; символа в адрес на экране
	; вход: H - горизонтальная и L - вертикальная координата
	; выход: HL - адрес на экране
	; ***************************
char_coord_to_scr_addr:
	ld a,h
	and $1f
	or $e0
	ld h,a
	ld a,l
	and $1f
	rlca
	rlca
	rlca
	ld l,a
	ret

	; ***************************
	; Процедура scr_addr_to_char_coord переводит адрес на экране 
	; в координаты символа.
	; вход: HL - адрес на экране
	; выход: H - горизонтальная и L - вертикальная координата
	; ***************************
scr_addr_to_char_coord:
	ld a,h
	and $1f
	ld h,a
	ld a,l
	rrca
	rrca
	rrca
	and $1f	
	ld l,a
	ret

	; ***************************
	; Процедура set_planes переводит адрес на экране 
	; в координаты символа.
	; вход: HL - адрес на экране
	; выход: H - горизонтальная и L - вертикальная координата
	; ***************************
set_planes:
	and $0f
	ld (scr_mask),a
	ret

cur_char_pos:
	db 0,0			; хранится текущее положение курсора y,x (0-31)

tab_length:
	db 4			; длина табуляции (0-255)

char_color:			; текущий цвет символов и фона (символ + 16 * фон)
	db %01010011

saved_sp:			; временное хранение значения регистра SP
	dw $0000				

cur_char_addr:		; сохраняем адрес текущего символа в таблице шрифта
	dw $0000

scr_addr_char:		; адрес на экране для вывода символа
	dw $0000 

scr_mask:			; маска запрета экранных плоскостей
	db %00001111

	; *****************************
	; Процедура print_char - вывод символа 8 байт (8x8 точек) в заданную часть экрана
	; Адрес на экране задается в HL
	; Код символа в A (не сохраняется)
	; Маска запрета плоскостей по адресу (scr_mask)
	; Текущий цвет по адресу (char_color)
	; *****************************
print_char:
	push hl
	push de
	push bc
	; ---------------------------
	ex de,hl				; сохранить SP
	ld hl,$0000
	add hl,sp
	ld (saved_sp),hl
	; ---------------------------
	sub $20					; вычесть служебные символы
	ld l,a
	ld h,$00
	add hl,hl				; умножить на 8
	add hl,hl
	add hl,hl	
	ld bc,font_table
	add hl,bc
	ld sp,hl				; в SP адрес символа в таблице шрифта
	ld (cur_char_addr),hl	; дополнительно сохраняем в ячейку
	ex de,hl
	ld c, %00010001			; маска выбора плоскости (биты 7-4 фон, биты 3-0 цвет символа)
	; ---------------------------
_print_char_repeat:
	ld a,(scr_mask)					; маска запрета плоскостей	
	and c
	jp z,_print_char_next_plane		; ничего не делать
	; ---------------------------
	ld a,(char_color)				; загрузить текущий цвет
	ld d,a							; дополнительно сохраняем в регистре D
	and c							; есть ли цвет и/или фон?
	jp nz,_print_char_is_bg			; что-то из этого есть, переход
	; ---------------------------
	; нет ни цвета, ни фона. заполняем 8 нулями
	xor a					
REPT 7
	ld (hl),a
	inc l
ENDM
	ld (hl),a
	jp _print_char_restore_l
	; ---------------------------
_print_char_is_bg:
	and $f0							; если ли фон?
	jp nz,_print_char_is_color		; переход если есть фон
	; ---------------------------		
	; фона нет, заполняем изображением символа из таблицы (8 байт)
REPT 3
	pop de					
	ld (hl),e
	inc l
	ld (hl),d
	inc l
ENDM
	pop de
	ld (hl),e
	inc l
	ld (hl),d	
	jp _print_char_rest_sp
	; ---------------------------
	; фон есть, если ли изображение одновременно с фоном?
_print_char_is_color:
	ld a,d						; загрузить сохраненный в D цвет символа с фоном
	and $0f						; выделяем только цвет символа
	and c						; наложить бит цвета для этой плоскости
	jp z,_print_char_inv_char	; если нет цвета, только фон, переход
	; ---------------------------	
	; есть и цвет и фон
	xor a						; заполняем значением $FF (8 байт)
	cpl
REPT 7
	ld (hl),a
	inc l
ENDM
	ld (hl),a
	jp _print_char_restore_l
	; ---------------------------	
	; выводить инверсный вариант символа (8 байт)
_print_char_inv_char:
REPT 3
	pop de
	ld a,e
	cpl
	ld (hl),a
	inc l
	ld a,d
	cpl
	ld (hl),a
	inc l	
ENDM
	pop de
	ld a,e
	cpl
	ld (hl),a
	inc l
	ld a,d
	cpl
	ld (hl),a
	; ---------------------------	
	; восстановить SP на начало символа
_print_char_rest_sp:			
	ex de,hl
	ld hl,(cur_char_addr)
	ld sp,hl
	ex de,hl
	; ---------------------------
	; восстановить L и сменить плоскость в H
_print_char_restore_l:		
	ld a,l					
	sub 7
	ld l,a
_print_char_next_plane:	
	ld a,h					
	sub $20
	ld h,a
	; ---------------------------
	; сдвинуть маску цвет/фон
_print_char_shift_mask:
	ld a,c					
	rlca
	ld c,a
	jp nc,_print_char_repeat	; повторить, если еще есть плоскости
	; ---------------------------
	ld hl,(saved_sp)			; восстановить SP и регистры
	ld sp,hl
	pop bc
	pop de
	pop hl
	ret

	; ******************************
	; Процедура palette_on - включить палитру
	; ******************************
palette_on:
	ld hl,palette_1
	ld (palette_cur),hl
	call setup_palette
	ret

    ; ******************************
	; Процедура palette_off - выключить палитру
    ; ******************************
palette_off:
	ld hl,palette_0
	ld (palette_cur),hl
	call setup_palette
	ret

	; ******************************
	; Процедура set_palette - программирование палитры.
    ; Адрес палитры  
	; ******************************
setup_palette:
	push af
	push hl
	push bc
	ld hl,(palette_cur)	; загрузить адрес палитры
	halt				; ждем начало развертки
	ld a,$88			; настроить ППИ
	out ($00),a
	ld a,$ff			; сбросить прокрутку
	out ($03),a
	ld bc,$0f00	; 		b - значений в палитре, c - номер цвета
_setup_palette_repeat:
	ld a,c				; задать номер текущего цвета
	out ($02),a
	ld a,(hl)			; по адресу в ячейке bc взять значение цвета
	out ($0c),a
	inc hl				; след. ячейка палитры 
	out ($0c),a
	inc c			; след. номер цвета	
	out ($0c),a
	dec b			; уменьшаем счетчик
	out ($0c),a
	jp p,_setup_palette_repeat
	ld a,8			; цвет бордюра такой же как фона
	out ($02),a		
	pop bc
	pop hl
	pop af
	ret

    ; адрес текущей палитры
palette_cur:
    dw palette_0

	;  палитра рабочая
palette_1:
	;   с к ч  з яз кп  ж  б
	db 64,128,16,208,6,134,22,54,0,197,34,192,2,152,82,173

	;  палитра для подготовки экрана
palette_0:
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0