unit uRegistry;

{$mode delphi}{$H+}

interface

uses
  Windows, KOL;
  
{ ANSI }
  
procedure RegKeyBreak(Full: String; var HKEY: DWORD; var Path: String; var Key: String);
function RegFindMatch(Key: String): PStrList;

function RegGetDWORD(Key: String; Def: DWORD = 0): DWORD;
function RegGetString(Key: String; Def: String = ''): String;
function RegGetMultiString(Key: String; Def: String = ''): String;
function RegGetBinary(Key: String; var Buffer: Pointer; var BufSize: Integer): Boolean;
function RegGetCustom(Key: String; var KeyType: DWORD; var Buffer: Pointer; var BufSize: Integer): Boolean;

procedure RegSetDWORD(Key: String; Value: DWORD);
procedure RegSetString(Key: String; Value: String);
procedure RegSetMultiString(Key: String; Value: String);
procedure RegSetCustom(Key: String; KeyType: DWORD; Data: Pointer; DataSize: Integer);

function RegExists(Key: String): Boolean;
function RegExistsKey(Key: String): Boolean;
procedure RegDelete(Key: String);
procedure RegDeleteKey(Key: String);

function RegEnum(Key: String): PStrList;
function RegEnumValues(Key: String): PStrList;

{ UNICODE }

procedure RegKeyBreakW(Full: KOLString; var HKEY: DWORD; var Path: KOLString; var Key: KOLString);
function RegFindMatchW(Key: KOLString): PWStrList;

function RegGetDWORDW(Key: KOLString; Def: DWORD = 0): DWORD;
function RegGetStringW(Key: KOLString; Def: KOLString = ''): KOLString;
function RegGetMultiStringW(Key: KOLString; Def: KOLString = ''): KOLString;
function RegGetCustomW(Key: KOLString; var KeyType: DWORD; var Buffer: Pointer; var BufSize: Integer): Boolean;

procedure RegSetDWORDW(Key: KOLString; Value: DWORD);

function RegEnumW(Key: KOLString): PWStrList;
function RegEnumValuesW(Key: KOLString): PWStrList;

{ UTIL }

procedure RegFlushKey(HKEY: HKEY);
procedure RegBeginUpdate;
procedure RegEndUpdate;

implementation

procedure RegKeyBreak(Full: String; var HKEY: DWORD; var Path: String; var Key: String);
var
  SL: PStrList;
  i: Integer;
  S: String;
