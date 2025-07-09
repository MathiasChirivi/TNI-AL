pageextension 65011 "CM1 Subcontracting Order" extends "Subcontracting Order"
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
    }

    actions
    {
        addafter("Re&lease")
        {
            action(ExportSucontractingOrder)
            {
                Caption = 'Export XML Subcontracting Order to Credemtel';
                ApplicationArea = All;
                Image = Export;
                trigger OnAction()
                var
                    TempBlob: Record TempBlob;
                    Vendor: Record Vendor;
                    PurchaseHeader: Record "Purchase Header";
                    PurchaseLine: Record "Purchase Line";
                    PurchasesPayablesSetup: Record "Purchases & Payables Setup";
                    CREDEMENTELGeneralFunct: Codeunit "CM1 Credemtel Gen. Fnc.";
                    OutStr: OutStream;
                    InStr: InStream;
                    FileName: Text;
                    FileNameXsl: Text;
                    ErrorMsg: Label 'Cannot export to Credemtel. Check the following:\1. Credemtel must be enabled in Purchases & Payables Setup\2. Credemtel must be active for the vendor\3. Order must be released\4. Document Date must be < Credemtel Activation Date for the vendor\5. Order Type code must be set';
                begin
                    PurchasesPayablesSetup.Get();
                    if not PurchasesPayablesSetup."CM1 Credemtel Enabled" then
                        Error(ErrorMsg);

                    if not Vendor.Get(Rec."Buy-from Vendor No.") then
                        exit;

                    if Rec.Status <> Rec.Status::Released then
                        Error(ErrorMsg);

                    if Rec."Document Date" < Vendor."CM1 Credemtel Activation Date" then
                        Error(ErrorMsg);

                    if not Vendor."CM1 Credemtel Active" then
                        Error(ErrorMsg);

                    FileNameXsl := FORMAT(WorkDate(), 0, '<Year>_<Month,2>_<Day,2>') + '_' +
                                FORMAT(TIME, 0, '<Hours24,2>_<Minutes,2>_<Seconds,2>_<Thousands>') + '_' +
                                PurchaseHeader."Reason Code" + '_' + PurchaseHeader."No.";

                    FileNameXsl := ConvertStr(FileNameXsl, '/', '_');

                    PurchaseHeader := Rec;
                    CREDEMENTELGeneralFunct.ExportSubcontractingComponents(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.", FileNameXsl);

                    TempBlob.Blob.CreateOutStream(OutStr);
                    CREDEMENTELGeneralFunct.CreateAndSendOrderXML(OutStr, Rec);
                    TempBlob.Blob.CreateInStream(InStr);
                    FileName := 'Order_' + Rec."No." + '.xml';
                    DownloadFromStream(InStr, '', '', '', FileName);

                    Rec."CM1 Credemtel Order Date" := WorkDate();
                    PurchaseLine.Reset();
                    PurchaseLine.SetRange("Document Type", Rec."Document Type");
                    PurchaseLine.SetRange("Document No.", Rec."No.");
                    if PurchaseLine.FindSet() then
                        repeat
                            PurchaseLine."CM1 Send to Credemetel" := true;
                            PurchaseLine.Modify();
                        until PurchaseLine.Next() = 0;
                    Rec.Modify();
                end;
            }
        }
    }
}