program DbgSHlp;

uses
  SysUtils,
  Classes,
  CBTools,
  SysTools,
  StrTools;

procedure Test_GetCodeBlocksAvailableUsers;
var
  CodeBlocksUsers: TWindowsUserAccountInformationArray;
  i: Integer;

begin
  WriteLn('');
  WriteLn('--- GetCodeBlocksAvailableUsers: BEGIN ---', sLineBreak);
  GetCodeBlocksAvailableUsers(CodeBlocksUsers);

  WriteLn(sLineBreak, '******************************************************************');

  for i := 0 to Length(CodeBlocksUsers) - 1 do
  begin
    WriteLn(CodeBlocksUsers[i].FullName, ' (', CodeBlocksUsers[i].UserName, ')');
  end;

  WriteLn('******************************************************************', sLineBreak);

  WriteLn(sLineBreak, '--- GetCodeBlocksAvailableUsers: END ---');
end;

begin
  WriteLn('Test_GetCodeBlocksAvailableUsers');
  Test_GetCodeBlocksAvailableUsers();
  WriteLn('Strike the <ENTER> key to exit');
  ReadLn();
end.

