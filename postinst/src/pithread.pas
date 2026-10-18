unit PIThread;

(*
  Post-install session used by the PostInst helper library.

  The installation itself is done by TKallistiInstaller (KOSInst) in a worker
  thread. DreamSDK Setup (Inno Setup) polls this session from its main thread:
  each poll calls CheckSynchronize, so the events sent with Synchronize (e.g.,
  shell output lines) are executed in the Setup main thread. Everything that
  must be read by the Setup is stored in this session, protected by a critical
  section, as the events are triggered from both threads.
*)

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  SyncObjs,
  DCSDKMgr,
  KOSInst,
  ProgLine;

type
  TPostInstallStatus = (
    pisIdle,
    pisRunning,
    pisSucceeded,
    pisFailed,
    pisAborted
  );

  TPostInstallSession = class;

  { TPostInstallThread }
  TPostInstallThread = class(TThread)
  private
    fSession: TPostInstallSession;
  protected
    procedure Execute; override;
  public
    constructor Create(ASession: TPostInstallSession);
  end;

  { TPostInstallSession }
  TPostInstallSession = class(TObject)
  private
    fLock: TCriticalSection;
    fManager: TDreamcastSoftwareDevelopmentKitManager;
    fInstaller: TKallistiInstaller;
    fThread: TPostInstallThread;
    fStatus: TPostInstallStatus;
    fProgressText: string;
    fProgressPosition: Integer;
    fProgressLineParser: TProgressLineParser;
    fPendingLines: TStringList;
    fResultOutput: string;
{$IFDEF DEBUG}
    fSelfTest: Boolean;
{$ENDIF}
    function GetStatus: TPostInstallStatus;
    procedure SetStatus(const Value: TPostInstallStatus);
    procedure AddLine(const Line: string);
    procedure AddOutputLine(const Line: string);
    procedure HandleShellCommandNewLine(Sender: TObject; NewLine: string);
    procedure HandleInstallerNewLine(Sender: TObject; const Text: string);
    procedure HandleInstallerProgressText(Sender: TObject; const Text: string);
  protected
    procedure Run;
  public
    constructor Create;
    destructor Destroy; override;

    (* Start the post-install process in a worker thread. *)
    function Start: Boolean;

    (* Execute the pending Synchronize calls; must be called from the main
       thread (i.e., the thread that loaded the library). *)
    function Poll: TPostInstallStatus;

    (* Request to abort the running process. *)
    procedure Abort;

    (* Abort if needed and wait for the worker thread to be terminated. *)
    procedure WaitForTermination;

    (* Extract the pending lines, as long as they fit in MaxLength chars. *)
    function ExtractPendingLines(const MaxLength: Integer): string;

    function GetProgressText: string;

    (* Current progress bar position (0 to 100), detected from the output
       lines, as done by DreamSDK Manager, or PROGRESS_POSITION_MARQUEE. *)
    function GetProgressPosition: Integer;

    function GetResultOutput: string;

    property Status: TPostInstallStatus read GetStatus;
{$IFDEF DEBUG}
    (* Run harmless shell commands instead of the post-install process. *)
    property SelfTest: Boolean read fSelfTest write fSelfTest;
{$ENDIF}
  end;

implementation

uses
  LazUTF8,
  SysTools;

const
  POLL_WAIT_TIMEOUT = 100;

{ TPostInstallThread }

constructor TPostInstallThread.Create(ASession: TPostInstallSession);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  fSession := ASession;
end;

procedure TPostInstallThread.Execute;
begin
  fSession.Run;
end;

{ TPostInstallSession }

constructor TPostInstallSession.Create;
begin
  fLock := TCriticalSection.Create;
  fPendingLines := TStringList.Create;
  fProgressLineParser := TProgressLineParser.Create;
  fProgressPosition := PROGRESS_POSITION_MARQUEE;
  fStatus := pisIdle;
  fThread := nil;

  fManager := TDreamcastSoftwareDevelopmentKitManager.Create;
  fManager.Environment.OnShellCommandNewLine := @HandleShellCommandNewLine;

  fInstaller := TKallistiInstaller.Create(fManager);
  fInstaller.OnNewLine := @HandleInstallerNewLine;
  fInstaller.OnProgressText := @HandleInstallerProgressText;
end;

destructor TPostInstallSession.Destroy;
begin
  WaitForTermination;
  FreeAndNil(fThread);
  fInstaller.Free;
  fManager.Free; // This saves the configuration file
  fProgressLineParser.Free;
  fPendingLines.Free;
  fLock.Free;
  inherited Destroy;
end;

function TPostInstallSession.GetStatus: TPostInstallStatus;
begin
  fLock.Acquire;
  try
    Result := fStatus;
  finally
    fLock.Release;
  end;
end;

procedure TPostInstallSession.SetStatus(const Value: TPostInstallStatus);
begin
  fLock.Acquire;
  try
    fStatus := Value;
  finally
    fLock.Release;
  end;
end;

procedure TPostInstallSession.AddLine(const Line: string);
begin
  fLock.Acquire;
  try
    fPendingLines.Add(TrimRight(Line));
  finally
    fLock.Release;
  end;
end;

