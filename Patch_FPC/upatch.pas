unit uPatch;

{$mode delphi}{$H+}

(*

I have used this unit, earlier and later versions, in all sorts of 'hacky' projects on WM.

Code in this unit may or may not work for a specific WM version and/or purpose. This stuff gets mixed up in WM revisions.

Some of the structures and info is taken from other famous WM hackers, some I have written and figured out myself, some with help of others.

Either way, at least the following people should be credited alongside myself here:

Itsme, Mamiach, OliPro, Cmonex

Thanks,
- Chainfire

*)

interface

uses
  Windows;
  
type
  TFuncCode = Array of Byte;
  
  CPUCONTEXT = packed record
    Psr,
    R0,
    R1,
    R2,
    R3,
    R4,
    R5,
    R6,
    R7,
    R8,
    R9,
    R10,
    R11,
    R12,
    Sp,
    Lr,
    Pc: DWORD;
    
{
    Fpscr,
    FpExc,
    S[NUM_VFP_REGS+1]
    FpExtra[NUM_EXTRA_CONTROL_REGS]: DWORD;
}
  end;
  
  CALLSTACK = packed record
    pcstkNext: Pointer; // PCALLSTACK
    retAddr: Pointer;
    pprcLast: Pointer; // PPROCESS
    accesskeyLast: DWORD;
    extra: DWORD;
    dwPrevSP: DWORD;
    dwPrcInfo: DWORD;
  end;
  PCALLSTACK = ^CALLSTACK;

  THREAD = packed record
    wInfo: WORD;
    bSuspendCnt: Byte;
    bWaitState: Byte;
    pProxList: Pointer;
    pNextInProc: Pointer; // PTHREAD
    pProc: Pointer; // PPROCESS
    pOwnerProc: Pointer; // PPROCESS
    accesskey: DWORD;
    pcstkTop: PCALLSTACK;
    dwOrigBase: DWORD;
    dwOrigStkSize: DWORD;
    tlsPtr: Pointer;
    dwWakeupTime: DWORD;
    tlsSecure: Pointer;
    tlsNonSecure: Pointer;
    lpProxy: Pointer;
    dwLastError: DWORD;
    hTh: DWORD;
    bBPrio: Byte;
    bCPrio: Byte;
    wCount: Word;
    pPrevInProc: Pointer; // PTRHEAD
    pThrdDbg: Pointer;
    pSwapStack: Pointer;
    ftCreate1,
    ftCreate2: DWORD;
    lpce: Pointer;
    dwStartAddr: DWORD;
    ctx: CPUCONTEXT;
    // ...
  end;
  PTHREAD = ^THREAD;
  
  Re32_lite_table = record
    rva: DWORD;
    size: DWORD;
  end;

  Re32_lite = packed record
    objcnt: WORD;                     // 0x70
    cevermajor: BYTE;                 // 0x72
    ceverminor: BYTE;                 // 0x73
    stackmax: DWORD;                  // 0x74
    vbase: DWORD;                     // 0x78
    vsize: DWORD;                     // 0x7C
    sect14rva: DWORD;                 // 0x80
    sect14size: DWORD;                // 0x84
    timestamp: DWORD;                 // 0x88
    exporttable: Re32_lite_table;     // 0x8C
    importtable: Re32_lite_table;
    resourcetable: Re32_lite_table;
    exceptiontable: Re32_lite_table;
    securitytable: Re32_lite_table;
    fixuptable: Re32_lite_table;
  end;
  Pe32_lite = ^Re32_lite;

  RMODULE = packed record
    lpSelf: Pointer;                  // 0x00
    pModule: Pointer;                 // 0x04
    lpszModName: PWideChar;           // 0x08
    inuse: DWORD;                     // 0x0C
    refcnt: array[0..31] of Word;     // 0x10
    BasePtr: Pointer;                 // 0x50
    stuff: Array[0..27] of Byte;      // 0x54
    e32: Re32_lite;                   // 0x70
  end;
  PMODULE = ^RMODULE;

  ROMHDR = packed record
    dllfirst,
    dlllast,
    physfirst,
    physlast,
    nummods,
    ulRAMStart,
    ulRAMFree,
    ulRAMEnd,
    ulCopyEntries,
    ulCopyOffset,
    ulProfileLen,
    ulProfilesOffset,
    numfiles,
    ulKernelFlags,
    ulFSRamPercent,
    ulDriveglobStart,
    ulDriveglobLen: DWord;

    usCPUType,
    usMiscFlags: Word;

    pExtensions: Pointer;

    ulTrackingStart,
    ulTrackingLen: Cardinal;
  end;
  PROMHDR = ^ROMHDR;

  TOCentry = packed record
    dwFileAttributes,
    ftTime1,
    ftTime2,
    nFileSize: DWord;

    lpszFilename: PChar;

    ulE32Offset,
    ulO32Offset,
    ulLoadOffest: DWord;
  end;
  PTOCentry = ^TOCentry;

  O32_ROM = packed record
    o32_vsize,
    o32_rva,
    o32_psize,
    o32_dataptr,
    o32_realaddr,
    o32_flags: DWORD;
  end;
  PO32_ROM = ^O32_ROM;

  HDATA = packed record
    linkage1,
    linkage2: DWORD;
    hValue: DWORD;
    lock: DWORD;
    ref: DWORD;
    pci: DWORD;
    pvObj: Pointer;
    dwInfo: DWORD;
  end;
  PHDATA = ^HDATA;
  
  openexe_t = packed record
    dummy1,
    dummy2,
    dummy3,
    dummy4{,
    dummy5,
    dummy6}: DWORD;
  end;

  PROCESS = packed record
    procnum: Byte;
    DbgActive: Byte;
    bChainDebug: Byte;
    bTrustLevel: Byte;
    pProxyList: Pointer;
    hProc: HANDLE;
    dmWMBase: DWORD;
    pThread: Pointer; // PTHREAD
    AccessKey: DWORD;
    BasePtr: Pointer;
    hDbgrThrd: DWORD;
    lpszProcName: PWideChar;
    tlsLowUsed: DWORD;
    tlsHighUsed: DWORD;
    pfnEH: Pointer;
    ZonePtr: Pointer;
    pMainTh: Pointer; // PTHREAD
    pmodResource: PMODULE;
    pStdNames: Array[0..2] of Pointer;
    pCmdLine: PWideChar;
    dwDyingThreads: DWORD;
    oe: openexe_t;
    e32: Re32_lite;
    // ...
  end;
  PPROCESS = ^PROCESS;
  
  RIMAGE_EXPORT_DIRECTORY = record
    Characteristics: DWORD;
    TimeDateStamp: DWORD;
    MajorVersion: WORD;
    MinorVersion: WORD;
    Name: DWORD;
    Base: DWORD;
    NumberOfFunctions: DWORD;
    NumberOfNames: DWORD;
    AddressOfFunctions: DWORD; // RVA from base of image
    AddressOfNames: DWORD; // RVA from base of image
    AddressOfNameOrdinals: DWORD; // RVA from base of image
  end;
  PIMAGE_EXPORT_DIRECTORY = ^RIMAGE_EXPORT_DIRECTORY;

  RIMAGE_IMPORT_DIRECTORY = record
    rva_lookup: DWORD;
    timestamp: DWORD;
    forwarder: DWORD;
    rva_dllname: DWORD;
    rva_address: DWORD;
  end;
  PIMAGE_IMPORT_DIRECTORY = ^RIMAGE_IMPORT_DIRECTORY;
  
  TOpCode32 = Array[0..3] of WORD;
  
