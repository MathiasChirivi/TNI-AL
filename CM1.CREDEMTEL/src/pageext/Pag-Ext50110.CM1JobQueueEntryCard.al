pageextension 50110 "CM1 Job Queue Entry Card" extends "Job Queue Entry Card"
{
    actions
    {
        addlast(Processing)
        {
            action(RunNow)
            {
                ApplicationArea = All;
                Caption = 'Run Now (Foreground)';
                Image = ExecuteBatch;
                trigger OnAction()
                var
                    ErrorMessage: Text;
                begin
                    Rec.Modify();   // Salvo eventuali modifiche
                    COMMIT;         // Esco dalla write transaction

                    case Rec."Object Type to Run" of
                        Rec."Object Type to Run"::Codeunit:
                            begin
                                Codeunit.Run(Rec."Object ID to Run", Rec);
                                Message('Codeunit %1 eseguita con successo.', Rec."Object ID to Run");
                            end;
                        Rec."Object Type to Run"::Report:
                            begin
                                Report.Run(Rec."Object ID to Run", false);
                                Message('Report %1 eseguito con successo.', Rec."Object ID to Run");
                            end;
                        else
                            ErrorMessage := StrSubstNo('Tipo oggetto %1 non supportato.', Rec."Object Type to Run");
                            Error(ErrorMessage);
                    end;
                end;
            }
        }
    }
}
