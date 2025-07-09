pageextension 50107 "CM1 User Setup Card" extends "User Setup Card"
{
    layout
    {
        addafter("CAMEOS CAMA")
        {
            group(CREDEMTEL)
            {
                Caption = 'CREDEMTEL';
                field("CM1 Credemtel Delete Line"; Rec."CM1 Credemtel Delete Line")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
    }

    var
}