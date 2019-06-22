{***************************************************************************************************

  Zydis Top Level API

  Original Author : Florian Bernd

 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.

***************************************************************************************************}

unit Zydis.Exception;

interface

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  {$IFNDEF FPC}System.SysUtils{$ELSE}SysUtils{$ENDIF}, Zydis;

type
  TZydisException = class(Exception)
  strict private
    FStatus: TZydisStatus;
  public
    class procedure RaiseException(Status: TZydisStatus); inline;
  public
    property Status: TZydisStatus read FStatus write FStatus;
  end;

implementation

{ TZydisException }

class procedure TZydisException.RaiseException(Status: TZydisStatus);
var
  E: TZydisException;
begin
  E := TZydisException.CreateFmt('Zydis exception. Status code: %2x', [Ord(Status)]);
  E.Status := Status;
  raise E;
end;

end.
