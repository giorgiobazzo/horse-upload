# horse-upload
Middleware for upload files to server storege in HORSE

### Official Horse Repository:
https://github.com/HashLoad/horse

### For install in your project using [boss](https://github.com/HashLoad/boss):
``` sh
$ boss install github.com/giorgiobazzo/horse-upload
```

### Supports:
 - Multipart/form-data Content-Type request
 - Upload multiple files in the same request
 - Server-side path settings

### Sample Horse Server with upload middleware
```delphi
uses Horse, Horse.Upload, System.SysUtils;

begin
  THorse.Use(Upload);

  THorse.Post('/upload',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      LUploadConfig: TUploadConfig;
    begin
      LUploadConfig := TUploadConfig.Create('c:\serverfiles');
      LUploadConfig.ForceDir := True;
      LUploadConfig.OverrideFiles := True;

      //Optional: Callback for each file received
      LUploadConfig.UploadFileCallBack :=
        procedure(Sender: TObject; AFile: TUploadFileInfo)
        begin
          Writeln('');
          Writeln('Upload file: ' + AFile.filename + ' ' + AFile.size.ToString);
        end;

      //Optional: Callback on end of all files
      LUploadConfig.UploadsFishCallBack :=
        procedure(Sender: TObject; AFiles: TUploadFiles)
        begin
          Writeln('');
          Writeln('Finish ' + AFiles.Count.ToString + ' files.');
        end;

      Res.Send<TUploadConfig>(LUploadConfig);
    end);

  THorse.Listen;
end.
```
### In Client-side upload can be easily tested using the curl command line utility. Ex:
```
curl -F "files[]=@C:\MyFiles\Doc.pdf" -F "files[]=@C:\MyFiles\Image.jpg" http://localhost:9000/upload
```
### Settings (TUploadConfig)
 - StorePath : Path where files will be stored on server.
 - ForceDir : Creates the path if it doesn't exist.
 - OverrideFiles : If true it replaces existing files. If false, automatically increments the file name. Ex: file.txt, file_1.txt, file_2.txt ......

