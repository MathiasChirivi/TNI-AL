page 50144 "TNI Interfaces IN Entries"
{
    PageType = List;
    Caption = 'Interfaces IN Entries (TNI)';
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "TNI Interfaces IN Entry";
    Editable = false;
    DeleteAllowed = false;
    SourceTableView = sorting("TNI Timestamp") order(descending);

    layout
    {
        area(Content)
        {
            repeater(EntriesList)
            {
                field("Entry No."; Rec."Entry No.")
                {
                }
                field("TNI Status"; Rec."TNI Status")
                {
                    StyleExpr = StatusColour;
                }
                field("TNI Interface Code"; Rec."TNI Interface Code")
                {
                }
                field("TNI Flow Code"; Rec."TNI Flow Code")
                {
                }
                field("TNI Transaction ID"; Rec."TNI Transaction ID")
                {
                }
                field("TNI Timestamp"; Rec."TNI Timestamp")
                {
                }
                field("TNI File Name"; Rec."TNI File Name")
                {
                }
                field("TNI Source Key Text"; Rec."TNI Source Key Text")
                {
                }
                field("TNI Document No."; Rec."TNI Document No.")
                {
                    //Visible = DocumentEnable;
                }
                field("TNI Posted Document No."; Rec."TNI Posted Document No.")
                {
                    //Visible = DocumentEnable;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(ViewTools)
            {
                Caption = 'View';
                Image = View;
                action(ViewRecords_)
                {
                    Caption = 'View Records';
                    ApplicationArea = All;
                    Image = Line;
                    Enabled = "TNI Flow Code" <> '';

                    trigger OnAction()
                    var
                        TNIFlows: Record "TNI Flows";
                        RecRef: RecordRef;
                        FldRef: FieldRef;
                        RecVariant: Variant;
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;

                        TNIFlows.Get(Rec."TNI Interface Code", Rec."TNI Flow Code");
                        TNIFlows.TestField("Table No.");

                        RecRef.Open(TNIFlows."Table No.");

                        OnAfterOpenRecRef_ViewRecords(IsHandled, RecRef, Rec);

                        if not IsHandled then begin
                            FldRef := RecRef.Field(1000);
                            FldRef.SetRange(Rec."TNI Interface Code");

                            FldRef := RecRef.Field(1001);
                            FldRef.SetRange(Rec."TNI Flow Code");

                            FldRef := RecRef.Field(1002);
                            FldRef.SetRange(Rec."TNI Transaction ID");
                        end;

                        RecRef.FindFirst();
                        RecVariant := RecRef;

                        Page.RunModal(0, RecVariant);
                    end;
                }
                action(ProcessSelected_)
                {
                    ApplicationArea = All;
                    Caption = 'Process Selected';
                    Image = Process;
                    Enabled = "TNI Flow Code" <> '';

                    trigger OnAction()
                    var
                        TNIFlows: Record "TNI Flows";
                        TNIInterfacesINEntry: Record "TNI Interfaces IN Entry";
                        TNIMgt: Codeunit "TNI Mgt.";
                        IsHandled: Boolean;
                        Text001Msg: Label 'Completed';
                        EmptyGUID: Guid;
                    begin
                        OnBeforeOnAction_ProcessSelected(Rec, IsHandled);
                        if IsHandled then
                            exit;

                        CurrPage.SetSelectionFilter(TNIInterfacesINEntry);

                        if TNIInterfacesINEntry.IsEmpty then
                            exit;

                        TNIInterfacesINEntry.FindSet();

                        repeat
                            TNIFlows.Get(TNIInterfacesINEntry."TNI Interface Code", TNIInterfacesINEntry."TNI Flow Code");
                            TNIFlows.TestField(Enable);
                            TNIFlows.TestField("Process Single Record", false);

                            TNIMgt.ProcessReadFlow(TNIInterfacesINEntry, TNIFlows, EmptyGUID);
                        until TNIInterfacesINEntry.Next() = 0;

                        Message(Text001Msg);
                    end;
                }
                action(ViewEntryLog_)
                {
                    Caption = 'View Log Details';
                    ApplicationArea = All;
                    Image = View;
                    Enabled = "TNI Flow Code" <> '';

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
                action(ViewFile_)
                {
                    ApplicationArea = All;
                    Caption = 'View JSON File';
                    Image = View;

                    trigger OnAction()
                    var
                        InStr: InStream;
                        ResultText: Text;
                    begin
                        Rec.CalcFields("TNI File");
                        Rec."TNI File".CreateInStream(InStr, TextEncoding::UTF8);
                        InStr.Read(ResultText);
                        Message(ResultText);
                    end;
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                //Visible = DocumentEnable;
                action("Show Document")
                {
                    Caption = 'Show Document';
                    ApplicationArea = All;
                    Image = Order;

                    trigger OnAction()
                    begin
                        OnAction_ShowDocument(Rec);
                    end;
                }
                action("Show Posted Document")
                {
                    Caption = 'Show Posted Document';
                    ApplicationArea = All;
                    Image = PostedOrder;

                    trigger OnAction()
                    begin
                        OnAction_ShowPostedDocument(Rec);
                    end;
                }
            }
        }

        // area(Promoted)
        // {
        //     group(Category_Category4)
        //     {
        //         Caption = 'Records';
        //         actionref(ViewRecords__Promoted; ViewRecords_)
        //         {
        //         }
        //         actionref(ViewEntryLog__Promoted; ViewEntryLog_)
        //         {
        //         }
        //         actionref(ProcessSelected__Promoted; ProcessSelected_)
        //         {
        //         }
        //     }
        //     group(Category_Category6)
        //     {
        //         Caption = 'Documents';
        //         actionref(ShowDocument_Promoted; "Show Document")
        //         {
        //         }
        //         actionref(ShowPostedDocument_Promoted; "Show Posted Document")
        //         {
        //         }
        //     }
        // }
    }

    trigger OnOpenPage()
    begin
        //DocumentEnable := false;
        //EnableDocumentMgt(Rec, DocumentEnable);
    end;

    trigger OnAfterGetRecord()
    begin
        Clear(StatusColour);
        case Rec."TNI Status" of
            Rec."TNI Status"::"TNI Received":
                StatusColour := 'Subordinate';
            Rec."TNI Status"::"TNI Processed":
                StatusColour := 'favorable';
            Rec."TNI Status"::"TNI Not Processed":
                StatusColour := 'Ambiguous';
            Rec."TNI Status"::"TNI Error":
                StatusColour := 'unfavorable';
            Rec."TNI Status"::"TNI Closed":
                StatusColour := 'StandardAccent';
        end;
    end;

    // [IntegrationEvent(false, false)]
    // local procedure EnableDocumentMgt(Rec: Record "TNI Interfaces IN Entry"; var DocumentEnable: Boolean)
    // begin
    // end;

    [IntegrationEvent(false, false)]
    local procedure OnAction_ShowDocument(Rec: Record "TNI Interfaces IN Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAction_ShowPostedDocument(Rec: Record "TNI Interfaces IN Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAction_ProcessSelected(var Rec: Record "TNI Interfaces IN Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenRecRef_ViewRecords(var IsHandled: Boolean; var RecRef: RecordRef; Rec: Record "TNI Interfaces IN Entry")
    begin
    end;

    var
        StatusColour: Text;
    //DocumentEnable: Boolean;
}