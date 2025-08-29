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

function IsWindowsTerminalInstalled: Boolean; stdcall;
begin
  Result := WTTools.IsWindowsTerminalInstalled;
end;

function GetFileLocationsInSystemPathW(const lpFileName: PWideChar;
  const lpDelimiter: AnsiChar; lpPathFileNames: PWideChar;
  const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  PathFileNames: TStringList;

begin
  Result := 0;
  PathFileNames := TStringList.Create;
  try
    if GetFileLocationsInSystemPath(lpFileName, PathFileNames) then
      Result := WriteSharedWideString(
        StringListToString(PathFileNames, lpDelimiter), lpPathFileNames,
        uBufferMaxSize);
  finally
    PathFileNames.Free;
  end;
end;

function RenameFileOrDirectoryAsBackupW(
  const OldDirectoryFullPath: PWideChar): Boolean; stdcall;
begin
  Result := RenameFileOrDirectoryAsBackup(OldDirectoryFullPath);
end;

function GetPortableExecutableBitnessW(
  const FileName: PWideChar): Byte; stdcall;
var
  Bitness: TPortableExecutableBitness;

begin
  Bitness := pebUnknown;
  if FileExists(FileName) then
    Bitness := GetPortableExecutableBitness(FileName);
  Result := Ord(Bitness);
end;

exports
  IsWindowsTerminalInstalled,
  GetFileLocationsInSystemPathW,
  GetPortableExecutableBitnessW,
  RenameFileOrDirectoryAsBackupW;

end.

