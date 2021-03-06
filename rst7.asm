	; ********************************************
	; File: rst7.asm
	; Various subroutines-utilities in the assembly
	; language for the Vector 06c personal computer.
	; @author Sergey S. (der.fremd@gmail.com)
 	; @version 1.0
	; ********************************************

KeyBufferAddr	EQU $0010			; адрес буфера клавиш
KeyBufferSize	EQU 32				; размер буфера
KeySSCode		EQU $40				; код клавиши СС
KeyUSCode		EQU $41				; код клавиши УС
KeyRUSCode		EQU $42				; код клавиши РУС/LAT
KeyRepDelay		EQU 50				; пауза перед автоповтором клавиш (1 сек)
KeyRepDelay2	EQU 5				; пауза между автоповторами (0.1 сек)
KeyRepMask		EQU $00000010		; маска автоповторов нажатий клавиш в служебной переменной

	; ---------------------------------
	; Процедура interrupt - обработка прерывания:
	; Изменение таймера (1 байт).
	; Опрос служебных клавиш: РУС/ЛАТ, УС, СС и их триггерное состояние.
	; Состояние индикатора: РУС/ЛАТ.
	; Опрос основных клавиш и построение битовой карты клавиш.
	; Определение кода клавиш (не ascii), заполенение буфера кодами клавиш.
	; Управление автоповтором нажатия клавиш (пауза до автоповтора и во время).
	; Установка аппаратного скролинга.
	; ---------------------------------
interrupt:
	push af
	push hl
	push bc
	push de

	ld hl,int_counter			; увеличить таймер
	inc (hl)

	; ---------------------------------
	; задать режим порта В/В для опроса клавиш
	ld a,$8a
	out ($00),a

	; ---------------------------------
	; Чтение клавиш РУС/LAT, УС и СС (биты 7,6,5 соответственно)
	ld de,keys_ext
	in a,($01)					; считываем статус клавиш, порт $01 (инверсные значения: 0-нажата, 1-нет)
	cpl							; инвертируем (прямые значения: 1-нажата, 0-нет)
	and %11100000				; выделяем только эти клавиши (без входа от магнитафона)
	ld (de),a					; сохранить состояние
	and %10000000				; клавиши УС и СС только как модификаторы, клавиша РУС/LAT - как обычная клавиша
	ld b,a						; рег. B - признак нажатия хотя бы одной клавиши (исключая УС и СС)

	; ---------------------------------
	; Сканирование основных клавиш (64 шт.) начиная с 7-го ряда (от 7 до 0)
	; Сохраняем битовую карту в буфер keys_lines (8 байт)
	inc de
	ld c,$7f					; в рег. C - маска выбора ряда
_interrupt_key_row:
	ld a,c
	out ($03),a					; выбираем текущий ряд
	in a,($02)					; считываем нажатые клавиши (0 - нажата, 1 - нет)
	cpl							; инверсия (1 - нажата, 0 - нет)
	ld (de),a					; сохранить	в битовую таблицу
	or b						; признак нажатия хотя бы одной клавиши
	ld b,a
	inc de						; перейти на адрес другого ряда
	ld a,c						; сдвинуть и сохранить маску - следующий ряд
	rrca
	ld c,a
	jp c,_interrupt_key_row		; и так все ряды (от 7 до 0)

	; ---------------------------------
	; режим порта для записи
	ld a,$88
	out ($00),a

	ld a,(scroll_pos)			; скроллинг экрана
	out ($03),a

	ld a,(border_color)			; цвет бордюра экрана и режим 256x256 точек
	and %00001111
	out ($02),a

	ld a,(service_flags)		; загрузить служебный байт
	ld c,a

	ld a,%00001000				; зажигаем/гасим индикатор РУС (3-й бит)
	and c
	out ($01),a

	ld a,%00000001				; разрешена обработка клавиш? (0-й бит)
	and c
	jp z,_interrupt_exit		; переход, если запрещено

	ld a,b						; признак хотя бы одного нажатия на клавишу
	call keys_proc				; обратботка клавиш

_interrupt_exit:
	pop de
	pop bc
	pop hl
	pop af
	ei
	ret

	; ---------------------------------
	; Процедура led_rus_on - включает индикатор РУС
	; ---------------------------------
