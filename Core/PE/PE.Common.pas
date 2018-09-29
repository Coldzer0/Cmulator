unit PE.Common;

interface

uses
  Generics.Collections,Classes,sysutils;


{$MINENUMSIZE 4}

{ Base types }

type
  Int8 = ShortInt;
  Int16 = SmallInt;
  Int32 = Integer;
  IntPtr = NativeInt;
  UInt8 = Byte;
  UInt16 = Word;
  UInt32 = Cardinal;

  Dword = UInt32;
  PDword = ^Dword;

  TVA = UInt64;
  TRVA = UInt64;

  PInt8 = ^Int8;
  PInt16 = ^Int16;
  PInt32 = ^Int32;
  PInt64 = ^Int64;

  PUInt8 = ^UInt8;
  PUInt16 = ^UInt16;
  PUInt32 = ^UInt32;
  PUInt64 = ^UInt64;

  TFileOffset = type UInt64;

  TParserFlag = (
    PF_EXPORT,
    PF_IMPORT,
    PF_IMPORT_DELAYED,
    PF_RELOCS,
    PF_TLS,
    PF_RESOURCES
    );

  TParserFlags = set of TParserFlag;

  TPEImageKind = (
    PEIMAGE_KIND_DISK,
    PEIMAGE_KIND_MEMORY
    );

  TPEImageObject = TObject; // Meant to cast TObject -> TPEImage

  TParserOption = (
    // If section vsize is 0 try to use rsize instead.
    PO_SECTION_VSIZE_FALLBACK,

    // Rename non-alphanumeric section names.
    PO_SECTION_AUTORENAME_NON_ALPHANUMERIC,

    // If data directory is invalid directory RVA and Size nulled.
    PO_NULL_INVALID_DIRECTORY
    );

  TParserOptions = set of TParserOption;

const
  MAX_PATH_WIN = 260;

  SUSPICIOUS_MIN_LIMIT_EXPORTS = $10000;
  DEFAULT_SECTOR_SIZE          = 512;
  DEFAULT_PAGE_SIZE            = 4096;

  ALL_PARSER_FLAGS = [PF_EXPORT, PF_IMPORT, PF_IMPORT_DELAYED, PF_RELOCS,
    PF_TLS, PF_RESOURCES];

  DEFAULT_PARSER_FLAGS = ALL_PARSER_FLAGS;

  DEFAULT_OPTIONS      = [
     PO_SECTION_VSIZE_FALLBACK,

  // This is disabled by default because now it can reject good names, like
  // .text, .data. In future this option must be either removed or reworked.
  // PO_SECTION_AUTORENAME_NON_ALPHANUMERIC,

     PO_NULL_INVALID_DIRECTORY
    ];

  // Data directories.
  DDIR_EXPORT           = 0;
  DDIR_IMPORT           = 1;
  DDIR_RESOURCE         = 2;
  DDIR_EXCEPTION        = 3;
  DDIR_CERTIFICATE      = 4;
  DDIR_RELOCATION       = 5;
  DDIR_DEBUG            = 6;
  DDIR_ARCHITECTURE     = 7;
  DDIR_GLOBALPTR        = 8;
  DDIR_TLS              = 9;
  DDIR_LOADCONFIG       = 10;
  DDIR_BOUNDIMPORT      = 11;
  DDIR_IAT              = 12;
  DDIR_DELAYIMPORT      = 13;
  DDIR_CLRRUNTIMEHEADER = 14;

  DDIR_LAST = 14;

type
  TParserResult = (PR_OK, PR_ERROR, PR_SUSPICIOUS);

  { Overlay }

type
  TOverlay = packed record
    Offset: TFileOffset;
    Size: UInt64;
  end;

  POverlay = ^TOverlay;

{$SCOPEDENUMS ON}
  TEndianness = (Little, Big);
{$SCOPEDENUMS OFF}


const
  SCategoryLoadFromFile = 'LoadFromFile';
  SCategoryDOSHeader    = 'DOS Header';
  SCategorySections     = 'Sections';
  SCategoryDataDirecory = 'Data Directories';
  SCategoryResources    = 'Resources';
  SCategoryImports      = 'Imports';
  SCategoryTLS          = 'TLS';
  SCategoryRelocs       = 'Relocs';


