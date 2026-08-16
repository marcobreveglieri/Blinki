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
{   Unit:        Blinki.Widgets.Toggle.pas                       }
{   Version:     0.1.0                                           }
{   Repository:  https://github.com/marcobreveglieri/blinki      }
{                                                                }
{   Copyright (c) 2026 Marco Breveglieri                         }
{                                                                }
{   Released under the MIT License - see LICENSE file            }
{                                                                }
{****************************************************************}

/// <summary>
///   TTuiCustomToggle: shared base class for single-line glyph + caption
///   toggle widgets (check boxes, radio buttons).
/// </summary>
unit Blinki.Widgets.Toggle;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.Types,
  Blinki.Core.Ansi,
  Blinki.Core.Canvas,
  Blinki.Core.Style,
  Blinki.Core.Theme,
  Blinki.Core.Widget;

type

{ TTuiCustomToggle }

  /// <summary>
  ///   Base class for single-line toggle widgets rendered as a state glyph,
  ///   a space and a caption. When focused, the line is drawn with the theme
  ///   Primary colour. Descendants provide the glyph pair and define what
  ///   assigning Checked means (plain toggle, radio-group exclusivity).
  ///   Becomes focusable in DoInit.
  /// </summary>
  TTuiCustomToggle = class(TTuiWidget)
  strict private
    FCaption: string;
    FChecked: Boolean;
    FFocusedStyle: TTuiStyle;
    FFocusedStyleOverride: Boolean;
    FNormalStyle: TTuiStyle;
    FNormalStyleOverride: Boolean;
    procedure RebuildStyles;
    procedure SetCaption(const AValue: string);
    procedure SetFocusedStyle(const AValue: TTuiStyle);
    procedure SetNormalStyle(const AValue: TTuiStyle);
  protected
    /// <summary>
    ///   Direct state access for descendants; assigning it fires no events
    ///   and no repaint (radio-group logic relies on this).
    /// </summary>
    property CheckedState: Boolean read FChecked write FChecked;
    procedure DoApplyTheme(const ATheme: TTuiTheme); override;
    procedure DoInit; override;
    procedure DoRender(const ACanvas: TTuiCanvas; const ARect: TRect); override;
    /// <summary>
    ///   Returns the glyph drawn before the caption for the given state.
    /// </summary>
    function GlyphFor(AChecked: Boolean): string; virtual; abstract;
    /// <summary>
    ///   Updates the checked state. Descendants define the semantics and
    ///   the events fired.
    /// </summary>
    procedure SetChecked(AValue: Boolean); virtual; abstract;
  public
    /// <summary>
    ///   Creates the toggle. Initial Checked value: False. Becomes focusable
    ///   after Init.
    /// </summary>
    constructor Create(AParent: TTuiWidget = nil);
    /// <summary>
    ///   Label text displayed next to the glyph.
    /// </summary>
    property Caption: string read FCaption write SetCaption;
    /// <summary>
    ///   Current checked state.
    /// </summary>
    property Checked: Boolean read FChecked write SetChecked;
    /// <summary>
    ///   Style used when the widget is focused. Assigning it disables
    ///   automatic theme updates.
    /// </summary>
    property FocusedStyle: TTuiStyle read FFocusedStyle write SetFocusedStyle;
    /// <summary>
    ///   Style used when the widget is unfocused. Assigning it disables
    ///   automatic theme updates.
    /// </summary>
    property NormalStyle: TTuiStyle read FNormalStyle write SetNormalStyle;
  end;

implementation

{ TTuiCustomToggle }

constructor TTuiCustomToggle.Create(AParent: TTuiWidget);
begin
  inherited Create(AParent);
  RebuildStyles;
end;

procedure TTuiCustomToggle.RebuildStyles;
begin
  if not FNormalStyleOverride then
    FNormalStyle := TTuiStyle.Create(Theme.Text, Theme.Surface);
  if not FFocusedStyleOverride then
    FFocusedStyle := TTuiStyle.Create(Theme.Primary, Theme.Surface);
end;

procedure TTuiCustomToggle.DoInit;
begin
  SetFocusable(True);
end;

procedure TTuiCustomToggle.DoApplyTheme(const ATheme: TTuiTheme);
begin
  RebuildStyles;
end;

procedure TTuiCustomToggle.DoRender(const ACanvas: TTuiCanvas; const ARect: TRect);
begin
  if ARect.IsEmpty then
    Exit;

  var LStyle: TTuiStyle;
  if Focused then
    LStyle := FFocusedStyle
  else
    LStyle := FNormalStyle;

  ACanvas.FillRect(ARect, ' ', LStyle);

  var LLine := GlyphFor(FChecked) + ' ' + FCaption;

  // Truncate by columns so a wide glyph (CJK, emoji) is never cut in half.
  LLine := TTuiAnsi.TruncateToWidth(LLine, ARect.Width);

  ACanvas.WriteAt(ARect.Left, ARect.Top, LLine, LStyle);
end;

procedure TTuiCustomToggle.SetCaption(const AValue: string);
begin
  if FCaption = AValue then
    Exit;
  FCaption := AValue;
  Invalidate;
end;

procedure TTuiCustomToggle.SetFocusedStyle(const AValue: TTuiStyle);
begin
  if FFocusedStyle = AValue then
    Exit;
  FFocusedStyle := AValue;
  FFocusedStyleOverride := True;
  Invalidate;
end;

procedure TTuiCustomToggle.SetNormalStyle(const AValue: TTuiStyle);
begin
  if FNormalStyle = AValue then
    Exit;
  FNormalStyle := AValue;
  FNormalStyleOverride := True;
  Invalidate;
end;

end.
