unit WinHelper;

interface

uses
  Generics.Collections,
  SysUtils,

  PE.Common,

  TlHelp32,
  Windows;

type
  TProcessRec = record
    PID: DWORD;
    Name: string;
    constructor Create(PID: DWORD; const Name: string);
  end;

  TProcessRecList = TList<TProcessRec>;

  TModuleRec = TModuleEntry32;

  TModuleRecList = TList<TModuleRec>;

  // return True to continue enumeration or False to stop it.
  //TEnumProcessesCallback = reference to function(const pe: TProcessEntry32): boolean;
  //TEnumModulesCallback = reference to function(const me: TModuleEntry32): boolean;
  // oranke modified
  TEnumProcessesCallback = function(const pe: TProcessEntry32; UserData: Pointer): boolean;
  TEnumModulesCallback = function(const me: TModuleEntry32; UserData: Pointer): boolean;

  // Enumerate processes with callback. Result is False if there was error.
function EnumProcesses(cb: TEnumProcessesCallback; UserData: Pointer): boolean;

// Enumerate processes to list. Result is False if there was error.
function EnumProcessesToList(List: TProcessRecList): boolean;

type
  // Used to compare strings.
  TStringMatchKind = (
    MATCH_STRING_WHOLE, // string equals to X
    MATCH_STRING_START, // string starts with X
    MATCH_STRING_END,   // string ends with X
    MATCH_STRING_PART   // string contains X
    );

function FindPIDByProcessName(
  const Name: string;
  out PID: DWORD;
  Match: TStringMatchKind = MATCH_STRING_WHOLE): boolean;

// Enumerate modules with callback. Result is False if there was error.
function EnumModules(PID: DWORD; cb: TEnumModulesCallback; UserData: Pointer): boolean;

// Enumerate modules to list. Result is False if there was error.
function EnumModulesToList(PID: DWORD; List: TModuleRecList): boolean;

type
  // Used in FindModule to test if this is the module we search.
  // Return True on match.
  //TFindModuleChecker = reference to function(const me: TModuleEntry32): boolean;
  // oranke modified
  TFindModuleChecker = function(const me: TModuleEntry32; UserData: Pointer): boolean;

  // Find module by custom condition.
function FindModule(PID: DWORD; out value: TModuleEntry32; Checker: TFindModuleChecker; UserData: Pointer): boolean;

// Find module by address that belongs to this module.
function FindModuleByAddress(PID: DWORD; Addr: NativeUInt; out me: TModuleEntry32): boolean;

// Find module by module name.
function FindModuleByName(PID: DWORD; const Name: string): boolean;

// Find main process module (exe).
function FindMainModule(PID: DWORD; out me: TModuleEntry32): boolean;

function SetPrivilegeByName(const Name: string; State: boolean): boolean;

function SetDebugPrivilege(State: boolean): boolean;

implementation


function EnumProcesses(cb: TEnumProcessesCallback; UserData: Pointer): boolean;
var
  hShot, hShotMod: THandle;
  pe: TProcessEntry32;
begin
  // Create process snapshot.
  hShot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if hShot = INVALID_HANDLE_VALUE then
    exit(false);

  // Traverse it.
  try
    ZeroMemory(@pe, SizeOf(pe));
    pe.dwSize := SizeOf(pe);

    if not Process32First(hShot, pe) then
      exit(false);

    repeat
      // Add process only if we can query its module list.
      hShotMod := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, pe.th32ProcessID);
      if hShotMod <> INVALID_HANDLE_VALUE then
      begin
        CloseHandle(hShotMod);
        if not cb(pe, UserData) then
          break;
      end;
    until not Process32Next(hShot, pe);

    exit(True);
  finally
    CloseHandle(hShot);
  end;
end;

function EnumProcessProc(const pe: TProcessEntry32; UserData: Pointer): boolean;
begin
  //List.Add(TProcessRec.Create(pe.th32ProcessID, pe.szExeFile));
  TProcessRecList(UserData).Add(TProcessRec.Create(pe.th32ProcessID, pe.szExeFile));

  result := True;
end;

function EnumProcessesToList(List: TProcessRecList): boolean;
begin
  List.Clear;
  result := EnumProcesses(EnumProcessProc, List);

  // oranke modified
  {
  result := EnumProcesses(
    function(const pe: TProcessEntry32): boolean
    begin
      List.Add(TProcessRec.Create(pe.th32ProcessID, pe.szExeFile));
      result := True;
    end);
  }
