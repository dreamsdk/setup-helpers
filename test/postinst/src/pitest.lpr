(*
  Test harness for the PostInst helper library (postinst.dll).
  It drives the library the same way DreamSDK Setup does.

  Usage:
    pitest <home-dir>                 Initialize/Finalize only (non-destructive)
    pitest <home-dir> --run           Run the whole post-install process
    pitest <home-dir> --run --abort N Same, but request an abort after N seconds
    pitest <home-dir> --self-test     Run harmless shell commands through the
                                      same thread/poll path (Debug DLL only)

  WARNING: --run executes the real post-install: the existing KallistiOS,
  KallistiOS Ports and Dreamcast Tool directories are renamed as backups then
  everything is cloned and built again. Use it on a test installation only.
*)
program PITest;

{$mode objfpc}{$H+}

uses
  Windows,
  SysUtils,
  Classes;

const
  POSTINST_LIBRARY = 'postinst.dll';
  BUFFER_SIZE = 8192;
  POLL_INTERVAL = 100;

  STATUS_NAMES: array[0..4] of string = (
    'Idle', 'Running', 'Succeeded', 'Failed', 'Aborted'
  );
  STATUS_RUNNING = 1;

type
  TPostInstallInitializeW = function(const lpHomeDirectory: PWideChar): Boolean; stdcall;
  TPostInstallStart = function: Boolean; stdcall;
  TPostInstallPoll = function: UInt32; stdcall;
  TPostInstallGetTextW = function(lpBuffer: PWideChar;
    const uBufferMaxSize: UInt32): UInt32; stdcall;
  TPostInstallProcedure = procedure; stdcall;

var
  LibraryHandle: THandle;
  PostInstallInitializeW: TPostInstallInitializeW;
  PostInstallStart: TPostInstallStart;
  PostInstallStartSelfTest: TPostInstallStart; // Debug DLL only
  PostInstallPoll: TPostInstallPoll;
  PostInstallGetProgressTextW: TPostInstallGetTextW;
  PostInstallGetNewLinesW: TPostInstallGetTextW;
  PostInstallGetResultOutputW: TPostInstallGetTextW;
  PostInstallAbort: TPostInstallProcedure;
  PostInstallFinalize: TPostInstallProcedure;

function StatusToString(const Status: UInt32): string;
begin
  Result := Format('Unknown (%d)', [Status]);
  if Status <= High(STATUS_NAMES) then
    Result := STATUS_NAMES[Status];
end;

function Bind(const Name: string): Pointer;
begin
  Result := GetProcAddress(LibraryHandle, PChar(Name));
  if not Assigned(Result) then
    raise Exception.CreateFmt('Export not found: %s', [Name]);
end;

function GetText(Getter: TPostInstallGetTextW): string;
var
  Buffer: UnicodeString;
  Size: UInt32;

begin
  SetLength(Buffer, BUFFER_SIZE);
  Size := Getter(PWideChar(Buffer), BUFFER_SIZE);
  SetLength(Buffer, Size);
  Result := UTF8Encode(Buffer);
end;

procedure LoadPostInstallLibrary;
var
  LibraryFileName: TFileName;

