(*
  This library is a library helper for DreamSDK Setup.
  It handles the DreamSDK extension for Visual Studio Code and its forks (e.g.
  VSCodium), which is installed for all the Windows user profiles (see the
  VSCTools unit).
  This *MUST* be compiled in *RELEASE* mode. If not, the library couldn't be
  loaded in Inno Setup.
*)
library VSHelper;

{$mode objfpc}{$H+}

uses
  Windows,
  SysUtils,
  Classes,
  LazUTF8,
  SysTools,
  StrTools,
  SetupHlp,
  VSCTools;

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

(* Convert the list of users to a delimiter-separated list. *)
function UsersToString(const Users: TWindowsUserAccountInformationArray;
  const Delimiter: AnsiChar): string;
var
  Buffer: TStringList;
  i: Integer;

begin
  Buffer := TStringList.Create;
  try
    for i := Low(Users) to High(Users) do
      Buffer.Add(Users[i].FriendlyName);
    Result := StringListToString(Buffer, Delimiter);
  finally
    Buffer.Free;
  end;
end;

(* Convert an editor identifier passed by Inno Setup (e.g. "vscode", "vscodium",
   see VSCODE_EDITORS in the VSCTools unit). *)
function EditorIdToString(const lpEditorId: PWideChar): string;
begin
  Result := UTF16ToUTF8(UnicodeString(lpEditorId));
end;

(* Retrieve the command-line interface (e.g. code.cmd) of the most recent
   installation of an editor, or an empty string if not installed. *)
function VSCodeDetectCliW(const lpEditorId: PWideChar;
  lpCommandLineInterface: PWideChar; const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  Installation: TVisualStudioCodeInstallation;

begin
  Result := 0;
  try
    GetVisualStudioCodeInstallation(EditorIdToString(lpEditorId), Installation);
    Result := WriteSharedWideString(Installation.CommandLineInterface,
      lpCommandLineInterface, uBufferMaxSize);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Retrieve the version of the most recent installation of an editor. *)
function VSCodeDetectVersionW(const lpEditorId: PWideChar;
  lpVersion: PWideChar; const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  Installation: TVisualStudioCodeInstallation;

begin
  Result := 0;
  try
    GetVisualStudioCodeInstallation(EditorIdToString(lpEditorId), Installation);
    Result := WriteSharedWideString(Installation.Version, lpVersion,
      uBufferMaxSize);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Retrieve all Windows users that will receive the extension. *)
function VSCodeGetAvailableUsersW(const lpDelimiter: AnsiChar;
  lpAvailableUsers: PWideChar; const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  AvailableUsers: TWindowsUserAccountInformationArray;

begin
  Result := 0;
  try
    GetVisualStudioCodeAvailableUsers(AvailableUsers);
    Result := WriteSharedWideString(UsersToString(AvailableUsers, lpDelimiter),
      lpAvailableUsers, uBufferMaxSize);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Retrieve all Windows users that have the extension installed in an editor. *)
function VSCodeGetInstalledUsersW(const lpEditorId: PWideChar;
  const lpDelimiter: AnsiChar; lpInstalledUsers: PWideChar;
  const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  InstalledUsers: TWindowsUserAccountInformationArray;

begin
  Result := 0;
  try
    GetVisualStudioCodeInstalledUsers(EditorIdToString(lpEditorId),
      VSCODE_DREAMSDK_EXTENSION_ID, InstalledUsers);
    Result := WriteSharedWideString(UsersToString(InstalledUsers, lpDelimiter),
      lpInstalledUsers, uBufferMaxSize);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Install the extension (.vsix) in an editor for all the Windows users. *)
function VSCodeInstallExtensionW(const lpEditorId: PWideChar;
  const lpVsixFileName: PWideChar): Boolean; stdcall;
begin
  Result := False;
  try
    Result := VisualStudioCodeInstallExtension(EditorIdToString(lpEditorId),
      UTF16ToUTF8(UnicodeString(lpVsixFileName)), LastErrorMessage);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Remove the extension from an editor for all the Windows users. *)
function VSCodeRemoveExtensionW(const lpEditorId: PWideChar): Boolean; stdcall;
begin
  Result := False;
  try
    Result := VisualStudioCodeUninstallExtension(EditorIdToString(lpEditorId),
      VSCODE_DREAMSDK_EXTENSION_ID, LastErrorMessage);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Save the users that have the extension installed in an editor, in the
   DreamSDK IDE configuration file (ide.conf). DreamSDK Manager can't read the
   profiles of the other users when not elevated, so it uses this list. Must be
   called elevated (i.e., from DreamSDK Setup), so all the profiles are read. *)
function VSCodeRefreshInstalledUsersW(const lpEditorId: PWideChar;
  const lpConfigurationFileName: PWideChar): Boolean; stdcall;
var
  InstalledUsers: TStringList;

begin
  Result := False;
  try
    InstalledUsers := TStringList.Create;
    try
      Result := RefreshVisualStudioCodeInstalledUsers(EditorIdToString(lpEditorId),
        VSCODE_DREAMSDK_EXTENSION_ID, UTF16ToUTF8(UnicodeString(lpConfigurationFileName)),
        InstalledUsers);
    finally
      InstalledUsers.Free;
    end;
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Retrieve the error message of the last install/remove operation, or of the
   last exception caught in this library. *)
function VSCodeGetLastErrorW(lpErrorMessage: PWideChar;
  const uBufferMaxSize: UInt32): UInt32; stdcall;
begin
  Result := 0;
  try
    Result := WriteSharedWideString(LastErrorMessage, lpErrorMessage,
      uBufferMaxSize);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

exports
  VSCodeDetectCliW,
  VSCodeDetectVersionW,
  VSCodeGetAvailableUsersW,
  VSCodeGetInstalledUsersW,
  VSCodeInstallExtensionW,
  VSCodeRemoveExtensionW,
  VSCodeRefreshInstalledUsersW,
  VSCodeGetLastErrorW;

end.