end;

function CompareStringsWithMachKind(const s1, s2: string; kind: TStringMatchKind): boolean;
begin
  // oranke modified
  case kind of
    MATCH_STRING_WHOLE:
      result := s1 = s1;//s1.Equals(s2);
    MATCH_STRING_START:
      result := SysUtils.StrLComp(PChar(s1), PChar(s2), Length(s2)) = 0; //s1.StartsWith(s2);
    MATCH_STRING_END:
      result := s1.EndsWith(s2);
    MATCH_STRING_PART:
      result := System.Pos(s2, s1) > 0; //s1.Contains(s2);
  else
    result := false;
  end;
end;

type
  PFindPIDRec = ^TFindPIDRec;
  TFindPIDRec = record
    tmpName: String;
    Match: TStringMatchKind;
    foundPID: DWORD;
  end;

function FindPIDByProcessProc(const pe: TProcessEntry32; UserData: Pointer): Boolean;
begin
  with PFindPIDRec(UserData)^ do
  if CompareStringsWithMachKind(UpperCase(string(pe.szExeFile)), tmpName, Match) then
  begin
    foundPID := pe.th32ProcessID;
    exit(false); // don't continue search, already found
  end;

  exit(True); // continue search
end;

function FindPIDByProcessName(const Name: string; out PID: DWORD; Match: TStringMatchKind): boolean;
var
  //tmpName: string;
  //foundPID: DWORD;
  MR: TFindPIDRec;
begin
  MR.tmpName := UpperCase(Name);
  MR.Match := Match;
  MR.foundPID := 0;

  //tmpName := Uppercase(Name);// Name.ToUpper;
  //foundPID := 0;

  EnumProcesses(FindPIDByProcessProc, @MR);

  {
  EnumProcesses(
    function(const pe: TProcessEntry32): boolean
    begin
      if CompareStringsWithMachKind(string(pe.szExeFile).ToUpper, tmpName, Match) then
      begin
        foundPID := pe.th32ProcessID;
        exit(false); // don't continue search, already found
      end;
      exit(True); // continue search
    end);
  }

  PID := MR.foundPID;
  result := MR.foundPID <> 0;
end;

function EnumModules(PID: DWORD; cb: TEnumModulesCallback; UserData: Pointer): boolean;
var
  hShot: THandle;
  me: TModuleEntry32;
begin
  hShot := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, PID);
  if hShot = INVALID_HANDLE_VALUE then
    exit(false);

  try
    ZeroMemory(@me, SizeOf(me));
    me.dwSize := SizeOf(me);

    if not Module32First(hShot, me) then
      exit(false);

    repeat
      if not cb(me, UserData) then
        break;
    until not Module32Next(hShot, me);

    exit(True);
  finally
    CloseHandle(hShot);
  end;
end;

function EnumModuleToListProc(const me: TModuleEntry32; UserData: Pointer): Boolean;
begin
  TModuleRecList(UserData).Add(me);
  Exit(true);
end;

function EnumModulesToList(PID: DWORD; List: TModuleRecList): boolean;
begin
  List.Clear;
  result := EnumModules(PID, EnumModuleToListProc, List);

  {
  result := EnumModules(PID,
    function(const me: TModuleEntry32): boolean
    begin
      List.Add(me);
      exit(True);
    end);
  }
end;

type
  PFindModuleRec = ^TFindModuleRec;
  TFindModuleRec = record
    found: Boolean;
    Checker: TFindModuleChecker;
    tmp: TModuleEntry32;
    UserData: Pointer;
  end;

function FindModuleProc(const me: TModuleEntry32; UserData: Pointer): boolean;
begin
  with PFindModuleRec(UserData)^ do
  if Checker(me, UserData) then
  begin
    tmp := me;
    found := True;
    exit(false);
  end;
  exit(True);
end;

function FindModule(PID: DWORD; out value: TModuleEntry32; Checker: TFindModuleChecker; UserData: Pointer): boolean;
var
  //found: boolean;
  //tmp: TModuleEntry32;
  FMR: TFindModuleRec;
begin
  FMR.found := false;
  FMR.Checker := Checker;
  FMR.UserData := UserData;

  EnumModules(PID, FindModuleProc, @FMR);

  //found := false;
  {
  EnumModules(PID,
    function(const me: TModuleEntry32): boolean
    begin
      if Checker(me) then
      begin
        tmp := me;
        found := True;
        exit(false);
      end;
      exit(True);
    end);
  }

  with FMR do
  if found then
    value := tmp
  else
    fillchar(value, SizeOf(value), 0);

  exit(FMR.found);
