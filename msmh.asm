	P386
	MODEL   flat, stdcall
	JUMPS
	LOCALS

INCLUDE W32.inc

EXTRN	SHGetSpecialFolderLocation	: PROC
EXTRN	SHBrowseForFolder		: PROC
EXTRN	IsDlgButtonChecked		: PROC
EXTRN	CheckDlgButton			: PROC
EXTRN	LoadLibraryA			: PROC

	DATASEG

IDI_ICON	EQU 100

IDD_DIALOG	EQU 100
IDC_RPOPUP	EQU 10
IDC_RNETMSG	EQU 20
IDC_FROM	EQU 100
IDC_LOCFROM	EQU 1000
IDC_TO		EQU 200
IDC_LOCTO	EQU 2000
IDC_FAKETO	EQU 250
IDC_LOCFAKETO	EQU 2500
IDC_MESSAGE	EQU 300
IDC_DELAY	EQU 400
IDC_TIMES	EQU 500
IDC_LOOP	EQU 30
IDC_USEFAKETO	EQU 40
IDC_SEND	EQU 3000
IDC_CANCEL	EQU 4000
IDC_ABOUT	EQU 5000
IDC_PROGRESS	EQU 10000

IDD_ABOUT	EQU 200
IDC_BOX		EQU 100
IDC_OK		EQU 1000

IDR_VERSION	EQU 100


IDC_TIMER	EQU	1


BROWSEINFO	STRUC
hwndOwner	HWND	?
pidlRoot	LPCVOID	?
pszDisplayName	LPSTR	?
lpszTitle	LPCSTR	?
ulFlags		UINT	?
lpfn		LPFN	?
lParam_         LPARAM  ?
iImage		UINT	?
BROWSEINFO	ENDS


NERR_BASE		EQU	2100
NERR_NameNotFound	EQU	NERR_BASE + 173
NERR_NetworkError	EQU	NERR_BASE + 36
ERROR_ACCESS_DENIED	EQU	5h
CSIDL_NETWORK		EQU	12h
BIF_BROWSEFORCOMPUTER	EQU	1000h
PBM_STEPIT              EQU     WM_USER + 5h


Loop		DD	0
CanUseNetMsg	DD	FALSE
UseNetMsg	DD	FALSE
UseFakeTo	DD	FALSE

@NetAPI32       DB      "NETAPI32.DLL", NULL
@NetMessageBufferSend   DB "NetMessageBufferSend", NULL

NameNotFound	DB	"The user name could not be found!!!", NULL
NetworkError	DB	"A general failure occurred in the network hardware!!!", NULL
Access_Denied	DB	"The user does not have access to perform specified action!!!", NULL
UnknownNetworkError	DB	"Unknown Network Error!!!", NULL
CantSend        DB      "Can't send message!!!", NULL
OutOfRange1	DB	"'Delay' must be between 0 and 10000!!!", NULL
OutOfRange2	DB	"'Times to send' must be between 1 and 5000!!!", NULL

bTitle		DB	"Select computer:", NULL
nbFilePath      DB      "\MAILSLOT\MESSNGR", NULL

CRLF		EQU	0Dh, 0Ah
TAB		EQU	9h
AboutText       DB	TAB, '-=x[ Micro$oft Messenger Hack v1.2 ]x=-', CRLF
		DB	"Coded by Stas (Mail: stas@grad.icmc.sc.usp.br; URL: http://sysd.hypermart.net);", CRLF
		DB	"(C)opyLeft by SysD Destructive Labs, 1997-2000", CRLF, CRLF

		DB	'This program is intended to provide Micro$oft Messenger Service'
		DB	' functionality, with clean graphical interface and spoof/flood'
		DB	' options. It allows you to send messages through 2 methods:', CRLF, CRLF

		DB	'I). Through MAILSLOT\MESSNGR, using CreateFile()/WriteFile(); like Win9x WinPopup program.', CRLF
		DB	'II). Through WinNT native Net API NetMessageBufferSend(); like WinNT/2K "net send" command.', CRLF, CRLF

                DB      'Main disadvantages of this second method are: it needs WinNT/2K,'
		DB	' has low speed and needs remote administrator access to use spoof.'
		DB	' (And, sure, computer from which you want to send your message'
		DB	' MUST be online)', CRLF, CRLF

		DB	'Read WinPopup and "net send" help for more info about usage of'
		DB	' Micro$oft Messenger Service.', CRLF, CRLF

		DB	'*************** WARNING ***************', CRLF
		DB	'Use at your own risk, I give you no garanties at all!'
		DB	' Remember that spoofing is illegal, and network admin has'
                DB      ' all rights to kick your ass if got you using this shit!!!'
		DB	NULL

	UDATASEG

