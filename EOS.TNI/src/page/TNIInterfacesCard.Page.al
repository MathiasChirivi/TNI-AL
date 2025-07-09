page 50143 "TNI Interfaces Card"
{
    PageType = Document;
    SourceTable = "TNI Interfaces";
    Caption = 'Interfaces Card (TNI)';
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = DynamicEditable;
                field("TNI Interface Status"; Rec."TNI Interface Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Status';
                }
                field("Flow Code"; Rec."Code")
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

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);

                        CurrPage.Flows.Page.SetDataExchTypeVisibility("Data Exchange Type");
                        CurrPage.Flows.Page.Update(false);
                    end;
                }
            }
            part(Flows; "TNI Flows")
            {
                ApplicationArea = Basic, Suite;
                Editable = DynamicEditable;
                Enabled = "Code" <> '';
                SubPageLink = "TNI Interface Code" = field("Code");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Release)
            {
                ApplicationArea = All;
                Caption = 'Release';
                Image = ReleaseDoc;
                Enabled = "TNI Interface Status" = "TNI Interface Status"::Open;

                trigger OnAction()
                begin
                    Rec.TestField("Code");
                    Rec.Validate("TNI Interface Status", Rec."TNI Interface Status"::Released);
                    Rec.Modify();
                end;
            }
            action(Reopen)
            {
                ApplicationArea = All;
                Caption = 'Reopen';
                Image = ReOpen;
                Enabled = ("TNI Interface Status" = "TNI Interface Status"::Closed) or ("TNI Interface Status" = "TNI Interface Status"::Released);

                trigger OnAction()
                begin
                    Rec.TestField("Code");
                    Rec.Validate("TNI Interface Status", Rec."TNI Interface Status"::Open);
                    Rec.Modify();
                end;
            }
            action(Close)
            {
                ApplicationArea = All;
                Caption = 'Close';
                Image = Close;
                Enabled = "TNI Interface Status" = "TNI Interface Status"::Open;

                trigger OnAction()
                begin
                    Rec.TestField("Code");
                    Rec.Validate("TNI Interface Status", Rec."TNI Interface Status"::Closed);
                    Rec.Modify();
                end;
            }
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
        //     group(Category_Category4)
        //     {
        //         Caption = 'Status';
        //         actionref(Release_Promoted; Release)
        //         {
        //         }
        //         actionref(Reopen_Promoted; Reopen)
        //         {
        //         }
        //         actionref(Close_Promoted; Close)
        //         {
        //         }
        //     }
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
    }

    trigger OnAfterGetRecord()
    begin
        case Rec."TNI Interface Status" of
            Rec."TNI Interface Status"::Open:
                DynamicEditable := true;
            else
                DynamicEditable := false;
        end;

        if DynamicEditable = false then
            CurrPage.Editable(DynamicEditable);

        Clear(DynamicEditable);
        DynamicEditable := CurrPage.Editable;
    end;

    trigger OnOpenPage()
    begin
        if Rec."Code" = '' then
            DynamicEditable := true;

        CurrPage.Flows.Page.SetDataExchTypeVisibility("Data Exchange Type");
    end;

    var
        DynamicEditable: Boolean;
}