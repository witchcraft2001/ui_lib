; Sprinter DSS/BIOS constants.
; Local copies are kept in include/platform/.
; Primary upstream source: sprinter_ai_doc/manual/include.

        include "include/platform/dss_equ.inc"
        include "include/platform/bios_equ.inc"
        include "include/platform/ports.inc"

DSS_WAITKEY     equ     Dss.WaitKey
DSS_SCANKEY     equ     Dss.ScanKey
DSS_TESTKEY     equ     Dss.TestKey
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
BIOS_MOUSE_SHOW equ     01h
BIOS_MOUSE_HIDE equ     02h
BIOS_MOUSE_REFRESH equ  83h
