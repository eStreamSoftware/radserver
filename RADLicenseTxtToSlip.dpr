program RADLicenseTxtToSlip;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows;

function HexChar(c: Char): Byte;
begin
  case c of
    '0'..'9': Result := Byte(c) - Byte('0');
    'a'..'f': Result := (Byte(c) - Byte('a')) + 10;
    'A'..'F': Result := (Byte(c) - Byte('A')) + 10;
  else
    Writeln(ErrOutput, 'Error parsing hex character', c);
    Result := 0;
  end;
end;

function HexStrToBytes(aStr: string): TBytes;
begin
  Result := [];

  var HexDigit := '';
  var i := 1;
  while i <= Length(aStr) do begin
    var c := aStr[i];
    if c = '%' then begin
      Result := Result + [HexChar(aStr[i + 1]) shl 4 + HexChar(aStr[i + 2])];
      Inc(i, 2);
    end else if not CharInSet(c, [#13, #10]) then
      Result := Result + [Byte(c)];
    Inc(i);
  end;
end;

begin
  var Input := THandleStream.Create(GetStdHandle(STD_INPUT_HANDLE));
//  var Input := TFileStream.Create('R:\reg5542_1629958852000.txt', fmOpenRead);
  var Output := THandleStream.Create(GetStdHandle(STD_OUTPUT_HANDLE));
  var Reader := TStreamReader.Create(Input);
  try
    var Parsing := False;
    repeat
      var s := Reader.ReadLine;
      if Parsing and (s.Length > 2) then
        while (s[s.Length - 1] = '%') or (s[s.Length] = '%') do
          s := s + Reader.ReadLine;

      if s = '-----BEGIN BLOCK-----' then
        Parsing := True
      else if s = '-----END BLOCK-----' then
        Parsing := False
      else if Parsing then
        for var b in HexStrToBytes(s) do Write(AnsiChar(b));
    until Reader.EndOfStream;
  finally
    Reader.Free;
    Output.Free;
    Input.Free;
  end;
end.
