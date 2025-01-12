program RenBckp;

{$mode objfpc}{$H+}

uses
  Windows,
  SysUtils,
  SysTools,
  FSTools;

var
  ProgramName: string;
  DirectoryFullPath: TFileName;

{$R *.res}

begin
  ProgramName := GetProgramName;
  if ParamCount < 1 then
  begin
    WriteLn('Usage: ', ProgramName, ' <FileOrDirectoryPath>');
    Exit;
  end;

  DirectoryFullPath := ParamStr(1);
  if RenameFileOrDirectoryAsBackup(DirectoryFullPath) then
    Exit;

  ExitCode := -1;
end.

