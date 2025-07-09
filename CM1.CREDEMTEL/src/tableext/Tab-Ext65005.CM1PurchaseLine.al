tableextension 65005 "CM1 Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(50020; "CM1 Send to Credemetel"; Boolean)
        {
            Caption = 'Send to Credemetel';
            DataClassification = CustomerContent;
        }
        field(50025; "CM1 Status Credemtel"; Enum "CM1 Status")
        {
            Caption = 'Stato Credemtel';
            DataClassification = CustomerContent;
        }
        field(50030; "CM1 Credemtel Ord Line Status"; Enum "CREDEMTEL Status")
        {
            Caption = 'Credemtel Order Line Status';
            DataClassification = CustomerContent;
        }
        field(50035; "CM1 Change Price Credemtel"; Boolean)
        {
            Caption = 'Change Price Credemtel';
            DataClassification = CustomerContent;
        }
        field(50040; "CM1 Missed engag Credemtel"; Boolean)
        {
            Caption = 'Missed Engagement Credemtel';
            DataClassification = CustomerContent;
        }
        field(50050; "CM1 Close Add Item Prop Tag"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Close Add Item Prop Tag';
        }
        field(50060; "CM1 Cancel Add Item Prop Tag"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Cancel Add Item Prop Tag';
        }
        field(50070; "CM1 Country/Region Origin Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Country/Region of Origin Code';
        }
        field(50080; "CM1 Credemtel Change Type"; Enum "CM1 Credemtel Change Type")
        {
            Caption = 'Credemtel Change Type';
            DataClassification = CustomerContent;
        }
        field(50090; "CM1 Additional Vendor No."; Code[20])
        {
            Caption = 'Additional Vendor No.';
            DataClassification = CustomerContent;
        }
    }

    procedure GetCredemtelStatus(): Enum "CM1 Status"
    var
        CredemtelStaging: Record "CM1 Credemtel Staging";
        LastStatus: Enum "CM1 Status";
    begin
        CredemtelStaging.Reset();
        CredemtelStaging.SetCurrentKey("Entry No.");
        CredemtelStaging.SetRange("Order No.", Rec."Document No.");
        CredemtelStaging.SetRange("Order Line No.", Rec."Line No.");
        CredemtelStaging.SetRange("Document Type", CredemtelStaging."Document Type"::ORDACQ);
        CredemtelStaging.SetRange("Document Type", CredemtelStaging."Document Type"::ORDACQUPD);
        CredemtelStaging.Ascending(true);
        if CredemtelStaging.FindLast then
            LastStatus := CredemtelStaging.Status;

        exit(LastStatus);
    end;


}