begin
  HKEY := HKEY_LOCAL_MACHINE;
  Path := '';
  Key := '';

  SL := NewStrList;
  try
    S := Full;
    i := Pos('\', S);
    while i > 0 do begin
      SL.Add(Copy(S, 1, i - 1));
      S := Copy(S, i + 1, Length(S));
      i := Pos('\', S);
    end;
    SL.Add(S);

    if SL.Count >= 3 then begin
      if SL.Items[0] = 'HKCR' then HKEY := HKEY_CLASSES_ROOT
      else if SL.Items[0] = 'HKCU' then HKEY := HKEY_CURRENT_USER
      else if SL.Items[0] = 'HKLM' then HKEY := HKEY_LOCAL_MACHINE;

      if Copy(Full, Length(Full), 1) = '\' then
        SL.Add('');

      for i := 1 to SL.Count - 2 do
        Path := Path + SL.Items[i] + '\';
      Path := Copy(Path, 1, Length(Path) - 1);

      Key := SL.Items[SL.Count - 1];
    end;
    
    if (Key = 'Default') then
      Key := '';
  finally
    SL.Free;
  end;
end;

function RegExists(Key: String): Boolean;
var
  Ret: LongInt;
  HKEY: LongWord;
  Size: DWORD;

  Root: DWORD;
  Path: String;
  Entry: String;
  Data: PWideChar;
begin
  Result := False;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  Data := nil;

  RegKeyBreak(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_ALL_ACCESS, HKEY);

  if Ret = ERROR_SUCCESS then begin
    GetMem(Data, 4096);
    try
      FillChar(Data^, 4096, 0);
      Size := 4096;
      Ret := RegQueryValueExW(HKEY, PWideChar(WideString(Entry)), nil, nil, Data, @Size);

      if Ret = ERROR_SUCCESS then
        Result := True;
    finally
      FreeMem(Data);
      RegCloseKey(HKEY);
    end;
  end;
end;

function RegExistsKey(Key: String): Boolean;
var
  Ret: LongInt;
  HKEY: LongWord;

  Root: DWORD;
  Path: String;
  Entry: String;
begin
  Result := False;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreak(Key + '\Dummy', Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_ALL_ACCESS, HKEY);
  if Ret = ERROR_SUCCESS then begin
    Result := True;
    RegCloseKey(HKEY);
  end;
end;

function RegGetDWORD(Key: String; Def: DWORD = 0): DWORD;
var
  Ret: LongInt;
  HKEY: LongWord;
  KeyType: DWORD;
  Size: DWORD;

  Root: DWORD;
  Path: String;
  Entry: String;
begin
  Result := Def;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreak(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_ALL_ACCESS, HKEY);

  if Ret = ERROR_SUCCESS then begin
    Size := 4;
    KeyType := REG_DWORD;
    Ret := RegQueryValueExW(HKEY, PWideChar(WideString(Entry)), nil, @KeyType, @Result, @Size);

    RegCloseKey(HKEY);
  end;
end;

function RegGetString(Key: String; Def: String = ''): String;
var
  Ret: LongInt;
  HKEY: LongWord;
  KeyType: DWORD;
  Size: DWORD;

  Root: DWORD;
  Path: String;
  Entry: String;
  Data: PWideChar;
begin
  Result := Def;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  Data := nil;

  RegKeyBreak(Key, Root, Path, Entry);
  
  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_ALL_ACCESS, HKEY);

  if Ret = ERROR_SUCCESS then begin
    GetMem(Data, 4096);
    try
      FillChar(Data^, 4096, 0);
      Size := 4096;
      KeyType := REG_SZ;
      Ret := RegQueryValueExW(HKEY, PWideChar(WideString(Entry)), nil, @KeyType, Data, @Size);

      if Ret = ERROR_SUCCESS then
        Result := String(WideString(Data));
    finally
      FreeMem(Data);
      RegCloseKey(HKEY);
    end;
  end;
end;

function RegGetMultiString(Key: String; Def: String = ''): String;
begin
  Result := RegGetString(Key, Def);
end;

function RegGetBinary(Key: String; var Buffer: Pointer; var BufSize: Integer): Boolean;
var
  Ret: LongInt;
  HKEY: LongWord;
  KeyType: DWORD;
  Size: DWORD;

  Root: DWORD;
  Path: String;
  Entry: String;
  Data: PWideChar;
begin
  Result := False;
  Buffer := nil;
  BufSize := 0;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  Data := nil;

  RegKeyBreak(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_ALL_ACCESS, HKEY);

  if Ret = ERROR_SUCCESS then begin
    GetMem(Data, 4096);
    try
      FillChar(Data^, 4096, 0);
      Size := 4096;
      KeyType := REG_BINARY;
      Ret := RegQueryValueExW(HKEY, PWideChar(WideString(Entry)), nil, @KeyType, Data, @Size);

      if Ret = ERROR_SUCCESS then begin
        BufSize := Size;
        GetMem(Buffer, BufSize);
        Move(Data^, Buffer^, BufSize);
        Result := True;
      end;
    finally
      FreeMem(Data);
      RegCloseKey(HKEY);
    end;
  end;
end;

function RegGetCustom(Key: String; var KeyType: DWORD; var Buffer: Pointer; var BufSize: Integer): Boolean;
var
  Ret: LongInt;
  HKEY: LongWord;
  Size: DWORD;

  Root: DWORD;
  Path: String;
  Entry: String;
  Data: Pointer;
begin
  Result := False;
  Buffer := nil;
  BufSize := 0;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  Data := nil;

  RegKeyBreak(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_ALL_ACCESS, HKEY);

  if Ret = ERROR_SUCCESS then begin
    GetMem(Data, 4096);
    try
      FillChar(Data^, 4096, 0);
      Size := 4096;
      KeyType := REG_NONE;
      
      Ret := RegQueryValueExW(HKEY, PWideChar(WideString(Entry)), nil, @KeyType, Data, @Size);

      if Ret = ERROR_SUCCESS then begin
        BufSize := Size;
        GetMem(Buffer, BufSize);
        Move(Data^, Buffer^, BufSize);
        Result := True;
      end;
    finally
      FreeMem(Data);
      RegCloseKey(HKEY);
    end;
  end;
end;

procedure RegSetDWORD(Key: String; Value: DWORD);
var
  Ret: LongInt;
  HKEY: LongWord;
  KeyType: DWORD;

  Root: DWORD;
  Path: String;
  Entry: String;
begin
  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreak(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_ALL_ACCESS, HKEY);

  if Ret <> ERROR_SUCCESS then
    Ret := RegCreateKeyExW(Root, PWideChar(WideString(Path)), 0, nil, 0, KEY_ALL_ACCESS, nil, @HKEY, nil);

  if Ret = ERROR_SUCCESS then begin
    KeyType := REG_DWORD;
    RegSetValueExW(HKEY, PWideChar(WideString(Entry)), 0, KeyType, @Value, 4);

    RegFlushKey(HKEY);
    RegCloseKey(HKEY);
  end;
end;

procedure RegSetCustom(Key: String; KeyType: DWORD; Data: Pointer; DataSize: Integer);
var
  Ret: LongInt;
  HKEY: LongWord;

  Root: DWORD;
  Path: String;
  Entry: String;
begin
  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreak(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_ALL_ACCESS, HKEY);

  if Ret <> ERROR_SUCCESS then
    Ret := RegCreateKeyExW(Root, PWideChar(WideString(Path)), 0, nil, 0, KEY_ALL_ACCESS, nil, @HKEY, nil);

  if Ret = ERROR_SUCCESS then begin
    RegSetValueExW(HKEY, PWideChar(WideString(Entry)), 0, KeyType, Data, DataSize);

    RegFlushKey(HKEY);
    RegCloseKey(HKEY);
  end;
end;

procedure RegSetString(Key: String; Value: String);
var
  Ret: LongInt;
  HKEY: LongWord;
  KeyType: DWORD;
  Size: DWORD;

  Root: DWORD;
  Path: String;
  Entry: String;

  i: Integer;
  Val: Array of Char;
begin
  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';
  SetLength(Val, 0);

  RegKeyBreak(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_ALL_ACCESS, HKEY);

  if Ret <> ERROR_SUCCESS then
    Ret := RegCreateKeyExW(Root, PWideChar(WideString(Path)), 0, nil, 0, KEY_ALL_ACCESS, nil, @HKEY, nil);

  if Ret = ERROR_SUCCESS then begin
    KeyType := REG_SZ;

    Size := (Length(Value) * 2) + 2;
    SetLength(Val, Size);
    try
      FillChar(Val[0], Size, 0);

      if Length(Value) > 0 then
      for i := 1 to Length(Value) do begin
        Val[(i - 1) * 2] := Value[i];
        Val[(i - 1) * 2 + 1] := #0;
      end;
      Val[Length(Val) - 2] := #0;
      Val[Length(Val) - 1] := #0;

      RegSetValueExW(HKEY, PWideChar(WideString(Entry)), 0, KeyType, @Val[0], Size);
    finally
      SetLength(Val, 0);
    end;

    RegFlushKey(HKEY);
    RegCloseKey(HKEY);
  end;
end;

procedure RegSetMultiString(Key: String; Value: String);
var
  Ret: LongInt;
  HKEY: LongWord;
  KeyType: DWORD;
  Size: DWORD;

  Root: DWORD;
  Path: String;
  Entry: String;

  i: Integer;
  Val: Array of Char;
begin
  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';
  SetLength(Val, 0);

  RegKeyBreak(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_ALL_ACCESS, HKEY);

  if Ret <> ERROR_SUCCESS then
    Ret := RegCreateKeyExW(Root, PWideChar(WideString(Path)), 0, nil, 0, KEY_ALL_ACCESS, nil, @HKEY, nil);

  if Ret = ERROR_SUCCESS then begin
    KeyType := REG_MULTI_SZ;

    Size := (Length(Value) * 2) + 4;
    SetLength(Val, Size);
    try
      FillChar(Val[0], Size, 0);

      if Length(Value) > 0 then
      for i := 1 to Length(Value) do begin
        Val[(i - 1) * 2] := Value[i];
        Val[(i - 1) * 2 + 1] := #0;
      end;
      Val[Length(Val) - 4] := #0;
      Val[Length(Val) - 3] := #0;
      Val[Length(Val) - 2] := #0;
      Val[Length(Val) - 1] := #0;

      RegSetValueExW(HKEY, PWideChar(WideString(Entry)), 0, KeyType, @Val[0], Size);
    finally
      SetLength(Val, 0);
    end;

    RegFlushKey(HKEY);
    RegCloseKey(HKEY);
  end;
end;

procedure RegDelete(Key: String);
var
  Ret: LongInt;
  HKEY: LongWord;

  Root: DWORD;
  Path: String;
  Entry: String;
begin
  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreak(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_ALL_ACCESS, HKEY);

  if Ret = ERROR_SUCCESS then begin
    RegDeleteValueW(HKEY, PWideChar(WideString(Entry)));
    RegFlushKey(HKEY);
    RegCloseKey(HKEY);
  end;
end;

procedure RegDeleteKey(Key: String);
var
  Ret: LongInt;
  HKEY: LongWord;

  Root: DWORD;
  Path: String;
  Entry: String;
begin
  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreak(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_ALL_ACCESS, HKEY);

  if Ret = ERROR_SUCCESS then begin
    RegDeleteKeyW(HKEY, PWideChar(WideString(Entry)));
    RegFlushKey(HKEY);
    RegCloseKey(HKEY);
  end;
end;

function RegFindMatch(Key: String): PStrList;
var
  Output: PStrList;
  Parts: PStrList;

  Root: DWORD;
  RootS: String;
  Path: String;
  Entry: String;

  procedure RegFindMatchInt(CurKey: String; Depth: Integer);
  var
    Ret: LongInt;
    HKEY: LongWord;
    i: Integer;

    Key, KeyO: String;
    KeyName: PWideChar;
    KeyNameSize: DWORD;
    Match: Boolean;
    MatchS: String;
  begin
    HKEY := 0;
    Ret := RegOpenKeyExW(Root, PWideChar(WideString(CurKey)), 0, KEY_QUERY_VALUE OR KEY_ENUMERATE_SUB_KEYS, HKEY);

    KeyName := nil;
    if Ret = ERROR_SUCCESS then begin
      GetMem(KeyName, 4096);
      try
        FillChar(KeyName^, 4096, 0);
        KeyNameSize := 4096;

        i := 0;
        Ret := RegEnumKeyExW(HKEY, i, KeyName, @KeyNameSize, nil, nil, nil, nil);
        while Ret = ERROR_SUCCESS do begin
          KeyO := String(WideString(KeyName));
          Key := UpperCase(KeyO);

          MatchS := UpperCase(Parts.Items[Depth]);
          while Pos('*', MatchS) > 0 do
            StrReplace(MatchS, '*', '');

          Match := False;
          if Pos('*', Parts.Items[Depth]) = 0 then
            Match := (MatchS = Key)
          else if Parts.Items[Depth] = '*' then
            Match := True
          else begin
            if Copy(Parts.Items[Depth], 1, 1) = '*' then begin
              if Copy(Parts.Items[Depth], Length(Parts.Items[Depth]), 1) = '*' then
                Match := (Pos(MatchS, Key) > 0)
              else
                Match := (Pos(MatchS, Key) = 1);
            end else begin
              Match := (Copy(Key, Length(Key) - Length(MatchS) + 1, Length(MatchS)) = MatchS);
            end;
          end;

          if Match then begin
            if Depth < Parts.Count - 1 then begin
              if CurKey = '' then
                RegFindMatchInt(KeyO, Depth + 1)
              else
                RegFindMatchInt(CurKey + '\' + KeyO, Depth + 1);
            end else begin
              Output.Add(RootS + '\' + CurKey + '\' + KeyO + '\' + Entry);
            end;
          end;

          i := i + 1;
          FillChar(KeyName^, 4096, 0);
          KeyNameSize := 4096;
          Ret := RegEnumKeyExW(HKEY, i, KeyName, @KeyNameSize, nil, nil, nil, nil);
        end;
      finally
        FreeMem(KeyName);
        RegCloseKey(HKEY);
      end;
    end;
  end;

var S: String;
begin
  Output := NewStrList;
  Result := Output;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreak(Key, Root, Path, Entry);

  Parts := NewStrList;
  try
    S := Key;
    while Pos('\', S) > 0 do StrReplace(S, '\', #13);
    Parts.Text := S;
    if Parts.Count > 0 then
      RootS := Parts.Items[0];

    S := Path;
    while Pos('\', S) > 0 do StrReplace(S, '\', #13);
    Parts.Text := S;

    if Parts.Count > 0 then
      RegFindMatchInt('', 0);
  finally
    Parts.Free;
  end;
end;

function RegEnum(Key: String): PStrList;
var
  Output: PStrList;

  Root: DWORD;
  Path: String;
  Entry: String;

  Ret: LongInt;
  HKEY: LongWord;
  i: Integer;

  Value: String;
  ValueName: PWideChar;
  ValueNameSize: DWORD;
begin
  Output := NewStrList;
  Result := Output;
  
  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreak(Key + '\Dummy', Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_QUERY_VALUE OR KEY_ENUMERATE_SUB_KEYS, HKEY);

  ValueName := nil;
  if Ret = ERROR_SUCCESS then begin
    GetMem(ValueName, 4096);
    try
      FillChar(ValueName^, 4096, 0);
      ValueNameSize := 4096;

      i := 0;
      Ret := RegEnumKeyExW(HKEY, i, ValueName, @ValueNameSize, nil, nil, nil, nil);
      while Ret = ERROR_SUCCESS do begin
        Value := String(WideString(ValueName));
        Output.Add(Key + '\' + Value);

        i := i + 1;
        FillChar(ValueName^, 4096, 0);
        ValueNameSize := 4096;
        Ret := RegEnumKeyEx(HKEY, i, ValueName, @ValueNameSize, nil, nil, nil, nil);
      end;
    finally
      FreeMem(ValueName);
      RegCloseKey(HKEY);
    end;
  end;
end;

function RegEnumValues(Key: String): PStrList;
var
  Output: PStrList;

  Root: DWORD;
  Path: String;
  Entry: String;

  Ret: LongInt;
  HKEY: LongWord;
  i: Integer;
  
  Value: String;
  ValueName: PWideChar;
  ValueNameSize: DWORD;
begin
  Output := NewStrList;
  Result := Output;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreak(Key + '\Dummy', Root, Path, Entry);
  
  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(WideString(Path)), 0, KEY_QUERY_VALUE OR KEY_ENUMERATE_SUB_KEYS, HKEY);

  ValueName := nil;
  if Ret = ERROR_SUCCESS then begin
    GetMem(ValueName, 4096);
    try
      FillChar(ValueName^, 4096, 0);
      ValueNameSize := 4096;

      i := 0;
      Ret := RegEnumValue(HKEY, i, ValueName, @ValueNameSize, nil, nil, nil, nil);
      while Ret = ERROR_SUCCESS do begin
        Value := String(WideString(ValueName));
        Output.Add(Key + '\' + Value);

        i := i + 1;
        FillChar(ValueName^, 4096, 0);
        ValueNameSize := 4096;
        Ret := RegEnumValue(HKEY, i, ValueName, @ValueNameSize, nil, nil, nil, nil);
      end;
    finally
      FreeMem(ValueName);
      RegCloseKey(HKEY);
    end;
  end;
end;

{ Unicode }

procedure RegKeyBreakW(Full: KOLString; var HKEY: DWORD; var Path: KOLString; var Key: KOLString);
var SL: PWStrList;
    i: Integer;
    S: KOLString;
begin
  HKEY := HKEY_LOCAL_MACHINE;
  Path := '';
  Key := '';

  SL := NewWStrList;
  try
    S := Full;
    while (Pos('\', S) > 0) do
      WStrReplace(S, '\', #13);
    SL.Text := S;

    if SL.Count >= 3 then begin
      if SL.Items[0] = 'HKCR' then HKEY := HKEY_CLASSES_ROOT
      else if SL.Items[0] = 'HKCU' then HKEY := HKEY_CURRENT_USER
      else if SL.Items[0] = 'HKLM' then HKEY := HKEY_LOCAL_MACHINE;

      if Copy(Full, Length(Full), 1) = '\' then
        SL.Add('');

      for i := 1 to SL.Count - 2 do
        Path := Path + SL.Items[i] + '\';
      Path := Copy(Path, 1, Length(Path) - 1);

      Key := SL.Items[SL.Count - 1];
    end;

    if (Key = 'Default') then
      Key := '';
  finally
    SL.Free;
  end;
end;

function RegFindMatchW(Key: KOLString): PWStrList;
var
  Output: PWStrList;
  Parts: PWStrList;

  Root: DWORD;
  RootS: KOLString;
  Path: KOLString;
  Entry: KOLString;

  procedure RegFindMatchInt(CurKey: KOLString; Depth: Integer);
  var
    Ret: LongInt;
    HKEY: LongWord;
    i: Integer;

    Key, KeyO: KOLString;
    KeyName: PWideChar;
    KeyNameSize: DWORD;
    Match: Boolean;
    MatchS: KOLString;
  begin
    HKEY := 0;
    Ret := RegOpenKeyExW(Root, PWideChar(CurKey), 0, KEY_QUERY_VALUE OR KEY_ENUMERATE_SUB_KEYS, HKEY);

    KeyName := nil;
    if Ret = ERROR_SUCCESS then begin
      GetMem(KeyName, 4096);
      try
        FillChar(KeyName^, 4096, 0);
        KeyNameSize := 4096;

        i := 0;
        Ret := RegEnumKeyExW(HKEY, i, KeyName, @KeyNameSize, nil, nil, nil, nil);
        while Ret = ERROR_SUCCESS do begin
          KeyO := WideString(KeyName);
          Key := UpperCase(KeyO);

          MatchS := UpperCase(Parts.Items[Depth]);
          while Pos('*', MatchS) > 0 do
            WStrReplace(MatchS, '*', '');

          Match := False;
          if Pos('*', Parts.Items[Depth]) = 0 then
            Match := (MatchS = Key)
          else if Parts.Items[Depth] = '*' then
            Match := True
          else begin
            if Copy(Parts.Items[Depth], 1, 1) = '*' then begin
              if Copy(Parts.Items[Depth], Length(Parts.Items[Depth]), 1) = '*' then
                Match := (Pos(MatchS, Key) > 0)
              else
                Match := (Pos(MatchS, Key) = 1);
            end else begin
              Match := (Copy(Key, Length(Key) - Length(MatchS) + 1, Length(MatchS)) = MatchS);
            end;
          end;

          if Match then begin
            if Depth < Parts.Count - 1 then begin
              if CurKey = '' then
                RegFindMatchInt(KeyO, Depth + 1)
              else
                RegFindMatchInt(CurKey + '\' + KeyO, Depth + 1);
            end else begin
              Output.Add(RootS + '\' + CurKey + '\' + KeyO + '\' + Entry);
            end;
          end;

          i := i + 1;
          FillChar(KeyName^, 4096, 0);
          KeyNameSize := 4096;
          Ret := RegEnumKeyExW(HKEY, i, KeyName, @KeyNameSize, nil, nil, nil, nil);
        end;
      finally
        FreeMem(KeyName);
        RegCloseKey(HKEY);
      end;
    end;
  end;

var S: KOLString;
begin
  Output := NewWStrList;
  Result := Output;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreakW(Key, Root, Path, Entry);

  Parts := NewWStrList;
  try
    S := Key;
    while Pos('\', S) > 0 do WStrReplace(S, '\', #13);
    Parts.Text := S;
    if Parts.Count > 0 then
      RootS := Parts.Items[0];

    S := Path;
    while Pos('\', S) > 0 do WStrReplace(S, '\', #13);
    Parts.Text := S;

    if Parts.Count > 0 then
      RegFindMatchInt('', 0);
  finally
    Parts.Free;
  end;
end;

function RegGetDWORDW(Key: KOLString; Def: DWORD = 0): DWORD;
var
  Ret: LongInt;
  HKEY: LongWord;
  KeyType: DWORD;
  Size: DWORD;

  Root: DWORD;
  Path: KOLString;
  Entry: KOLString;
begin
  Result := Def;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreakW(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(Path), 0, KEY_ALL_ACCESS, HKEY);

  if Ret = ERROR_SUCCESS then begin
    Size := 4;
    KeyType := REG_DWORD;
    Ret := RegQueryValueExW(HKEY, PWideChar(Entry), nil, @KeyType, @Result, @Size);

    RegCloseKey(HKEY);
  end;
end;

function RegGetStringW(Key: KOLString; Def: KOLString = ''): KOLString;
var
  Ret: LongInt;
  HKEY: LongWord;
  KeyType: DWORD;
  Size: DWORD;

  Root: DWORD;
  Path: KOLString;
  Entry: KOLString;
  Data: PWideChar;
begin
  Result := Def;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  Data := nil;

  RegKeyBreakW(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(Path), 0, KEY_ALL_ACCESS, HKEY);

  if Ret = ERROR_SUCCESS then begin
    GetMem(Data, 4096);
    try
      FillChar(Data^, 4096, 0);
      Size := 4096;
      KeyType := REG_SZ;
      Ret := RegQueryValueExW(HKEY, PWideChar(Entry), nil, @KeyType, Data, @Size);

      if Ret = ERROR_SUCCESS then
        Result := WideString(Data);
    finally
      FreeMem(Data);
      RegCloseKey(HKEY);
    end;
  end;
end;

function RegGetMultiStringW(Key: KOLString; Def: KOLString = ''): KOLString;
begin
  Result := RegGetStringW(Key, Def);
end;

function RegGetCustomW(Key: KOLString; var KeyType: DWORD; var Buffer: Pointer; var BufSize: Integer): Boolean;
var
  Ret: LongInt;
  HKEY: LongWord;
  Size: DWORD;

  Root: DWORD;
  Path: KOLString;
  Entry: KOLString;
  Data: Pointer;
begin
  Result := False;
  Buffer := nil;
  BufSize := 0;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  Data := nil;

  RegKeyBreakW(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(Path), 0, KEY_ALL_ACCESS, HKEY);

  if Ret = ERROR_SUCCESS then begin
    GetMem(Data, 4096);
    try
      FillChar(Data^, 4096, 0);
      Size := 4096;
      KeyType := REG_NONE;

      Ret := RegQueryValueExW(HKEY, PWideChar(Entry), nil, @KeyType, Data, @Size);

      if Ret = ERROR_SUCCESS then begin
        BufSize := Size;
        GetMem(Buffer, BufSize);
        Move(Data^, Buffer^, BufSize);
        Result := True;
      end;
    finally
      FreeMem(Data);
      RegCloseKey(HKEY);
    end;
  end;
end;

procedure RegSetDWORDW(Key: KOLString; Value: DWORD);
var
  Ret: LongInt;
  HKEY: LongWord;
  KeyType: DWORD;
  Size: DWORD;

  Root: DWORD;
  Path: KOLString;
  Entry: KOLString;
begin
  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreakW(Key, Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(Path), 0, KEY_ALL_ACCESS, HKEY);

  if Ret <> ERROR_SUCCESS then
    Ret := RegCreateKeyExW(Root, PWideChar(Path), 0, nil, 0, KEY_ALL_ACCESS, nil, HKEY, nil);

  if Ret = ERROR_SUCCESS then begin
    KeyType := REG_DWORD;
    RegSetValueExW(HKEY, PWideChar(Entry), 0, KeyType, @Value, 4);

    RegFlushKey(HKEY);
    RegCloseKey(HKEY);
  end;
end;

function RegEnumW(Key: KOLString): PWStrList;
var
  Output: PWStrList;

  Root: DWORD;
  Path: KOLString;
  Entry: KOLString;

  Ret: LongInt;
  HKEY: LongWord;
  i: Integer;

  Value: KOLString;
  ValueName: PWideChar;
  ValueNameSize: DWORD;
begin
  Output := NewWStrList;
  Result := Output;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreakW(Key + '\Dummy', Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(Path), 0, KEY_QUERY_VALUE OR KEY_ENUMERATE_SUB_KEYS, HKEY);

  ValueName := nil;
  if Ret = ERROR_SUCCESS then begin
    GetMem(ValueName, 4096);
    try
      FillChar(ValueName^, 4096, 0);
      ValueNameSize := 4096;

      i := 0;
      Ret := RegEnumKeyExW(HKEY, i, ValueName, @ValueNameSize, nil, nil, nil, nil);
      while Ret = ERROR_SUCCESS do begin
        Value := WideString(ValueName);
        Output.Add(Key + WideString('\') + Value);

        i := i + 1;
        FillChar(ValueName^, 4096, 0);
        ValueNameSize := 4096;
        Ret := RegEnumKeyEx(HKEY, i, ValueName, @ValueNameSize, nil, nil, nil, nil);
      end;
    finally
      FreeMem(ValueName);
      RegCloseKey(HKEY);
    end;
  end;
end;

function RegEnumValuesW(Key: KOLString): PWStrList;
var
  Output: PWStrList;

  Root: DWORD;
  Path: KOLString;
  Entry: KOLString;

  Ret: LongInt;
  HKEY: LongWord;
  i: Integer;

  Value: KOLString;
  ValueName: PWideChar;
  ValueNameSize: DWORD;
begin
  Output := NewWStrList;
  Result := Output;

  Root := HKEY_LOCAL_MACHINE;
  Path := '';
  Entry := '';

  RegKeyBreakW(Key + '\Dummy', Root, Path, Entry);

  HKEY := 0;
  Ret := RegOpenKeyExW(Root, PWideChar(Path), 0, KEY_QUERY_VALUE OR KEY_ENUMERATE_SUB_KEYS, HKEY);

  ValueName := nil;
  if Ret = ERROR_SUCCESS then begin
    GetMem(ValueName, 4096);
    try
      FillChar(ValueName^, 4096, 0);
      ValueNameSize := 4096;

      i := 0;
      Ret := RegEnumValue(HKEY, i, ValueName, @ValueNameSize, nil, nil, nil, nil);
      while Ret = ERROR_SUCCESS do begin
        Value := WideString(ValueName);
        Output.Add(Key + '\' + Value);

        i := i + 1;
        FillChar(ValueName^, 4096, 0);
        ValueNameSize := 4096;
        Ret := RegEnumValue(HKEY, i, ValueName, @ValueNameSize, nil, nil, nil, nil);
      end;
    finally
      FreeMem(ValueName);
      RegCloseKey(HKEY);
    end;
  end;
end;

{ RegUpdates }

var RegUpdateCounter: Integer = 0;

procedure RegFlushKey(HKEY: HKEY);
begin
  if RegUpdateCounter = 0 then
    Windows.RegFlushKey(HKEY);
end;

procedure RegBeginUpdate;
begin
  Inc(RegUpdateCounter);
end;

procedure RegEndUpdate;
begin
  Dec(RegUpdateCounter);
  if RegUpdateCounter < 0 then
    RegUpdateCounter := 0;
  if RegUpdateCounter = 0 then begin
    RegFlushKey(HKEY_CLASSES_ROOT);
    RegFlushKey(HKEY_LOCAL_MACHINE);
    RegFlushKey(HKEY_CURRENT_USER);
  end;
end;

end.

