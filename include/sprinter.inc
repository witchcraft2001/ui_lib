; Sprinter DSS/BIOS constants.
; Local copies are kept in include/platform/.
; Primary upstream source: sprinter_ai_doc/manual/include.

        include "include/platform/dss_equ.inc"
        include "include/platform/bios_equ.inc"

DSS_WAITKEY     equ     Dss.WaitKey
DSS_SCANKEY     equ     Dss.ScanKey
DSS_SETVMOD     equ     Dss.SetVMod
DSS_GETMEM      equ     Dss.GetMem
DSS_FREEMEM     equ     Dss.FreeMem
DSS_SETWIN3     equ     Dss.SetWin3
DSS_EXIT        equ     Dss.Exit
DSS_CLEAR       equ     Dss.Clear
DSS_WRCHAR      equ     Dss.WrChar
DSS_WINCOPY     equ     Dss.WinCopy
DSS_WINREST     equ     Dss.WinRest

BIOS_MOUSE_READ equ     03h
