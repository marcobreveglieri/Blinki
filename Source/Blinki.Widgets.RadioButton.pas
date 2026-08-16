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
{   Unit:        Blinki.Widgets.RadioButton.pas                  }
{   Version:     0.1.0                                           }
{   Repository:  https://github.com/marcobreveglieri/blinki      }
{                                                                }
{   Copyright (c) 2026 Marco Breveglieri                         }
{                                                                }
{   Released under the MIT License - see LICENSE file            }
{                                                                }
{****************************************************************}

/// <summary>
///   Widget TTuiRadioButton: mutually exclusive selection within a sibling group.
/// </summary>
unit Blinki.Widgets.RadioButton;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Blinki.Core.Event,
  Blinki.Core.Widget,
  Blinki.Widgets.Toggle;

type

{ TTuiRadioButton }

  /// <summary>
  ///   Single-line radio button: renders a Unicode glyph + space + caption.
  ///   Radio buttons sharing the same Group and the same parent are mutually
  ///   exclusive: checking one unchecks the others silently. Pressing Space
  ///   or Enter selects the button and fires OnSelect.
  ///   Becomes focusable in DoInit.
  /// </summary>
  TTuiRadioButton = class(TTuiCustomToggle)
  strict private
    FGroup: string;
    FOnSelect: TProc;
    procedure SetGroup(const AValue: string);
    /// <summary>
    /// Unchecks the radio button without invoking OnSelect (used by group logic).
    /// </summary>
    procedure UncheckSilent;
  protected
    function  DoHandleEvent(const AEvent: TTuiEvent): Boolean; override;
    function  GlyphFor(AChecked: Boolean): string; override;
    procedure SetChecked(AValue: Boolean); override;
  public
    /// <summary>
    ///   Name of the belonging group. Radio buttons sharing the same Group and the same
    ///   parent are mutually exclusive. Empty string means anonymous group.
    /// </summary>
    property Group: string read FGroup write SetGroup;
    /// <summary>
    /// Invoked when this radio button becomes selected (Checked transitions from False to True).
    /// </summary>
    property OnSelect: TProc read FOnSelect write FOnSelect;
  end;

implementation

uses
  Blinki.Core.Input;

const

  /// <summary>
  /// Unicode glyph for a checked radio button (U+25C9).
  /// </summary>
  CRadioChecked   = #$25C9;

  /// <summary>
  /// Unicode glyph for an unchecked radio button (U+25CB).
  /// </summary>
  CRadioUnchecked = #$25CB;

{ TTuiRadioButton }

function TTuiRadioButton.GlyphFor(AChecked: Boolean): string;
begin
  if AChecked then
    Result := CRadioChecked
  else
    Result := CRadioUnchecked;
end;

procedure TTuiRadioButton.UncheckSilent;
begin
  if not CheckedState then
    Exit;
  CheckedState := False;
  Invalidate;
end;

procedure TTuiRadioButton.SetChecked(AValue: Boolean);
begin
  if CheckedState = AValue then
    Exit;
  CheckedState := AValue;
  if AValue and Assigned(Parent) then
  begin
    for var LIndex := 0 to Parent.ChildCount - 1 do
    begin
      var LSib := Parent.Children[LIndex];
      if (LSib <> Self) and (LSib is TTuiRadioButton) then
      begin
        var LRadio := TTuiRadioButton(LSib);
        if LRadio.FGroup = FGroup then
          LRadio.UncheckSilent;
      end;
    end;
    if Assigned(FOnSelect) then
      FOnSelect;
  end;
  Invalidate;
end;

function TTuiRadioButton.DoHandleEvent(const AEvent: TTuiEvent): Boolean;
begin
  Result := False;
  if AEvent.Kind <> ekKey then
    Exit;
  if (AEvent.Key.Code = kcSpace) or (AEvent.Key.Code = kcEnter) then
  begin
    if not Checked then
      SetChecked(True);
    Result := True;
  end;
end;

procedure TTuiRadioButton.SetGroup(const AValue: string);
begin
  if FGroup = AValue then
    Exit;
  FGroup := AValue;
end;

end.
