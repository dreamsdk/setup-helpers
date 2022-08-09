program WhereIs;

{$mode objfpc}{$H+}

uses
  Windows,
  SysUtils,
  Classes,
  SysTools,
  FSTools,
  PEUtils;

var
  ProgramName: string;
  FileName: TFileName;
  PathFileNames: TStringList;
  i: Integer;

{$R *.res}

begin
  ProgramName := GetProgramName;
  if ParamCount < 1 then
  begin
    WriteLn('Usage: ', ProgramName, ' <FileName>');
    Exit;
  end;

  FileName := ParamStr(1);
  PathFileNames := TStringList.Create;
  try
    GetFileLocationsInSystemPath(FileName, PathFileNames);
    for i := 0 to PathFileNames.Count - 1 do
      WriteLn(PathFileNames[i]);
  finally
    PathFileNames.Free;
  end;
end.

