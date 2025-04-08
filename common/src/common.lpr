library Common;

{$mode objfpc}{$H+}

uses
  Windows,
  SysUtils,
  Classes,
  SysTools,
  FSTools,
  PEUtils,
  SetupHlp,
  WTTools;

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

procedure GetMessage(Buffer: PAnsiChar; BufSize: Integer); stdcall;
var
  Msg: AnsiString; //UnicodeString;

begin
  if (Buffer = nil) or (BufSize <= 0) then Exit;
  Msg := 'Bonjour depuis la DLL Unicode 🎉'; //  🎉
  // FillChar(Buffer[0], BufSize, 0);
  StrPLCopy(Buffer, PAnsiChar(Msg), Length(Msg));
end;

// https://stackoverflow.com/a/65401568
procedure GetMessageW(Buffer: PWideChar; BufSize: Integer); stdcall;
var
  Msg: UnicodeString;

begin
  if (Buffer = nil) or (BufSize <= 0) then Exit;
  Msg := 'xxxx_'#$04C5'_x_'#$30BA'_xx_'#$30A1'_xxxxxB'#$1F00'o'#$0100'__|';
  StrPLCopy(Buffer, Msg, Length(Msg));
  //  StrPCopy(Buffer, Msg);
  MessageBoxW(0, PWideChar(Msg), 'DLL', 0);
end;

exports
  GetMessage,
  GetMessageW,
  GetFileLocationsInSystemPathA,
  GetPortableExecutableBitnessA,
  IsWindowsTerminalInstalledA,
  RenameFileOrDirectoryAsBackupA;

end.

