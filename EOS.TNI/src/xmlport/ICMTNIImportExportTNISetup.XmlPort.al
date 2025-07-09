xmlport 50100 "TNI Import/Export TNI Setup"
{
    Caption = 'Import/Export TNI Setup (TNI)';
    Encoding = UTF8;
    FormatEvaluate = Xml;
    DefaultFieldsValidation = false;

    schema
    {
        textelement(root)
        {
            tableelement(TNIInterfaces; "TNI Interfaces")
            {
                MinOccurs = Zero;
                XmlName = 'TNIInterfaces';
                fieldelement("Code"; TNIInterfaces."Code")
                {
                    trigger OnAfterAssignField()
                    var
                        TNIFlows: Record "TNI Flows";
                    begin
                        TNIFlows.Reset();
                        TNIFlows.SetRange("TNI Interface Code", TNIInterfaces."Code");
                        TNIFlows.DeleteAll();
                    end;
                }
                fieldelement(Description; TNIInterfaces.Description)
                {
                }
                fieldelement(DataExchangeType; TNIInterfaces."Data Exchange Type")
                {
                }
                tableelement(TNIFlows; "TNI Flows")
                {
                    MinOccurs = Zero;
                    XmlName = 'TNIFlows';
                    LinkTable = TNIInterfaces;
                    LinkFields = "TNI Interface Code" = field(Code);
                    SourceTableView = sorting("TNI Interface Code", "TNI Flow Code");
                    fieldelement(TNIInterfaceCode; TNIFlows."TNI Interface Code")
                    {
                    }
                    fieldelement(TNIFlowCode; TNIFlows."TNI Flow Code")
                    {
                    }
                    fieldelement(WSUri; TNIFlows."WS Uri")
                    {
                    }
                    fieldelement(TNICredentialCode; TNIFlows."TNI Credential Code")
                    {
                    }
                    fieldelement(Description; TNIFlows.Description)
                    {
                    }
                    fieldelement(TNIInterfaceType; TNIFlows."TNI Interface Type")
                    {
                    }
                    fieldelement(TNIFlowType; TNIFlows."TNI Flow Type")
                    {
                    }
                    fieldelement(TNIImportMode; TNIFlows."TNI Import Mode")
                    {
                    }
                    fieldelement(TNIProcess; TNIFlows."TNI Process")
                    {
                    }
                    fieldelement(TNIGUID; TNIFlows."TNI GUID")
                    {
                    }
                    fieldelement(TNIFilePath; TNIFlows."TNI File Path")
                    {
                    }
                    fieldelement(TNIArchivedFilePath; TNIFlows."TNI Archived File Path")
                    {
                    }
                    fieldelement(EOSFunctionAPICode; TNIFlows."EOS Function API Code")
                    {
                    }
                    fieldelement(TNIFileNameCode; TNIFlows."TNI File Name Code")
                    {
                    }
                    fieldelement(TableNo; TNIFlows."Table No.")
                    {
                    }
                    fieldelement(WSMethod; TNIFlows."WS Method")
                    {
                    }
                    fieldelement(ProcessSingleRecord; TNIFlows."Process Single Record")
                    {
                    }
                    fieldelement(Enable; TNIFlows.Enable)
                    {
                    }
                }
            }
        }
    }
}