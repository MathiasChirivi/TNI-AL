page 50130 "CM1 Credemtel Error Log List"
{
    PageType = List;
    SourceTable = "CM1 Credemtel Error Log";
    Caption = 'Credemtel Error Log';
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; "Entry No.") { ApplicationArea = All; }
                field("Order No."; "Order No.") { ApplicationArea = All; }
                field("Order Line No."; "Order Line No.") { ApplicationArea = All; }
                field("Interface Entry No."; "Interface Entry No.") { ApplicationArea = All; }
                field("Error Message"; "Error Message") { ApplicationArea = All; }
                field("Error Date"; "Error Date") { ApplicationArea = All; }
                field("Error Time"; "Error Time") { ApplicationArea = All; }
                field("User ID"; "User ID") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProcessSelected)
            {
                ApplicationArea = All;
                Caption = 'Process Selected';
                Image = Process;
                trigger OnAction()
                var
                    RecordRef: RecordRef;
                begin
                    // CurrPage.SetSelectionFilter(RecordRef);
                end;
            }
        }
    }

}