// -----
// by oranke
type
  TStringSplitOptions = (None, ExcludeEmpty);

  { TMyStringHelper }

  TMyStringHelper = record helper for string
  private type
    TSplitKind = (StringSeparatorNoQuoted, StringSeparatorQuoted, CharSeparatorNoQuoted, CharSeparatorQuoted);
  private
    function IndexOfAny(const Values: array of string; var Index: Integer; StartIndex: Integer): Integer; overload;
    function IndexOfAnyUnquoted(const Values: array of string; StartQuote, EndQuote: Char; var Index: Integer; StartIndex: Integer): Integer; overload;
    function IndexOfQuoted(const Value: string; StartQuote, EndQuote: Char; StartIndex: Integer): Integer; overload;
    function InternalSplit(SplitType: TSplitKind; const SeparatorC: array of Char; const SeparatorS: array of string;
      QuoteStart, QuoteEnd: Char; Count: Integer; Options: TStringSplitOptions): TArray<string>;
    function GetChars(Index: Integer): Char;
    function GetLength: Integer;
  public
    const Empty = '';

    function IsEmpty: Boolean;
    function IndexOf(const Value: string; StartIndex: Integer): Integer; overload;

    function IndexOfAny(const AnyOf: array of Char): Integer; overload;
    function IndexOfAny(const AnyOf: array of Char; StartIndex: Integer): Integer; overload;
    function IndexOfAny(const AnyOf: array of Char; StartIndex: Integer; Count: Integer): Integer; overload;

    function IndexOfAnyUnquoted(const AnyOf: array of Char; StartQuote, EndQuote: Char): Integer; overload;
    function IndexOfAnyUnquoted(const AnyOf: array of Char; StartQuote, EndQuote: Char; StartIndex: Integer): Integer; overload;
    function IndexOfAnyUnquoted(const AnyOf: array of Char; StartQuote, EndQuote: Char; StartIndex: Integer; Count: Integer): Integer; overload;

    function Substring(StartIndex: Integer): string; overload;
    function Substring(StartIndex: Integer; Length: Integer): string; overload;
    function Split(const Separator: array of Char): TArray<string>; overload;
    function Split(const Separator: array of Char; Count: Integer; Options: TStringSplitOptions): TArray<string>; overload;

    class function EndsText(const ASubText, AText: string): Boolean; static;

    function StartsWith(const Value: string): Boolean; overload; inline;
    function StartsWith(const Value: string; IgnoreCase: Boolean): Boolean; overload;

    function EndsWith(const Value: string): Boolean; overload; inline;
    function EndsWith(const Value: string; IgnoreCase: Boolean): Boolean; overload;


    property Chars[Index: Integer]: Char read GetChars;
    property Length: Integer read GetLength;
  end;


implementation

{ TMyStringHelper }

function TMyStringHelper.IndexOfAny(const Values: array of string;
  var Index: Integer; StartIndex: Integer): Integer;
var
  C, P, IoA: Integer;
begin
  IoA := -1;
  for C := 0 to High(Values) do
  begin
    P := IndexOf(Values[C], StartIndex);
    if (P >= 0) and((P < IoA) or (IoA = -1)) then
    begin
      IoA := P;
      Index := C;
    end;
  end;
  Result := IoA;
end;




function TMyStringHelper.IndexOfAnyUnquoted(const Values: array of string;
  StartQuote, EndQuote: Char; var Index: Integer; StartIndex: Integer): Integer;
var
  C, P, IoA: Integer;
begin
  IoA := -1;
  for C := 0 to High(Values) do
  begin
    P := IndexOfQuoted(Values[C], StartQuote, EndQuote, StartIndex);
    if (P >= 0) and((P < IoA) or (IoA = -1)) then
    begin
      IoA := P;
      Index := C;
    end;
  end;
  Result := IoA;
end;

function TMyStringHelper.IndexOfQuoted(const Value: string; StartQuote,
  EndQuote: Char; StartIndex: Integer): Integer;
var
  I, LIterCnt, L, J: Integer;
  PSubStr, PS: PWideChar;
  LInQuote: Integer;
  LInQuoteBool: Boolean;