const
  PRETLS_THRDINFO = -5;
  
  PROCESS_SIZE = 240;
  
  KERNEL_MODE = $1F;
  USER_MODE = $10;
  
  UTLS_INKMODE = $1;
  
  CST_MODE_FROM_USER = $0001;
  CST_MODE_TO_USER = $0002;

  ROMFLAGS_DISALLOW_PAGING = 1;
  ROMFLAGS_NOT_ALL_KMODE = 2;
  ROMFLAGS_TRUST_MODULE_ONLY = 10;
  
  addr_romhdr_ptr = $FFFFCB30;

  addr_kdatastruct = $FFFFC800;
  offset_kdatastruct_ainfo = $300;
  offset_kdatastruct_ainfo_processlist_ptr = $0;
  offset_kdatastruct_ainfo_modulelist_ptr = $24;
  addr_processlist_ptr = addr_kdatastruct + offset_kdatastruct_ainfo + offset_kdatastruct_ainfo_processlist_ptr;
  addr_modulelist_ptr = addr_kdatastruct + offset_kdatastruct_ainfo + offset_kdatastruct_ainfo_modulelist_ptr;

  MAX_PROCESSES = 32;

const
  opBXLR: TOpCode32 = ($1E, $FF, $2F, $E1);
  opLDRPC: TOpCode32 = ($04, $F0, $1F, $E5); // follow by absolute jump address

  CACHE_SYNC_DISCARD      = $01;
  CACHE_SYNC_INSTRUCTIONS = $02;
  