begin
  // Next to this executable, or else in the postinst build output directory
  LibraryFileName := ExtractFilePath(ParamStr(0)) + POSTINST_LIBRARY;
  if not FileExists(LibraryFileName) then
    LibraryFileName := ExpandFileName(ExtractFilePath(ParamStr(0))
      + '..\..\..\postinst\bin\' + POSTINST_LIBRARY);
  LibraryHandle := LoadLibrary(PChar(LibraryFileName));
  if LibraryHandle = 0 then
    raise Exception.CreateFmt('Unable to load "%s" (error %d)', [
      LibraryFileName, GetLastError]);

  Pointer(PostInstallInitializeW) := Bind('PostInstallInitializeW');
  Pointer(PostInstallStart) := Bind('PostInstallStart');
  Pointer(PostInstallPoll) := Bind('PostInstallPoll');
  Pointer(PostInstallGetProgressTextW) := Bind('PostInstallGetProgressTextW');
  Pointer(PostInstallGetNewLinesW) := Bind('PostInstallGetNewLinesW');
  Pointer(PostInstallGetResultOutputW) := Bind('PostInstallGetResultOutputW');
  Pointer(PostInstallAbort) := Bind('PostInstallAbort');
  Pointer(PostInstallFinalize) := Bind('PostInstallFinalize');
  Pointer(PostInstallStartSelfTest) := GetProcAddress(LibraryHandle,
    'PostInstallStartSelfTest');
  WriteLn('Library loaded: ', LibraryFileName);
end;

procedure RunPostInstall(const AbortAfterSeconds: Integer;
  const SelfTest: Boolean);
var
  Status: UInt32;
  StartTime: QWord;
  ProgressText,
  PreviousProgressText,
  NewLines: string;
  AbortRequested: Boolean;

begin
  if SelfTest then
  begin
    if not Assigned(PostInstallStartSelfTest) then
      raise Exception.Create('PostInstallStartSelfTest not exported (Release DLL?)');
    if not PostInstallStartSelfTest() then
      raise Exception.Create('PostInstallStartSelfTest failed');
  end
  else if not PostInstallStart() then
    raise Exception.Create('PostInstallStart failed');

  StartTime := GetTickCount64;
  PreviousProgressText := EmptyStr;
  AbortRequested := False;
  repeat
    Sleep(POLL_INTERVAL);
    Status := PostInstallPoll();

    ProgressText := GetText(PostInstallGetProgressTextW);
    if ProgressText <> PreviousProgressText then
    begin
      WriteLn('[STEP] ', ProgressText);
      PreviousProgressText := ProgressText;
    end;

    NewLines := GetText(PostInstallGetNewLinesW);
    if NewLines <> EmptyStr then
      WriteLn(NewLines);

    if (AbortAfterSeconds > 0) and (not AbortRequested)
      and ((GetTickCount64 - StartTime) div 1000 >= QWord(AbortAfterSeconds)) then
    begin
      WriteLn('[TEST] Requesting abort...');
      PostInstallAbort();
      AbortRequested := True;
    end;
  until Status <> STATUS_RUNNING;

  // Flush the remaining lines
  repeat
    NewLines := GetText(PostInstallGetNewLinesW);
    if NewLines <> EmptyStr then
      WriteLn(NewLines);
  until NewLines = EmptyStr;

  WriteLn('[TEST] Final status: ', StatusToString(Status), ' after ',
    (GetTickCount64 - StartTime) div 1000, 's');
end;

var
  HomeDirectory: UnicodeString;
  DoRun,
  DoSelfTest: Boolean;
  AbortAfterSeconds,
  i: Integer;

begin
  ExitCode := 1;
  try
    if ParamCount < 1 then
    begin
      WriteLn('Usage: pitest <home-dir> [--run [--abort <seconds>]]');
      Exit;
    end;

    HomeDirectory := UnicodeString(ParamStr(1));
    DoRun := False;
    DoSelfTest := False;
    AbortAfterSeconds := 0;
    for i := 2 to ParamCount do
    begin
      if SameText(ParamStr(i), '--run') then
        DoRun := True
      else if SameText(ParamStr(i), '--self-test') then
        DoSelfTest := True
      else if SameText(ParamStr(i), '--abort') and (i < ParamCount) then
        AbortAfterSeconds := StrToIntDef(ParamStr(i + 1), 0);
    end;

    LoadPostInstallLibrary;
    try
      // Invalid home directory must be rejected
      WriteLn('[TEST] PostInstallInitializeW(invalid): ',
        PostInstallInitializeW(PWideChar(UnicodeString('Z:\__does_not_exist__'))));
      WriteLn('[TEST] PostInstallPoll (no session): ', StatusToString(PostInstallPoll()));

      WriteLn('[TEST] PostInstallInitializeW("', HomeDirectory, '"): ',
        PostInstallInitializeW(PWideChar(HomeDirectory)));
      WriteLn('[TEST] PostInstallInitializeW (second call): ',
        PostInstallInitializeW(PWideChar(HomeDirectory)));
      WriteLn('[TEST] PostInstallPoll: ', StatusToString(PostInstallPoll()));

      if DoRun or DoSelfTest then
        RunPostInstall(AbortAfterSeconds, DoSelfTest);

      WriteLn('[TEST] PostInstallFinalize');
      PostInstallFinalize();
      ExitCode := 0;
    finally
      FreeLibrary(LibraryHandle);
      WriteLn('[TEST] Library unloaded');
    end;
  except
    on E: Exception do
      WriteLn('*** ', E.ClassName, ': ', E.Message);
  end;
end.
