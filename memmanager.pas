unit MemManager;

{$mode delphi}

interface

uses
  Classes, SysUtils,
  Generics.Collections,Generics.Defaults,
  Unicorn_dyn, UnicornConst,Utils,
  QuickJS;

  type
    TMemory = record
      RealPtr : Pointer;
      Base    : Int64;
      size    : UInt64;
      perms   : UInt32;
      IsFree  : Boolean;
    end;
    { TCmuMemoryManager }
    TCmuMemoryManager = Class
    private
      uc : uc_engine;
      Status : THeapStatus; // Memory Status.
      Base_Address, // Base Address for Heap.
      CurrHeapUsed,
      CurrHeapSize,
      Size_limit  : Int64; // Max size of Heap.


      Heap : Generics.Collections.TList<TMemory>;
    public
      constructor Create(uc : uc_engine; BaseAddress, SizeLimit : Int64);
      function GetHeapStatus : THeapStatus;
      function GetPrems(HPtr : Int64) : UInt32;
      function Alloc(Size : Int64; perms : UInt32) : Int64;
    end;

implementation
  uses
    Globals;

{ TCmuMemoryManager }

constructor TCmuMemoryManager.Create(uc : uc_engine;
  BaseAddress, SizeLimit : Int64);
begin
  Self.Heap := Generics.Collections.TList<TMemory>.Create; // init heap list.
  Self.Base_Address := BaseAddress;
  Self.Size_limit := SizeLimit;
  Self.CurrHeapUsed := 0;
  Self.CurrHeapSize := SizeLimit;
  Self.uc := uc;
  FillByte(Status,SizeOf(Status),0);
end;

function TCmuMemoryManager.GetHeapStatus : THeapStatus;
begin
  FillByte(Status,SizeOf(result),0);
  result.TotalAllocated   := CurrHeapUsed;
  result.TotalFree        := CurrHeapSize - CurrHeapUsed;
  result.TotalAddrSpace   := CurrHeapSize;
  result.TotalUncommitted := 0;
  result.TotalCommitted   := 0;
  result.Unused           := 0;
  result.Overhead         := 0;
  result.HeapErrorCode    := 0;
end;

function TCmuMemoryManager.GetPrems(HPtr : Int64) : UInt32;
begin
  Result := 0;
end;

function TCmuMemoryManager.Alloc(Size : Int64; perms : UInt32) : Int64;
var
  item,MemItem : TMemory;
  LPtr : Pointer;

begin
  Result := 0;
  while Heap.GetEnumerator.MoveNext do
  begin
    if Heap.GetEnumerator.Current.IsFree and (Heap.GetEnumerator.Current.size >= Size) then
    begin
      item := Heap.GetEnumerator.Current;
      item.IsFree := False;
      Result := item.Base;
      Break;
    end;
  end;

  if Result = 0 then
  begin
    LPtr := AllocMem(Size);
    if LPtr <> nil then
    begin
      Emulator.err := uc_mem_map_ptr(uc, Result, UC_PAGE_SIZE, UC_PROT_ALL,LPtr);
      if Emulator.err = UC_ERR_OK then
      begin
        item.Base := Result;
      end
      else
      begin

      end;
    end;
  end;
end;


end.
