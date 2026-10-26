(*
  This library is a library helper for DreamSDK Setup.
  This *MUST* be compiled in *RELEASE* mode. If not, the library couldn't be
  loaded in Inno Setup.
*)
library Common;

{$mode objfpc}{$H+}

uses
  Windows,
  SysUtils,
  Classes,
  SysTools,
  StrTools,
  FSTools,
  PEUtils,
  SetupHlp,
  WTTools;

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

function IsWindowsTerminalInstalled: Boolean; stdcall;
begin
  Result := False;
  try
    Result := WTTools.IsWindowsTerminalInstalled;
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

function GetFileLocationsInSystemPathW(const lpFileName: PWideChar;
  const lpDelimiter: AnsiChar; lpPathFileNames: PWideChar;
  const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  PathFileNames: TStringList;

begin
  Result := 0;
  try
    PathFileNames := TStringList.Create;
    try
      if GetFileLocationsInSystemPath(lpFileName, PathFileNames) then
        Result := WriteSharedWideString(
          StringListToString(PathFileNames, lpDelimiter), lpPathFileNames,
          uBufferMaxSize);
    finally
      PathFileNames.Free;
    end;
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

function RenameFileOrDirectoryAsBackupW(
  const OldDirectoryFullPath: PWideChar): Boolean; stdcall;
begin
  Result := False;
  try
    Result := RenameFileOrDirectoryAsBackup(OldDirectoryFullPath) = rfdbSuccess;
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

function GetPortableExecutableBitnessW(
  const FileName: PWideChar): Byte; stdcall;
var
  Bitness: TPortableExecutableBitness;

begin
  Result := Ord(pebUnknown);
  try
    Bitness := pebUnknown;
    if FileExists(FileName) then
      Bitness := GetPortableExecutableBitness(FileName);
    Result := Ord(Bitness);
  except
    on E: Exception do
      LogException({$I %CURRENTROUTINE%}, E);
  end;
end;

(* Retrieve the message of the last exception caught in this library, then
   clear it; empty if there was no exception since the last call. Call it when
   an export returns its failure value (e.g., False or 0). *)
function CommonGetLastErrorW(lpErrorMessage: PWideChar;
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
  IsWindowsTerminalInstalled,
  GetFileLocationsInSystemPathW,
  GetPortableExecutableBitnessW,
  RenameFileOrDirectoryAsBackupW,
  CommonGetLastErrorW;

end.

