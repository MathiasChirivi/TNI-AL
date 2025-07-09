codeunit 50092 "CM1 Credemtel Driver"
{
    trigger OnRun()
    var
        CREDEMENTELGeneralFunct: Codeunit "CM1 Credemtel Gen. Fnc.";
        Content: Text;
    begin
        Clear(CREDEMENTELGeneralFunct);

        case GlobalChannel of
            7:
                CREDEMENTELGeneralFunct.Credemtel_GeneralOrder_Seinding(GlobalPurchaseHeader);
            8:
                CREDEMENTELGeneralFunct.Credemtel_ClosePurchLine(GlobalPurchaseLine);
            9:
                CREDEMENTELGeneralFunct.Credemtel_CancelPurchLine(GlobalPurchaseLine);
            11:
                CREDEMENTELGeneralFunct.Credemtel_WriteReceiptAdviceStornoXML(GlobalPurchRcptHeader);
            12:
                CREDEMENTELGeneralFunct.Credemtel_WriteReceipt(GlobalPurchRcptHeader, GlobalPurchRcptLine);
            20:
                CREDEMENTELGeneralFunct.CredemtelGetOrderRespose(GlobalTNIInterfacesINEntry);
            21:
                CREDEMENTELGeneralFunct.CredemtelProcessOrderRespose();
            22:
                CREDEMENTELGeneralFunct.ProcessEntry(GlobalEntryNo);
        end;
    end;

    procedure SetParameters(SetChannel: Integer; var SetPurchaseHeader: Record "Purchase Header")
    begin
        Clear(GlobalChannel);
        Clear(GlobalPurchaseHeader);

        GlobalChannel := SetChannel;
        GlobalPurchaseHeader := SetPurchaseHeader;
    end;

    procedure SetParametersClose_CancelPurchLine(SetChannel: Integer; SetOutStream: OutStream; SetPurchaseHeader: Record "Purchase Header"; SetPurchaseLine: Record "Purchase Line")
    begin
        Clear(GlobalChannel);
        Clear(GlobalPurchaseHeader);
        Clear(GlobalPurchaseLine);

        GlobalChannel := SetChannel;
        GlobalPurchaseHeader := SetPurchaseHeader;
        GlobalPurchaseLine := SetPurchaseLine;
    end;

    procedure SetParametersReceiptAdviceStorno(SetChannel: Integer; SetPurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
        Clear(GlobalChannel);
        Clear(GlobalPurchRcptHeader);

        GlobalChannel := SetChannel;
        GlobalPurchRcptHeader := SetPurchRcptHeader;
    end;

    procedure SetParametersRecipt(SetChannel: Integer; var SetPurchRcptHeader: Record "Purch. Rcpt. Header"; var SetPurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        Clear(GlobalChannel);
        Clear(GlobalPurchRcptHeader);
        Clear(GlobalPurchRcptLine);

        GlobalChannel := SetChannel;
        GlobalPurchRcptHeader := SetPurchRcptHeader;
        GlobalPurchRcptLine := SetPurchRcptLine;
    end;

    procedure SetParametersGetOrders(SetChannel: Integer; var TNIInterfacesINEntry: Record "TNI Interfaces IN Entry")
    begin
        Clear(GlobalChannel);
        Clear(GlobalTNIInterfacesINEntry);

        GlobalChannel := SetChannel;
        GlobalTNIInterfacesINEntry := TNIInterfacesINEntry;
    end;

    procedure SetParametersProcessOrderResponse(SetChannel: Integer; var CM1CredemtelStaging: Record "CM1 Credemtel Staging")
    begin
        Clear(GlobalChannel);
        Clear(GlobalTNIInterfacesINEntry);

        GlobalChannel := SetChannel;
        GlobalCM1CredemtelStaging := CM1CredemtelStaging;
    end;

    procedure SetParametersEntryNo(SetChannel: Integer; SetEntryNo: Integer)
    begin
        Clear(GlobalChannel);
        Clear(GlobalEntryNo);

        GlobalChannel := SetChannel;
        GlobalEntryNo := SetEntryNo;
    end;

    var
        GlobalPurchaseHeader: Record "Purchase Header";
        GlobalPurchaseLine: Record "Purchase Line";
        GlobalPurchRcptHeader: Record "Purch. Rcpt. Header";
        GlobalPurchRcptLine: Record "Purch. Rcpt. Line";
        GlobalTNIInterfacesINEntry: Record "TNI Interfaces IN Entry";
        GlobalCM1CredemtelStaging: Record "CM1 Credemtel Staging";
        GlobalEntryNo: Integer;
        GlobalChannel: Integer;
}