pageextension 65009 "CM1 Vendor Card" extends "Vendor Card"
{
    layout
    {
        addafter(IUNGO)
        {
            group(CREDEMTEL)
            {
                Caption = 'Credemtel';
                field("CM1 Credemtel Active"; Rec."CM1 Credemtel Active")
                {
                    ApplicationArea = All;
                }
                field("CM1 Credemtel Auto Send"; Rec."CM1 Credemtel Auto Send")
                {
                    ApplicationArea = All;
                }
                field("CM1 Credemtel Activation Date"; Rec."CM1 Credemtel Activation Date")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}