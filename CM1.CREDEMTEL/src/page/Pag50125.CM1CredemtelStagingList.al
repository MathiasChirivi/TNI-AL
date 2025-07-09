page 50125 "CM1 Credemtel Staging List"
{
    PageType = List;
    SourceTable = "CM1 Credemtel Staging";
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Credemtel Order Staging List';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Order No."; "Order No.")
                {
                    ApplicationArea = All;
                }
                field("Order Line No."; "Order Line No.")
                {
                    ApplicationArea = All;
                }
                field("Movement Type"; Rec."Movement Type")
                {
                    ApplicationArea = All;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = All;
                }
                field("Trace Type"; Rec."Trace Type")
                {
                    ApplicationArea = All;
                }
                field("Status"; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StyleExp;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = All;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = All;
                }
                field("Item Description"; "Item Description")
                {
                    ApplicationArea = All;
                }
                field("Cross Reference No."; "Cross Reference No.")
                {
                    ApplicationArea = All;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = All;
                }
                field("Quantity"; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = All;
                }
                field("Promised Receipt Date"; "Promised Receipt Date")
                {
                    ApplicationArea = All;
                }
                field("Received Quantity"; "Received Quantity")
                {
                    ApplicationArea = All;
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = All;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = All;
                }
                field("Order Confirmation No."; "Order Confirmation No.")
                {
                    ApplicationArea = All;
                }
                field("Import Date"; "Import Date")
                {
                    ApplicationArea = All;
                }
                field("Import Time"; "Import Time")
                {
                    ApplicationArea = All;
                }
                field("Processing Date"; "Processing Date")
                {
                    ApplicationArea = All;
                }
                field("Processing Time"; "Processing Time")
                {
                    ApplicationArea = All;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = All;
                }
                field("Error Message"; "Error Message")
                {
                    ApplicationArea = All;
                }
                field("Is Error"; "Is Error")
                {
                    ApplicationArea = All;
                }
                field("Send DateTime"; "Send DateTime")
                {
                    ApplicationArea = All;
                }
                field("Line Status Code"; "Line Status Code")
                {
                    ApplicationArea = All;
                }
                field("Country of Origin Code"; "Country of Origin Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Order")
            {
                action("Open Order")
                {
                    Caption = 'Process Order';
                    Image = Process;
                    ApplicationArea = All;
                    trigger OnAction()
                    var
                        CREDEMENTELGeneralFunct: Codeunit "CM1 Credemtel Gen. Fnc.";
                    begin
                        if Rec."Movement Type" = rec."Movement Type"::"Exit" then
                            exit;
                        CREDEMENTELGeneralFunct.ProcessEntry("Entry No.");
                    end;
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Completed:
                StyleExp := 'Favorable'; // Verde
            Rec.Status::Error:
                StyleExp := 'Unfavorable'; // Rosso
            Rec.Status::InProgress:
                StyleExp := 'Normal'; // Giallo
            else
                StyleExp := ''; // Nessuno stile
        end;
    end;

    var
        StyleExp: Text;
}
