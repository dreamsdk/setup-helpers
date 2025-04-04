unit CBHelper;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils,
  Classes;

function CodeBlocksGetAvailableUsersA(const lpDelimiter: AnsiChar;
  lpAvailableUsers: PAnsiChar; const uBufferMaxSize: UInt32): UInt32; stdcall;

function CodeBlocksRemoveProfilesA: Boolean; stdcall;

function CodeBlocksDetectInstallationPathA(lpInstallationPath: PAnsiChar;
  const uBufferMaxSize: UInt32): UInt32; stdcall;

function CodeBlocksDetectVersionA(const lpCodeBlocksInstallationDirectory: PAnsiChar;
  lpCodeBlockVersion: PAnsiChar; const uBufferMaxSize: UInt32): UInt32; stdcall;

procedure CodeBlocksInitializeProfilesA; stdcall;

implementation

uses
  SysTools,
  Version,
  CBTools,
  CBPatch,
  Helper;

(* Retrieve all Windows users that can use Code::Blocks in this system. *)
function CodeBlocksGetAvailableUsersA(const lpDelimiter: AnsiChar;
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
end;

(* Remove all DreamSDK references from Code::Blocks profiles. *)
function CodeBlocksRemoveProfilesA: Boolean; stdcall;
var
  CodeBlocksPatcher: TCodeBlocksPatcher;

begin
  CodeBlocksPatcher := TCodeBlocksPatcher.Create;
  try
    Result := CodeBlocksPatcher.ResetProfiles;
  finally
    CodeBlocksPatcher.Free;
  end;
end;

(* Retrieve the Code::Blocks installation path. *)
function CodeBlocksDetectInstallationPathA(lpInstallationPath: PAnsiChar;
  const uBufferMaxSize: UInt32): UInt32; stdcall;
type
  TInnoSetupTranslation = record
    EnvironmentVariable: string;
    InnoSetupVariable: string;
    Is64BitOnly: Boolean;
  end;

const
  DIRECTORIES: array[0..3] of TInnoSetupTranslation = (
    (EnvironmentVariable: '%ProgramW6432%'; InnoSetupVariable: '{pf64}'; Is64BitOnly: True),
    (EnvironmentVariable: '%ProgramFiles(x86)%'; InnoSetupVariable: '{pf32}'; Is64BitOnly: True),
    (EnvironmentVariable: '%ProgramFiles%'; InnoSetupVariable: '{pf64}'; Is64BitOnly: True),
    (EnvironmentVariable: '%ProgramFiles%'; InnoSetupVariable: '{pf32}'; Is64BitOnly: False)
  );

var
  i: Integer;
  InstallationDirectory: TFileName;
  EnvironmentVariable,
  InnoSetupVariable: string;
  InnoSetupTranslation: TInnoSetupTranslation;

begin
  InstallationDirectory := GetCodeBlocksDefaultInstallationDirectory;
{$IFDEF DEBUG}
  WriteLn('InstallationDirectory: ', InstallationDirectory);
{$ENDIF}
  for i := Low(DIRECTORIES) to High(DIRECTORIES) do
  begin
    InnoSetupTranslation := DIRECTORIES[i];
    if ((InnoSetupTranslation.Is64BitOnly and IsWindows64)
      or (not InnoSetupTranslation.Is64BitOnly and not IsWindows64)) then
    begin
      EnvironmentVariable := InnoSetupTranslation.EnvironmentVariable;
      InnoSetupVariable := InnoSetupTranslation.InnoSetupVariable;
{$IFDEF DEBUG}
      WriteLn(EnvironmentVariable, ' => ', InnoSetupVariable);
{$ENDIF}
      if IsInString(EnvironmentVariable, InstallationDirectory) then
      begin
{$IFDEF DEBUG}
        WriteLn('  Before: ', InstallationDirectory);
{$ENDIF}
        InstallationDirectory := StringReplace(
          InstallationDirectory,
          EnvironmentVariable,
          InnoSetupVariable,
          [rfReplaceAll, rfIgnoreCase]
        );
{$IFDEF DEBUG}
        WriteLn('  After: ', InstallationDirectory);
{$ENDIF}
      end;
    end;
  end;

  Result := WriteSharedAnsiString(InstallationDirectory, lpInstallationPath,
    uBufferMaxSize);
end;

(* Retrieve the Code::Blocks version in the installation path. *)
function CodeBlocksDetectVersionA(const lpCodeBlocksInstallationDirectory: PAnsiChar;
  lpCodeBlockVersion: PAnsiChar; const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  CodeBlocksVersion: TCodeBlocksVersion;

begin
  CodeBlocksVersion := GetCodeBlocksVersion(lpCodeBlocksInstallationDirectory);
  Result := WriteSharedAnsiString(CodeBlocksVersionToString(CodeBlocksVersion),
    lpCodeBlockVersion, uBufferMaxSize);
end;

procedure CodeBlocksInitializeProfilesA; stdcall;
begin
  InitializeCodeBlocksProfiles;
end;

end.

