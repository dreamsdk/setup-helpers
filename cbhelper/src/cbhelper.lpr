(*
  This library is a library helper for DreamSDK Setup.
  This *MUST* be compiled in *RELEASE* mode. If not, the library couldn't be
  loaded in Inno Setup.
*)
library CBHelper;

{$mode objfpc}{$H+}

uses
  Windows,
  SysUtils,
  Classes,
  LazUTF8,
  SysTools,
  StrTools,
  FSTools,
  PEUtils,
  WTTools,
  SetupHlp,
  Version,
  CBTools,
  CBVerInf,
  CBPatch;

{$R *.res}

var
  LastErrorMessage: string = '';

(* Log an exception caught in an export and keep its message, so Setup can
   retrieve it. *)
procedure LogException(const RoutineName: string; E: Exception);
var
  LogContext: TLogMessageContext;

begin
  LastErrorMessage := E.Message;
  LogContext := LogMessageEnter({$I %FILE%}, RoutineName);
  try
    LogMessage(LogContext, Format('Exception: %s: %s', [E.ClassName, E.Message]));
  finally
    LogMessageExit(LogContext);
  end;
end;

(* Retrieve all Windows users that can use Code::Blocks in this system. *)
function CodeBlocksGetAvailableUsersW(const lpDelimiter: AnsiChar;
  lpAvailableUsers: PWideChar; const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  Buffer: TStringList;
  AvailableUsers: TWindowsUserAccountInformationArray;
  i: Integer;

begin
  Result := 0;
  try
    Buffer := TStringList.Create;
    try
      GetCodeBlocksAvailableUsers(AvailableUsers);
      for i := 0 to Length(AvailableUsers) - 1 do
        Buffer.Add(AvailableUsers[i].FriendlyName);
      Result := WriteSharedWideString(StringListToString(Buffer,
        lpDelimiter), lpAvailableUsers, uBufferMaxSize);
    finally
      Buffer.Free;
    end;
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Remove all DreamSDK references from Code::Blocks profiles. *)
function CodeBlocksRemoveProfiles: Boolean; stdcall;
var
  CodeBlocksPatcher: TCodeBlocksPatcher;

begin
  Result := False;
  try
    CodeBlocksPatcher := TCodeBlocksPatcher.Create;
    try
      Result := CodeBlocksPatcher.ResetProfiles;
    finally
      CodeBlocksPatcher.Free;
    end;
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Retrieve the Code::Blocks installation path. *)
function CodeBlocksDetectInstallationPathW(lpInstallationPath: PWideChar;
  const uBufferMaxSize: UInt32): UInt32; stdcall;
type
  TInnoSetupTranslation = record
    EnvironmentVariable: string;
    InnoSetupVariable: string;
    Is64BitOnly: Boolean;
  end;

const
  DIRECTORIES: array[0..3] of TInnoSetupTranslation = (
    (EnvironmentVariable: '%ProgramW6432%'; InnoSetupVariable: '{pf64}'; Is64BitOnly: True),
    (EnvironmentVariable: '%ProgramFiles(x86)%'; InnoSetupVariable: '{pf32}'; Is64BitOnly: True),
    (EnvironmentVariable: '%ProgramFiles%'; InnoSetupVariable: '{pf64}'; Is64BitOnly: True),
    (EnvironmentVariable: '%ProgramFiles%'; InnoSetupVariable: '{pf32}'; Is64BitOnly: False)
  );

var
  i: Integer;
  InstallationDirectory: TFileName;
  EnvironmentVariable,
  InnoSetupVariable: string;
  InnoSetupTranslation: TInnoSetupTranslation;

begin
  Result := 0;
  try
    InstallationDirectory := GetCodeBlocksDefaultInstallationDirectory;
{$IFDEF DEBUG}
    WriteLn('InstallationDirectory: ', InstallationDirectory);
{$ENDIF}
    for i := Low(DIRECTORIES) to High(DIRECTORIES) do
    begin
      InnoSetupTranslation := DIRECTORIES[i];
      if ((InnoSetupTranslation.Is64BitOnly and IsWindows64)
        or (not InnoSetupTranslation.Is64BitOnly and not IsWindows64)) then
      begin
        EnvironmentVariable := InnoSetupTranslation.EnvironmentVariable;
        InnoSetupVariable := InnoSetupTranslation.InnoSetupVariable;
{$IFDEF DEBUG}
        WriteLn(EnvironmentVariable, ' => ', InnoSetupVariable);
{$ENDIF}
        if IsInString(EnvironmentVariable, InstallationDirectory) then
        begin
{$IFDEF DEBUG}
          WriteLn('  Before: ', InstallationDirectory);
{$ENDIF}
          InstallationDirectory := StringReplace(
            InstallationDirectory,
            EnvironmentVariable,
            InnoSetupVariable,
            [rfReplaceAll, rfIgnoreCase]
          );
{$IFDEF DEBUG}
          WriteLn('  After: ', InstallationDirectory);
{$ENDIF}
        end;
      end;
    end;

    Result := WriteSharedWideString(InstallationDirectory, lpInstallationPath,
      uBufferMaxSize);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Retrieve the Code::Blocks version in the installation path. *)
function CodeBlocksDetectVersionW(const lpCodeBlocksInstallationDirectory: PWideChar;
  lpCodeBlockVersion: PWideChar; const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  CodeBlocksVersion: TCodeBlocksVersion;

begin
  Result := 0;
  try
    CodeBlocksVersion := GetCodeBlocksVersion(lpCodeBlocksInstallationDirectory);
    Result := WriteSharedWideString(CodeBlocksVersionToString(CodeBlocksVersion),
      lpCodeBlockVersion, uBufferMaxSize);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

procedure CodeBlocksInitializeProfiles; stdcall;
begin
  try
    CBTools.InitializeCodeBlocksProfiles;
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Retrieve the message of the last exception caught in this library, then
   clear it; empty if there was no exception since the last call. Call it when
   an export returns its failure value (e.g., False or 0). *)
function CodeBlocksGetLastErrorW(lpErrorMessage: PWideChar;
  const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  ErrorMessage: string;

begin
  Result := 0;
  try
    ErrorMessage := LastErrorMessage;
    LastErrorMessage := '';
    Result := WriteSharedWideString(ErrorMessage, lpErrorMessage,
      uBufferMaxSize);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

exports
  CodeBlocksDetectInstallationPathW,
  CodeBlocksDetectVersionW,
  CodeBlocksGetAvailableUsersW,
  CodeBlocksInitializeProfiles,
  CodeBlocksRemoveProfiles,
  CodeBlocksGetLastErrorW;

end.

