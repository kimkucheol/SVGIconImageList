{******************************************************************************}
{                                                                              }
{       SVG Image in TPicture: useful to show a Scalable Vector Graphic        }
{                                                                              }
{       Copyright (c) 2019-2020 (Ethea S.r.l.)                                 }
{       Author: Carlo Barazzetta                                               }
{       Contributors:                                                          }
{                                                                              }
{       https://github.com/EtheaDev/SVGIconImageList                           }
{                                                                              }
{******************************************************************************}
{       Original version (c) 2005, 2008 Martin Walter with license:            }
{       Use of this file is permitted for commercial and non-commercial        }
{       use, as long as the author is credited.                                }
{       home page: http://www.mwcs.de                                          }
{       email    : martin.walter@mwcs.de                                       }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}
unit SVGIconImage;

interface

{$INCLUDE SVGIconImageList.inc}

uses
  Winapi.Windows
  , Winapi.Messages
  , System.SysUtils
  , System.Types
{$IFDEF D10_4+}
  , System.UITypes
{$ENDIF}
  , System.Classes
  , Vcl.Controls
  , Vcl.Graphics
  , SVGInterfaces
  , SVGIconImageListBase;

type
  TSVGIconImage = class(TCustomControl)
  strict private
    FSVG: ISVG;
    FCenter: Boolean;
    FProportional: Boolean;
    FStretch: Boolean;
    FAutoSize: Boolean;
    FScale: Double;
    FOpacity: Byte;
    FFileName: TFileName;
    FImageList: TSVGIconImageListBase;
    FImageIndex: Integer;
    procedure SetCenter(Value: Boolean);
    procedure SetProportional(Value: Boolean);
    procedure SetOpacity(Value: Byte);
    procedure SetFileName(const Value: TFileName);
    //procedure ReadData(Stream: TStream);
    //procedure WriteData(Stream: TStream);
    procedure SetImageIndex(const Value: Integer);
    procedure SetStretch(const Value: Boolean);
    procedure SetScale(const Value: Double);
    procedure SetAutoSizeImage(const Value: Boolean);
  private
    function GetSVGText: string;
    procedure SetSVGText(const AValue: string);
    function StoreScale: Boolean;
    function UsingSVGText: Boolean;
    procedure SetImageList(const Value: TSVGIconImageListBase);
  protected
    procedure Paint; override;
    //procedure DefineProperties(Filer: TFiler); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CheckAutoSize;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    function Empty: Boolean;
    //procedure Paint; override;
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToFile(const FileName: string);
    procedure Assign(Source: TPersistent); override;
    property SVG: ISVG read FSVG;
  published
    property AutoSize: Boolean read FAutoSize write SetAutoSizeImage;
    property Center: Boolean read FCenter write SetCenter default True;
    property ParentDoubleBuffered;
    property DoubleBuffered;
    property Proportional: Boolean read FProportional write SetProportional;
    property Stretch: Boolean read FStretch write SetStretch default True;
    property Opacity: Byte read FOpacity write SetOpacity default 255;
    property Scale: Double read FScale write SetScale stored StoreScale;
    property FileName: TFileName read FFileName write SetFileName;
    property ImageList: TSVGIconImageListBase read FImageList write SetImageList;
    property ImageIndex: Integer read FImageIndex write SetImageIndex default -1;
    property SVGText: string read GetSVGText write SetSVGText stored UsingSVGText;
    property Enabled;
    property Visible;
    property Constraints;
    property Anchors;
    property Align;

    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;


  TSVGGraphic = class(TGraphic)
  strict private
    FSVG: ISVG;
    FOpacity: Byte;
    FFileName: TFileName;

    procedure SetOpacity(Value: Byte);
    procedure SetFileName(const Value: TFileName);
  protected
    procedure DefineProperties(Filer: TFiler); override;

    procedure Draw(ACanvas: TCanvas; const Rect: TRect); override;

    function GetEmpty: Boolean; override;
    function GetWidth: Integer; override;
    function GetHeight: Integer; override;
    procedure SetHeight(Value: Integer); override;
    procedure SetWidth(Value: Integer); override;

    procedure ReadData(Stream: TStream); override;
    procedure WriteData(Stream: TStream); override;
  public
    constructor Create; override;
    procedure Clear;

    procedure Assign(Source: TPersistent); override;
    procedure AssignTo(Dest: TPersistent); override;

    procedure AssignSVG(SVG: ISVG);

    procedure LoadFromFile(const Filename: String); override;
    procedure LoadFromStream(Stream: TStream); override;

    procedure SaveToStream(Stream: TStream); override;

    procedure LoadFromClipboardFormat(AFormat: Word; AData: THandle;
      APalette: HPALETTE); override;
    procedure SaveToClipboardFormat(var AFormat: Word; var AData: THandle;
      var APalette: HPALETTE); override;

    property Opacity: Byte read FOpacity write SetOpacity;
  published
    property FileName: TFileName read FFileName write SetFileName;
  end;

implementation

constructor TSVGIconImage.Create(AOwner: TComponent);
begin
  inherited;
  FSVG := GlobalSVGFactory.NewSvg;
  FProportional := False;
  FCenter := True;
  FStretch := True;
  FOpacity := 255;
  FScale := 1;
  FImageIndex := -1;
end;

destructor TSVGIconImage.Destroy;
begin
  inherited;
end;

procedure TSVGIconImage.CheckAutoSize;
begin
  if FAutoSize and (FSVG.Width > 0) and (FSVG.Height > 0) then
  begin
    SetBounds(Left, Top,  Round(FSVG.Width), Round(FSVG.Height));
  end;
end;

procedure TSVGIconImage.Clear;
begin
  FSVG.Clear;
  FFileName := '';
  Repaint;
end;

function TSVGIconImage.Empty: Boolean;
begin
  Empty := FSVG.IsEmpty;
end;

function TSVGIconImage.GetSVGText: string;
begin
  if not UsingSVGText then
    Result := FImageList.Images[FImageIndex].Source
  else
    Result := FSVG.Source;
end;

function TSVGIconImage.UsingSVGText: Boolean;
begin
  Result := not (Assigned(FImageList) and (FImageIndex >= 0) and
     (FImageIndex < FImagelist.Count));
end;

procedure TSVGIconImage.Paint;
var
  SVG: ISVG;
begin
  if not UsingSVGText then
    SVG := FImageList.Images[FImageIndex]
  else
    SVG := FSVG;

  if not SVG.IsEmpty then
  begin
    SVG.Opacity := FOpacity / 255;
    SVG.PaintTo(Canvas.Handle, TRectF.Create(TPointF.Create(0, 0), Width, Height), FProportional);
    SVG.Opacity := 1;
  end;

  if csDesigning in ComponentState then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Style := psDash;
    Canvas.Pen.Color := clBlack;
    Canvas.Rectangle(0, 0, Width, Height);
  end;
end;

procedure TSVGIconImage.LoadFromFile(const FileName: string);
begin
  if csLoading in ComponentState then
    Exit;
  try
    FSVG.LoadFromFile(FileName);
    FFileName := FileName;
  except
    Clear;
  end;
  CheckAutoSize;
  Repaint;
end;

procedure TSVGIconImage.LoadFromStream(Stream: TStream);
begin
  try
    FFileName := '';
    FSVG.LoadFromStream(Stream);
  except
  end;
  CheckAutoSize;
  Repaint;
end;

procedure TSVGIconImage.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FImageList) then
    FImageList := nil;
