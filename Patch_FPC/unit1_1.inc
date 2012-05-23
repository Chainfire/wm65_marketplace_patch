{ KOL MCK } // Do not remove this line!
const menuPatch = 0;
const menuExit = 1;


procedure NewForm1( var Result: PForm1; AParent: PControl );
begin

  {$IFDEF KOLCLASSES}
  Result := PForm1.Create;
  {$ELSE OBJECTS}
  New( Result, Create );
  {$ENDIF KOL CLASSES/OBJECTS}
  Result.Form := NewForm( AParent, 'Form1' );
  Applet :=  Result.Form;
  Result.Form.Add2AutoFree( Result );
{$IFDEF UNICODE_CTRLS}{$IFNDEF wince}
     Result.Form.SetUnicode(TRUE);
{$ENDIF wince}{$ENDIF UNICODE_CTRLS}
   {$IFDEF USE_NAMES}
    Result.Form.SetName( Applet, 'Form1' );
   {$ENDIF}

    Result.MainMenu1 := NewMenu( Result.Form, 0, [ 'Patch'
      , 'Exit', '' ], nil );
   {$IFDEF USE_NAMES}
    Result.MainMenu1.SetName( Result.Form, 'MainMenu1' ); 
   {$ENDIF}
    Result.MainMenu1.AssignEvents( 0, [ Result.menuPatchMenu ] );
    Result.MainMenu1.AssignEvents( 1, [ Result.menuExitMenu ] );
    // Result.pnlContainer.TabOrder = 0
    Result.pnlContainer := NewPanel( Result.Form, esNone ).SetPosition( 88, 56 ).SetSize( 240, 180 );
   {$IFDEF USE_NAMES}
    Result.pnlContainer.SetName( Result.Form, 'pnlContainer' ); 
   {$ENDIF}
   {$IFDEF UNICODE_CTRLS}{$IFNDEF wince}
   Result.pnlContainer.SetUnicode(TRUE);
   {$ENDIF wince}{$ENDIF UNICODE_CTRLS}
    Result.pnlContainer.Border := 0;
    Result.pnlContainer.Color := clWhite;
    // Result.Label1.TabOrder = -1
      Result.Label1 := NewLabel( Result.pnlContainer, 'MarketPlaceAdvancedPatch' ).SetPosition( 8, 7 ).SetSize( 224, 0 );
   {$IFDEF USE_NAMES}
      Result.Label1.SetName( Result.Form, 'Label1' ); 
   {$ENDIF}
   {$IFDEF UNICODE_CTRLS}{$IFNDEF wince}
   Result.Label1.SetUnicode(TRUE);
   {$ENDIF wince}{$ENDIF UNICODE_CTRLS}
    Result.Label1.Font.FontStyle := [ fsBold ];
    Result.Label1.Font.FontHeight := -14;
    Result.Label1.TextAlign := KOL.taCenter;
    // Result.Label2.TabOrder = -1
      Result.Label2 := NewLabel( Result.pnlContainer, 'v1.0 - Copyright (C) 2009 - Chainfire' ).SetPosition( 8, 32 ).SetSize( 224, 0 );
   {$IFDEF USE_NAMES}
      Result.Label2.SetName( Result.Form, 'Label2' ); 
   {$ENDIF}
   {$IFDEF UNICODE_CTRLS}{$IFNDEF wince}
   Result.Label2.SetUnicode(TRUE);
   {$ENDIF wince}{$ENDIF UNICODE_CTRLS}
    Result.Label2.Font.FontStyle := [ fsBold ];
    Result.Label2.Font.FontHeight := -11;
    Result.Label2.TextAlign := KOL.taCenter;
    // Result.lbLog.TabOrder = 0
      Result.lbLog := NewListBox( Result.pnlContainer, [ loNoIntegralHeight ] ).SetPosition( 0, 56 ).SetSize( 240, 124 );
   {$IFDEF USE_NAMES}
      Result.lbLog.SetName( Result.Form, 'lbLog' ); 
   {$ENDIF}
   {$IFDEF UNICODE_CTRLS}{$IFNDEF wince}
   Result.lbLog.SetUnicode(TRUE);
   {$ENDIF wince}{$ENDIF UNICODE_CTRLS}
    Result.lbLog.Color := clWindow;
      Result.lbLog.CurIndex := 0;
    Result.Label1.Anchor(TRUE, TRUE, TRUE, FALSE);
    Result.Label2.Anchor(TRUE, TRUE, TRUE, FALSE);
    Result.lbLog.Anchor(TRUE, TRUE, TRUE, TRUE);
    Result.KOLForm1FormCreate( Result );

end;

