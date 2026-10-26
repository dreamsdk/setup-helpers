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

exports
  IsWindowsTerminalInstalled,
  GetFileLocationsInSystemPathW,
  GetPortableExecutableBitnessW,
  RenameFileOrDirectoryAsBackupW;

end.

