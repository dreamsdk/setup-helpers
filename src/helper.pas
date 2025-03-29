unit Helper;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils,
  Classes;

function WriteSharedAnsiString(const Source: string;
  Destination: PAnsiChar; const MaxLength: UInt32): UInt32;

implementation

function WriteSharedAnsiString(const Source: string;
  Destination: PAnsiChar; const MaxLength: UInt32): UInt32;

begin
  Result := 0;
  if Assigned(Destination) and (MaxLength > 0) then
  begin
    StrPLCopy(Destination, Source, MaxLength);
    Result := Length(Destination);
  end;
end;

end.

