pageextension 50106 "CM1 Purchase Lines" extends "Purchase Lines"
{
    layout
    {
        addafter(Description)
        {
            field("CM1 Send to Credemetel"; Rec."CM1 Send to Credemetel")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
    }
}