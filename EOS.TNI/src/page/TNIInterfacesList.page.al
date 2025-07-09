page 50146 "TNI Interfaces List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "TNI Interfaces";
    Caption = 'Interfaces List (TNI)';
    CardPageId = "TNI Interfaces Card";
    Editable = false;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            repeater(FlowList)
            {
                field("TNI Interface Status"; Rec."TNI Interface Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Status';
                    StyleExpr = StatusStyleExpr;
                }
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Code';
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Description';
                }
                field("Data Exchange Type"; Rec."Data Exchange Type")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Import Setup")
            {
                ApplicationArea = All;
                Caption = 'Import Setup';
                Image = Import;
                trigger OnAction()
                begin
                    Rec.ImportMapping();
                end;
            }
            action("Export Setup")
            {
                ApplicationArea = All;
                Caption = 'Export Setup';
                Image = Export;
                trigger OnAction()
                begin
                    Rec.ExportMapping();
                end;
            }
        }
        // area(Promoted)
        // {
        //     group(Category_Category6)
        //     {
        //         Caption = 'Import/Export';
        //         actionref(ImportSetup_Promoted; "Import Setup")
        //         {
        //         }
        //         actionref(ExportSetup_Promoted; "Export Setup")
        //         {
        //         }
        //     }
        // }
    }

    trigger OnAfterGetRecord()
    begin
        StatusStyleExpr := 'Standard';

        case Rec."TNI Interface Status" of
            Rec."TNI Interface Status"::Released:
                StatusStyleExpr := 'Favorable';
            Rec."TNI Interface Status"::Closed:
                StatusStyleExpr := 'Unfavorable';
        end;
    end;

    procedure GetSelectionFilter(): Text
    var
        TNIInterfaces: Record "TNI Interfaces";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecRef: RecordRef;
    begin
        CurrPage.SetSelectionFilter(TNIInterfaces);
        RecRef.GetTable(TNIInterfaces);
        exit(SelectionFilterManagement.GetSelectionFilter(RecRef, TNIInterfaces.FieldNo(Code)));
    end;

    var
        StatusStyleExpr: Text;
}