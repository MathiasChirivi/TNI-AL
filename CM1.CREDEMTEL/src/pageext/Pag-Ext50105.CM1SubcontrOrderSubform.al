pageextension 50105 "CM1 Subcontr Order Subform" extends "Subcontracting Order Subform"
{
    layout
    {
        addafter("Operation No.")
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
            }
        }
    }
    actions
    {
        addlast("&Line")
        {
            action(CM1_OpenLine)
            {
                Caption = 'Delete Credemtel Line';
                ApplicationArea = All;
                Image = Open;
                Visible = CREDEMTELEnable;
                Enabled = CREDEMTELEnable;
                trigger OnAction()
                var
                    UserSetup: Record "User Setup";
                    CREDEMTELManagement: Codeunit "CM1 Credemtel Gen. Fnc.";
                    ErrorMsg: Label 'You do not have permission to delete this line.';
                begin
                    if UserSetup.Get(UserId) then
                        if UserSetup."CM1 Credemtel Delete Line" then
                            CREDEMTELManagement.DeletePurchLineCREDEMTEL(Rec)
                        else
                            Error(ErrorMsg);
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        Vendor: Record Vendor;
    begin
        if Vendor.Get(Rec."Buy-from Vendor No.") then
            if Vendor."CM1 Credemtel Active" then
                CREDEMTELEnable := true
            else
                CREDEMTELEnable := false;
    end;

    trigger OnDeleteRecord(): Boolean
    var
        UserSetup: Record "User Setup";
        CREDEMTELManagement: Codeunit "CM1 Credemtel Gen. Fnc.";
        ErrorMsg: Label 'You do not have permission to delete this line.';
    begin
        if UserSetup.Get(UserId) then
            if UserSetup."CM1 Credemtel Delete Line" then
                CREDEMTELManagement.DeletePurchLineCREDEMTEL(Rec)
            else
                Error(ErrorMsg);
        exit(false);
    end;

    var
        CREDEMTELEnable: Boolean;
}