end;

procedure TSVGIconImage.Assign(Source: TPersistent);
begin
  if (Source is TSVGIconImage) then
  begin
    FSVG := (Source as TSVGIconImage).FSVG;
    FImageIndex := -1;
    CheckAutoSize;
  end;

  Repaint;
end;

procedure TSVGIconImage.SaveToFile(const FileName: string);
begin
  FSVG.SaveToFile(FileName);
end;

procedure TSVGIconImage.SetAutoSizeImage(const Value: Boolean);
begin
  if (Value = FAutoSize) then
    Exit;
  FAutoSize := Value;

  CheckAutoSize;
end;

procedure TSVGIconImage.SetCenter(Value: Boolean);
begin
  if Value = FCenter then
    Exit;

  FCenter := Value;
  Repaint;
end;

procedure TSVGIconImage.SetProportional(Value: Boolean);
begin
  if Value = FProportional then
    Exit;

  FProportional := Value;
  Repaint;
end;

procedure TSVGIconImage.SetScale(const Value: Double);
begin
  if Value = FScale then
    Exit;
  FScale := Value;
  FAutoSize := False;
  Repaint;
end;

procedure TSVGIconImage.SetStretch(const Value: Boolean);
begin
  if Value = FStretch then
    Exit;

  FStretch := Value;
  if FStretch then
    FAutoSize := False;
  Repaint;
end;

procedure TSVGIconImage.SetSVGText(const AValue: string);
begin
  FSVG.Source := AValue;
  Repaint;
end;

function TSVGIconImage.StoreScale: Boolean;
begin
  Result := FScale <> 1;
end;

procedure TSVGIconImage.SetOpacity(Value: Byte);
begin
  if Value = FOpacity then
    Exit;

  FOpacity := Value;
  Repaint;
end;

