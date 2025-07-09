page 50148 "TNI Interfaces OUT Entries"
{
    PageType = List;
    Caption = 'Interfaces OUT Entries (TNI)';
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "TNI Interfaces OUT Entry";
    Editable = false;
    DeleteAllowed = false;
    SourceTableView = sorting("TNI Timestamp") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Control1)
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
                field("TNI Timestamp"; Rec."TNI Timestamp")
                {
                }
                field("TNI File Name"; Rec."TNI File Name")
                {
                }
                field("TNI File Path"; Rec."TNI File Path")
                {
                }
                field("TNI Source Key Text"; Rec."TNI Source Key Text")
                {
                    Visible = false;
                }
                field("TNI Document No."; Rec."TNI Document No.")
                {
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
            action(ViewEntryLog)
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
            group("Sent Group")
            {
                Caption = 'Sent';
                action("View Sent File")
                {
                    ApplicationArea = All;
                    Caption = 'View Sent File';
                    Image = View;
                    Enabled = "TNI Flow Code" <> '';

                    trigger OnAction()
                    var
                        InStr: InStream;
                        ResultText: Text;
                    begin
                        Rec.CalcFields("TNI Sent File");
                        Rec."TNI Sent File".CreateInStream(InStr, TextEncoding::UTF8);
                        InStr.Read(ResultText);
                        Message(ResultText);
                    end;
                }
                action("Download Sent File")
                {
                    ApplicationArea = All;
                    Caption = 'Download Sent File';
                    Image = Download;
                    Enabled = "TNI Flow Code" <> '';

                    trigger OnAction()
                    var
                        InStr: InStream;
                        FileName: Text;
                    begin
                        Rec.CalcFields("TNI Sent File");
                        Rec."TNI Sent File".CreateInStream(InStr, TextEncoding::UTF8);

                        FileName := Rec."TNI File Name";

                        DownloadFromStream(InStr, '', '', '', FileName);
                    end;
                }
            }
            group("Response Group")
            {
                Caption = 'Response';
                action("View Response File")
                {
                    ApplicationArea = All;
                    Caption = 'View Response File';
                    Image = View;
                    Enabled = "TNI Flow Code" <> '';

                    trigger OnAction()
                    var
                        InStr: InStream;
                        ResultText: Text;
                    begin
                        Rec.CalcFields("TNI Response File");
                        Rec."TNI Response File".CreateInStream(InStr, TextEncoding::UTF8);
                        InStr.Read(ResultText);
                        Message(ResultText);
                    end;
                }
                action("Download Response File")
                {
                    ApplicationArea = All;
                    Caption = 'Download Response File';
                    Image = Download;
                    Enabled = "TNI Flow Code" <> '';

                    trigger OnAction()
                    var
                        InStr: InStream;
                        FileName: Text;
                    begin
                        Rec.CalcFields("TNI Response File");
                        Rec."TNI Response File".CreateInStream(InStr, TextEncoding::UTF8);

                        FileName := Rec."TNI File Name";

                        DownloadFromStream(InStr, '', '', '', FileName);
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
            }
        }
        // area(Promoted)
        // {
        //     group(Category_Process)
        //     {
        //         actionref(ViewEntryLog_Promoted; ViewEntryLog)
        //         {
        //         }
        //     }
        //     group(Category_Category4)
        //     {
        //         Caption = 'Sent';
        //         actionref(ViewSentFile_Promoted; "View Sent File")
        //         {
        //         }
        //         actionref(DownloadSentFile_Promoted; "Download Sent File")
        //         {
        //         }
        //     }
        //     group(Category_Category5)
        //     {
        //         Caption = 'Response';
        //         actionref(ViewResponseFile_Promoted; "View Response File")
        //         {
        //         }
        //         actionref(DownloadResponseFile_Promoted; "Download Response File")
        //         {
        //         }
        //     }
        //     group(Category_Category6)
        //     {
        //         Caption = 'Documents';
        //         actionref(ShowDocument_Promoted; "Show Document")
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
            Rec."TNI Status"::"TNI Sent":
                StatusColour := 'favorable';
            Rec."TNI Status"::"TNI Error":
                StatusColour := 'unfavorable';
        end;
    end;

    // [IntegrationEvent(false, false)]
    // local procedure EnableDocumentMgt(Rec: Record "TNI Interfaces OUT Entry"; var DocumentEnable: Boolean)
    // begin
    // end;

    [IntegrationEvent(false, false)]
    local procedure OnAction_ShowDocument(Rec: Record "TNI Interfaces OUT Entry")
    begin
    end;

    var
        StatusColour: Text;
    //DocumentEnable: Boolean;
}