end;

function FindModuleByAddressProc(const me: TModuleEntry32; UserData: Pointer): Boolean;
begin
  result :=
    (PNativeUInt(UserData)^ >= NativeUInt(me.modBaseAddr)) and
    (PNativeUInt(UserData)^ < NativeUInt(me.modBaseAddr + me.modBaseSize));
end;

function FindModuleByAddress(PID: DWORD; Addr: NativeUInt; out me: TModuleEntry32): boolean;
begin
  result := FindModule(PID, me, FindModuleByAddressProc, @Addr);

  {
  result := FindModule(PID, me,
    function(const me: TModuleEntry32): boolean
    begin
      result :=
        (Addr >= NativeUInt(me.modBaseAddr)) and
        (Addr < NativeUInt(me.modBaseAddr + me.modBaseSize));
    end);
  }
end;

function FindModuleByNameProc(const me: TModuleEntry32; UserData: Pointer): Boolean;
begin
  Result := UpperCase(string(me.szModule)) = PString(UserData)^;
end;

function FindModuleByName(PID: DWORD; const Name: string): boolean;
var
  tmpName: string;
  me: TModuleEntry32;
begin
  tmpName := UpperCase(Name);
  Result := FindModule(PID, me, FindModuleByNameProc, @tmpName);

  {
  tmpName := name.ToUpper;
  result := FindModule(PID, me,
    function(const me: TModuleEntry32): boolean
    begin
      result := string(me.szModule).ToUpper.Equals(tmpName);
    end);
  }
end;

function FindMainModuleProc(const me: TModuleEntry32; UserData: Pointer): Boolean;
begin
  Result := true;
end;

function FindMainModule(PID: DWORD; out me: TModuleEntry32): boolean;
begin
  result := FindModule(PID, me, FindMainModuleProc, nil);
  {
  result := FindModule(PID, me,
    function(const me: TModuleEntry32): boolean
    begin
      result := True; // first module is main one
    end);
  }

end;

function AdjustTokenPrivileges(TokenHandle: THandle; DisableAllPrivileges: BOOL;
  const NewState: TTokenPrivileges; BufferLength: DWORD;
  PreviousState: PTokenPrivileges; var ReturnLength: DWORD): BOOL; external advapi32 name 'AdjustTokenPrivileges';

// http://msdn.microsoft.com/en-us/library/windows/desktop/aa446619(v=vs.85).aspx
function SetPrivilege(
  hToken: THandle;      // access token handle
lpszPrivilege: LPCTSTR; // name of privilege to enable/disable
bEnablePrivilege: BOOL  // to enable or disable privilege
  ): boolean;
var
  tp: TOKEN_PRIVILEGES;
  luid: int64;
  Status: DWORD;
  ReturnLength: DWORD;
begin
  if LookupPrivilegeValue(
    nil,         // lookup privilege on local system
  lpszPrivilege, // privilege to lookup
  luid)          // receives LUID of privilege
  then
  begin
    tp.PrivilegeCount := 1;
    tp.Privileges[0].luid := luid;
    if bEnablePrivilege then
      tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED
    else
      tp.Privileges[0].Attributes := 0;

    // Enable the privilege or disable all privileges.
    if AdjustTokenPrivileges(hToken, false, tp, SizeOf(TOKEN_PRIVILEGES), nil, ReturnLength) then
    begin
      Status := GetLastError();
      if Status = ERROR_SUCCESS then
        exit(True);
    end;
  end;

  exit(false);
end;

function SetPrivilegeByName(const Name: string; State: boolean): boolean;
var
  hToken: THandle;
begin
  if not OpenProcessToken(GetCurrentProcess, TOKEN_QUERY or TOKEN_ADJUST_PRIVILEGES, hToken) then
    exit(false);
  result := SetPrivilege(hToken, LPCTSTR(Name), State);
  CloseHandle(hToken);
end;

function SetDebugPrivilege(State: boolean): boolean;
begin
  result := SetPrivilegeByName('SeDebugPrivilege', State);
end;

{ TProcessRec }

constructor TProcessRec.Create(PID: DWORD; const Name: string);
begin
  self.PID := PID;
  self.Name := Name;
end;

end.
