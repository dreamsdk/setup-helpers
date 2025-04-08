program DbgSHlp;

uses
  SysUtils,
  Classes,
  CBTools,
  SysTools;

const
  HELPER_LIBRARY_BUFFER_SPLIT_CHAR = '|';
  HELPER_LIBRARY_BUFFER_SIZE_SMALL = 4096;    // 4 KB
  HELPER_LIBRARY_BUFFER_SIZE_LARGE = 131072;  // 128 KB

var
  Buffer: array[0..HELPER_LIBRARY_BUFFER_SIZE_LARGE - 1] of AnsiChar;
  BufferSize: Cardinal;
  Output: string;

(*
function CodeBlocksGetAvailableUsers(var AvailableUsers: TArrayOfString): Boolean;
var
  Buffer: AnsiString;
  BufferSize: Cardinal;
  Output: String;

begin
  SetLength(Buffer, HELPER_LIBRARY_BUFFER_SIZE_LARGE);
  if IsUninstallMode() then
    BufferSize := CodeBlocksGetAvailableUsersUninstall(
      HELPER_LIBRARY_BUFFER_SPLIT_CHAR, Buffer, HELPER_LIBRARY_BUFFER_SIZE_LARGE)
  else
    BufferSize := CodeBlocksGetAvailableUsersSetup(
      HELPER_LIBRARY_BUFFER_SPLIT_CHAR, Buffer, HELPER_LIBRARY_BUFFER_SIZE_LARGE);
  SetLength(Buffer, BufferSize);
  Output := Copy(Buffer, 1, Length(Buffer));
  Result := Length(Output) > 0;
  if Result then
    Explode(AvailableUsers, Output, HELPER_LIBRARY_BUFFER_SPLIT_CHAR);
end;
*)

(* Retrieve all Windows users that can use Code::Blocks in this system. *)
(*function CodeBlocksGetAvailableUsersA(const lpDelimiter: AnsiChar;
  lpAvailableUsers: PAnsiChar; const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  AvailableUsers: TStringList;

begin
  AvailableUsers := TStringList.Create;
  try
    GetCodeBlocksAvailableUsers(AvailableUsers);
    Result := WriteSharedAnsiString(StringListToString(AvailableUsers,
      lpDelimiter), lpAvailableUsers, uBufferMaxSize);
  finally
    AvailableUsers.Free;
  end;
end;*)

(*function CodeBlocksGetAvailableUsersA(const lpDelimiter: AnsiChar;
  lpAvailableUsers: PAnsiChar; const uBufferMaxSize: Cardinal): Cardinal;
stdcall; external 'dreamsdk.dll';*)

function WriteSharedWideString(const Source: string;
  Destination: PWideChar; const MaxLength: UInt32): UInt32;

begin
  Result := 0;
  if Assigned(Destination) and (MaxLength > 0) then
  begin
    StrPLCopy(Destination, Source, MaxLength);
    Result := Length(Destination);
  end;
end;

procedure Test_GetCodeBlocksAvailableUsers;
var
  CodeBlocksUsers: TStringList;
  Output: WideString;
  test: array[0..255] of widechar;

begin
  CodeBlocksUsers := TStringList.Create;
  try
    WriteLn('');
    WriteLn('--- GetCodeBlocksAvailableUsers: BEGIN ---', sLineBreak);
    GetCodeBlocksAvailableUsers(CodeBlocksUsers);

    WriteLn(sLineBreak, '******************************************************************');
    Output := StringListToString(CodeBlocksUsers, sLineBreak);
    WriteSharedWideString(Output, test, length(output));
    WriteLn(Output);
    WriteLn('******************************************************************', sLineBreak);

    WriteLn(sLineBreak, '--- GetCodeBlocksAvailableUsers: END ---');
  finally
    CodeBlocksUsers.Free;
  end;
end;

begin
  (*Buffer := Default(AnsiString);
  BufferSize := CodeBlocksGetAvailableUsersA(
    HELPER_LIBRARY_BUFFER_SPLIT_CHAR, @Buffer[0], HELPER_LIBRARY_BUFFER_SIZE_LARGE);
  Output := Copy(string(Buffer), 1, Length(Buffer));
  WriteLn('Output: ', Output);*)
  WriteLn('Test_GetCodeBlocksAvailableUsers');
  Test_GetCodeBlocksAvailableUsers();
  WriteLn('Strike the <ENTER> key to exit');
  ReadLn();
end.

