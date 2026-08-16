{****************************************************************}
{                                                                }
{            ██████╗ ██╗     ██╗███╗   ██╗██╗  ██╗██╗            }
{            ██╔══██╗██║     ██║████╗  ██║██║ ██╔╝██║            }
{            ██████╔╝██║     ██║██╔██╗ ██║█████╔╝ ██║            }
{            ██╔══██╗██║     ██║██║╚██╗██║██╔═██╗ ██║            }
{            ██████╔╝███████╗██║██║ ╚████║██║  ██╗██║            }
{            ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝            }
{                                                                }
{       Modern, beautiful Text User Interfaces for Delphi        }
{                                                                }
{****************************************************************}
{                                                                }
{   Unit:        Blinki.Widgets.ProgressBar.pas                  }
{   Version:     0.1.0                                           }
{   Repository:  https://github.com/marcobreveglieri/blinki      }
{                                                                }
{   Copyright (c) 2026 Marco Breveglieri                         }
{                                                                }
{   Released under the MIT License - see LICENSE file            }
{                                                                }
{****************************************************************}

/// <summary>
///   Widget TTuiProgressBar: horizontal progress bar with Unicode partial-block characters.
/// </summary>
unit Blinki.Widgets.ProgressBar;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.Types,
  Blinki.Core.Canvas,
  Blinki.Core.Style,
  Blinki.Core.Theme,
  Blinki.Core.Widget;

type

{ TTuiProgressBar }

  /// <summary>
  ///   Horizontal progress bar. Value ranges from 0.0 to 1.0 (out-of-range values are
  ///   clamped). Uses Unicode partial-block characters (#$258F..#$2588) for sub-character
  ///   rendering. When ShowPercentage is True, the percentage is right-aligned in 4+1
  ///   characters. Colors are updated automatically on theme changes.
  /// </summary>
  TTuiProgressBar = class(TTuiWidget)
  strict private
    FValue: Single;
    FShowPercentage: Boolean;
    FFillColor: TTuiColor;
    FEmptyColor: TTuiColor;
    FColorOverride: Boolean;
    procedure SetValue(AValue: Single);
    procedure SetShowPercentage(AValue: Boolean);
    procedure SetFillColor(const AValue: TTuiColor);
    procedure SetEmptyColor(const AValue: TTuiColor);
  protected
    procedure DoRender(const ACanvas: TTuiCanvas; const ARect: TRect); override;
    procedure DoApplyTheme(const ATheme: TTuiTheme); override;
  public
    /// <summary>
    /// Creates the progress bar. Initial Value: 0.0; ShowPercentage: True.
    /// </summary>
    constructor Create(AParent: TTuiWidget = nil);
    /// <summary>
    /// Current progress, from 0.0 to 1.0. Out-of-range values are clamped.
    /// </summary>
    property Value: Single read FValue write SetValue;
    /// <summary>
    /// When True, displays the percentage right-aligned (5 chars). Default: True.
    /// </summary>
    property ShowPercentage: Boolean read FShowPercentage write SetShowPercentage;
    /// <summary>
    ///   Color of the filled blocks. Once set explicitly, theme changes no longer override it.
    /// </summary>
    property FillColor: TTuiColor read FFillColor write SetFillColor;
    /// <summary>
    ///   Color of the empty blocks. Once set explicitly, theme changes no longer override it.
    /// </summary>
    property EmptyColor: TTuiColor read FEmptyColor write SetEmptyColor;
  end;

implementation

{ TTuiProgressBar }

constructor TTuiProgressBar.Create(AParent: TTuiWidget);
begin
  inherited Create(AParent);
  FShowPercentage := True;
  FFillColor := Theme.Primary;
  FEmptyColor := Theme.Surface;
end;

procedure TTuiProgressBar.DoApplyTheme(const ATheme: TTuiTheme);
begin
  if not FColorOverride then
  begin
    FFillColor := ATheme.Primary;
    FEmptyColor := ATheme.Surface;
  end;
end;

procedure TTuiProgressBar.SetValue(AValue: Single);
begin
  if AValue < 0.0 then
    AValue := 0.0;
  if AValue > 1.0 then
    AValue := 1.0;
  if FValue = AValue then
    Exit;
  FValue := AValue;
  Invalidate;
end;

procedure TTuiProgressBar.SetShowPercentage(AValue: Boolean);
begin
  if FShowPercentage = AValue then
    Exit;
  FShowPercentage := AValue;
  Invalidate;
end;

procedure TTuiProgressBar.SetFillColor(const AValue: TTuiColor);
begin
  if FFillColor = AValue then
    Exit;
  FFillColor := AValue;
  FColorOverride := True;
  Invalidate;
end;

procedure TTuiProgressBar.SetEmptyColor(const AValue: TTuiColor);
begin
  if FEmptyColor = AValue then
    Exit;
  FEmptyColor := AValue;
  FColorOverride := True;
  Invalidate;
end;

procedure TTuiProgressBar.DoRender(const ACanvas: TTuiCanvas; const ARect: TRect);
begin
  if ARect.IsEmpty then
    Exit;

  var LFillStyle := TTuiStyle.Create(FFillColor, TTuiColor.Default);
  var LEmptyStyle := TTuiStyle.Create(FEmptyColor, TTuiColor.Default);
  var LTextStyle := TTuiStyle.Create(Theme.Text, TTuiColor.Default);

  var LPctStr: string;
  var LPctWidth: Integer;
  if FShowPercentage then
  begin
    LPctStr := Format('%3d%%', [Round(FValue * 100)]);
    LPctWidth := Length(LPctStr) + 1;  // separator space
  end
  else
  begin
    LPctStr := '';
    LPctWidth := 0;
  end;

  var LBarWidth := ARect.Width - LPctWidth;
  if LBarWidth < 1 then
    LBarWidth := 1;

  ACanvas.DrawEighthsBar(ARect.Left, ARect.Top, LBarWidth, FValue,
    LFillStyle, LEmptyStyle);

  // Percentage
  if FShowPercentage then
    ACanvas.WriteAt(ARect.Left + LBarWidth, ARect.Top, ' ' + LPctStr, LTextStyle);
end;

end.
