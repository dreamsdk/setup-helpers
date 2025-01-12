program RenBckp;

{$mode objfpc}{$H+}

uses
  Windows,
  SysUtils,
  SysTools,
  FSTools;

var
  ProgramName: string;
  OldDirectoryFullPath,
  NewDirectoryFullPath: TFileName;

{$R *.res}

begin
  ProgramName := GetProgramName;
  if ParamCount < 1 then
  begin
    WriteLn('Usage: ', ProgramName, ' <FileOrDirectoryPath>');
    Exit;
  end;

  OldDirectoryFullPath := ParamStr(1);
  if RenameFileOrDirectoryAsBackup(OldDirectoryFullPath, NewDirectoryFullPath) then
  begin
    WriteLn('Target successfully renamed.');
    WriteLn('  Old: "', OldDirectoryFullPath, '"');
    WriteLn('  New: "', NewDirectoryFullPath, '"');
    Exit;
  end;

  WriteLn('Error: Unable to rename target: "', OldDirectoryFullPath, '".');
  ExitCode := -1;
end.

