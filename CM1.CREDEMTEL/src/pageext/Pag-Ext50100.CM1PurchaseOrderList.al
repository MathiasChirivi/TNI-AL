pageextension 50100 "CM1 Purchase Order List" extends "Purchase Order List"
{
    layout
    {
        addafter("Assigned User ID")
        {
            field("CM1 Credemtel Order Date"; Rec."CM1 Credemtel Order Date")
            {
                ApplicationArea = All;
            }
        }
    }
}