hInst           DD      ?
hSendButton     DD      ?
hCancelButton   DD      ?
hTimesEdit	DD	?
hFakeTo		DD	?
hLocFakeTo	DD	?
hUseFakeTo	DD	?

NetMessageBufferSend	DD	?

idl		DD	?
bi              BROWSEINFO      <?>
bBuffer         DB      MAX_PATH DUP (?)

TimerID		DD	?

Handle          DD      ?
bytes_rdwr      DD      ?

LEN		EQU	512
From            DB      LEN DUP (?)
To              DB      LEN DUP (?)
FakeTo		DB	LEN DUP (?)
Message         DB      10 * LEN DUP (?)

nbFile		DB	(LEN * 2) DUP (?)
nbMsg		DB	10 * (LEN * 2) DUP (?)
nbMsg_		DD	?

Delay		DD	?
Times		DD	?

	CODESEG

Start:
	call    GetModuleHandle, NULL
	mov     [hInst], eax


	call	LoadLibraryA, offset @NetAPI32
	or	eax, eax
	jz	short @@10

	call	GetProcAddress, eax, offset @NetMessageBufferSend
	or	eax, eax
	jz	short @@10

	mov	[NetMessageBufferSend], eax
	mov	[CanUseNetMsg], TRUE


@@10:
	call	SHGetSpecialFolderLocation, NULL, CSIDL_NETWORK, offset idl;

        mov     eax, [idl]
        mov     [bi.pidlRoot], eax
        mov     [bi.pszDisplayName], offset bBuffer
        mov     [bi.lpszTitle], offset bTitle
        mov     [bi.ulFlags], BIF_BROWSEFORCOMPUTER


	call    DialogBoxParam, hInst, IDD_DIALOG, NULL, offset DlgProc, NULL
	call    ExitProcess, eax


DlgProc PROC
	ARG	hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

	mov	eax, [uMsg]

        cmp     ax, WM_INITDIALOG
	jz	short @@InitDialog
        cmp     ax, WM_COMMAND
        jz      @@Command
        cmp     ax, WM_CLOSE
        jz      @@Close
        cmp     ax, WM_TIMER
        jz      @@Send

@@RetFalse:
	xor	eax, eax
	ret


@@InitDialog:
	call    LoadIcon, hInst, IDI_ICON
	call    SendMessage, hWnd, 80h, 0, eax

	push	[hWnd]
	pop	[bi.hwndOwner]

	mov	[bytes_rdwr], LEN
	call    GetComputerName, offset From, offset bytes_rdwr
        call    SetDlgItemText, hWnd, IDC_FROM, offset From
	call	SendDlgItemMessage, hWnd, IDC_FROM, CB_ADDSTRING, 0, offset From

        call    GetDlgItem, hWnd, IDC_SEND
        mov     [hSendButton], eax
        call    GetDlgItem, hWnd, IDC_CANCEL
        mov     [hCancelButton], eax
        call    GetDlgItem, hWnd, IDC_TIMES
        mov     [hTimesEdit], eax
        call    GetDlgItem, hWnd, IDC_FAKETO
        mov     [hFakeTo], eax
	call	EnableWindow, eax, FALSE
        call    GetDlgItem, hWnd, IDC_LOCFAKETO
        mov     [hLocFakeTo], eax
	call	EnableWindow, eax, FALSE
        call    GetDlgItem, hWnd, IDC_USEFAKETO
        mov     [hUseFakeTo], eax

	call	CheckDlgButton, hWnd, IDC_RPOPUP, TRUE

	cmp	[CanUseNetMsg], TRUE
	jz	short @@CantUseNetMsg
	call	GetDlgItem, hWnd, IDC_RNETMSG
	call	EnableWindow, eax, FALSE