function SetKMode(Mode: BOOL): BOOL; external 'coredll.dll';
function SetProcPermissions(Perm: DWORD): DWORD; external 'coredll.dll';
procedure CacheSync(Flags: Integer); external 'coredll.dll';

function GetProcess(hProc: DWORD): PPROCESS;

function GetProcessList: Pointer;
function GetModuleList: Pointer;

function GetFunctionCode(hMod: HMODULE; funcname: String; maxLen: Integer): TFuncCode; overload;
function GetFunctionCode(addr: Pointer; maxLen: Integer; opTerm: TOpCode32): TFuncCode; overload;

function GetCoreDLLAddress(coredll: HMODULE; address: Pointer): Pointer;

function CreateJumpCode(address: Pointer): TFuncCode;
function PatchCode(address: Pointer; newCode: array of byte): TFuncCode;

function PatchCOREDLL(hModCoreDLL: HMODULE; funcname: String; newCode: array of byte): TFuncCode;

procedure PatchThreadKernelMode(Thread: PTHREAD);

function GetROMFLAGS: DWORD;
procedure SetROMFLAGS(value: DWORD);

procedure ClearCache;

function PatchImportTable(Process: PPROCESS; find, replace: DWORD): Boolean;

implementation

procedure ClearCache;
begin
  CacheSync(CACHE_SYNC_DISCARD OR CACHE_SYNC_INSTRUCTIONS);
end;

function GetROMFLAGS: DWORD;
begin
  Result := PROMHDR(PDWORD(addr_romhdr_ptr)^).ulKernelFlags;
end;

procedure SetROMFLAGS(value: DWORD);
begin
  PROMHDR(PDWORD(addr_romhdr_ptr)^).ulKernelFlags := value;
end;

function GetFunctionCode(hMod: HMODULE; funcname: String; maxLen: Integer): TFuncCode;
var
  p: Pointer;
begin
  SetLength(Result, 0);

  if hMod = 0 then Exit;

  p := GetProcAddress(hMod, PWideChar(WideString(funcname)));
  if p = nil then Exit;
  
  Result := GetFunctionCode(p, maxLen, opBXLR);
end;

function GetFunctionCode(addr: Pointer; maxLen: Integer; opTerm: TOpCode32): TFuncCode;
var
  oldKMode: BOOL;
  oldProcPerm: DWORD;
  
  curOP: Array[0..3] of Byte;
  p: PBYTE;
  i: Integer;
  ok: Boolean;
begin
  p := addr;

  ok := False;
  SetLength(Result, 0);
  
  oldKMode := SetKMode(True);
  oldProcPerm := SetProcPermissions($FFFFFFFF);
  try
    maxLen := maxLen div 4;
    for i := 0 to maxLen do begin
      curOP[0] := p^;
      cardinal(p) := cardinal(p) + 1;
      curOP[1] := p^;
      cardinal(p) := cardinal(p) + 1;
      curOP[2] := p^;
      cardinal(p) := cardinal(p) + 1;
      curOP[3] := p^;
      cardinal(p) := cardinal(p) + 1;
        
      SetLength(Result, Length(Result) + 4);
      Result[Length(Result) - 4] := curOP[0];
      Result[Length(Result) - 3] := curOP[1];
      Result[Length(Result) - 2] := curOP[2];
      Result[Length(Result) - 1] := curOP[3];
        
      if ((curOP[0] = opTerm[0]) OR (opTerm[0] > $FF)) AND
         ((curOP[1] = opTerm[1]) OR (opTerm[1] > $FF)) AND
         ((curOP[2] = opTerm[2]) OR (opTerm[2] > $FF)) AND
         ((curOP[3] = opTerm[3]) OR (opTerm[3] > $FF)) then begin
        ok := True;
        Break;
      end;
    end;
  finally
    SetKMode(oldKMode);
    SetProcPermissions(oldProcPerm);
  end;

  if not ok then
    SetLength(Result, 0);
end;

procedure PatchThreadKernelMode(Thread: PTHREAD);
var
  pdw: PDWORD;