begin
  L := Value.Length;
  LIterCnt := Self.Length - StartIndex - L + 1;

  if (StartIndex >= 0) and (LIterCnt >= 0) and (L > 0) then
  begin
    PSubStr := PWideChar(Value);
    PS := PWideChar(Self);
    Inc(PS, StartIndex);

    if StartQuote <> EndQuote then
    begin
      LInQuote := 0;

      for I := 0 to LIterCnt do
      begin
        J := 0;
        while (J >= 0) and (J < L) do
        begin
          if PS[I + J] = StartQuote then
            Inc(LInQuote)
          else
            if PS[I + J] = EndQuote then
              Dec(LInQuote);

          if LInQuote > 0 then
            J := -1
          else
          begin
            if PS[I + J] = PSubStr[J] then
              Inc(J)
            else
              J := -1;
          end;
        end;
        if J >= L then
          Exit(I + StartIndex);
      end;
    end
    else
    begin
      LInQuoteBool := False;
      for I := 0 to LIterCnt do
      begin
        J := 0;
        while (J >= 0) and (J < L) do
        begin
          if PS[I + J] = StartQuote then
            LInQuoteBool := not LInQuoteBool;

          if LInQuoteBool then
            J := -1
          else
          begin
            if PS[I + J] = PSubStr[J] then
              Inc(J)
            else
              J := -1;
          end;
        end;
        if J >= L then
          Exit(I + StartIndex);
      end;
    end;
  end;

  Result := -1;
end;


function TMyStringHelper.InternalSplit(SplitType: TSplitKind;
  const SeparatorC: array of Char; const SeparatorS: array of string;
  QuoteStart, QuoteEnd: Char; Count: Integer;
  Options: TStringSplitOptions): TArray<string>;
const
  DeltaGrow = 32;
var
  NextSeparator, LastIndex: Integer;
  Total: Integer;
  CurrentLength: Integer;
  SeparatorIndex: Integer;
  S: string;
begin
  Total := 0;
  LastIndex := 0;
  NextSeparator := -1;
  CurrentLength := 0;
  SeparatorIndex := 0;
  case SplitType of
    TSplitKind.StringSeparatorNoQuoted: NextSeparator := IndexOfAny(SeparatorS, SeparatorIndex, LastIndex);
    TSplitKind.StringSeparatorQuoted: NextSeparator := IndexOfAnyUnquoted(SeparatorS, QuoteStart, QuoteEnd, SeparatorIndex, LastIndex);
    TSplitKind.CharSeparatorNoQuoted: NextSeparator := IndexOfAny(SeparatorC, LastIndex);
    TSplitKind.CharSeparatorQuoted: NextSeparator := IndexOfAnyUnquoted(SeparatorC, QuoteStart, QuoteEnd, LastIndex);
  end;
  while (NextSeparator >= 0) and (Total < Count) do
  begin
    S := Substring(LastIndex, NextSeparator - LastIndex);
    if (S <> '') or ((S = '') and (Options <> ExcludeEmpty)) then
    begin
      Inc(Total);
      if CurrentLength < Total then
      begin
        CurrentLength := Total + DeltaGrow;
        SetLength(Result, CurrentLength);
      end;
      Result[Total - 1] := S;
    end;

    case SplitType of
      TSplitKind.StringSeparatorNoQuoted:
      begin
        LastIndex := NextSeparator + SeparatorS[SeparatorIndex].Length;
        NextSeparator := IndexOfAny(SeparatorS, SeparatorIndex, LastIndex);
      end;
      TSplitKind.StringSeparatorQuoted:
      begin
        LastIndex := NextSeparator + SeparatorS[SeparatorIndex].Length;
        NextSeparator := IndexOfAnyUnquoted(SeparatorS, QuoteStart, QuoteEnd, SeparatorIndex, LastIndex);
      end;
      TSplitKind.CharSeparatorNoQuoted:
      begin
        LastIndex := NextSeparator + 1;
        NextSeparator := IndexOfAny(SeparatorC, LastIndex);
      end;
      TSplitKind.CharSeparatorQuoted:
      begin
        LastIndex := NextSeparator + 1;
        NextSeparator := IndexOfAnyUnquoted(SeparatorC, QuoteStart, QuoteEnd, LastIndex);
      end;
    end;
  end;

  if (LastIndex < Self.Length) and (Total < Count) then
  begin
    Inc(Total);
    SetLength(Result, Total);
    Result[Total - 1] := Substring(LastIndex, Self.Length - LastIndex);
  end
  else
    SetLength(Result, Total);
