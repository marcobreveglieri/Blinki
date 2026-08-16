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
{   Unit:        Blinki.Widgets.Checkbox.pas                     }
{   Version:     0.1.0                                           }
{   Repository:  https://github.com/marcobreveglieri/blinki      }
{                                                                }
{   Copyright (c) 2026 Marco Breveglieri                         }
{                                                                }
{   Released under the MIT License - see LICENSE file            }
{                                                                }
{****************************************************************}

/// <summary>
///   Widget TTuiCheckbox: two-state check box with Unicode glyph and caption.
/// </summary>
unit Blinki.Widgets.Checkbox;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Blinki.Core.Event,
  Blinki.Widgets.Toggle;

type

{ TTuiCheckbox }

  /// <summary>
  ///   Single-line check box: renders a Unicode glyph + space + caption.
  ///   Pressing Space or Enter toggles the state and fires OnToggle.
  ///   When focused, the text is drawn with the theme Primary colour.
  ///   Becomes focusable in DoInit.
  /// </summary>
  TTuiCheckbox = class(TTuiCustomToggle)
  strict private
    FOnToggle: TProc<Boolean>;
  protected
    function  DoHandleEvent(const AEvent: TTuiEvent): Boolean; override;
    function  GlyphFor(AChecked: Boolean): string; override;
    procedure SetChecked(AValue: Boolean); override;
  public
    /// <summary>
    /// Fired when the state changes; receives the new Checked value.
    /// </summary>
    property OnToggle: TProc<Boolean> read FOnToggle write FOnToggle;
  end;

implementation

uses
  Blinki.Core.Input;

const

  /// <summary>
  /// Unicode ballot box checked glyph (U+2611).
  /// </summary>
  CCheckboxChecked = #$2611;

  /// <summary>
  /// Unicode ballot box unchecked glyph (U+2610).
  /// </summary>
  CCheckboxUnchecked = #$2610;

{ TTuiCheckbox }

function TTuiCheckbox.GlyphFor(AChecked: Boolean): string;
begin
  if AChecked then
    Result := CCheckboxChecked
  else
    Result := CCheckboxUnchecked;
end;

procedure TTuiCheckbox.SetChecked(AValue: Boolean);
begin
  if CheckedState = AValue then
    Exit;
  CheckedState := AValue;
  if Assigned(FOnToggle) then
    FOnToggle(AValue);
  Invalidate;
end;

function TTuiCheckbox.DoHandleEvent(const AEvent: TTuiEvent): Boolean;
begin
  Result := False;
  if AEvent.Kind <> ekKey then
    Exit;
  if (AEvent.Key.Code = kcSpace) or (AEvent.Key.Code = kcEnter) then
  begin
    SetChecked(not Checked);
    Result := True;
  end;
end;

end.
