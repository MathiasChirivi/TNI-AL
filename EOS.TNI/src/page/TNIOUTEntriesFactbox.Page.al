page 50149 "TNI OUT Entries Factbox"
{
    PageType = ListPart;
    Caption = 'Interfaces OUT Entries (TNI)';
    Editable = false;
    // ApplicationArea = All;
    SourceTable = "TNI Interfaces OUT Entry";
    SourceTableView = sorting("TNI Timestamp") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Control)
            {
                field("TNI Interface Code"; Rec."TNI Interface Code")
                {
                }
                field("TNI Timestamp"; Rec."TNI Timestamp")
                {
                }
                field("TNI Status"; Rec."TNI Status")
                {
                    StyleExpr = StatusColour;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewEntryLog)
            {
                Caption = 'View Log Details';
                ApplicationArea = All;
                Image = View;
                Enabled = Rec."TNI Flow Code" <> '';
                Scope = Repeater;

                trigger OnAction()
                var
                    TNIInterfacesLog: Record "TNI Interfaces Log";
                begin
                    TNIInterfacesLog.Reset();
                    TNIInterfacesLog.SetRange("TNI Interface Code", Rec."TNI Interface Code");
                    TNIInterfacesLog.SetRange("TNI Flow Code", Rec."TNI Flow Code");
                    TNIInterfacesLog.SetRange("TNI Transaction ID", Rec."TNI Transaction ID");
                    Page.Run(Page::"TNI Interfaces Log List", TNIInterfacesLog);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Clear(StatusColour);
        case Rec."TNI Status" of
            Rec."TNI Status"::"TNI Sent":
                StatusColour := 'favorable';
            Rec."TNI Status"::"TNI Error":
                StatusColour := 'unfavorable';
        end;
    end;

    procedure SetFactboxFilter(KeyFilter: Text)
    begin
        Rec.SetRange("TNI Source Key Text", KeyFilter);
        CurrPage.SetTableView(Rec);
    end;

    procedure SetFactboxFilterDocNo(DocumentNo: Code[20])
    begin
        Rec.SetRange("TNI Document No.", DocumentNo);
        CurrPage.SetTableView(Rec);
    end;

    var
        StatusColour: Text;
}