@@CantUseNetMsg:
        call    EnableWindow, hCancelButton, FALSE
        jmp     @@RetTrue


@@Command:
	mov	eax, [wParam]

        cmp     ax, IDC_RPOPUP
	jz	@@Method
        cmp     ax, IDC_RNETMSG
	jz	@@Method
        cmp     ax, IDC_LOOP
	jz	@@Loop
        cmp     ax, IDC_USEFAKETO
	jz	@@UseFakeTo
        cmp     ax, IDC_SEND
	jz	@@SendButton
        cmp     ax, IDC_CANCEL
        jz      @@Stop
        cmp     ax, IDC_ABOUT
	jz	@@AboutButton
        cmp     ax, IDC_LOCFROM
	jz	@@LocFromButton
        cmp     ax, IDC_LOCTO
	jz	@@LocToButton
        cmp     ax, IDC_LOCFAKETO
	jnz	@@RetTrue

@@LocFakeToButton:
	call	Locate, IDC_FAKETO
        jmp     @@RetTrue

@@LocFromButton:
	call	Locate, IDC_FROM
        jmp     @@RetTrue

@@LocToButton:
	call	Locate, IDC_TO
        jmp     @@RetTrue

@@AboutButton:
	call	DialogBoxParam, hInst, IDD_ABOUT, hWnd, offset About, NULL
        jmp     @@RetTrue

@@SendButton:
	call	ReadData
	or	eax, eax
        jz      @@RetTrue

	call	SendInit

	call	SetTimer, hWnd, IDC_TIMER, Delay, NULL
	mov	[TimerID], eax
	jmp	@@Send

@@Method:
	call	IsDlgButtonChecked, hWnd, IDC_RPOPUP
	push	eax
	call	EnableWindow, [hUseFakeTo], eax
	pop	eax
	or	eax, eax
	jnz	@@RetTrue

	call	CheckDlgButton, hWnd, IDC_USEFAKETO, FALSE

@@UseFakeTo:
	call	IsDlgButtonChecked, hWnd, IDC_USEFAKETO
	push	eax
	call	EnableWindow, [hFakeTo], eax
	pop	eax
	call	EnableWindow, [hLocFakeTo], eax
        jmp     @@RetTrue

@@Loop:
	call	IsDlgButtonChecked, hWnd, IDC_LOOP
	neg	eax
	not	eax
	call	EnableWindow, [hTimesEdit], eax
        jmp     @@RetTrue

@@Close:
	call	EndDialog, hWnd, NULL
        jmp     @@RetTrue


@@Send:
	cmp	[UseNetMsg], TRUE
        jnz     @@UseWriteFile
	call	[NetMessageBufferSend], offset From, offset To, offset From, offset Message, nbMsg_
	or	eax, eax
        jz      @@AllOK

	push	eax
	call	SendStop
	pop	eax

	cmp	ax, NERR_NameNotFound
	jz	short @@NameNotFound
	cmp	ax, NERR_NetworkError
	jz	short @@NetworkError
	cmp	ax, ERROR_ACCESS_DENIED
	jz	short @@Access_Denied

        call    MessageBox, hWnd, offset UnknownNetworkError, NULL, MB_OK + MB_ICONSTOP + MB_TASKMODAL
        jmp     @@RetTrue

@@NameNotFound:
        call    MessageBox, hWnd, offset NameNotFound, NULL, MB_OK + MB_ICONSTOP + MB_TASKMODAL
        jmp     @@RetTrue
@@NetworkError:
        call    MessageBox, hWnd, offset NetworkError, NULL, MB_OK + MB_ICONSTOP + MB_TASKMODAL
        jmp     @@RetTrue
