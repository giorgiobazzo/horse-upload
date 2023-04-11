unit Horse.Upload;

interface

uses System.SysUtils, Horse, System.Classes,System.JSON;

type
  TUploadFileInfo = record
    filename: string;
    fullpath: string;
    size: Int64;
    md5: string;
    status: string;
    procedure Clear;
  end;

  TUploadFiles = TArray<TUploadFileInfo>;

  TUploadFilesHelper = record helper for TUploadFiles
    function toJsonArray(AWithFullpath: Boolean = True): TJSONArray;
    function toJsonString: string;
    procedure Clear;
    function Add(AUploadFileInfo: TUploadFileInfo):Integer;
    function Count: Integer;
  end;

  TUploadFileCallBack = reference to procedure(Sender: TObject; AFile: TUploadFileInfo);
  TUploadsFishCallBack = reference to procedure(Sender: TObject; AFiles: TUploadFiles);

  TUploadConfig = class
  private
    FStorePath: string;
    FForceDir: Boolean;
    FOverrideFiles: Boolean;
    FUploadFileCallBack: TUploadFileCallBack;
    FUploadsFishCallBack: TUploadsFishCallBack;
    procedure DoUploadFileCallBack(AFile: TUploadFileInfo);
    procedure DoUploadsFishCallBack(AFiles: TUploadFiles);
  public
    constructor Create(AStorePath: string);
  public
    //Path where files will be stored on server
    property StorePath: string read FStorePath write FStorePath;
    //Creates the path if it doesn't exist
    property ForceDir: Boolean read FForceDir write FForceDir default True;
    //If true it replaces existing files.
    //If false, it automatically increments the file name. Ex: file.txt, file_1.txt, file_2.txt ......
    property OverrideFiles: Boolean read FOverrideFiles write FOverrideFiles default False;
    //Callback for each file received
    property UploadFileCallBack: TUploadFileCallBack read FUploadFileCallBack write FUploadFileCallBack;
    //Callback on end of all files
    property UploadsFishCallBack: TUploadsFishCallBack read FUploadsFishCallBack write FUploadsFishCallBack;
  end;

