page 50147 "TNI Interfaces Log List"
{
    PageType = List;
    UsageCategory = None;
    SourceTable = "TNI Interfaces Log";
    // SourceTableView = sorting(SystemCreatedAt);
    Caption = 'Interfaces Log List (TNI)';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    // ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("TNI Interface Code"; Rec."TNI Interface Code")
                {
                }
                field("TNI Flow Code"; Rec."TNI Flow Code")
                {
                }
                field("Table No."; Rec."Table No.")
                {
                    // Visible = false;
                }
                field("TNI Source ID"; Rec."TNI Source ID")
                {
                    // Visible = false;
                }
                field("TNI Source Line No."; Rec."TNI Source Line No.")
                {
                    // Visible = false;
                }
                field("TNI Transaction ID"; Rec."TNI Transaction ID")
                {
                    Visible = false;
                }
                field("TNI Timestamp"; Rec."TNI Timestamp")
                {
                }
                field("TNI Log Type"; Rec."TNI Log Type")
                {
                    StyleExpr = StatusColour;
                }
                field("TNI Log Description"; Rec."TNI Log Description")
                {
                    Style = Strong;
                }
                field("TNI Last Stack Error"; Rec."TNI Last Stack Error")
                {
                }
                field("Log Group ID"; Rec."Log Group ID")
                {
                    Visible = false;
                }

            }
        }
    }
    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Clear(StatusColour);
        case Rec."TNI Log Type" of
            Rec."TNI Log Type"::Information:
                StatusColour := 'Favorable';
            Rec."TNI Log Type"::Error:
                StatusColour := 'Unfavorable';
            Rec."TNI Log Type"::Warning:
                StatusColour := 'Ambiguous';
        end;
    end;

    var
        StatusColour: Text;
}