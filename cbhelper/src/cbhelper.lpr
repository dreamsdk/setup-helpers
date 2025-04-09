(*
  This library is a library helper for DreamSDK Setup.
  This *MUST* be compiled in *RELEASE* mode. If not, the library couldn't be
  loaded in Inno Setup.
*)
library CBHelper;

{$mode objfpc}{$H+}

uses
  Windows,
  SysUtils,
  Classes,
  LazUTF8,
  SysTools,
  FSTools,
  PEUtils,
  WTTools,
  SetupHlp,
  Version,
  CBTools,
  CBPatch;

{$R *.res}

(* Retrieve all Windows users that can use Code::Blocks in this system. *)
function CodeBlocksGetAvailableUsersW(const lpDelimiter: AnsiChar;
  lpAvailableUsers: PWideChar; const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  AvailableUsers: TStringList;

begin
  AvailableUsers := TStringList.Create;
  try
    GetCodeBlocksAvailableUsers(AvailableUsers);
    Result := WriteSharedWideString(StringListToString(AvailableUsers,
      lpDelimiter), lpAvailableUsers, uBufferMaxSize);
  finally
    AvailableUsers.Free;
  end;
end;

(* Remove all DreamSDK references from Code::Blocks profiles. *)
function CodeBlocksRemoveProfiles: Boolean; stdcall;
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
function CodeBlocksDetectInstallationPathW(lpInstallationPath: PWideChar;
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

  Result := WriteSharedWideString(InstallationDirectory, lpInstallationPath,
    uBufferMaxSize);
end;

(* Retrieve the Code::Blocks version in the installation path. *)
function CodeBlocksDetectVersionW(const lpCodeBlocksInstallationDirectory: PWideChar;
  lpCodeBlockVersion: PWideChar; const uBufferMaxSize: UInt32): UInt32; stdcall;
var
  CodeBlocksVersion: TCodeBlocksVersion;

begin
  CodeBlocksVersion := GetCodeBlocksVersion(lpCodeBlocksInstallationDirectory);
  Result := WriteSharedWideString(CodeBlocksVersionToString(CodeBlocksVersion),
    lpCodeBlockVersion, uBufferMaxSize);
end;

procedure CodeBlocksInitializeProfiles; stdcall;
begin
  CBTools.InitializeCodeBlocksProfiles;
end;

exports
  CodeBlocksDetectInstallationPathW,
  CodeBlocksDetectVersionW,
  CodeBlocksGetAvailableUsersW,
  CodeBlocksInitializeProfiles,
  CodeBlocksRemoveProfiles;

end.