led_rus_on:
	ld a,(service_flags)		; загрузить служебный байт
	or %00001000				; установить бит
	ld (service_flags),a		; сохранить служебный байт
	ret	

	; ---------------------------------
	; Процедура led_rus_off - выключает индикатор РУС
	; ---------------------------------
led_rus_off:
	ld a,(service_flags)		; загрузить служебный байт
	or %11110111				; сбросить бит
	ld (service_flags),a		; сохранить служебный байт
	ret		

	; ---------------------------------
	; Процедура keys_enable - разрешает вызов процедуры обработки клавиш keys_proc
	; ---------------------------------
keys_enable:
	ld a,(service_flags)		; загрузить служебный байт
	or %00000001				; установить бит
	ld (service_flags),a		; сохранить служебный байт
	ret

	; ---------------------------------
	; Процедура keys_disable - разрешает вызов процедуры обработки клавиш keys_proc
	; ---------------------------------
keys_disable:
	ld a,(service_flags)		; загрузить служебный байт
	and %11111110				; сбросить бит
	ld (service_flags),a		; сохранить служебный байт	
	ret

	; ---------------------------------
	; Процедура keys_reset_bufer - запрещает обработку клавиш, 
	; сбрасывает буфер, автоповтор и битовые маски клавиш
	; ---------------------------------
keys_reset_bufer:
	call keys_disable
	;----------------------------------
	; сбрасывает счетчик буфера
keys_reset_counter:
	xor a						
	ld (keys_buffer_counter),a	
	call keys_proc				; сбрасываем маски (рег.A=0) и восстанавливаем автоповтор.
	ret
	
	; ---------------------------------
	; Процедура keys_setup_buffer - устанавливает адрес и размер буфера.keys_buffer_size
	; Вход: HL - адрес буфера, C - размер буфера
keys_setup_buffer:
	call keys_disable
	ld (keys_buffer_addr),hl
	ld a,c
	ld (keys_buffer_size),a
	call keys_reset_counter
	ret

	; ---------------------------------
	; Процедура keys_proc - помещает коды клавиш в буфер
	; и обеспечивает автоповтор нажатия.
	; Вход: рег. A=0 если не нажата ни одна клавиша, A<>0 если нажата хотя бы одна.
	; ---------------------------------
keys_proc:
	or a							; нажата хотя бы одна клавиша?
	ld hl,keys_repeat_delay			; адрес значения паузы перед автоповтором
	jp z,_kproc_set_counter			; переход, если не было нажато ни одной клавиши

	call keys_parser				; обработать клавиши, заполнить буфер

	ld a,(keys_repeat_delay)		; разрешен ли автоповтор?
	or a
	ret z							; запрещен

	ld hl,keys_repeat_counter		; уменьшаем счетчик паузы автоповтора
	dec (hl)
	ret nz							; выходим, если счетчик не равен нулю
	ld hl,keys_repeat_delay2		; адрес значения паузы самого автоповтора

_kproc_set_counter:
	ld a,(hl)
	ld (keys_repeat_counter),a		; восстановить значение счетчика паузы автоповтора

keys_reset_mask:
	ld hl,$ffff						; сбрасываем все маски клавиш 
	ld (keys_mask),hl
	ld (keys_mask+2),hl
	ld (keys_mask+4),hl
	ld (keys_mask+6),hl
	ld a,h
	ld (keys_ext_mask),a			; (включая РУС/LAT,УС,СС)
	ret

	; ---------------------------------
	; Процедура keys_parser конвертирует битовую таблицу клавиш из (keys_ext, keys_lines)
	; в код от 0 до 63 (не ascii) и помещает в буфер (keys_buffer).
	; Число клавиш в буфере определяется значением из (keys_buffer_counter)
	; Определение клавиш идет в обратном порядке.
	; ---------------------------------
keys_parser:
	ld de,keys_ext					; адрес битовой карты клавиш
	ld hl,keys_ext_mask				; адрес масок запрета повтора
	ld bc,$0342						; B-счетчик битов, C-код клавиши
_kp_key_cycle:
	ld a,(de)						; загрузить ряд клавиш
	and (hl)						; наложить маску
	or a							; нажата ли хоть одна клавиша в ряду?
	jp nz,_kp_bit_loop				; да, на начало цикла с битами
	ld a,c							; нет, пропускаем N клавиш
	sub b
	ld c,a
	jp _kp_next_byte