procedure TSVGIconImage.SetFileName(const Value: TFileName);
begin
  if Value = FFileName then
    Exit;
  LoadFromFile(Value);
end;

procedure TSVGIconImage.SetImageIndex(const Value: Integer);
begin
  if FImageIndex = Value then
    Exit;
  FImageIndex := Value;
  CheckAutoSize;
  Repaint;
end;

procedure TSVGIconImage.SetImageList(const Value: TSVGIconImageListBase);
begin
  FImageList := Value;
  SVGText := '';
end;

constructor TSVGGraphic.Create;
begin
  inherited;
  FSVG := GlobalSVGFactory.NewSvg;
  FOpacity := 255;
end;

procedure TSVGGraphic.Clear;
begin
  FSVG.Clear;
  FFileName := '';
  Changed(Self);
end;

procedure TSVGGraphic.Assign(Source: TPersistent);
begin
  if (Source is TSVGGraphic) then
  begin
    try
      //AssignSVG(TSVGGraphic(Source).FSVG);
      FSVG := TSVGGraphic(Source).FSVG;
    except
    end;
    Changed(Self);
  end;
end;

procedure TSVGGraphic.AssignSVG(SVG: ISVG);
begin
  FSVG := SVG;
  Changed(Self);
end;

procedure TSVGGraphic.AssignTo(Dest: TPersistent);
begin
  if Dest is TSVGGraphic then
    TSVGGraphic(Dest).Assign(Self);
end;

procedure TSVGGraphic.SetOpacity(Value: Byte);
begin
  if Value = FOpacity then
    Exit;

  FOpacity := Value;
  Changed(Self);
end;

procedure TSVGGraphic.SetWidth(Value: Integer);
begin
  inherited;

end;

procedure TSVGGraphic.SetFileName(const Value: TFileName);
begin
  if Value = FFileName then
    Exit;

  LoadFromFile(Value);
end;

procedure TSVGGraphic.SetHeight(Value: Integer);
begin
  inherited;

end;

procedure TSVGGraphic.ReadData(Stream: TStream);
var
  Size: LongInt;
  MemStream: TMemoryStream;
begin
  Stream.Read(Size, SizeOf(Size));
  MemStream := TMemoryStream.Create;
  try
    MemStream.CopyFrom(Stream, Size);
    MemStream.Position := 0;
    FSVG.LoadFromStream(MemStream);
  finally
    MemStream.Free;
  end;
end;

procedure TSVGGraphic.WriteData(Stream: TStream);
var
  Size: LongInt;
  MemStream: TMemoryStream;
begin
  MemStream := TMemoryStream.Create;
  try
    FSVG.SaveToStream(MemStream);
    Size := MemStream.Size;
    Stream.Write(Size, SizeOf(Size));
    MemStream.Position := 0;
    MemStream.SaveToStream(Stream);
  finally
    MemStream.Free;
  end;
end;

procedure TSVGGraphic.DefineProperties(Filer: TFiler);
begin
  Filer.DefineBinaryProperty('Data', ReadData, WriteData, True);
end;

procedure TSVGGraphic.Draw(ACanvas: TCanvas; const Rect: TRect);
begin
  if Empty then
    Exit;

  FSVG.Opacity := FOpacity / 255;
  FSVG.PaintTo(ACanvas.Handle, TRectF.Create(Rect));
end;


function TSVGGraphic.GetEmpty: Boolean;
begin
  Result := FSVG.IsEmpty;
end;

function TSVGGraphic.GetWidth: Integer;
begin
  Result := Round(FSVG.Width);
end;

function TSVGGraphic.GetHeight: Integer;
begin
  Result := Round(FSVG.Height);
end;

procedure TSVGGraphic.LoadFromClipboardFormat(AFormat: Word; AData: THandle;
  APalette: HPALETTE);
begin
  inherited;

end;

procedure TSVGGraphic.LoadFromFile(const Filename: String);
begin
  FSVG.LoadFromFile(Filename);
  Changed(Self);
end;

procedure TSVGGraphic.LoadFromStream(Stream: TStream);
begin
  try
    FSVG.LoadFromStream(Stream);
  except
  end;
  Changed(Self);
end;

procedure TSVGGraphic.SaveToClipboardFormat(var AFormat: Word;
  var AData: THandle; var APalette: HPALETTE);
begin
  inherited;

end;

procedure TSVGGraphic.SaveToStream(Stream: TStream);
begin
  FSVG.SaveToStream(Stream);
end;


initialization
  TPicture.RegisterFileFormat('SVG', 'Scalable Vector Graphics', TSVGGraphic);

finalization
  TPicture.UnregisterGraphicClass(TSVGGraphic);
end.
