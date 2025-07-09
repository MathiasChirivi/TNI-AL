page 50141 "TNI Flows"
{
    PageType = ListPart;
    SourceTable = "TNI Flows";
    DelayedInsert = true;
    LinksAllowed = false;
    Caption = 'Flows (TNI)';
    // ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(InterfacesList)
            {
                field(Enable; Rec.Enable)
                {
                    ToolTip = 'Enable';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("TNI Flow Code"; Rec."TNI Flow Code")
                {
                    ToolTip = 'Flow Code';
                    StyleExpr = CodeStyleExpr;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Description';
                }
                field("TNI Interface Type"; Rec."TNI Interface Type")
                {
                    ToolTip = 'Interface Type';
                }
                field("TNI Flow Type"; Rec."TNI Flow Type")
                {
                    ToolTip = 'Flow Type';
                    Style = Strong;
                }
                field("Table No."; Rec."Table No.")
                {
                    Enabled = "TNI Flow Type" = "TNI Flow Type"::"In";
                }
                field("TNI File Path"; Rec."TNI File Path")
                {
                    ToolTip = 'File Path';
                    Visible = DataExchangeType = DataExchangeType::File;
                }
                field("TNI Archived File Path"; Rec."TNI Archived File Path")
                {
                    Visible = DataExchangeType = DataExchangeType::File;
                }
                field("TNI File Name Code"; Rec."TNI File Name Code")
                {
                    ToolTip = 'File name with no. series';
                    Visible = DataExchangeType = DataExchangeType::File;
                }
                field("EOS Function API Code"; Rec."EOS Function API Code")
                {
                    ToolTip = 'EOS Function API Code';
                    Visible = DataExchangeType = DataExchangeType::File;
                }
                field("WS Uri"; Rec."WS Uri")
                {
                    ToolTip = 'WS Uri';
                    Visible = DataExchangeType = DataExchangeType::"Web Services";
                    Enabled = (DataExchangeType = DataExchangeType::"Web Services") and ("TNI Flow Type" = "TNI Flow Type"::Out);
                }
                field("WS Method"; Rec."WS Method")
                {
                    Visible = DataExchangeType = DataExchangeType::"Web Services";
                    Enabled = (DataExchangeType = DataExchangeType::"Web Services") and ("TNI Flow Type" = "TNI Flow Type"::Out);
                }
                field("TNI Credential Code"; Rec."TNI Credential Code")
                {
                    ToolTip = 'Credentials';
                }
                field("TNI Import Mode"; Rec."TNI Import Mode")
                {
                    Visible = DataExchangeType = DataExchangeType::File;
                }
                field("TNI Process"; Rec."TNI Process")
                {
                    Enabled = "TNI Flow Type" = "TNI Flow Type"::"In";
                }
                field("Process Single Record"; Rec."Process Single Record")
                {
                    Enabled = "TNI Flow Type" = "TNI Flow Type"::"In";
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Entries)
            {
                ApplicationArea = All;
                Caption = 'Entries';
                Image = EntriesList;

                trigger OnAction()
                var
                    TNIInterfacesWSIN: Record "TNI Interfaces IN Entry";
                    TNIInterfacesWSOUT: Record "TNI Interfaces OUT Entry";
                    TNIInterfacesINEntries: Page "TNI Interfaces IN Entries";
                    TNIInterfacesOUTEntries: Page "TNI Interfaces OUT Entries";
                begin
                    case Rec."TNI Flow Type" of
                        Rec."TNI Flow Type"::"In":
                            begin
                                TNIInterfacesWSIN.Reset();
                                TNIInterfacesWSIN.SetRange("TNI Interface Code", Rec."TNI Interface Code");
                                TNIInterfacesWSIN.SetRange("TNI Flow Code", Rec."TNI Flow Code");
                                TNIInterfacesWSIN.FindSet();

                                TNIInterfacesINEntries.SetTableView(TNIInterfacesWSIN);
                                TNIInterfacesINEntries.RunModal();
                            end;
                        Rec."TNI Flow Type"::"Out":
                            begin
                                TNIInterfacesWSOUT.Reset();
                                TNIInterfacesWSOUT.SetRange("TNI Interface Code", Rec."TNI Interface Code");
                                TNIInterfacesWSOUT.SetRange("TNI Flow Code", Rec."TNI Flow Code");
                                TNIInterfacesWSOUT.FindSet();

                                TNIInterfacesOUTEntries.SetTableView(TNIInterfacesWSOUT);
                                TNIInterfacesOUTEntries.RunModal();
                            end;
                    end;
                end;
            }
            action("Execute Manually")
            {
                ApplicationArea = All;
                Caption = 'Execute Manually';
                Image = ExecuteBatch;

                trigger OnAction()
                var
                    ExecCompletedMsg: Label 'Execution completed';
                begin
                    Rec.TestField("TNI Flow Type", Rec."TNI Flow Type"::"In");

                    TNIMgt.ReadFlow(Rec."TNI Interface Code", Rec."TNI Flow Code");

                    Message(ExecCompletedMsg);
                end;
            }
            action("View Token")
            {
                ApplicationArea = All;
                Caption = 'View Token';
                Image = View;

                trigger OnAction()
                var
                    InStr: InStream;
                    ResultText: Text;
                begin
                    Rec.CalcFields("Access Token");
                    Rec."Access Token".CreateInStream(InStr, TextEncoding::UTF8);
                    InStr.Read(ResultText);
                    Message(ResultText);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if TNIInterfaces.Get(Rec."TNI Interface Code") then
            DataExchangeType := TNIInterfaces."Data Exchange Type";
    end;

    trigger OnAfterGetRecord()
    begin
        CodeStyleExpr := 'Strong';
        if Rec.Enable then
            CodeStyleExpr := 'Favorable'
    end;

    procedure SetDataExchTypeVisibility(inDataExchangeType: Enum "TNI Data Exchange Type")
    begin
        DataExchangeType := inDataExchangeType;
    end;

    var
        TNIInterfaces: Record "TNI Interfaces";
        TNIMgt: Codeunit "TNI Mgt.";
        CodeStyleExpr: Text;
        DataExchangeType: Enum "TNI Data Exchange Type";
}