(*
  This library is a library helper for DreamSDK Setup.
  It executes the post-install steps (i.e., unpacking toolchains, installing
  KallistiOS, KallistiOS Ports and Dreamcast Tool), as DreamSDK Manager does
  with the --post-install switch.
  This *MUST* be compiled in *RELEASE* mode. If not, the library couldn't be
  loaded in Inno Setup.

  Typical usage from the Setup:
    PostInstallInitializeW(HomeDirectory);
    PostInstallStart;
    repeat
      Status := PostInstallPoll; // *MUST* be called regularly
      PostInstallGetProgressTextW / PostInstallGetProgressPosition
      PostInstallGetNewLinesW
    until Status <> PostInstallStatusRunning;
    PostInstallFinalize;
*)
library PostInst;

{$mode objfpc}{$H+}

uses
  Windows,
  SysUtils,
  Classes,
  LazUTF8,
  SysTools,
  SetupHlp,
  RefBase,
  InstMode,
  ProgLine,
  PIThread;

{$R *.res}

var
  Session: TPostInstallSession = nil;

procedure LogException(const RoutineName: string; E: Exception);
var
  LogContext: TLogMessageContext;

begin
  LogContext := LogMessageEnter({$I %FILE%}, RoutineName);
  try
    LogMessage(LogContext, Format('Exception: %s: %s', [E.ClassName, E.Message]));
  finally
    LogMessageExit(LogContext);
  end;
end;

(* Initialize the post-install session for the DreamSDK installation
   directory (e.g., "C:\DreamSDK"). This should be called only once. *)
function PostInstallInitializeW(const lpHomeDirectory: PWideChar): Boolean; stdcall;
var
  HomeDirectory: TFileName;

begin
  Result := False;
  try
    if Assigned(Session) or (not Assigned(lpHomeDirectory)) then
      Exit;

    HomeDirectory := UTF16ToUTF8(UnicodeString(lpHomeDirectory));
    if not DirectoryExists(HomeDirectory) then
      Exit;

    SetBaseInstallationHomeDirectory(HomeDirectory);
    SetPostInstallMode(True);
    Session := TPostInstallSession.Create;
    Result := True;
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Start the post-install process; returns immediately. *)
function PostInstallStart: Boolean; stdcall;
begin
  Result := False;
  try
    if Assigned(Session) then
      Result := Session.Start;
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

{$IFDEF DEBUG}
(* Debug only: same as PostInstallStart, but runs harmless shell commands. *)
function PostInstallStartSelfTest: Boolean; stdcall;
begin
  Result := False;
  try
    if Assigned(Session) then
    begin
      Session.SelfTest := True;
      Result := Session.Start;
    end;
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;
{$ENDIF}

(* Process the pending events and return the current status, which is one of
   TPostInstallStatus (0: Idle, 1: Running, 2: Succeeded, 3: Failed,
   4: Aborted). This *MUST* be called regularly while the process is running,
   from the thread that loaded this library. *)
function PostInstallPoll: UInt32; stdcall;
begin
  Result := Ord(pisFailed);
  try
    if Assigned(Session) then
      Result := Ord(Session.Poll);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Retrieve the current progress text (i.e., the current step). *)
function PostInstallGetProgressTextW(lpProgressText: PWideChar;
  const uBufferMaxSize: UInt32): UInt32; stdcall;
begin
  Result := 0;
  try
    if Assigned(Session) then
      Result := WriteSharedWideString(Session.GetProgressText, lpProgressText,
        uBufferMaxSize);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Retrieve the current progress position, i.e. 0 to 100 when a percentage
   is detected in the output (e.g., Git, Wget, CMake), or -1 when there is no
   percentage (i.e., the progress bar should be displayed as a marquee). *)
function PostInstallGetProgressPosition: Int32; stdcall;
begin
  Result := PROGRESS_POSITION_MARQUEE;
  try
    if Assigned(Session) then
      Result := Session.GetProgressPosition;
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Retrieve the output lines received since the last call, separated by
   CR/LF; lines that don't fit in the buffer are kept for the next call. *)
function PostInstallGetNewLinesW(lpNewLines: PWideChar;
  const uBufferMaxSize: UInt32): UInt32; stdcall;
begin
  Result := 0;
  try
    if Assigned(Session) and (uBufferMaxSize > 0) then
      Result := WriteSharedWideString(Session.ExtractPendingLines(uBufferMaxSize),
        lpNewLines, uBufferMaxSize);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Retrieve the combined output of the process, once it's finished. *)
function PostInstallGetResultOutputW(lpResultOutput: PWideChar;
  const uBufferMaxSize: UInt32): UInt32; stdcall;
begin
  Result := 0;
  try
    if Assigned(Session) then
      Result := WriteSharedWideString(Session.GetResultOutput, lpResultOutput,
        uBufferMaxSize);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Request to abort the running process; continue to poll until the status
   is not Running anymore. *)
procedure PostInstallAbort; stdcall;
begin
  try
    if Assigned(Session) then
      Session.Abort;
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Abort if needed, wait for the end of the process and free everything.
   This *MUST* be called before unloading the library. *)
procedure PostInstallFinalize; stdcall;
begin
  try
    FreeAndNil(Session);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

exports
  PostInstallInitializeW,
  PostInstallStart,
{$IFDEF DEBUG}
  PostInstallStartSelfTest,
{$ENDIF}
  PostInstallPoll,
  PostInstallGetProgressTextW,
  PostInstallGetProgressPosition,
  PostInstallGetNewLinesW,
  PostInstallGetResultOutputW,
  PostInstallAbort,
  PostInstallFinalize;

end.