(* Process output line: lines with a percentage update the progress position
   and are not displayed, as done in the DreamSDK Manager progress window. *)
procedure TPostInstallSession.AddOutputLine(const Line: string);
var
  Position: Integer;
  Display: Boolean;

begin
  fLock.Acquire;
  try
    Display := fProgressLineParser.Parse(Line, Position);
    if Position <> PROGRESS_POSITION_UNCHANGED then
      fProgressPosition := Position;
  finally
    fLock.Release;
  end;
  if Display then
    AddLine(Line);
end;

procedure TPostInstallSession.HandleShellCommandNewLine(Sender: TObject;
  NewLine: string);
begin
  AddOutputLine(NewLine);
end;

procedure TPostInstallSession.HandleInstallerNewLine(Sender: TObject;
  const Text: string);
begin
  AddOutputLine(Text);
end;

procedure TPostInstallSession.HandleInstallerProgressText(Sender: TObject;
  const Text: string);
begin
  fLock.Acquire;
  try
    fProgressText := Text;
  finally
    fLock.Release;
  end;
  AddLine(Text);
end;

procedure TPostInstallSession.Run;
var
  LogContext: TLogMessageContext;
  FinalStatus: TPostInstallStatus;

begin
  LogContext := LogMessageEnter({$I %FILE%}, {$I %CURRENTROUTINE%}, ClassName);
  try
    FinalStatus := pisFailed;
    try
{$IFDEF DEBUG}
      if fSelfTest then
      begin
        // Harmless shell commands, using the same thread/Synchronize path
        HandleInstallerProgressText(Self, 'Self-test: executing shell commands...');
        fManager.Environment.ExecuteShellCommand('echo postinst-self-test-1 && uname -a', GetTempDir);
        HandleInstallerProgressText(Self, 'Self-test: second shell command...');
        fManager.Environment.ExecuteShellCommand('echo postinst-self-test-2', GetTempDir);
        FinalStatus := pisSucceeded;
        if fInstaller.Aborted then
          FinalStatus := pisAborted;
      end
      else
{$ENDIF}
      if fInstaller.Execute then
      begin
        // Handle IDE files, as done by DreamSDK Manager after the process
        fManager.KallistiPorts.GenerateIntegratedDevelopmentEnvironmentLibraryInformation;
        FinalStatus := pisSucceeded;
      end
      else if fInstaller.Aborted then
        FinalStatus := pisAborted;

      fLock.Acquire;
      try
        fResultOutput := fInstaller.ResultOutput;
      finally
        fLock.Release;
      end;
    except
      on E: Exception do
      begin
        LogMessage(LogContext, Format('Exception: %s: %s', [E.ClassName, E.Message]));
        AddLine(Format('*** %s: %s', [E.ClassName, E.Message]));
        FinalStatus := pisFailed;
      end;
    end;

    LogMessage(LogContext, Format('FinalStatus: %d', [Ord(FinalStatus)]));
    SetStatus(FinalStatus);
  finally
    LogMessageExit(LogContext);
  end;
end;

function TPostInstallSession.Start: Boolean;
begin
  Result := (Status = pisIdle);
  if Result then
  begin
    SetStatus(pisRunning);
    fThread := TPostInstallThread.Create(Self);
    fThread.Start;
  end;
end;

function TPostInstallSession.Poll: TPostInstallStatus;
begin
  CheckSynchronize(0);
  Result := Status;
end;

procedure TPostInstallSession.Abort;
begin
  if Status = pisRunning then
    fInstaller.Abort;
end;

procedure TPostInstallSession.WaitForTermination;
begin
  if Assigned(fThread) then
  begin
    Abort;
    // The worker thread may wait for Synchronize calls, so keep processing them
    while not fThread.Finished do
      CheckSynchronize(POLL_WAIT_TIMEOUT);
    fThread.WaitFor;
  end;
end;

function TPostInstallSession.ExtractPendingLines(
  const MaxLength: Integer): string;
var
  Line: string;

begin
  Result := EmptyStr;
  fLock.Acquire;
  try
    while fPendingLines.Count > 0 do
    begin
      Line := fPendingLines[0];
      // A single line that can't fit is truncated, else it would block the queue
      if (Result = EmptyStr) and (Length(Line) >= MaxLength) then
        Line := UTF8Copy(Line, 1, MaxLength - 1)
      else if (Length(Result) + Length(sLineBreak) + Length(Line)) >= MaxLength then
        Break;
      if Result <> EmptyStr then
        Result := Result + sLineBreak;
      Result := Result + Line;
      fPendingLines.Delete(0);
    end;
  finally
    fLock.Release;
  end;
end;

function TPostInstallSession.GetProgressText: string;
begin
  fLock.Acquire;
  try
    Result := fProgressText;
  finally
    fLock.Release;
  end;
end;

function TPostInstallSession.GetProgressPosition: Integer;
begin
  fLock.Acquire;
  try
    Result := fProgressPosition;
  finally
    fLock.Release;
  end;
end;

function TPostInstallSession.GetResultOutput: string;
begin
  fLock.Acquire;
  try
    Result := fResultOutput;
  finally
    fLock.Release;
  end;
end;

end.
