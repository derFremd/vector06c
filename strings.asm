    ; ********************************************
    ; ����� � ��������� KOI8-R
	; ********************************************

str_test:
    DEFM "����� �� ��� ���� ������ ����������� ����� �� ����� ���.",0x0a
    DEFM "��� 0x10 ������ ���� ��������. "
    DEFB $10,6 ; ������� ���� ��������
    DEFM $0a,"����� �� �ݣ ���� ������ ����������� ����� �� ����� ���!",0x0a
    DEFM "��� 0x11 ������ ���� �������� ��������. "
    DEFM $10,15 ; ������� ���� ��������
    DEFB $11,8 ; ������� ���� ���� ��������    
    DEFM "The quick brown fox jumps over the lazy dog. "
    DEFM "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG"
    DEFM $10,15,$11,0,"a$=(12/3+456*78-90)^�2���������"
    DEFB $10,7,$11,8 ; ������� ����
    DEFB $16,1,20 ; ������� ����������
    DEFM "����� ���������� CUR 1,26"
    DEFB $16,2,19 ; ������� ����������
    DEFM "����� ���������� CUR 2,25",$0a,$0a
    DEFB $10,15,$11,0 ; ������� ����
    DEFM "� ���� ������ ���� ",$10,3,"���",$08,"���",$10,15," \"Backspace\" (0x08) � ����� \"������\"."
    DEFB $16,0,14 ; ������� ����������
    DEFB $10,3 ; ������� ���� ��������
    DEFB $11,0 ; ������� ���� ���� ��������
    DEFM "� ���� ������ ���� ������",$0a,"�������� ������ (LF 0x0A).",$0a
    DEFB $10,4 ; ������� ���� ��������
    DEFM "���� ������ CR (0x0D) ����������          �� ������ ����",$10,5,$0d,"������.",$0a,$0a
    DEFB $10,15 ; ������� ���� ��������
    DEFM "������",$10,7,$02,10,"�",$10,15,"������ ������ ����� ���� 0x02,nn, ��� nn - ����� ��������.",$0a
    DEFB $10,15 ; ������� ���� ��������
    DEFM "0",$09,"1",$09,"2",$09,"3",$09,"4",$09,"5",$09,"6",$09,"7",$09,"8"
    DEFB $11,6 ; ������� ���� ���� ��������
    DEFM " ��",$09,"��",$09,"��",$09,"��",$09,"�",$09,"�������",$09,"4.",$09,$0a
    DEFB $11,0 ; ������� ���� ���� ��������
    DEFB 0 ; ���������� ������

str_test2:
    DEFM $11,$00,"������ ����������� ���������",$0a
    DEFM "����� 1",$09,"10 c."
    DEFM "����� 2",$09,"20 c."
    DEFB 0 ; ���������� ������

