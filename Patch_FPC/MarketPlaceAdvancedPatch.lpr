{ KOL MCK } // Do not remove this line!
{$DEFINE KOL_MCK}
{$ifdef FPC} {$mode delphi} {$endif}
program MarketPlaceAdvancedPatch;

uses
  KOL,
  Unit1;

begin // PROGRAM START HERE -- Please do not remove this comment

{$IFNDEF LAZIDE_MCK} {$I MarketPlaceAdvancedPatch_0.inc} {$ELSE}

  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;

{$ENDIF}

end.
