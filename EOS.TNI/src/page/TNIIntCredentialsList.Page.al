page 50142 "TNI Credentials List"
{
    PageType = List;
    Caption = 'Credentials (TNI)';
    UsageCategory = Administration;
    ApplicationArea = All;
    SourceTable = "TNI Interfaces Credentials";
    CardPageId = "TNI Credentials Card";

    layout
    {
        area(Content)
        {
            repeater(CredentialsList)
            {
                field("TNI Credential Code"; Rec."Credential Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Authentication Type"; Rec."Authentication Type")
                {
                }
            }
        }
    }

    actions
    {
    }
}