unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfmUpload = class(TForm)
    btnUpload: TButton;
    edtFile: TEdit;
    foUpload: TFileOpenDialog;
    edtUploadEndPoint: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    edtResponse: TMemo;
    btnOpenFile: TButton;
    procedure btnUploadClick(Sender: TObject);
    procedure btnOpenFileClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmUpload: TfmUpload;

implementation

uses IdHTTP,IdMultipartFormData;

{$R *.dfm}

procedure TfmUpload.btnUploadClick(Sender: TObject);
var
  LIdHTTP: TIdHTTP;
  LParams: TIdMultiPartFormDataStream;
  LResponse: string;
begin
  if FileExists(edtFile.Text) then
  begin
    LParams := TIdMultiPartFormDataStream.Create;
    LIdHTTP := TIdHTTP.Create(nil);
    try
      LParams.AddFile('file', edtFile.Text, '');
      LIdHTTP.ReadTimeout := 30000;
      LIdHTTP.ConnectTimeout := 30000;
      LResponse := LIdHTTP.Post(edtUploadEndPoint.Text, LParams);
      edtResponse.Lines.Text := LResponse;
    finally
      FreeAndNil(LIdHTTP);
      FreeAndNil(LParams);
    end;
  end;
end;

procedure TfmUpload.btnOpenFileClick(Sender: TObject);
begin
  if foUpload.Execute then
    edtFile.Text := foUpload.FileName;
end;

end.
