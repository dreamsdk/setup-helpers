program WTCheck;

{$mode objfpc}{$H+}

uses
  Windows,
  SysUtils,
  WTTools;

{$R *.res}

begin
  if IsWindowsTerminalInstalled then
    WriteLn('Windows Terminal is installed.')
  else
    WriteLn('Error: Windows Terminal is not installed.');
end.

