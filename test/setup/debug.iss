﻿; Script generated by the Inno Script Studio Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "DreamSDK DEBUG"
#define MyAppVersion "0.0"
#define MyAppPublisher "The DreamSDK Team"
#define MyAppURL "https://dreamsdk.org/"
#define MyAppExeName "MyProg.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{3A92718C-AF5C-4373-A65D-80106B49A1DA}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
CreateAppDir=no
OutputBaseFilename=setup
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Code]
var
  UninstallMode: Boolean;

function IsUninstallMode(): Boolean;
begin
  Result := UninstallMode;
end;

procedure SetUninstallMode(SelectedMode: Boolean);
begin
  UninstallMode := SelectedMode;
end;

// Destination Path [Support]
#define AppSupportDirectoryName "support"

#include "../../../setup-generator/src/inc/utils/utils.iss"
#include "../../../setup-generator/src/inc/helpers/helperlib.iss"

(*
procedure GetMessage(Buffer: AnsiString; BufSize: Integer);
  external 'GetMessage@files:common.dll stdcall';

procedure GetMessageW(Buffer: string; BufSize: Integer);
 external 'GetMessageW@files:common.dll stdcall';
*)

function InitializeSetup(): Boolean;
var
  AvailableUsers: TArrayOfString;
  i: Integer;
//  Buffer: AnsiString;
  BufferW: string;
  
begin
  Result := False;                         
  SetUninstallMode(False);
       
  if CodeBlocksGetAvailableUsers(AvailableUsers) then
  begin
    BufferW := '';
    for i := 0 to Length(AvailableUsers) - 1 do
      BufferW := BufferW + #13#10 + AvailableUsers[i];
    MsgBox(BufferW, mbError, MB_OK);
  end;

(*

  // Allouer un buffer de 256 caractères Unicode
  SetLength(Buffer, 256);
  SetLength(BufferW, 256);

  // Appeler la DLL
  GetMessage(Buffer, Length(Buffer));
  GetMessageW(BufferW, Length(BufferW));

  // Afficher le message retourné
  // MsgBox('ドリームキャスト❤️', mbInformation, MB_OK);
  // MsgBox(Buffer, mbInformation, MB_OK);
  MsgBox(BufferW, mbInformation, MB_OK);
*)
end;

function InitializeUninstall(): Boolean;
begin
  Result := True;
  SetUninstallMode(True);  
end;

[Files]                                 
Source: "..\..\cbhelper\bin\{#CodeBlocksHelperLibraryFileName}"; DestDir: "{app}"; Flags: ignoreversion noencryption nocompression
Source: "..\..\common\bin\{#CommonHelperLibraryFileName}"; DestDir: "{app}"; Flags: ignoreversion noencryption nocompression