@@Access_Denied:
        call    MessageBox, hWnd, offset Access_Denied, NULL, MB_OK + MB_ICONSTOP + MB_TASKMODAL
        jmp     @@RetTrue


@@UseWriteFile:
        call    WriteFile, Handle, offset nbMsg, nbMsg_, offset bytes_rdwr, 0

        or      eax, eax
       	jnz	short @@AllOK

	call	SendStop
        call    MessageBox, hWnd, offset CantSend, NULL, MB_OK + MB_ICONSTOP + MB_TASKMODAL
        jmp     short @@RetTrue

@@AllOK:
        call    SendDlgItemMessage, hWnd, IDC_PROGRESS, PBM_STEPIT, NULL, NULL

	cmp	[Loop], TRUE
	jz	short @@RetTrue

	dec	[Times]
	cmp	[Times], 0
        jnz     short @@RetTrue

@@Stop:
	call	SendStop


@@RetTrue:
	mov	eax, TRUE
	ret
DlgProc ENDP


ReadData PROC
	USES	ebx, edi, esi

	call	IsDlgButtonChecked, hWnd, IDC_LOOP
	mov	[Loop], eax


        call    GetDlgItemText, hWnd, IDC_FROM, offset From, LEN / 2
        call    GetDlgItemText, hWnd, IDC_TO, offset To, LEN / 2
        call    GetDlgItemText, hWnd, IDC_FAKETO, offset FakeTo, LEN / 2
        call    GetDlgItemText, hWnd, IDC_MESSAGE, offset Message, (10 * LEN) / 2


	mov	esi, IDC_TO
	mov	edi, offset To
	xor	ebx, ebx
	call	TryInsertInCB

	mov	esi, IDC_FAKETO
	mov	edi, offset FakeTo
	call	TryInsertInCB

	mov	esi, IDC_FROM
	mov	edi, offset From
	inc	ebx
	call	TryInsertInCB


	call	IsDlgButtonChecked, hWnd, IDC_USEFAKETO
	mov	[UseFakeTo], eax

	call	IsDlgButtonChecked, hWnd, IDC_RNETMSG
	mov	[UseNetMsg], eax


	cmp	eax, TRUE
	jnz	short @@UseMailslot


	mov	esi, offset From
	call	Ascii2Unicode
	mov	esi, offset To
	call	Ascii2Unicode
	mov	esi, offset Message
	call	Ascii2Unicode
	mov	[nbMsg_], ecx

	jmp	short @@GetRest


@@UseMailslot:
        mov     edi, offset nbFile
        mov     WORD PTR [edi], '\\'
        inc     edi
        inc     edi

        mov     esi, offset To
        call    Append
        dec     edi
        mov     esi, offset nbFilePath
        call    Append


        mov     edi, offset nbMsg

        mov     esi, offset From
        call    Append

	cmp	[UseFakeTo], TRUE
	jz	@@UseFakeTo

        mov     esi, offset To
        call    Append
	jmp	@@Message

@@UseFakeTo:
        mov     esi, offset FakeTo
        call    Append

@@Message:
        mov     esi, offset Message
        call    Append

        sub     edi, offset nbMsg
	mov	[nbMsg_], edi


@@GetRest:
        call    GetDlgItemInt, hWnd, IDC_DELAY, offset bytes_rdwr, FALSE
	cmp	[bytes_rdwr], TRUE
        jnz     @@sux1
	cmp	eax, 10000
        jg      @@sux1

	mov	[Delay], eax

	cmp	[Loop], TRUE
	jnz	short @@GetTimes
	mov	eax, 10
	jmp	short @@SetProgressBar

@@GetTimes:
        call    GetDlgItemInt, hWnd, IDC_TIMES, offset bytes_rdwr, FALSE
	cmp	[bytes_rdwr], TRUE
	jnz	@@sux2
	cmp	eax, 1
        jb      @@sux2
	cmp	eax, 5000
	ja	short @@sux2

