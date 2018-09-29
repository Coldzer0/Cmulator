unit PsePeLoader;

interface

uses
  Classes, PseImgLoader, PseSection, PseVirtMem;

type
  TPsePeLoader = class(TPseImgLoader)
  private
    procedure LoadSection(AMem: TPseVirtMem; ASection: TPseSection);
  public
    procedure Load(AMem: TPseVirtMem); override;
  end;

implementation

procedure TPsePeLoader.Load(AMem: TPseVirtMem);
var
  i: integer;
begin
  for i := 0 to FFile.Sections.Count - 1 do begin
    LoadSection(AMem, FFile.Sections[i]);
  end;
end;

procedure TPsePeLoader.LoadSection(AMem: TPseVirtMem; ASection: TPseSection);
var
  seg: TPseMemSegment;
  flags: TPseMemFlags;
  ms: TMemoryStream;
begin
  flags := [];
  if (saReadable in ASection.Attribs) then
    Include(flags, pmfRead);
  if (saWriteable in ASection.Attribs) then
    Include(flags, pmfWrite);
  if (saExecuteable in ASection.Attribs) then
    Include(flags, pmfExecute);
  if flags <> [] then begin
    seg := AMem.CreateSegment(ASection.Name, ASection.Address,
      ASection.Size, [pmfWrite]);
    ms := TMemoryStream.Create;
    try
      ASection.SaveToStream(ms);
      ms.Position := 0;
      seg.Write(ASection.Address, ms.Memory^, ASection.Size);
    finally
      ms.Free;
    end;
    seg.Flags := flags;
  end;
end;

end.
