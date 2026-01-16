#Requires AutoHotkey v1.1.05+
;==============================================================
; guiControlButtonImage — Sets a button control image list (BCM_SETIMAGELIST) with DPI-aware sizing
;
; GitHub: https://github.com/SevenKeyboard/gui-control-button-image
; Author: SevenKeyboard Ltd. (2026)
; License: The Unlicense
;
; Documentation / References:
;   [Function] GuiButtonIcon
;     https://www.autohotkey.com/boards/viewtopic.php?t=1985
;     https://www.autohotkey.com/boards/viewtopic.php?t=115871
;   ImageList_Create function (commctrl.h)
;     https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nf-commctrl-imagelist_create
;   BUTTON_IMAGELIST structure (commctrl.h)
;     https://learn.microsoft.com/en-us/windows/win32/api/commctrl/ns-commctrl-button_imagelist
;   BCM_SETIMAGELIST message
;     https://learn.microsoft.com/en-us/windows/win32/controls/bcm-setimagelist
;==============================================================
class VersionManager_guiControlButtonImage
{
    static _ := VersionManager_guiControlButtonImage._init()
    _init()    {
        global
        GUICONTROLBUTTONIMAGE_VERSION := "1.0.0"
    }
}
guiControlButtonImage(controlID, options:="", ilArgs*)    {
    local
    static ILC_MASK:=0x00000001
        ,ILC_COLOR32:=0x00000020
        ,BCM_FIRST:=0x1600
        ,BCM_SETIMAGELIST:=BCM_FIRST+0x0002
        ,SMTO_NORMAL:=0x0000
    if (!ilArgs.maxIndex())
        return false
    if (!dllCall("User32.dll\IsWindow","Ptr",hCntl:=format("{:d}",controlID)))    {
        switch (!!regExMatch(controlID, "O)^(.*?):(.*)$", m))
        {
            case true:			gn:=m[1]            ,assocVar:=m[2]
            case false:         gn:=A_DefaultGui	,assocVar:=controlID
        }
        guiControlGet hCntl, % gn ":Hwnd", % assocVar
        if (errorLevel || !hCntl)
            return false
    }
    for _,v in ["W","H","S","L","T","R","B","A"]    {
        if (regExMatch(options, "iO)\b" v "\K(-?\d+(?:\.\d+)?)\b", m))    {
            switch (v)
            {
                default:        %v%:=m[0]+0
                case "S":       W:= H := m[0]+0
            }
            continue
        }
        switch (v) ;  %v%:=(v~="W|H"?16:v~="L|T|R|B"?0:v=="A"?4:"")
        {
            case "W","H":               %v%:=16
            case "L","T","R","B":       %v%:=0
            case "A":                   %v%:=4
        }
    }
    dpiForWindow:=dllCall("User32.dll\GetDpiForWindow", "Ptr",hCntl, "UInt"), dpiScale:=(dpiForWindow?dpiForWindow:96)/96
    for _,v in ["W","H","L","T","R","B"]
        %v%:=floor(%v%*dpiScale)
    if !(normIml:=dllCall("Comctl32.dll\ImageList_Create", "Int",W, "Int",H, "UInt",ILC_MASK|ILC_COLOR32, "Int",1, "Int",1, "Ptr"))
        return false
    varSetCapacity(btnIml, A_PtrSize+20, 0)
  	adr:=numPut(normIml, btnIml, "Ptr") ;  himl
    for _,v in ["L","T","R","B"]
	    adr:=numPut(%v%, adr+0, "Int") ;  margin
	adr:=numPut(A, adr+0, "UInt") ;  uAlign
    lr:=dllCall("User32.dll\SendMessageTimeout"
        ,"Ptr",hCntl
        ,"UInt",BCM_SETIMAGELIST
        ,"UPtr",0
        ,"Ptr",&btnIml
        ,"UInt",SMTO_NORMAL
        ,"UInt",150
        ,"Ptr*",lpdwResult:=0
        ,"Ptr")
    return (lr && lpdwResult==true && IL_Add(normIml, ilArgs*))
        ?normIml
        :format("{2}",dllCall("Comctl32.dll\ImageList_Destroy", "Ptr",normIml),false)
}