_kp_bit_loop:
	rlca							; выдвинуть бит
	call c,put_key_to_buffer		; если нажата, добавить клавишу в буффер
	dec c							; след. код клавиши
	dec b							; след. бит в ряду
	jp nz,_kp_bit_loop				; на начало цикла битов
_kp_next_byte:
	ld a,(de)						; загрузить снова нажатые клавиши
	cpl								; инвертируем все биты клавиш для новой маски
	ld (hl),a						; сохраняем маску
	inc de							; след. ряд клавиш
	inc hl							; след. маска ряда клавиш
	ld b,$08						; счетчик клавиш в ряду
	inc c							; проверяем рег. B (код клавиши) на отриц. значение
	dec c
	jp p,_kp_key_cycle				; возврат пока код клавиши больше или равен нулю	
	ret

put_key_to_buffer:
	push af
	push de
	ld a,(keys_buffer_size)			; максимальный размер буфера
	ld e,a
	ld a,(keys_buffer_counter)		; проверить заполненность буфера
	cp e
	jp nc,_pktb_exit
	push hl	
	ld hl,(keys_buffer_addr)		; вычислить смещение в буфере
	ld d,0
	ld e,a
	add hl,de
	ld (hl),c						; сохранить в буфер код клавиши
	inc e							; увеличить счетчик клавиш в буфере
	ld a,e
	ld (keys_buffer_counter),a	
	pop hl
_pktb_exit:
	pop de
	pop af
	ret

	; ---------------------------------
	; Битовая карта (8 байт / 8 бит) содержит данные о нажатых (удерживаемых) клавишах.
	; Биты: 7 6 5 4 3 2 1 0 обозначают нажатие соотв. клавиши в ряду.
keys_ext:		; Служебные клавиши:
	DEFB $00 	; РУС/LAT, УС и СС (биты 7,6,5)
keys_lines:		; Основные клавиши:
	DEFB $00	; Пробел ^ ] \ [ Z Y X
	DEFB $00	; W V U T S R Q P
	DEFB $00	; O N M L K J I H
	DEFB $00	; G F D C B A @
	DEFB $00	; / . = , ; : 9 8
	DEFB $00	; 7 6 5 4 3 2 1 0
	DEFB $00	; F5 F4 F3 F2 F1 АР2 СТР ↖
	DEFB $00	; ↓ → ↑ ← ЗБ ВК ПС ТАБ

	; ---------------------------------
	; Карта запрета повторного определения клавиш. Последовательность см. в (keys_lines).
	; Здесь бит=1 разрешена обработка клавиши, бит=0 запрещена.
	; Используется процедурой keys_parser для заполнения буфера.
keys_ext_mask:
	DEFB $ff	; Маска блокировки повторов РУС/LAT, УС и СС (биты 7,6,5)
keys_mask:
	DEFS 8,$ff	; Маска блокировки основных клавиш

	; ---------------------------------
	; Адрес буфера нажатых клавиш
keys_buffer_addr:
	DEFW KeyBufferAddr

	; ---------------------------------
	; Размер буфера нажатых клавиш
keys_buffer_size:
	DEFB KeyBufferSize

	; ---------------------------------
	; Размер данных в буфере (счетчик)
keys_buffer_counter:
	DEFB $00

	; ---------------------------------
	; Служебная переменная.
	; 0 бит = 1 - разрешение на обработку клавишь и запись в буфер , 0 - запрет
	; 3 бит = состояние индикатора РУС
service_flags:
	DEFB %00000001

	; ---------------------------------
	; пауза перед автоповтором нажатия клавиш
keys_repeat_delay:
	DEFB KeyRepDelay

	; ---------------------------------
	; пауза автоповтора нажатия клавиш
keys_repeat_delay2:
	DEFB KeyRepDelay2

	; ---------------------------------
	; сам счетчик паузы автоповтора
keys_repeat_counter:
	DEFB KeyRepDelay

	; ---------------------------------
	; Счетчик прерываний
int_counter:
	DEFB $00

	; ---------------------------------
	; Аппаратный скроллинг ($ff - по умолчанию)
scroll_pos:
	DEFB $ff

	; ---------------------------------
	; Математический цвет бордюра
border_color:
	DEFB $01


