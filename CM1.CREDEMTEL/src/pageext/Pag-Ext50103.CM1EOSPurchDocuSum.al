pageextension 50103 "CM1 EOS Purch Docu Sum" extends "EOS Purchase Document Summary"
{
    layout
    {
        addafter(Type)
        {
            field("CM1 Send to Credemetel"; Rec."CM1 Send to Credemetel")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("CM1 Change Price Credemtel"; Rec."CM1 Change Price Credemtel")
            {
                ApplicationArea = All;
            }
            field("CM1 Missed engag Credemtel"; Rec."CM1 Missed engag Credemtel")
            {
                ApplicationArea = All;
            }
            field("CM1 Credemtel Ord Line Status"; Rec."CM1 Credemtel Ord Line Status")
            {
                ApplicationArea = All;
            }

        }
    }
}