end;

function TMyStringHelper.GetChars(Index: Integer): Char;
begin
  Result := Self[Index];
end;

function TMyStringHelper.GetLength: Integer;
begin
  Result := System.Length(Self);
end;


function Pos2(const SubStr, Str: String; Offset: Integer): Integer; overload;
var
  I, LIterCnt, L, J: Integer;
  PSubStr, PS: PChar;
begin
  L := Length(SubStr);
  { Calculate the number of possible iterations. Not valid if Offset < 1. }
  LIterCnt := Length(Str) - Offset - L + 1;

  { Only continue if the number of iterations is positive or zero (there is space to check) }
  if (Offset > 0) and (LIterCnt >= 0) and (L > 0) then
  begin
    PSubStr := PChar(SubStr);
    PS := PChar(Str);
    Inc(PS, Offset - 1);

    for I := 0 to LIterCnt do
    begin
      J := 0;
      while (J >= 0) and (J < L) do
      begin
        if PS[I + J] = PSubStr[J] then
          Inc(J)
        else
          J := -1;
      end;
      if J >= L then
        Exit(I + Offset);
    end;
  end;

  Result := 0;
end;

function TMyStringHelper.IsEmpty: Boolean;
begin
  Result := Self = Empty;
end;

function TMyStringHelper.IndexOf(const Value: string;
  StartIndex: Integer): Integer;
begin
  //Result := System.Pos(Value, Self, StartIndex + 1) - 1;
  Result := Pos2(Value, Self, StartIndex + 1) - 1;
end;

function TMyStringHelper.IndexOfAny(const AnyOf: array of Char): Integer;
begin
  Result := IndexOfAny(AnyOf, 0, Self.Length);
end;

function TMyStringHelper.IndexOfAny(const AnyOf: array of Char;
  StartIndex: Integer): Integer;
begin
  Result := IndexOfAny(AnyOf, StartIndex, Self.Length);
end;

function TMyStringHelper.IndexOfAny(const AnyOf: array of Char;
  StartIndex: Integer; Count: Integer): Integer;
var
  I: Integer;
  C: Char;
  Max: Integer;
begin
  if (StartIndex + Count) >= Self.Length then
    Max := Self.Length
  else
    Max := StartIndex + Count;

  I := StartIndex;
  while I < Max do
  begin
    for C in AnyOf do
      if Self[I] = C then
        Exit(I);
    Inc(I);
  end;
  Result := -1;
end;

function TMyStringHelper.IndexOfAnyUnquoted(const AnyOf: array of Char;
  StartQuote, EndQuote: Char): Integer;
begin
  Result := IndexOfAnyUnquoted(AnyOf, StartQuote, EndQuote, 0, Self.Length);
end;

function TMyStringHelper.IndexOfAnyUnquoted(const AnyOf: array of Char;
  StartQuote, EndQuote: Char; StartIndex: Integer): Integer;
begin
  Result := IndexOfAnyUnquoted(AnyOf, StartQuote, EndQuote, StartIndex, Self.Length);
end;

function TMyStringHelper.IndexOfAnyUnquoted(const AnyOf: array of Char;
  StartQuote, EndQuote: Char; StartIndex: Integer; Count: Integer): Integer;
var
  I: Integer;
  C: Char;
  Max: Integer;
  LInQuote: Integer;
  LInQuoteBool: Boolean;
begin
  if (StartIndex + Count) >= Length then
    Max := Length
  else
    Max := StartIndex + Count;

  I := StartIndex;
  if StartQuote <> EndQuote then
  begin
    LInQuote := 0;
    while I < Max do
    begin
      if Self[I] = StartQuote then
        Inc(LInQuote)
      else
        if (Self[I] = EndQuote) and (LInQuote > 0) then
          Dec(LInQuote);

      if LInQuote = 0 then
        for C in AnyOf do
          if Self[I] = C then
            Exit(I);
      Inc(I);
    end;
  end
  else
  begin
    LInQuoteBool := False;
    while I < Max do
    begin
      if Self[I] = StartQuote then
        LInQuoteBool := not LInQuoteBool;

      if not LInQuoteBool then
        for C in AnyOf do
          if Self[I] = C then
            Exit(I);
      Inc(I);
    end;
  end;
  Result := -1;
