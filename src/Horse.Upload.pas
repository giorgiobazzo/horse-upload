unit Horse.Upload;

interface

uses System.SysUtils, Horse, System.Classes;

type

  TUploadConfig = class
  private
    FStorePath: string;
    FForceDir:Boolean;
    FOverrideFiles:Boolean;
  public
    //Path where files will be stored on server
    property StorePath: string read FStorePath write FStorePath;
    //Creates the path if it doesn't exist
    property ForceDir: Boolean read FForceDir write FForceDir default True;
    //If true it replaces existing files.
    //If false, it automatically increments the file name. Ex: file.txt, file_1.txt, file_2.txt ......
    property OverrideFiles: Boolean read FOverrideFiles write FOverrideFiles default False;
    constructor Create(AStorePath: string);
  end;

  procedure Upload(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

uses
  Web.HTTPApp, System.Math, Web.ReqMulti, System.JSON, IdHashMessageDigest,
  System.IOUtils;

type

  TMultipartContentParserAccess = class(TMultipartContentParser);

function MD5FromStream(AStream:TStream):string;
var
 LIdmd5 : TIdHashMessageDigest5;
begin
  LIdmd5 := TIdHashMessageDigest5.Create;
  try
    Result := LowerCase(LIdmd5.HashStreamAsHex(AStream));
  finally
    LIdmd5.Free;
  end;
end;

{Credits for:
David Heffernan
https://stackoverflow.com/questions/28220015/function-to-increment-filename}
procedure DecodeFileName(const AFileName: string; out Stem, Ext: string; out Number: Integer);
var
  P: Integer;
begin
  Ext := TPath.GetExtension(AFileName);
  Stem := TPath.GetFileNameWithoutExtension(AFileName);
  Number := 0;

  P := Stem.LastIndexOf('_');
  if P = -1 then
    Exit;

  if TryStrToInt(Stem.Substring(P+1), Number) then
    Stem := Stem.Substring(0, P);

end;

function IncrementedFileName(const AFileName: string): string;
var
  Stem, Ext: string;
  Number: Integer;
begin
  DecodeFileName(AFileName, Stem, Ext, Number);
  Result := Format('%s_%d%s', [Stem, Number+1, Ext]);
end;

function AvailableFileName(const AFileName: string):string;
var LPath : string;
begin
  Result := AFileName;
  if not TFile.Exists(Result) then
    Exit;
  LPath := ExtractFilePath(Result);
  while TFile.Exists(Result) do
    Result := TPath.Combine(LPath,IncrementedFileName(Result));
end;

function ProcessUploads(AWebRequest : TWebRequest; AConfig:TUploadConfig):string;
var
  I : Integer;
  LFilesCount : Integer;
  LFiles : TAbstractWebRequestFiles;
  LFile  : TAbstractWebRequestFile;
  LStream: TFileStream;
  LMpReq : TMultipartContentParserAccess;

  LJsResp       : TJSONObject;
  LJsRespFiles  : TJSONArray;
  LJsFile       : TJSONObject;
  LFilesOK      : Integer;
  LUploadResponse : string;
  LLocalFilePath : string;
begin
  LFilesOK        := 0;
  LUploadResponse := '';

  if not AConfig.StorePath.IsEmpty and AConfig.ForceDir then
    TDirectory.CreateDirectory(AConfig.FStorePath);

  if not AConfig.StorePath.IsEmpty then
    if not TDirectory.Exists(AConfig.StorePath) then
      raise Exception.Create('The specified StorePath does not exist');

  if TMultipartContentParserAccess.CanParse(AWebRequest) then
  begin
    LMpReq := TMultipartContentParserAccess.Create(AWebRequest);
    LFiles := LMpReq.GetFiles;
    LFilesCount := LFiles.Count;

    LJsResp       := TJSONObject.Create;
    LJsRespFiles  := TJSONArray.Create;
    try
      LJsResp.AddPair(TJSONPair.Create('upload_files_request',TJSONNumber.Create(LFilesCount)));
      try
        for I := 0 to Pred(LFilesCount) do
        begin
          LJsFile := TJSONObject.Create;
          try
            LFile := LFiles[I];

            LLocalFilePath := TPath.Combine(AConfig.StorePath, LFile.FileName);
            if not AConfig.OverrideFiles then
            begin
              LLocalFilePath := AvailableFileName(LLocalFilePath);
              LLocalFilePath := TPath.Combine(AConfig.StorePath, LLocalFilePath);
            end;

            LJsFile.AddPair('filename',TJSONString.Create(ExtractFileName(LLocalFilePath)));
            LJsFile.AddPair('size',TJSONNumber.Create(LFile.Stream.Size));
            LJsFile.AddPair('md5', MD5FromStream(LFile.Stream));

            LStream := TFileStream.Create(LLocalFilePath, fmCreate);
            try
              LFile.Stream.Position := 0;
              LStream.CopyFrom(LFile.Stream, LFile.Stream.Size);
              LJsFile.AddPair('status',TJSONString.Create('ok'));
              Inc(LFilesOK);
            finally
              LStream.Free;
            end;
          except
            on E:Exception do
            begin
              LJsFile.AddPair('status',TJSONString.Create(e.Message));
            end;
          end;
          LJsRespFiles.AddElement(LJsFile);
        end;
      finally
        LMpReq.Free;
        LJsResp.AddPair('files',LJsRespFiles);
        LJsResp.AddPair(TJSONPair.Create('uploaded_files',TJSONNumber.Create(LFilesOK)));
        LUploadResponse := LJsResp.ToJSON;
      end;
    finally
      LJsResp.Free;
    end;
  end;
  Result := LUploadResponse;
end;

procedure Upload(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LWebRequest: TWebRequest;
  LWebResponse: TWebResponse;
  LContent: TObject;
  LUploadConfg : TUploadConfig;
begin
  LWebRequest := THorseHackRequest(Req).GetWebRequest;

  Next;

  LWebResponse := THorseHackResponse(Res).GetWebResponse;
  LContent := THorseHackResponse(Res).GetContent;

  if Assigned(LContent) and LContent.InheritsFrom(TUploadConfig) then
  begin
    LUploadConfg := TUploadConfig(LContent);
    LWebResponse.Content := ProcessUploads(LWebRequest,LUploadConfg);
    LWebResponse.SendResponse;
  end;
end;

{ TUploadResponse }

constructor TUploadConfig.Create(AStorePath: string);
begin
  FStorePath := AStorePath;
  FForceDir := True;
  FOverrideFiles := False;
end;

end.
