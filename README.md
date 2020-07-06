# horse-upload
Middleware for upload files to server storege in HORSE

### For install in your project using [boss](https://github.com/HashLoad/boss):
``` sh
$ boss install github.com/giorgiobazzo/horse-upload
```

### Sample Horse Server with octet-stream middleware
```delphi
uses
  Horse, Horse.Upload;

var
  App: THorse;

begin
  App := THorse.Create(9000);
  
  App.Use(Upload);
  
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
```
