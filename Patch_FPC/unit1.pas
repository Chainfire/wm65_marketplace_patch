{ KOL MCK } // Do not remove this line!
{$DEFINE KOL_MCK}
{$ifdef FPC} {$mode delphi} {$endif}
unit Unit1; 

interface

uses Windows, Messages, KOL {place your units here->}
{$IFDEF LAZIDE_MCK}, Forms, mirror, Classes, Controls, mckCtrls, mckObjs, Graphics;
{$ELSE} ; {$ENDIF}

type

  { TForm1 }

  {$I MCKfakeClasses.inc}
  {$IFDEF KOLCLASSES} TForm1 = class; PForm1 = TForm1; {$ELSE OBJECTS} PForm1 = ^TForm1; {$ENDIF CLASSES/OBJECTS}
  TForm1 = {$IFDEF KOLCLASSES}class{$ELSE}object{$ENDIF}({$IFDEF LAZIDE_MCK}TForm{$ELSE}TObj{$ENDIF})
    Form: PControl;
    KOLForm1: TKOLForm;
    KOLProject1: TKOLProject;
    Label1: TKOLLabel;
    Label2: TKOLLabel;
    lbLog: TKOLListBox;
    MainMenu1: TKOLMainMenu;
    pnlContainer: TKOLPanel;
    procedure KOLForm1FormCreate(Sender: PObj);
    procedure menuExitMenu(Sender: PMenu; Item: Integer);
    procedure menuPatchMenu(Sender: PMenu; Item: Integer);
  private
    { private declarations }
  public
    { public declarations }
    procedure Log(S: KOLString);
  end; 

var
  Form1 {$IFDEF KOL_MCK} : PForm1 {$ELSE} : TForm1 {$ENDIF} ;

{$IFDEF KOL_MCK}
procedure NewForm1( var Result: PForm1; AParent: PControl );
{$ENDIF}

implementation

uses
  uPatch,
  uRegistry;

{$IFDEF KOL_MCK}
{$I unit1_1.inc}
{$ENDIF}

{$O-}
const
  opPatch: TOpCode32 = ($FFFF, $A8, $1B, $E9);

type
  TRegQueryValueExW = function(hKey:HKEY; lpValueName:LPCWSTR; lpReserved:LPDWORD; lpType:LPDWORD; lpData:pointer;lpcbData:LPDWORD):LONG;

function newCryptVerifySignatureW(hHash: DWORD; pbSignature: PBYTE; dwSigLen: DWORD; hPubKey: DWORD; sDescription: PWideChar; dwFlags: DWORD): BOOL;
begin
  Result := True;
end;

function newRegQueryValueExW(hKey:HKEY; lpValueName:LPCWSTR; lpReserved:LPDWORD; lpType:LPDWORD; lpData:pointer;lpcbData:LPDWORD):LONG;
var
  c: Byte;
  p: PBYTE;
  oldRQVE: TRegQueryValueExW;
begin
  oldRQVE := TRegQueryValueExW($12345678);

  Result := 6; // ERROR_INVALID_HANDLE
  
  if lpValueName <> nil then begin
    DWORD(p) := DWORD(lpValueName);

    c := 0;
    repeat
      if p^ = $2D then // '-'
        inc(c);
      inc(p, 2);
    until p^ = 0;
    
    if c = 4 then begin
      lpType^ := 3; // REG_BINARY
      lpcbData^ := 256; // MAX_LICENSE_LENGTH

      Result := 0; // ERROR_SUCCESS
    end;
  end;
  
  if Result <> 0 then
    Result := oldRQVE(hKey, lpValueName, lpReserved, lpType, lpData, lpcbData);
end;

{ TForm1 }

procedure TForm1.menuExitMenu(Sender: PMenu; Item: Integer);
begin
  Form.Close;
end;

procedure TForm1.menuPatchMenu(Sender: PMenu; Item: Integer);
const
  HEAP_ZERO_MEMORY = $00000008;
  HEAP_SHARED_READONLY = $00001000;
var
  pHeap: Pointer;
  hHeap: THandle;
  hCoreDLL: HModule;
  totalMem: DWORD;
  cur: Pointer;

  fNewCryptVerifySignature,
  jNewCryptVerifySignature,
  fOldCryptVerifySignature: TFuncCode;
  aOldCryptVerifySignature,
  aNewCryptVerifySignature: Pointer;

  fNewRegQueryValueEx,
  jNewRegQueryValueEx,
  fOldRegQueryValueEx: TFuncCode;
  aOldRegQueryValueEx,
  aNewRegQueryValueEx: Pointer;
  
  aJumpRegQueryValueEx: Pointer;

  tf: TFuncCode;
  
  regType, regSize: DWORD;
