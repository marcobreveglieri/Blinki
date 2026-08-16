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
{   Unit:        Blinki.Layout.Scrollable.pas                    }
{   Version:     0.1.0                                           }
{   Repository:  https://github.com/marcobreveglieri/blinki      }
{                                                                }
{   Copyright (c) 2026 Marco Breveglieri                         }
{                                                                }
{   Released under the MIT License - see LICENSE file            }
{                                                                }
{****************************************************************}

/// <summary>
///   Scrollable container for the Blinki library.
///   TTuiScrollable wraps a single child widget of virtual size ContentSize,
///   showing only the visible portion via PushClip/PopClip on the canvas.
///   Handles vertical and/or horizontal scrolling with arrow keys,
///   PgUp/PgDn, Home and End. Optionally renders a scrollbar.
/// </summary>
unit Blinki.Layout.Scrollable;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.Types,
  Blinki.Core.Canvas,
  Blinki.Core.Event,
  Blinki.Core.Widget;

type

{ TTuiScrollDirection }

  /// <summary>
  ///   Scroll direction(s) enabled in TTuiScrollable.
  /// </summary>
  TTuiScrollDirection = (
    /// <summary>
    ///   No scrolling (static content with clipping).
    /// </summary>
    sdNone,
    /// <summary>
    ///   Vertical scrolling only.
    /// </summary>
    sdVertical,
    /// <summary>
    ///   Horizontal scrolling only.
    /// </summary>
    sdHorizontal,
    /// <summary>
    ///   Both vertical and horizontal scrolling.
    /// </summary>
    sdBoth
  );

{ TTuiScrollable }

  /// <summary>
  ///   Container that shows the visible portion of a child widget larger than
  ///   the available area. The child is rendered into a TRect of size ContentSize
  ///   translated by -Offset; clipping constrains output to the visible area.
  ///   Focusable: handles arrow keys, PgUp/PgDn, Home/End to update Offset.
  /// </summary>
  TTuiScrollable = class(TTuiWidget)
  strict private
    FContent: TTuiWidget;
    FContentSize: TSize;
    FOffsetX: Integer;
    FOffsetY: Integer;
    FDirection: TTuiScrollDirection;
    FShowScrollbar: Boolean;
    FLastViewSize: TSize;  // updated on each DoRender
    procedure ClampOffset(const AViewSize: TSize);
    function  HasVertical: Boolean; inline;
    function  HasHorizontal: Boolean; inline;
    procedure DrawVerticalScrollbar(const ACanvas: TTuiCanvas;
      const ARect: TRect; AViewHeight: Integer);
    procedure DrawHorizontalScrollbar(const ACanvas: TTuiCanvas;
      const ARect: TRect; AViewWidth: Integer);
    function  ScrollBy(ADX, ADY: Integer): Boolean;
  protected
    /// <summary>
    ///   Sets Focusable=True when the direction includes at least one scroll axis.
    /// </summary>
    procedure DoInit; override;
    /// <summary>
    ///   Computes the visible area, applies PushClip, renders FContent in translated
    ///   coordinates, calls PopClip, then draws the optional scrollbars.
    /// </summary>
    procedure DoRender(const ACanvas: TTuiCanvas; const ARect: TRect); override;
    /// <summary>
    ///   Handles arrow keys, PgUp, PgDn, Home and End by updating the offset and
    ///   invalidating the widget. Returns True if the event was consumed.
    /// </summary>
    function DoHandleEvent(const AEvent: TTuiEvent): Boolean; override;
  public
    /// <summary>
    ///   Creates a TTuiScrollable wrapping AContent.
    ///   AContent is registered as a child widget (ownership is transferred).
    ///   ADirection specifies the scroll axes; default: sdVertical.
    ///   ContentSize is initialized to (0, 0): assign it before calling Run.
    /// </summary>
    constructor Create(AContent: TTuiWidget;
      ADirection: TTuiScrollDirection = sdVertical;
      AParent: TTuiWidget = nil);
    /// <summary>
    ///   Virtual size of the content (Width x Height in cells).
    ///   Set before the first Run; changing this value invalidates the widget.
    /// </summary>
    property ContentSize: TSize read FContentSize write FContentSize;
    /// <summary>
    ///   When True (default), renders the scrollbar on the enabled axis.
    ///   The scrollbar occupies 1 column on the right (vertical) or 1 row at
    ///   the bottom (horizontal).
    /// </summary>
    property ShowScrollbar: Boolean read FShowScrollbar write FShowScrollbar;
    /// <summary>
    ///   Current horizontal scroll offset in columns.
    /// </summary>
    property OffsetX: Integer read FOffsetX;
    /// <summary>
    ///   Current vertical scroll offset in rows.
    /// </summary>
    property OffsetY: Integer read FOffsetY;
    /// <summary>
    ///   Enabled scroll direction(s).
    /// </summary>
    property Direction: TTuiScrollDirection read FDirection;
  end;

implementation

uses
  System.Math,
  Blinki.Core.Input,
  Blinki.Core.Style;

const
  CGlyphArrowUp = #$25B2;    // ▲
  CGlyphArrowDown = #$25BC;  // ▼
  CGlyphArrowLeft = #$25C4;  // ◄
  CGlyphArrowRight = #$25BA; // ►
  CGlyphThumb = #$2588;      // █
  CGlyphTrack = #$2591;      // ░

// Shared thumb geometry for both scrollbar orientations: size and position
// are proportional to the visible fraction and the scroll ratio.
procedure ComputeThumb(ATrackStart, ATrackLen, AViewLen, AContentLen,
  AOffset: Integer; out AThumbStart, AThumbEnd: Integer);
begin
  var LTrackEnd := ATrackStart + ATrackLen - 1;
  if AContentLen <= AViewLen then
  begin
    // Content smaller than the viewport: thumb fills the entire track
    AThumbStart := ATrackStart;
    AThumbEnd := LTrackEnd;
    Exit;
  end;
  var LContent := Max(1, AContentLen);
  var LMaxOffset := Max(1, LContent - AViewLen);
  var LThumbLen := Max(1, Round(ATrackLen * AViewLen / LContent));
  AThumbStart := ATrackStart +
    Round((ATrackLen - LThumbLen) * (AOffset / LMaxOffset));
  AThumbEnd := AThumbStart + LThumbLen - 1;
  if AThumbEnd > LTrackEnd then
    AThumbEnd := LTrackEnd;
end;

{ TTuiScrollable }

constructor TTuiScrollable.Create(AContent: TTuiWidget;
  ADirection: TTuiScrollDirection; AParent: TTuiWidget);
begin
  inherited Create(AParent);
  FContent := AContent;
  FDirection := ADirection;
  FShowScrollbar := True;
  FContentSize := TSize.Create(0, 0);
  FLastViewSize := TSize.Create(0, 0);
  // Registers the child (ownership transferred)
  if Assigned(AContent) and not Assigned(AContent.Parent) then
    AddChild(AContent);
end;

function TTuiScrollable.HasVertical: Boolean;
begin
  Result := FDirection in [sdVertical, sdBoth];
end;

function TTuiScrollable.HasHorizontal: Boolean;
begin
  Result := FDirection in [sdHorizontal, sdBoth];
end;

procedure TTuiScrollable.DoInit;
begin
  inherited DoInit;
  SetFocusable(FDirection <> sdNone);
end;

procedure TTuiScrollable.ClampOffset(const AViewSize: TSize);
begin
  if HasHorizontal then
  begin
    var LMaxX := Max(0, FContentSize.cx - AViewSize.cx);
    if FOffsetX < 0 then
      FOffsetX := 0;
    if FOffsetX > LMaxX then
      FOffsetX := LMaxX;
  end
  else
    FOffsetX := 0;

  if HasVertical then
  begin
    var LMaxY := Max(0, FContentSize.cy - AViewSize.cy);
    if FOffsetY < 0 then
      FOffsetY := 0;
    if FOffsetY > LMaxY then
      FOffsetY := LMaxY;
  end
  else
    FOffsetY := 0;
end;

function TTuiScrollable.ScrollBy(ADX, ADY: Integer): Boolean;
begin
  Inc(FOffsetX, ADX);
  Inc(FOffsetY, ADY);
  ClampOffset(FLastViewSize);
  Invalidate;
  Result := True;
end;

procedure TTuiScrollable.DrawVerticalScrollbar(const ACanvas: TTuiCanvas;
  const ARect: TRect; AViewHeight: Integer);
begin
  var LX := ARect.Right - 1;
  if (LX < ARect.Left) or (AViewHeight < 3) then
    Exit;

  var LStyleActive: TTuiStyle;
  if Focused then
    LStyleActive := TTuiStyle.Create(TTuiColors.BrightWhite, TTuiColor.Default, [])
  else
    LStyleActive := TTuiStyle.Create(TTuiColors.BrightBlack, TTuiColor.Default, []);
  var LStyleTrack := TTuiStyle.Create(TTuiColors.BrightBlack, TTuiColor.Default, []);

  // Arrows
  ACanvas.WriteAt(LX, ARect.Top, CGlyphArrowUp, LStyleActive);
  ACanvas.WriteAt(LX, ARect.Top + AViewHeight - 1, CGlyphArrowDown, LStyleActive);

  // Track
  var LTrackTop := ARect.Top + 1;
  var LTrackBot := ARect.Top + AViewHeight - 2;
  var LTrackLen := LTrackBot - LTrackTop + 1;
  if LTrackLen < 1 then
    Exit;

  var LThumbTop, LThumbBot: Integer;
  ComputeThumb(LTrackTop, LTrackLen, AViewHeight, FContentSize.cy, FOffsetY,
    LThumbTop, LThumbBot);

  // Track above the thumb, the thumb, track below: three fills at most
  if LThumbTop > LTrackTop then
    ACanvas.FillRect(TRect.Create(LX, LTrackTop, LX + 1, LThumbTop),
      CGlyphTrack, LStyleTrack);
  ACanvas.FillRect(TRect.Create(LX, LThumbTop, LX + 1, LThumbBot + 1),
    CGlyphThumb, LStyleActive);
  if LThumbBot < LTrackBot then
    ACanvas.FillRect(TRect.Create(LX, LThumbBot + 1, LX + 1, LTrackBot + 1),
      CGlyphTrack, LStyleTrack);
end;

procedure TTuiScrollable.DrawHorizontalScrollbar(const ACanvas: TTuiCanvas;
  const ARect: TRect; AViewWidth: Integer);
begin
  var LY := ARect.Bottom - 1;
  if (LY < ARect.Top) or (AViewWidth < 3) then
    Exit;

  var LStyleActive: TTuiStyle;
  if Focused then
    LStyleActive := TTuiStyle.Create(TTuiColors.BrightWhite, TTuiColor.Default, [])
  else
    LStyleActive := TTuiStyle.Create(TTuiColors.BrightBlack, TTuiColor.Default, []);
  var LStyleTrack := TTuiStyle.Create(TTuiColors.BrightBlack, TTuiColor.Default, []);

  // Arrows
  ACanvas.WriteAt(ARect.Left,                  LY, CGlyphArrowLeft, LStyleActive);
  ACanvas.WriteAt(ARect.Left + AViewWidth - 1, LY, CGlyphArrowRight, LStyleActive);

  // Track
  var LTrackLeft  := ARect.Left + 1;
  var LTrackRight := ARect.Left + AViewWidth - 2;
  var LTrackLen   := LTrackRight - LTrackLeft + 1;
  if LTrackLen < 1 then
    Exit;

  var LThumbLeft, LThumbRight: Integer;
  ComputeThumb(LTrackLeft, LTrackLen, AViewWidth, FContentSize.cx, FOffsetX,
    LThumbLeft, LThumbRight);

  // Track before the thumb, the thumb, track after: three fills at most
  if LThumbLeft > LTrackLeft then
    ACanvas.FillRect(TRect.Create(LTrackLeft, LY, LThumbLeft, LY + 1),
      CGlyphTrack, LStyleTrack);
  ACanvas.FillRect(TRect.Create(LThumbLeft, LY, LThumbRight + 1, LY + 1),
    CGlyphThumb, LStyleActive);
  if LThumbRight < LTrackRight then
    ACanvas.FillRect(TRect.Create(LThumbRight + 1, LY, LTrackRight + 1, LY + 1),
      CGlyphTrack, LStyleTrack);
end;

procedure TTuiScrollable.DoRender(const ACanvas: TTuiCanvas;
  const ARect: TRect);
begin
  if not Assigned(FContent) then
    Exit;

  // Computes the visible area (excludes scrollbars when active)
  var LViewRect := ARect;
  if FShowScrollbar and HasVertical and (ARect.Width >= 2) then
    Dec(LViewRect.Right);
  if FShowScrollbar and HasHorizontal and (ARect.Height >= 2) then
    Dec(LViewRect.Bottom);

  if LViewRect.IsEmpty then
    Exit;

  var LViewSize := TSize.Create(LViewRect.Width, LViewRect.Height);
  FLastViewSize := LViewSize;
  ClampOffset(LViewSize);

  // If ContentSize has not been set, uses the visible area as content
  if FContentSize.cx <= 0 then
    FContentSize.cx := LViewSize.cx;
  if FContentSize.cy <= 0 then
    FContentSize.cy := LViewSize.cy;

  // Clips to the visible area, then renders the translated content
  ACanvas.PushClip(LViewRect);
  try
    var LContentRect := TRect.Create(
      LViewRect.Left - FOffsetX,
      LViewRect.Top  - FOffsetY,
      LViewRect.Left - FOffsetX + FContentSize.cx,
      LViewRect.Top  - FOffsetY + FContentSize.cy);
    FContent.Render(ACanvas, LContentRect);
  finally
    ACanvas.PopClip;
  end;

  // Draws the scrollbars outside the clip region
  if FShowScrollbar then
  begin
    if HasVertical and (ARect.Width >= 2) then
      DrawVerticalScrollbar(ACanvas, ARect, LViewRect.Height);
    if HasHorizontal and (ARect.Height >= 2) then
      DrawHorizontalScrollbar(ACanvas, ARect, LViewRect.Width);
  end;
end;

function TTuiScrollable.DoHandleEvent(const AEvent: TTuiEvent): Boolean;
begin
  Result := False;

  if AEvent.Kind <> ekKey then
    Exit;

  // Uses the viewport height measured during the last DoRender
  var LPageH := Max(1, FLastViewSize.cy);

  case AEvent.Key.Code of
    kcUp:
      if HasVertical then
        Result := ScrollBy(0, -1);
    kcDown:
      if HasVertical then
        Result := ScrollBy(0, 1);
    kcLeft:
      if HasHorizontal then
        Result := ScrollBy(-1, 0);
    kcRight:
      if HasHorizontal then
        Result := ScrollBy(1, 0);
    kcPageUp:
      if HasVertical then
        Result := ScrollBy(0, -LPageH);
    kcPageDown:
      if HasVertical then
        Result := ScrollBy(0, LPageH);
    kcHome:
      if HasVertical then
        Result := ScrollBy(0, -FOffsetY);
    kcEnd:
      if HasVertical then
        Result := ScrollBy(0, Max(0, FContentSize.cy - LPageH) - FOffsetY);
  end;
end;

end.
