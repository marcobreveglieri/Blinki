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
{   Unit:        Blinki.Layout.Solver.pas                        }
{   Version:     0.1.0                                           }
{   Repository:  https://github.com/marcobreveglieri/blinki      }
{                                                                }
{   Copyright (c) 2026 Marco Breveglieri                         }
{                                                                }
{   Released under the MIT License - see LICENSE file            }
{                                                                }
{****************************************************************}

/// <summary>
///   Constraint-based solver for the Blinki layout engine.
///   TTuiLayoutSolver.Solve distributes ATotalCells across an array of
///   TTuiLayoutConstraint using three passes: Fixed/Percentage, Fill/Min/Max,
///   and remainder assignment (off-by-one prevention).
/// </summary>
unit Blinki.Layout.Solver;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Blinki.Core.Geometry;

type

{ TTuiLayoutSolver }

  /// <summary>
  ///   Static solver that converts an array of TTuiLayoutConstraint into
  ///   integer sizes. Stateless: call Solve once per frame.
  /// </summary>
  TTuiLayoutSolver = class sealed
  strict private
    class procedure AbsorbRemainder(ATotal, ALastFlex: Integer;
      var ASizes: TArray<Integer>); static;
    class function ApplyFixedAndPercentage(ATotal: Integer;
      const AConstraints: TArray<TTuiLayoutConstraint>;
      var ASizes: TArray<Integer>): Integer; static;
    class function DistributeFlex(ARemaining: Integer;
      const AConstraints: TArray<TTuiLayoutConstraint>;
      var ASizes: TArray<Integer>): Integer; static;
  public
    /// <summary>
    ///   Resolves AConstraints by distributing ATotal cells among children.
    ///   Returns a TArray{Integer} of the same length as AConstraints.
    ///   Guarantees that the sum of results equals exactly ATotal when at
    ///   least one Fill/Min/Max element is present to absorb the remainder.
    ///   If the sum of Fixed+Percentage exceeds ATotal, the excess cells are
    ///   trimmed from the last element.
    /// </summary>
    class function Solve(ATotal: Integer;
      const AConstraints: TArray<TTuiLayoutConstraint>): TArray<Integer>;
      overload; static;

    /// <summary>
    ///   As the function overload, but fills ASizes in place, resizing it
    ///   only when the length differs. Per-frame callers can pass a field
    ///   buffer and avoid one array allocation per Solve call.
    /// </summary>
    class procedure Solve(ATotal: Integer;
      const AConstraints: TArray<TTuiLayoutConstraint>;
      var ASizes: TArray<Integer>); overload; static;
  end;

implementation

uses
  System.Math;

{ TTuiLayoutSolver }

// ---- Pass 1: Fixed + Percentage; returns the cells they consumed ----
class function TTuiLayoutSolver.ApplyFixedAndPercentage(ATotal: Integer;
  const AConstraints: TArray<TTuiLayoutConstraint>;
  var ASizes: TArray<Integer>): Integer;
begin
  Result := 0;
  for var LIndex := 0 to High(AConstraints) do
  begin
    var LC := AConstraints[LIndex];
    case LC.Kind of
      lckFixed:
        begin
          ASizes[LIndex] := LC.Value;
          Inc(Result, LC.Value);
        end;
      lckPercentage:
        begin
          ASizes[LIndex] := Max(0, Round(ATotal * LC.Value / 100));
          Inc(Result, ASizes[LIndex]);
        end;
    end;
  end;
end;

// ---- Pass 2: distribute the remaining space to Fill/Min/Max ----
// Returns the index of the last flex element, or -1 when there is none.
class function TTuiLayoutSolver.DistributeFlex(ARemaining: Integer;
  const AConstraints: TArray<TTuiLayoutConstraint>;
  var ASizes: TArray<Integer>): Integer;
begin
  Result := -1;

  var LTotWeight := 0;
  for var LIndex := 0 to High(AConstraints) do
    case AConstraints[LIndex].Kind of
      lckFill:
        Inc(LTotWeight, AConstraints[LIndex].Value);
      lckMin, lckMax:
        Inc(LTotWeight, 1);
    end;
  if LTotWeight = 0 then
    Exit;

  for var LIndex := 0 to High(AConstraints) do
  begin
    var LC := AConstraints[LIndex];
    case LC.Kind of
      lckFill:
        begin
          ASizes[LIndex] := (ARemaining * LC.Value) div LTotWeight;
          Result := LIndex;
        end;
      lckMin:
        begin
          ASizes[LIndex] := Max(LC.Value, ARemaining div LTotWeight);
          Result := LIndex;
        end;
      lckMax:
        begin
          ASizes[LIndex] := Min(LC.Value, ARemaining div LTotWeight);
          Result := LIndex;
        end;
    end;
  end;
end;

// ---- Pass 3: remainder to the last flex (off-by-one prevention) ----
class procedure TTuiLayoutSolver.AbsorbRemainder(ATotal, ALastFlex: Integer;
  var ASizes: TArray<Integer>);
begin
  var LSum := 0;
  for var LIndex := 0 to High(ASizes) do
    Inc(LSum, ASizes[LIndex]);
  if LSum < ATotal then
    Inc(ASizes[ALastFlex], ATotal - LSum)
  else if LSum > ATotal then
    // trims excess from the last flex (Min case with high bound)
    Dec(ASizes[ALastFlex], LSum - ATotal);
end;

class function TTuiLayoutSolver.Solve(ATotal: Integer;
  const AConstraints: TArray<TTuiLayoutConstraint>): TArray<Integer>;
begin
  Result := nil;
  Solve(ATotal, AConstraints, Result);
end;

class procedure TTuiLayoutSolver.Solve(ATotal: Integer;
  const AConstraints: TArray<TTuiLayoutConstraint>; var ASizes: TArray<Integer>);
begin
  var LCount := Length(AConstraints);
  if Length(ASizes) <> LCount then
    SetLength(ASizes, LCount);
  if LCount = 0 then
    Exit;
  // ASizes may be a reused buffer: reset entries the passes do not assign.
  for var LIndex := 0 to LCount - 1 do
    ASizes[LIndex] := 0;

  var LFixedUsed := ApplyFixedAndPercentage(ATotal, AConstraints, ASizes);
  var LRemaining := Max(0, ATotal - LFixedUsed);
  var LLastFlex := DistributeFlex(LRemaining, AConstraints, ASizes);

  if LLastFlex >= 0 then
    AbsorbRemainder(ATotal, LLastFlex, ASizes)
  else if LFixedUsed > ATotal then
    // No flex elements: Fixed+Percentage only. If they exceed ATotal,
    // trims the last.
    ASizes[LCount - 1] := Max(0, ASizes[LCount - 1] - (LFixedUsed - ATotal));

  // Final clamp: no element below 0
  for var LIndex := 0 to LCount - 1 do
    if ASizes[LIndex] < 0 then
      ASizes[LIndex] := 0;
end;

end.