begin
  SetKMode(TRUE);
  SetProcPermissions($FFFFFFFF);

  Log('Patching...');
  
  // Ensure "HKCU\Security\Software\Microsoft\Marketplace\Licenses" exists
  RegSetDWORD('HKCU\Security\Software\Microsoft\Marketplace\Licenses\dummy', 0);
  RegDelete('HKCU\Security\Software\Microsoft\Marketplace\Licenses\dummy');
  
  fNewCryptVerifySignature := GetFunctionCode(@newCryptVerifySignatureW, 1024, opPatch);
  fNewRegQueryValueEx := GetFunctionCode(@newRegQueryValueExW, 1024, opPatch);
  
  totalMem := 1024;
  
  hCoreDll := LoadLibrary('coredll.dll');
  try
    hHeap := HeapCreate(HEAP_SHARED_READONLY, totalMem, totalMem);
    if hHeap <> 0 then
    try
      pHeap := HeapAlloc(hHeap, HEAP_ZERO_MEMORY, totalMem);
      if pHeap <> nil then
      try
        cur := pHeap;
        
        aOldCryptVerifySignature := GetProcAddress(hCoreDLL, 'CryptVerifySignatureW');
        aNewCryptVerifySignature := cur;
        Move(fNewCryptVerifySignature[0], aNewCryptVerifySignature^, Length(fNewCryptVerifySignature));
        jNewCryptVerifySignature := CreateJumpCode(aNewCryptVerifySignature);
        DWORD(cur) := DWORD(cur) + Length(fNewCryptVerifySignature);
        
        aOldRegQueryValueEx := GetProcAddress(hCoreDLL, 'RegQueryValueExW');

        tf := CreateJumpCode(Pointer(DWORD(aOldRegQueryValueEx) + 8));
        SetLength(tf, 16);
        Move(tf[0], tf[8], 8);
        Move(GetCoreDLLAddress(hCoreDLL, aOldRegQueryValueEx)^, tf[0], 8);
        Move(tf[0], cur^, 16);
        aJumpRegQueryValueEx := cur;
        DWORD(cur) := DWORD(cur) + 16;
        
        aNewRegQueryValueEx := cur;
        Move(fNewRegQueryValueEx[0], aNewRegQueryValueEx^, Length(fNewRegQueryValueEx));
        jNewRegQueryValueEx := CreateJumpCode(aNewRegQueryValueEx);
        DWORD(cur) := DWORD(cur) + Length(fNewRegQueryValueEx);
        
        Move(aJumpRegQueryValueEx, cur^, 4);
        DWORD(cur) := DWORD(cur) + 4;

        fOldCryptVerifySignature := PatchCode(GetCoreDLLAddress(hCoreDLL, aOldCryptVerifySignature), jNewCryptVerifySignature);
        fOldRegQueryValueEx := PatchCode(GetCoreDLLAddress(hCoreDLL, aOldRegQueryValueEx), jNewRegQueryValueEx);
        ClearCache;
      
        Log('Waiting...');

        Sleep(30000);
      
        Log('Unpatching...');

        PatchCode(GetCoreDLLAddress(hCoreDLL, aOldCryptVerifySignature), fOldCryptVerifySignature);
        PatchCode(GetCoreDLLAddress(hCoreDLL, aOldRegQueryValueEx), fOldRegQueryValueEx);
        ClearCache;
      finally
        HeapFree(hHeap, 0, pHeap);
      end else Log('Error: pHeap == nil :: ' + Int2Str(GetLastError));
    finally
      HeapDestroy(hHeap);
    end else Log('Error: hHeap == 0 :: ' + Int2Str(GetLastError));
  finally
    FreeLibrary(hCoreDLL);
  end;
  
  Log('Done!');
end;

procedure TForm1.KOLForm1FormCreate(Sender: PObj);
begin
  pnlContainer.Align := caClient;
end;

procedure TForm1.Log(S: KOLString);
begin
  lbLog.Add(S);
  lbLog.CurIndex := lbLog.Count - 1;
  Form.Invalidate;
  Form.Update;
  Form.ProcessPaintMessages;
end;

initialization
{$IFNDEF KOL_MCK} {$I unit1.lrs} {$ENDIF}

end.

