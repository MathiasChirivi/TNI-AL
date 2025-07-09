pageextension 65010 "CM1 Purchase Order" extends "Purchase Order"
{
    layout
    {
        addlast(General)
        {
            field("CM1 Credemtel Order Date"; Rec."CM1 Credemtel Order Date")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("CM1 Send to Credemetel"; Rec."CM1 Send to Credemetel")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
        modify("Buy-from Vendor No.")
        {
            trigger OnAfterValidate()
            var
                Vendor: Record Vendor;
            begin
                if Vendor.Get(Rec."Buy-from Vendor No.") then begin
                    Rec."CM1 Send to Credemetel" := Vendor."CM1 Credemtel Auto Send";
                    Rec.Modify();
                end;
            end;
        }
        modify("Buy-from Vendor Name")
        {
            trigger OnAfterValidate()
            var
                Vendor: Record Vendor;
            begin
                if Vendor.Get(Rec."Buy-from Vendor No.") then begin
                    Rec."CM1 Send to Credemetel" := Vendor."CM1 Credemtel Auto Send";
                    Rec.Modify();
                end;
            end;
        }

    }
    actions
    {
        addafter(IUNGO_Export)
        {
            action(ExportPeppolOrder)
            {
                ApplicationArea = All;
                Caption = 'Export Order to Credemtel';
                Image = Export;
                trigger OnAction()
                var
                    TempBlob: Record TempBlob;
                    Vendor: Record Vendor;
                    PurchaseHeader: Record "Purchase Header";
                    PurchaseLine: Record "Purchase Line";
                    PurchasesPayablesSetup: Record "Purchases & Payables Setup";
                    CREDEMENTELGeneralFunct: Codeunit "CM1 Credemtel Gen. Fnc.";
                    TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry";
                    CM1CredemtelGenFnc: Codeunit "CM1 Credemtel Gen. Fnc.";
                    CM1CREDEMTELDriver: Codeunit "CM1 Credemtel Driver";
                    TNIMgt: Codeunit "TNI Mgt.";
                    OutStr: OutStream;
                    NullRecRef: RecordRef;
                    InStr: InStream;
                    FileName: Text;
                    FileNameXsl: Text;
                    ErrorSendToCredemtel: Label 'All Lines must be sent to Credemtel.';
                    XMLSavedSuccLbl: Label 'File XML saved successfully';
                    ErrorMsg: Label 'Cannot export to Credemtel. Check the following:\1. Credemtel must be enabled in Purchases & Payables Setup\2. Credemtel must be active for the vendor\3. Order must be released\4. Document Date must be < Credemtel Activation Date for the vendor.';
                begin
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

                    PurchaseHeader := Rec;
                    Clear(PurchaseLine);
                    PurchaseLine.Reset();
                    PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                    PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                    PurchaseLine.SetRange("CM1 Send to Credemetel", false);
                    if PurchaseLine.IsEmpty() then
                        // Error(ErrorSendToCredemtel);
                        exit;

                    FileNameXsl := FORMAT(WorkDate(), 0, '<Year>_<Month,2>_<Day,2>') + '_' +
                                FORMAT(TIME, 0, '<Hours24,2>_<Minutes,2>_<Seconds,2>_<Thousands>') + '_' +
                                PurchaseHeader."Reason Code" + '_' + PurchaseHeader."No.";

                    FileNameXsl := ConvertStr(FileNameXsl, '/', '_');

                    CREDEMENTELGeneralFunct.ExportSubcontractingComponents(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.", FileNameXsl);

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

                        Clear(PurchaseLine);
                        PurchaseLine.Reset();
                        PurchaseLine.SetRange("Document Type", Rec."Document Type");
                        PurchaseLine.SetRange("Document No.", Rec."No.");
                        if PurchaseLine.FindSet() then
                            repeat
                                PurchaseLine."CM1 Send to Credemetel" := true;
                                PurchaseLine.Modify();
                            until PurchaseLine.Next() = 0;
                        Rec."CM1 Credemtel Order Date" := WorkDate();
                        Rec.Modify();
                    end;
                end;
            }
        }
        addlast(Processing)
        {
            action(TestImportXML)
            {
                ApplicationArea = All;
                Caption = 'Test Import XML';
                Image = Import;
                trigger OnAction()
                var
                    CM1CredemtelDriver: Codeunit "CM1 Credemtel Driver";
                    PurchasesPayablesSetup: Record "Purchases & Payables Setup";
                    TNIEntry: Record "TNI Interfaces IN Entry";
                    TNIFlows: Record "TNI Flows";
                    TNIMgt: Codeunit "TNI Mgt.";
                    TNILogType: Enum "TNI Log Type";
                    FileInStream: InStream;
                    FileName: Text;
                    ContentText: Text;
                    TextLine: Text;
                    // XmlCU: Codeunit "CM1 Credemtel Import Mgt";
                    TempStream: InStream;
                    TempOutStream: OutStream;
                    EntryNo: Integer;
                    TNIEntryGuid: Guid;
                    TNIGroupGuid: Guid;
                    NullFileName: Text[100];
                    OrderResponseSuccessLbl: Label 'Order response successfully';
                begin
                    PurchasesPayablesSetup.Get();
                    PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Interface");
                    PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Ord Response");
                    TNIFlows.Get(PurchasesPayablesSetup."CM1 Credemtel TNI Interface", PurchasesPayablesSetup."CM1 Credemtel TNI Ord Response");

                    TNIEntryGuid := CreateGuid();
                    TNIGroupGuid := CreateGuid();

                    TNIMgt.CreateInternalEntry(TNIEntry, TNIFlows, NullFileName, TNIEntryGuid);
                    Commit();
                    Clear(CM1CREDEMTELDriver);
                    CM1CREDEMTELDriver.SetParametersGetOrders(20, TNIEntry);
                    if not CM1CREDEMTELDriver.Run() then
                        TniMgt.WriteInterfacesINLog(TNIEntry, TNILogType::Error, GetLastErrorText(), GetLastErrorCallStack(), '', 0, Database::"Purchase Header", TNIEntryGuid, TNIGroupGuid)
                    else
                        TniMgt.WriteInterfacesINLog(TNIEntry, TNILogType::Information, OrderResponseSuccessLbl, '', '', 0, Database::"Purchase Header", TNIEntryGuid, TNIGroupGuid);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(Rec."Buy-from Vendor No.") then begin
            Rec."CM1 Send to Credemetel" := Vendor."CM1 Credemtel Auto Send";
            Rec.Modify();
        end;
    end;
}