pageextension 50108 "CM1 Purch. Extended Text" extends "Purch. Extended Text"
{
    layout
    {
        modify(Text)
        {
            trigger OnAfterValidate()
            begin
                HandleCredemtelFieldChange();
                ChangeCredemtelFieldsModification();
            end;
        }
    }

    procedure HandleCredemtelFieldChange()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ConfirModify: Boolean;
        MessageModify: Label 'Do you want to send a modification to Credemtel?';
    begin
        if PurchasesPayablesSetup.Get() then
            if PurchaseHeader.Get(Rec."Document Type", Rec."Document No.") then
                if PurchaseHeader."CM1 Credemtel Order Date" < PurchasesPayablesSetup."CM1 Go Live Date" then begin
                    PurchaseLine.SetRange("Document No.", Rec."Document No.");
                    PurchaseLine.SetRange("Document Type", Rec."Document Type");
                    PurchaseLine.SetRange("Line No.", Rec."Document Line No.");
                    if PurchaseLine.FindFirst() then
                        if PurchaseLine."CM1 Send to Credemetel" then begin
                            ConfirModify := Confirm(MessageModify, false);
                            if ConfirModify then begin
                                PurchaseLine."CM1 Send to Credemetel" := false;
                                PurchaseLine.Modify();
                            end;
                        end;
                end;
    end;

    local procedure ChangeCredemtelFieldsModification()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ConfirModify: Boolean;
        IsFieldModified: Boolean;
    begin
        if PurchasesPayablesSetup.Get() then
            if PurchaseHeader.Get(Rec."Document Type", Rec."Document No.") then
                if PurchaseHeader."CM1 Credemtel Order Date" > PurchasesPayablesSetup."CM1 Go Live Date" then begin
                    PurchaseLine.SetRange("Document No.", Rec."Document No.");
                    PurchaseLine.SetRange("Document Type", Rec."Document Type");
                    if not PurchaseLine.IsEmpty() then
                        if PurchaseLine."CM1 Send to Credemetel" then begin
                            IsFieldModified := (Rec.Text <> xRec."Text");
                            if IsFieldModified then
                                PurchaseLine."CM1 Credemtel Change Type" := PurchaseLine."CM1 Credemtel Change Type"::Revised;
                            PurchaseLine.ModifyAll("CM1 Send to Credemetel", false);
                        end;
                end;
    end;

    trigger OnDeleteRecord(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        ConfirmDelete: Boolean;
        MessageDelete: Label 'Are you sure you want to delete this line?';
    begin
        PurchaseLine.SetRange("Document No.", Rec."Document No.");
        PurchaseLine.SetRange("Document Type", Rec."Document Type");
        PurchaseLine.SetRange("Line No.", Rec."Document Line No.");
        if PurchaseLine.FindFirst() then
            if PurchaseLine."CM1 Send to Credemetel" then begin
                ConfirmDelete := Confirm(MessageDelete, false);
                if not ConfirmDelete then
                    exit(false); // Annulla la cancellazione

                PurchaseLine."CM1 Credemtel Change Type" := PurchaseLine."CM1 Credemtel Change Type"::Cancelled;
                PurchaseLine.Modify();
            end;
        exit(true);
    end;
}