begin
  // Set KTHRDINFO to UTLS_INKMODE
  pdw := Pointer(DWORD(thread.tlsPtr) + (PRETLS_THRDINFO * 4));
  pdw^ := pdw^ OR UTLS_INKMODE;

  // Set PSR register to KERNEL_MODE
  thread.ctx.Psr := (thread.ctx.Psr AND $FFFFFF00) OR KERNEL_MODE;

  if thread.pcstkTop <> nil then begin
    // Set stack of caller to "KERNEL_MODE_BASE"
    if thread.pcstkTop.pcstkNext <> nil then
      PCALLSTACK(thread.pcstkTop.pcstkNext).dwPrcInfo := PCALLSTACK(thread.pcstkTop.pcstkNext).dwPrcInfo AND (NOT CST_MODE_TO_USER);

    // Set stack to "KERNEL_MODE" && "KERNEL_MODE_BASE"
    thread.pcstkTop.dwPrcInfo := thread.pcstkTop.dwPrcInfo AND (NOT CST_MODE_FROM_USER) AND (NOT CST_MODE_TO_USER);
  end;
end;

function GetCoreDLLAddress(coredll: HMODULE; address: Pointer): Pointer;
var
  pMod: PModule;

  HDR: PROMHDR;
  entry: PTOCentry;
  o32: PO32_ROM;

  i, j: Integer;
begin
  Result := nil;

  Cardinal(pMod) := coredll;

  Cardinal(hdr) := PDWORD(addr_romhdr_ptr)^;
  Cardinal(entry) := Cardinal(hdr) + SizeOf(ROMHDR);

  if hdr.nummods > 0 then
  for i := 0 to hdr.nummods - 1 do begin
    if (entry.lpszFilename = 'coredll.dll') then begin
      Cardinal(o32) := entry.ulO32Offset;

      Result := Pointer(o32.o32_dataptr - o32.o32_rva + (DWORD(address) - DWORD(pMod.BasePtr)));
      
      Break;
    end;

    Cardinal(entry) := Cardinal(entry) + SizeOf(TOCentry);
  end;
end;

function CreateJumpCode(address: Pointer): TFuncCode;
begin
  SetLength(Result, 8);
  Result[0] := opLDRPC[0];
  Result[1] := opLDRPC[1];
  Result[2] := opLDRPC[2];
  Result[3] := opLDRPC[3];
  Move(address, Result[4], 4);
end;

function PatchCode(address: Pointer; newCode: array of byte): TFuncCode;
var
  pNew: Pointer;
  i: Integer;
begin
  if Length(newCode) > 0 then begin
    SetLength(Result, Length(newCode));
    pNew := address;
    
    for i := low(newCode) to high(newCode) do begin
      Result[i] := PBYTE(pNew)^;
      PBYTE(pNew)^ := newCode[i];
      Cardinal(pNew) := Cardinal(pNew) + 1;
    end;
  end;
end;

function PatchCOREDLL(hModCoreDLL: HMODULE; funcname: String; newCode: array of byte): TFuncCode;
begin
  Result := PatchCode(GetCoreDLLAddress(hModCoreDLL, GetProcAddress(hModCoreDLL, PWideChar(WideString(funcname)))), newCode);
end;

function GetProcess(hProc: DWORD): PPROCESS;
var
  ph: PHDATA;
begin
  ph := Pointer($80000000 OR (hProc AND $1FFFFFFC));
  result := ph.pvObj;
end;

function GetProcessList: Pointer;
begin
  Result := Pointer(PDWORD(addr_processlist_ptr)^);
end;

function GetModuleList: Pointer;
begin
  Result := Pointer(PDWORD(addr_modulelist_ptr)^);
end;

function PatchImportTable(Process: PPROCESS; find, replace: DWORD): Boolean;
var
  i: Integer;
  iat: PIMAGE_IMPORT_DIRECTORY;
  address: PDWORD;
  base: DWORD;
begin
  Result := False;

  if process.pThread <> nil then begin
    base := process.dmWMBase + process.e32.vbase;

    iat := Pointer(base + process.e32.importtable.rva);
    while iat.rva_lookup <> 0 do begin
      address := Pointer(base + iat.rva_address);
      while address^ <> 0 do begin
        if address^ = find then begin
          Result := True;
          address^ := replace;
        end;

        inc(address);
      end;
      inc(iat);
    end;
  end;
end;

end.