procedure Upload(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

uses Web.HTTPApp, System.Math, Web.ReqMulti, IdHashMessageDigest, System.IOUtils;

type
  TMultipartContentParserAccess = class(TMultipartContentParser);

function MD5FromStream(AStream:TStream):string;
var
 LIdmd5: TIdHashMessageDigest5;
begin
  LIdmd5:= TIdHashMessageDigest5.Create;
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

  if TryStrToInt(Stem.Substring(P + 1), Number) then
    Stem := Stem.Substring(0, P);
end;

function IncrementedFileName(const AFileName: string): string;
var
  Stem, Ext: string;
  Number: Integer;
begin
  DecodeFileName(AFileName, Stem, Ext, Number);
  Result := Format('%s_%d%s', [Stem, Number + 1, Ext]);
end;

function AvailableFileName(const AFileName: string): string;
var
  LPath: string;
begin
  Result := AFileName;
  if not TFile.Exists(Result) then
    Exit;
  LPath := ExtractFilePath(Result);
  while TFile.Exists(Result) do
    Result := TPath.Combine(LPath, IncrementedFileName(Result));
end;

function ProcessUploads(AWebRequest: TWebRequest; AConfig: TUploadConfig): string;
var
  I, LFilesCount, LFilesOK: Integer;
  LFiles : TAbstractWebRequestFiles;
  LFile: TAbstractWebRequestFile;
  LStream: TFileStream;
  LMpReq: TMultipartContentParserAccess;

  LJsResp: TJSONObject;
  LLocalFilePath, LUploadResponse: string;

  LUploadFiles: TUploadFiles;
  LUploadFileInfo: TUploadFileInfo;
begin
  LFilesOK := 0;
  LUploadResponse := '';
  LUploadFiles.Clear;

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

    LJsResp := TJSONObject.Create;
    try
      LJsResp.AddPair(TJSONPair.Create('upload_files_request', TJSONNumber.Create(LFilesCount)));
      try
        for I := 0 to Pred(LFilesCount) do
        begin
          try
            LUploadFileInfo.Clear;
            LFile := LFiles[I];

            LLocalFilePath := TPath.Combine(AConfig.StorePath, ExtractFileName(LFile.FileName));
            if not AConfig.OverrideFiles then
            begin
              LLocalFilePath := AvailableFileName(LLocalFilePath);
              LLocalFilePath := TPath.Combine(AConfig.StorePath, LLocalFilePath);
            end;

            LUploadFileInfo.filename := ExtractFileName(LLocalFilePath);
            LUploadFileInfo.fullpath := LLocalFilePath;
            LUploadFileInfo.size := LFile.Stream.Size;
            LUploadFileInfo.md5 := MD5FromStream(LFile.Stream);

            LStream := TFileStream.Create(LLocalFilePath, fmCreate);
            try
              LFile.Stream.Position := 0;
              LStream.CopyFrom(LFile.Stream, LFile.Stream.Size);
              LUploadFileInfo.status := 'ok';
              Inc(LFilesOK);
            finally
              LStream.Free;
            end;
          except
            on E: Exception do
              LUploadFileInfo.status := E.Message;
          end;
          LUploadFiles.Add(LUploadFileInfo);
          AConfig.DoUploadFileCallBack(LUploadFileInfo);
        end;
      finally
        AConfig.DoUploadsFishCallBack(LUploadFiles);
        LMpReq.Free;
        LJsResp.AddPair('files', LUploadFiles.toJsonArray(False));
        LJsResp.AddPair(TJSONPair.Create('uploaded_files', TJSONNumber.Create(LFilesOK)));
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
  LWebRequest := Req.RawWebRequest;

  Next;

  LWebResponse := Res.RawWebResponse;
  LContent := Res.Content;

  if Assigned(LContent) and LContent.InheritsFrom(TUploadConfig) then
  begin
    LUploadConfg := TUploadConfig(LContent);
    LWebResponse.Content := ProcessUploads(LWebRequest, LUploadConfg);
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

{ TUploadFilesHelper }

function TUploadFilesHelper.toJsonString: string;
var
  LJsArray: TJSONArray;
begin
  LJsArray := toJsonArray;
  try
    Result := LJsArray.ToJSON;
  finally
    LJsArray.Free;
  end;
end;

function TUploadFilesHelper.toJsonArray(AWithFullpath: Boolean = True): TJSONArray;
var
  LJsItem: TJSONObject;
  LFileInfo: TUploadFileInfo;
begin
  Result := TJSONArray.Create;
  for LFileInfo in Self do
  begin
    LJsItem := TJSONObject.Create;
    if AWithFullpath then
      LJsItem.AddPair('fullpath', TJSONString.Create(LFileInfo.fullpath));
    LJsItem.AddPair('filename', TJSONString.Create(LFileInfo.filename));
    LJsItem.AddPair('size', TJSONNumber.Create(LFileInfo.size));
    LJsItem.AddPair('md5', TJSONString.Create(LFileInfo.md5));
    LJsItem.AddPair('status', TJSONString.Create(LFileInfo.status));
    Result.AddElement(LJsItem);
  end;
end;

procedure TUploadFilesHelper.Clear;
begin
  SetLength(Self, 0);
end;

function TUploadFilesHelper.Add(AUploadFileInfo: TUploadFileInfo):Integer;
begin
  SetLength(Self, Length(Self) + 1);
  Self[High(Self)] := AUploadFileInfo;
  Result := High(Self);
end;

function TUploadFilesHelper.Count: Integer;
begin
  Result := Length(Self);
end;

{ TUploadFileInfo }

procedure TUploadFileInfo.Clear;
begin
  filename := '';
  fullpath := '';
  size := 0;
  md5 := '';
  status := '';
end;

{TUploadConfig}

procedure TUploadConfig.DoUploadFileCallBack(AFile: TUploadFileInfo);
begin
  if Assigned(FUploadFileCallBack) then
    FUploadFileCallBack(Self,AFile);
end;

procedure TUploadConfig.DoUploadsFishCallBack(AFiles: TUploadFiles);
begin
  if Assigned(FUploadsFishCallBack) then
    FUploadsFishCallBack(Self,AFiles);
end;

end.
