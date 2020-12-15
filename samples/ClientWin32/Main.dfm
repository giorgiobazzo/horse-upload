object fmUpload: TfmUpload
  Left = 0
  Top = 0
  Caption = 'Upload Test'
  ClientHeight = 295
  ClientWidth = 499
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 7
    Width = 78
    Height = 13
    Caption = 'Upload EndPoint'
  end
  object Label2: TLabel
    Left = 8
    Top = 50
    Width = 52
    Height = 13
    Caption = 'Upload File'
  end
  object Label3: TLabel
    Left = 8
    Top = 93
    Width = 47
    Height = 13
    Caption = 'Response'
  end
  object btnUpload: TButton
    Left = 407
    Top = 109
    Width = 75
    Height = 25
    Caption = 'Upload'
    TabOrder = 0
    OnClick = btnUploadClick
  end
  object edtFile: TEdit
    Left = 8
    Top = 66
    Width = 393
    Height = 21
    TabOrder = 1
  end
  object edtUploadEndPoint: TEdit
    Left = 8
    Top = 23
    Width = 393
    Height = 21
    TabOrder = 2
    Text = 'http://127.0.0.1:9000/upload'
  end
  object edtResponse: TMemo
    Left = 8
    Top = 109
    Width = 393
    Height = 172
    TabOrder = 3
  end
  object btnOpenFile: TButton
    Left = 407
    Top = 62
    Width = 75
    Height = 25
    Caption = 'File...'
    TabOrder = 4
    OnClick = btnOpenFileClick
  end
  object foUpload: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Left = 432
    Top = 24
  end
end
