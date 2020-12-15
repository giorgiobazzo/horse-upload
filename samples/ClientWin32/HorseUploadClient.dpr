program HorseUploadClient;

uses
  Vcl.Forms,
  Main in 'Main.pas' {fmUpload};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmUpload, fmUpload);
  Application.Run;
end.
