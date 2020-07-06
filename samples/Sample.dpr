program Sample;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Horse, Horse.Upload;

var
  App: THorse;

begin
  App := THorse.Create(9000);

  App.Use(Upload);

  //In Client-side upload can be easily tested using the curl command line utility. Ex:
  //curl -F "files[]=@C:\MyFiles\Doc.pdf" -F "files[]=@C:\MyFiles\Image.jpg" http://localhost:9000/upload

  App.Post('/upload',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      LUploadConfig : TUploadConfig;
    begin
      LUploadConfig := TUploadConfig.Create('c:\serverfiles');
      LUploadConfig.ForceDir := True;
      LUploadConfig.OverrideFiles := True;
      Res.Send<TUploadConfig>(LUploadConfig);
    end);

  App.Start;

end.