end;

function TMyStringHelper.Substring(StartIndex: Integer): string;
begin
  Result := System.Copy(Self, StartIndex + 1, Self.Length);
end;

function TMyStringHelper.Substring(StartIndex: Integer; Length: Integer
  ): string;
begin
  Result := System.Copy(Self, StartIndex + 1, Length);
end;


function TMyStringHelper.Split(const Separator: array of Char): TArray<string>;
begin
  Result := Split(Separator, MaxInt, None);
end;

function TMyStringHelper.Split(const Separator: array of Char; Count: Integer;
  Options: TStringSplitOptions): TArray<string>;
begin
  Result := InternalSplit(TSplitKind.CharSeparatorNoQuoted, Separator, [], Char(0), Char(0), Count, Options);
end;

class function TMyStringHelper.EndsText(const ASubText, AText: string): Boolean;
var
  SubTextLocation: Integer;
begin
  SubTextLocation := AText.Length - ASubText.Length;
  if (SubTextLocation >= 0) and (ASubText <> '') then //and
     //(ByteType(AText, SubTextLocation) <> mbTrailByte) then
    Result := //AnsiStrIComp(PChar(ASubText), PChar(@AText[SubTextLocation])) = 0
            (
              CompareText(PChar(ASubText),PChar(@AText[SubTextLocation])) = 0
            )
  else
    Result := False;
end;

function TMyStringHelper.StartsWith(const Value: string): Boolean;
begin
  Result := StartsWith(Value, False);
end;

function StrLComp(const Str1, Str2: PChar; MaxLen: Cardinal): Integer;
var
  I: Cardinal;
  P1, P2: PChar;
begin
  P1 := Str1;
  P2 := Str2;
  I := 0;
  while I < MaxLen do
  begin
    if (P1^ <> P2^) or (P1^ = #0) then
      Exit(Ord(P1^) - Ord(P2^));

    Inc(P1);
    Inc(P2);
    Inc(I);
  end;
  Result := 0;
end;

function StrLIComp(const Str1, Str2: PChar; MaxLen: Cardinal): Integer;
var
  P1, P2: PChar;
  I: Cardinal;
  C1, C2: Char;
begin
  P1 := Str1;
  P2 := Str2;
  I := 0;
  while I < MaxLen do
  begin
    if P1^ in ['a'..'z'] then
      C1 := Char(Byte(P1^) xor $20)
    else
      C1 := P1^;

    if P2^ in ['a'..'z'] then
      C2 := Char(Byte(P2^) xor $20)
    else
      C2 := P2^;

    if (C1 <> C2) or (C1 = #0) then
      Exit(Ord(C1) - Ord(C2));

    Inc(P1);
    Inc(P2);
    Inc(I);
  end;
  Result := 0;
end;


function TMyStringHelper.StartsWith(const Value: string; IgnoreCase: Boolean
  ): Boolean;
begin
  if Value = '' then
    Result := False
  else
    if not IgnoreCase then
      Result := StrLComp(PChar(Self), PChar(Value), Value.Length) = 0
    else
      Result := StrLIComp(PChar(Self), PChar(Value), Value.Length) = 0;
end;


function TMyStringHelper.EndsWith(const Value: string): Boolean;
begin
  Result := EndsWith(Value, False);
end;

//type
  //TMbcsByteType = (mbSingleByte, mbLeadByte, mbTrailByte);

function TMyStringHelper.EndsWith(const Value: string;
  IgnoreCase: Boolean): Boolean;
//var
  //SubTextLocation: Integer;
begin
  //if IgnoreCase then
      Result := EndsText(Value, Self)
  //else
  //begin
  {
    SubTextLocation := Self.Length - Value.Length;
    if (SubTextLocation >= 0) and (Value <> Empty) then //and
       (//ByteType2(Self, SubTextLocation) <> mbTrailByte) then
      Result := string.Compare(Value, 0, Self, SubTextLocation, Value.Length, []) = 0
    else
      Result := False;
  end;
  }
end;


end.
