codeunit 50091 "CM1 Credemtel Management"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EOS DS Management", 'OnDiscoverDSFunctions', '', false, false)]
    local procedure OnDiscoverDSFunctions(var DataSecurityFunctions: Record "EOS DS Functions")
    var
        EOSDSFunctions: Codeunit "EOS DS Functions";
        CredementelEDSSendOrderLbl: Label 'EXPORT_CREDEMTEL';
        CredemFnc1Lbl: Label 'EXPORT_CREDEMTEL';
    begin
        EOSDSFunctions.CreateDSFunction(DataSecurityFunctions, CredementelEDSSendOrderLbl, Database::"Purchase Header", 1, CopyStr(CredemFnc1Lbl, 1, 50));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EOS DS Management", 'OnExecuteDSFunction', '', false, false)]
    local procedure OnExecuteDSFunction(var DataSecurityFunctions: Record "EOS DS Functions"; DataSecurityStatusFunctions: Record "EOS DS Status Functions"; var RecRef: RecordRef; var ContinueExecution: Boolean; UseOptionType: Boolean; TableOptionType: Integer)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry";
        CM1CREDEMTELDriver: Codeunit "CM1 Credemtel Driver";
        TNIMgt: Codeunit "TNI Mgt.";
        NullRecRef: RecordRef;
        FncTxtCredemLbl: Label 'EXPORT_CREDEMTEL';
        XMLSavedSuccLbl: Label 'File XML saved successfully';
    begin
        case DataSecurityFunctions.Type of
            DataSecurityFunctions.Type::Exec:
                case DataSecurityFunctions.Code of
                    FncTxtCredemLbl:
                        ContinueExecution := EXPORT_CREDEMTEL(RecRef);
                end;
        end;
    end;

    local procedure EXPORT_CREDEMTEL(var RecRef: RecordRef): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry";
        CM1CredemtelGenFnc: Codeunit "CM1 Credemtel Gen. Fnc.";
        CM1CREDEMTELDriver: Codeunit "CM1 Credemtel Driver";
        TNIMgt: Codeunit "TNI Mgt.";
        NullRecRef: RecordRef;
        FileName: Text;
        FileNameXsl: Text;
        FncTxtCredemLbl: Label 'EXPORT_CREDEMTEL';
        XMLSavedSuccLbl: Label 'File XML saved successfully';
    begin
        RecRef.SetTable(PurchaseHeader);
        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Order then
            exit(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Interface");
        PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Flow");
        PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Change Order");

        if not PurchasesPayablesSetup."CM1 Credemtel Enabled" then
            exit;

        if Vendor.Get(PurchaseHeader."Buy-from Vendor No.") then
            if not Vendor."CM1 Credemtel Active" then
                exit;

        if not Vendor."CM1 Credemtel Auto Send" then
            exit;

        if PurchaseHeader."Document Date" < Vendor."CM1 Credemtel Activation Date" then
            exit;

        Clear(PurchaseLine);
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("CM1 Send to Credemetel", false);
        if PurchaseLine.IsEmpty() then
            exit;

        FileNameXsl := FORMAT(WorkDate(), 0, '<Year>_<Month,2>_<Day,2>') + '_' +
                            FORMAT(TIME, 0, '<Hours24,2>_<Minutes,2>_<Seconds,2>_<Thousands>') + '_' +
                            PurchaseHeader."Reason Code" + '_' + PurchaseHeader."No.";

        FileNameXsl := ConvertStr(FileNameXsl, '/', '_');

        CM1CredemtelGenFnc.ExportSubcontractingComponents(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.", FileNameXsl);
        //Fine dei controlli preliminari

        if PurchaseHeader."CM1 Credemtel Order Date" <> 0D then
            TNIMgt.CreateExternalEntry(TNIInterfacesOUTEntry, PurchasesPayablesSetup."CM1 Credemtel TNI Interface", PurchasesPayablesSetup."CM1 Credemtel TNI Change Order", NullRecRef)
        else
            TNIMgt.CreateExternalEntry(TNIInterfacesOUTEntry, PurchasesPayablesSetup."CM1 Credemtel TNI Interface", PurchasesPayablesSetup."CM1 Credemtel TNI Flow", NullRecRef);
        Commit();
        Clear(CM1CREDEMTELDriver);
        CM1CREDEMTELDriver.SetParameters(7, PurchaseHeader);
        if not CM1CREDEMTELDriver.Run() then
            TniMgt.WriteInterfacesOUTLog(TNIInterfacesOUTEntry, GetLastErrorCallStack(), '', '', GetLastErrorText(), '', 0, false)
        else begin
            TniMgt.WriteInterfacesOUTLog(TNIInterfacesOUTEntry, '', XMLSavedSuccLbl, '', '', '', 0, false);
            PurchaseLine.Reset();
            PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
            PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
            if PurchaseLine.FindSet() then
                repeat
                    PurchaseLine."CM1 Send to Credemetel" := true;
                    PurchaseLine.Modify();
                until PurchaseLine.Next() = 0;

            PurchaseHeader."CM1 Credemtel Order Date" := WorkDate();
            PurchaseHeader.Modify();
        end;

        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        RecRef.GetTable(PurchaseHeader);

        exit(true);
    end;

    //REGISTRAZIONE CARICO: 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure PurchPost_OnAfterPostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchRcpHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]; CommitIsSupressed: Boolean)
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Vendor: Record Vendor;
        TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry";
        TNIMgt: Codeunit "TNI Mgt.";
        CM1CredemtelDriver: Codeunit "CM1 Credemtel Driver";
        NullRecRef: RecordRef;
        XMLSavedSuccLbl: Label 'File XML saved successfully';
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Interface");
        PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Rcpt Adv");

        if PurchRcptHeader.Get(PurchRcpHdrNo) then begin
            PurchRcptLine.SetRange("Document No.", PurchRcpHdrNo);
            if not PurchRcptLine.FindFirst() then
                exit;

            if Vendor.Get(PurchRcptHeader."Buy-from Vendor No.") then
                if Vendor."CM1 Credemtel Active" then begin
                    // VarCredemtelFunctions.WriteReceiptAdviceXML(OutStream, PurchRcptHeader);
                    // VarCredemtelFunctions.LogCredemtelOrderTransmissionFlexibleRcpt(PurchRcptLine, true, "CM1 Movement Type"::"Exit", "CM1 Document Type"::"CAR", "CM1 Trace Type"::"ReceiptAdvice", "CM1 Status"::"InProgress");
                    TNIMgt.CreateExternalEntry(TNIInterfacesOUTEntry, PurchasesPayablesSetup."CM1 Credemtel TNI Interface", PurchasesPayablesSetup."CM1 Credemtel TNI Rcpt Adv", NullRecRef);
                    Commit();
                    Clear(CM1CREDEMTELDriver);
                    CM1CredemtelDriver.SetParametersRecipt(12, PurchRcptHeader, PurchRcptLine);
                    if not CM1CREDEMTELDriver.Run() then
                        TniMgt.WriteInterfacesOUTLog(TNIInterfacesOUTEntry, GetLastErrorCallStack(), '', '', GetLastErrorText(), '', 0, false)
                    else
                        TniMgt.WriteInterfacesOUTLog(TNIInterfacesOUTEntry, '', XMLSavedSuccLbl, '', '', '', 0, false);
                end;
        end;
    end;

    //ANNULLAMENTO CARICO: 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Purchase Receipt Line", 'OnAfterCode', '', false, false)]
    local procedure UndoPurchaseReceiptLine_OnAfterCode(var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Vendor: Record Vendor;
        TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry";
        CM1CREDEMTELDriver: Codeunit "CM1 Credemtel Driver";
        TNIMgt: Codeunit "TNI Mgt.";
        NullRecRef: RecordRef;
        XMLSavedSuccLbl: Label 'File XML saved successfully';
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Interface");
        PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Rcpt Adv St");

        PurchRcptHeader.Get(PurchRcptLine."Document No.");
        if Vendor.Get(PurchRcptHeader."Buy-from Vendor No.") then
            if Vendor."CM1 Credemtel Active" then begin
                TNIMgt.CreateExternalEntry(TNIInterfacesOUTEntry, PurchasesPayablesSetup."CM1 Credemtel TNI Interface", PurchasesPayablesSetup."CM1 Credemtel TNI Rcpt Adv St", NullRecRef);
                Commit();
                Clear(CM1CREDEMTELDriver);
                CM1CREDEMTELDriver.SetParametersReceiptAdviceStorno(11, PurchRcptHeader);
                if not CM1CREDEMTELDriver.Run() then
                    TniMgt.WriteInterfacesOUTLog(TNIInterfacesOUTEntry, GetLastErrorCallStack(), '', '', GetLastErrorText(), '', 0, false)
                else
                    TniMgt.WriteInterfacesOUTLog(TNIInterfacesOUTEntry, '', XMLSavedSuccLbl, '', '', '', 0, false);
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnAfterValidateEvent', 'CM1 Credemtel Active', false, false)]
    local procedure Vendor_OnAfterValidateEvent(var Rec: Record Vendor)
    var
        ErrorLbl: Label 'Credemtel Active cannot be enabled when IUNGO is enabled.';
    begin
        if Rec."CM1 Credemtel Active" then
            if Rec."IUNGO Enabled" then
                Error(ErrorLbl);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnAfterValidateEvent', 'IUNGO Enabled', false, false)]
    local procedure Vendor_OnAfterValidateEventErrorForIUNGO(var Rec: Record Vendor)
    var
        ErrorLbl: Label 'Credemtel Active cannot be enabled when IUNGO is enabled.';
    begin
        if Rec."IUNGO Enabled" then
            if Rec."CM1 Credemtel Active" then
                Error(ErrorLbl);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnAfterValidateEvent', 'CM1 Credemtel Auto Send', false, false)]
    local procedure Vendor_OnAfterValidateEventAutoSend(var Rec: Record Vendor)
    var
        ErrorLbl: Label 'Credemtel Auto Send cannot be enabled when Credemtel Active is not enabled.';
    begin
        if not Rec."CM1 Credemtel Active" then
            Error(ErrorLbl);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CAMEOS TDAG44809 Events Mgt", 'OnBeforeModifyUpdatePurchLineVersionIndex', '', false, false)]
    local procedure Credemtel_OnBeforeModifyUpdatePurchLineVersionIndex(var PurchaseLine: Record "Purchase Line")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Vendor: Record Vendor;
        MessageModifyLbl: Label 'Do you want to send a modification to Credemtel?';
    begin
        PurchasesPayablesSetup.Get();

        if Vendor.Get(PurchaseLine."Buy-from Vendor No.") then
            if PurchasesPayablesSetup."CM1 Credemtel Enabled" then
                if Vendor."CM1 Credemtel Active" then
                    if Confirm(MessageModifyLbl) then
                        PurchaseLine."CM1 Send to Credemetel" := false;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Order Subform", 'OnDeleteRecordEvent', '', false, false)]
    local procedure PurchaseOrderSubform_OnDeleteRecordEvent(var Rec: Record "Purchase Line"; var AllowDelete: Boolean)
    begin
        if Rec."CM1 Send to Credemetel" then
            AllowDelete := true
        else
            AllowDelete := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Extended Text Line", 'OnAfterModifyEvent', '', true, true)]
    local procedure "Purch. Extended Text Line_OnAfterModifyEvent"(var Rec: Record "Purch. Extended Text Line"; var xRec: Record "Purch. Extended Text Line"; RunTrigger: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        CredemtelGeneralFunctions: Codeunit "CM1 Credemtel Gen. Fnc.";
    begin
        if Rec.IsTemporary then
            exit;
        if not RunTrigger then
            exit;

        Clear(CredemtelGeneralFunctions);
        if (Rec.Text <> xRec.Text) or (Rec."Purchase Order" <> xRec."Purchase Order") then
            if PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Document Line No.") then
                if PurchaseLine."CM1 Send to Credemetel" then begin
                    PurchaseLine."CM1 Send to Credemetel" := false;
                    PurchaseLine."CM1 Credemtel Ord Line Status" := PurchaseLine."CM1 Credemtel Ord Line Status"::" ";
                    PurchaseLine.Modify();
                    CredemtelGeneralFunctions.UpdateOtherPurchaseLinesCredemetel(PurchaseLine, PurchaseLine."CM1 Credemtel Ord Line Status"::" ");
                end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Extended Text Line", 'OnAfterInsertEvent', '', true, true)]
    local procedure "Purch. Extended Text Line_OnAfterInsertEvent"(var Rec: Record "Purch. Extended Text Line"; RunTrigger: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        CredemtelGeneralFunctions: Codeunit "CM1 Credemtel Gen. Fnc.";
    begin
        if Rec.IsTemporary then
            exit;
        if not RunTrigger then
            exit;

        Clear(CredemtelGeneralFunctions);
        if Rec.Text <> '' then
            if PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Document Line No.") then
                if PurchaseLine."CM1 Send to Credemetel" then begin
                    PurchaseLine."CM1 Send to Credemetel" := false;
                    PurchaseLine."CM1 Credemtel Ord Line Status" := PurchaseLine."CM1 Credemtel Ord Line Status"::" ";
                    PurchaseLine.Modify();
                    CredemtelGeneralFunctions.UpdateOtherPurchaseLinesCredemetel(PurchaseLine, PurchaseLine."CM1 Credemtel Ord Line Status"::" ");
                end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Extended Text", 'OnAfterModifyEvent', '', false, false)]
    local procedure "Document Extended Text_OnAfterModifyEvent"(var Rec: Record "Document Extended Text"; var xRec: Record "Document Extended Text"; RunTrigger: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if Rec.IsTemporary then
            exit;
        if not RunTrigger then
            exit;
        if Rec."Source Type" <> Database::"Purchase Header" then
            exit;

        if (Rec.Text <> xRec.Text) or (Rec."Purchase Order" <> xRec."Purchase Order") then begin
            PurchaseLine.Reset();
            PurchaseLine.SetRange("Document Type", Rec."Source Subtype");
            PurchaseLine.SetRange("Document No.", Rec."Source ID");
            PurchaseLine.SetRange("CM1 Send to Credemetel", true);
            if not PurchaseLine.IsEmpty then begin
                PurchaseLine.ModifyAll("CM1 Send to Credemetel", false);
                PurchaseLine.ModifyAll("CM1 Credemtel Ord Line Status", PurchaseLine."CM1 Credemtel Ord Line Status"::" ");
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Extended Text", 'OnAfterInsertEvent', '', true, true)]
    local procedure "Document Extended Text_OnAfterInsertEvent"(var Rec: Record "Document Extended Text"; RunTrigger: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if Rec.IsTemporary then
            exit;
        if not RunTrigger then
            exit;
        if Rec."Source Type" <> Database::"Purchase Header" then
            exit;

        if Rec."Purchase Order" then begin
            PurchaseLine.Reset();
            PurchaseLine.SetRange("Document Type", Rec."Source Subtype");
            PurchaseLine.SetRange("Document No.", Rec."Source ID");
            PurchaseLine.SetRange("CM1 Send to Credemetel", true);
            if not PurchaseLine.IsEmpty then begin
                PurchaseLine.ModifyAll("CM1 Send to Credemetel", false);
                PurchaseLine.ModifyAll("CM1 Credemtel Ord Line Status", PurchaseLine."CM1 Credemtel Ord Line Status"::" ");
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Posting Management", 'OnAfterUpdatePurchline', '', true, true)]
    local procedure "Undo Posting Management_OnAfterUpdatePurchline"(var PurchLine: Record "Purchase Line")
    var
        CredemtelGeneralFunctions: Codeunit "CM1 Credemtel Gen. Fnc.";
    begin
        Clear(CredemtelGeneralFunctions);
        if PurchLine."Document Type" = PurchLine."Document Type"::Order then
            if PurchLine."CM1 Send to Credemetel" then begin
                PurchLine."CM1 Send to Credemetel" := false;
                PurchLine.Modify();
                CredemtelGeneralFunctions.UpdateOtherPurchaseLinesCredemetel(PurchLine, PurchLine."CM1 Credemtel Ord Line Status"::" ");
            end;
    end;
}