@@SetProgressBar:
	mov	[Times], eax

	mov	ebx, 10
	mul	ebx
	shl	eax, 16
        call    SendDlgItemMessage, hWnd, IDC_PROGRESS, PBM_SETRANGE, NULL, eax
        call    SendDlgItemMessage, hWnd, IDC_PROGRESS, PBM_SETPOS, 0, 0

	mov	eax, TRUE
	ret

@@sux1:
        call    MessageBox, hWnd, offset OutOfRange1, NULL, MB_OK + MB_ICONSTOP + MB_TASKMODAL
	xor	eax, eax
	ret

@@sux2:
        call    MessageBox, hWnd, offset OutOfRange2, NULL, MB_OK + MB_ICONSTOP + MB_TASKMODAL
	xor	eax, eax
	ret
ReadData ENDP


TryInsertInCB PROC
	call	SendDlgItemMessage, hWnd, esi, CB_FINDSTRINGEXACT, 0, edi
	cmp	eax, CB_ERR
	jnz	short @@NotInsert
	call	SendDlgItemMessage, hWnd, esi, CB_INSERTSTRING, ebx, edi

@@NotInsert:
	ret
TryInsertInCB ENDP


Locate PROC
	ARG	hEdit:DWORD
	USES	esi, edi

	call    SHBrowseForFolder, offset bi
	or	eax, eax
	jz	short @@BrowseCancel

	mov	esi, offset bBuffer
	mov	edi, esi

@@10:
	lodsb
	or	al, al
	jz	@@30

	cmp	al, 'a'
	jb	@@20
	cmp	al, 'z'
	ja	@@20

	sub	al, 'a' - 'A'

@@20:
	stosb
	jmp	@@10

@@30:
	call	SetDlgItemText, hWnd + 0Ch, hEdit, offset bBuffer

@@BrowseCancel:
	ret
Locate ENDP


SendInit PROC
	call	EnableWindow, hSendButton, FALSE
	call	EnableWindow, hCancelButton, TRUE
	call	SetFocus, hCancelButton

	cmp	[UseNetMsg], TRUE
	jz	short @@NotCreateFile
        call    CreateFile, offset nbFile, GENERIC_WRITE, FILE_SHARE_READ,\
                0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, -1
        mov     Handle, eax

@@NotCreateFile:
	ret
SendInit ENDP


SendStop PROC
	call	KillTimer, hWnd, TimerID

       	call    SendDlgItemMessage, hWnd, IDC_PROGRESS, PBM_SETPOS, 0, NULL

	call	EnableWindow, hSendButton, TRUE
	call	EnableWindow, hCancelButton, FALSE
	call	SetFocus, hSendButton

	cmp	[UseNetMsg], TRUE
	jz	short @@NotCloseHandle
        call    CloseHandle, Handle

@@NotCloseHandle:
	ret
SendStop ENDP


Append PROC
        lodsb
        stosb
        or      al, al
        jnz     short Append
        
        ret
Append ENDP


Ascii2Unicode PROC
	mov	edi, esi

	xor	ax, ax
	mov	ecx, -1
	repnz	scasb
	dec	edi

	sub	edi, esi
	mov	ecx, edi
	inc	ecx
	add	esi, edi
	add	edi, esi

	std
	push	ecx

@@10:
	lodsb
	stosw
	loop	@@10

	pop	ecx
	shl	ecx, 1
	cld

	ret	
Ascii2Unicode ENDP


About PROC
        ARG     hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

	mov	eax, [uMsg]

        cmp     ax, WM_INITDIALOG
	jz	short @@InitDialog
        cmp     ax, WM_CLOSE
	jz	short @@Close
        cmp     ax, WM_COMMAND
	jnz	short @@RetFalse

	mov	eax, [wParam]
        cmp     ax, IDC_OK
	jnz	short @@RetTrue

@@Close:
	call	EndDialog, hWnd, NULL
	jmp	short @@RetTrue

@@InitDialog:
	call	SetDlgItemText, hWnd, IDC_BOX, offset AboutText

@@RetTrue:
	mov	eax, TRUE
	ret

@@RetFalse:
	xor	eax, eax
	ret
About ENDP

END Start
