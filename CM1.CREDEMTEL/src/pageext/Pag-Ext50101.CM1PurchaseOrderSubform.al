pageextension 50101 "CM1 Purchase Order Subform" extends "Purchase Order Subform"
{
    layout
    {
        addafter("Location Code")
        {
            field("CM1 Send to Credemetel"; Rec."CM1 Send to Credemetel")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("CM1 Status Credemtel"; Rec.GetCredemtelStatus())
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("CM1 Credemtel Ord Line Status"; Rec."CM1 Credemtel Ord Line Status")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("CM1 Change Price Credemtel"; Rec."CM1 Change Price Credemtel")
            {
                ApplicationArea = All;
            }
            field("CM1 Missed engag Credemtel"; Rec."CM1 Missed engag Credemtel")
            {
                ApplicationArea = All;
            }
            field("Country/Region Origin Code"; Rec."CM1 Country/Region Origin Code")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                Item: Record Item;
            begin
                HandleCredemtelFieldChange();
                ChangeCredemtelFieldsModification();

                if Item.Get(Rec."No.") then
                    Rec."CM1 Country/Region Origin Code" := Item."Country/Region of Origin Code";
            end;
        }
        modify(Quantity)
        {
            trigger OnAfterValidate()
            begin
                HandleCredemtelFieldChange();
                ChangeCredemtelFieldsModification();
            end;
        }
        modify("Requested Receipt Date")
        {
            trigger OnAfterValidate()
            begin
                HandleCredemtelFieldChange();
            end;
        }
        modify("Promised Receipt Date")
        {
            trigger OnAfterValidate()
            begin
                HandleCredemtelFieldChange();
                ChangeCredemtelFieldsModification();
            end;
        }
        modify("Expected Receipt Date")
        {
            trigger OnAfterValidate()
            begin
                HandleCredemtelFieldChange();
            end;
        }
        modify("Direct Unit Cost")
        {
            trigger OnAfterValidate()
            begin
                HandleCredemtelFieldChange();
                ChangeCredemtelFieldsModification();
            end;
        }
        modify("Discount Text")
        {
            trigger OnAfterValidate()
            begin
                HandleCredemtelFieldChange();
                ChangeCredemtelFieldsModification();
            end;
        }
        modify("Line Closed")
        {
            Editable = EditableVendorByCredemtel;
            trigger OnAfterValidate()
            begin
                HandleCredemtelFieldChange();
                ChangeCredemtelFieldsModification();
            end;
        }
        modify("Location Code")
        {
            trigger OnAfterValidate()
            begin
                HandleCredemtelFieldChange();
                ChangeCredemtelFieldsModification();
            end;
        }
    }
    actions
    {
        addlast("&Line")
        {
            action(CM1_OpenLine)
            {
                Caption = 'Reopen Credemtel Line';
                ApplicationArea = All;
                Image = Open;
                Visible = CREDEMTELEnable;
                Enabled = CREDEMTELEnable;
                trigger OnAction()
                var
                    CREDEMTELManagement: Codeunit "CM1 Credemtel Gen. Fnc.";
                begin
                    CREDEMTELManagement.ReOpenPurchLineCREDEMTEL(Rec);
                end;
            }
            action(CM1_CloseLine)
            {
                Caption = 'Close Credemtel Line';
                ApplicationArea = All;
                Image = Close;
                Enabled = CREDEMTELEnable;
                trigger OnAction()
                var
                    CREDEMENTELGeneralFunct: Codeunit "CM1 Credemtel Gen. Fnc.";
                begin
                    CREDEMENTELGeneralFunct.ClosePurchLineCREDEMTEL(Rec);
                end;
            }
            action(CM1_CancelLine)
            {
                Caption = 'Cancel Credemtel Line';
                ApplicationArea = All;
                Image = Cancel;
                Enabled = CREDEMTELEnable;
                trigger OnAction()
                var
                    CREDEMTELGeneralFunct: Codeunit "CM1 Credemtel Gen. Fnc.";
                begin
                    CREDEMTELGeneralFunct.CancelPurchLineCREDEMTEL(Rec);
                end;
            }
        }
    }
    // trigger OnOpenPage()
    // var
    //     Vendor: Record Vendor;
    // begin
    //     if Vendor.Get(Rec."Buy-from Vendor No.") then
    //         if Vendor."CM1 Credemtel Active" then
    //             EditableVendorByCredemtel := false
    //         else
    //             EditableVendorByCredemtel := true;
    // end;

    trigger OnAfterGetRecord()
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(Rec."Buy-from Vendor No.") then
            CREDEMTELEnable := Vendor."CM1 Credemtel Active"
    end;

    trigger OnAfterGetCurrRecord()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PurchaseAndPayablesSetup: Record "Purchases & Payables Setup";
        MessageModify: Label 'Do you want to send a modification to Credemtel?';
    begin
        if PurchaseHeader.Get(Rec."Document Type", Rec."Document No.") then
            if PurchaseAndPayablesSetup.Get() then
                if PurchaseHeader."CM1 Credemtel Order Date" < PurchaseAndPayablesSetup."CM1 Go Live Date" then
                    AllowCredemtelModification := true
                else
                    AllowCredemtelModification := false;

        if Vendor.Get(Rec."Buy-from Vendor No.") then
            if Vendor."CM1 Credemtel Active" then
                EditableVendorByCredemtel := false
            else
                EditableVendorByCredemtel := true;
    end;

    local procedure HandleCredemtelFieldChange()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        ConfirModify: Boolean;
        IsFieldModified: Boolean;
        MessageModify: Label 'Do you want to send a modification to Credemtel?';
    begin
        if PurchasesPayablesSetup.Get() then
            if PurchaseHeader.Get(Rec."Document Type", Rec."Document No.") then
                if PurchaseHeader."CM1 Credemtel Order Date" < PurchasesPayablesSetup."CM1 Go Live Date" then
                    if Rec."CM1 Send to Credemetel" then begin
                        ConfirModify := Confirm(MessageModify, false);
                        if ConfirModify then begin
                            Rec."CM1 Send to Credemetel" := false;
                            Rec.Modify();
                        end;
                    end;
    end;

    local procedure ChangeCredemtelFieldsModification()
    var
        CREDEMENTELGeneralFunct: Codeunit "CM1 Credemtel Gen. Fnc.";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ConfirModify: Boolean;
        IsFieldModified: Boolean;
    begin
        if PurchasesPayablesSetup.Get() then
            if PurchaseHeader.Get(Rec."Document Type", Rec."Document No.") then
                if PurchaseHeader."CM1 Credemtel Order Date" > PurchasesPayablesSetup."CM1 Go Live Date" then
                    if Rec."CM1 Send to Credemetel" then begin
                        IsFieldModified := (Rec."No." <> xRec."No.") or
                        (Rec.Quantity <> xRec.Quantity) or
                        (Rec."Direct Unit Cost" <> xRec."Direct Unit Cost") or
                        (Rec."Promised Receipt Date" <> xRec."Promised Receipt Date") or
                        (Rec."Location Code" <> xRec."Location Code") or
                        (Rec."Discount Text" <> xRec."Discount Text") or
                        (Rec."Line Closed" <> xRec."Line Closed");
                        if IsFieldModified then begin
                            Rec."CM1 Credemtel Change Type" := Rec."CM1 Credemtel Change Type"::Revised;
                            Rec."CM1 Send to Credemetel" := false;
                            Rec.Modify();
                            // Rec.ModifyAll("CM1 Send to Credemetel", false);
                            CREDEMENTELGeneralFunct.UpdateOtherPurchaseLinesCredemetel(Rec, Rec."CM1 Credemtel Ord Line Status"::" ");
                        end;
                    end;
    end;


    trigger OnDeleteRecord(): Boolean
    var
        ConfirmDelete: Boolean;
        MessageDelete: Label 'Are you sure you want to delete this line?';
    begin
        if Rec."CM1 Send to Credemetel" then begin
            ConfirmDelete := Confirm(MessageDelete, false);
            if not ConfirmDelete then
                exit(false); // Annulla la cancellazione

            Rec."CM1 Credemtel Change Type" := Rec."CM1 Credemtel Change Type"::Cancelled;
            Rec.Modify();
        end;
        exit(true);
    end;

    var
        EditableVendorByCredemtel: Boolean;
        CREDEMTELEnable: Boolean;
        AllowCredemtelModification: Boolean;
}