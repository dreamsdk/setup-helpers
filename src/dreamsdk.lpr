library DreamSDK;

{$mode objfpc}{$H+}

uses
  Windows,
  SysUtils,
  Classes,
  SysTools,
  FSTools,
  PEUtils,
  WTTools,
  CBHelper,
  Helper;

{$R *.res}

function IsWindowsTerminalInstalledA: Boolean; stdcall;
begin
  Result := IsWindowsTerminalInstalled;
end;

function GetFileLocationsInSystemPathA(const lpFileName: PAnsiChar;
  const lpDelimiter: AnsiChar; lpPathFileNames: PAnsiChar;
  const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  PathFileNames: TStringList;

begin
  Result := 0;
  PathFileNames := TStringList.Create;
  try
    if GetFileLocationsInSystemPath(lpFileName, PathFileNames) then
      Result := WriteSharedAnsiString(StringListToString(PathFileNames, lpDelimiter)
        , lpPathFileNames, uBufferMaxSize);
  finally
    PathFileNames.Free;
  end;
end;

function RenameFileOrDirectoryAsBackupA(
  const OldDirectoryFullPath: PAnsiChar): Boolean; stdcall;
var
  NewDirectoryFullPath: TFileName;

begin
  NewDirectoryFullPath := Default(string);
  Result := RenameFileOrDirectoryAsBackup(OldDirectoryFullPath, NewDirectoryFullPath);
end;

function GetPortableExecutableBitnessA(const FileName: PAnsiChar): Byte; stdcall;
var
  Bitness: TPortableExecutableBitness;

begin
  Bitness := pebUnknown;
  if FileExists(FileName) then
    Bitness := GetPortableExecutableBitness(FileName);
  Result := Ord(Bitness);
end;

exports
  CodeBlocksDetectInstallationPathA,
  CodeBlocksDetectVersionA,
  CodeBlocksGetAvailableUsersA,
  CodeBlocksInitializeProfilesA,
  CodeBlocksRemoveProfilesA,
  GetFileLocationsInSystemPathA,
  GetPortableExecutableBitnessA,
  IsWindowsTerminalInstalledA,
  RenameFileOrDirectoryAsBackupA;

end.

