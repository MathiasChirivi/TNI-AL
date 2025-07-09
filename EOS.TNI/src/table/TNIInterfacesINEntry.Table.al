table 50065 "TNI Interfaces IN Entry"
{
    DataClassification = CustomerContent;
    Caption = 'Interfaces IN Entries (TNI)';

    fields
    {
        field(1; "TNI Interface Code"; Code[20])
        {
            Caption = 'Interface Code';
            TableRelation = "TNI Interfaces"."Code";
        }
        field(2; "TNI Flow Code"; Code[20])
        {
            Caption = 'Flow Code';
        }
        field(3; "TNI Transaction ID"; Guid)
        {
            Caption = 'Transaction ID';
        }
        field(5; "TNI File Name"; text[100])
        {
            Caption = 'File Name';
        }
        field(6; "TNI File"; Blob)
        {
            Caption = 'File';
        }
        field(7; "TNI Processed"; Boolean)
        {
            Caption = 'Processed';
        }
        field(8; "TNI File Path"; Text[250])
        {
            Caption = 'File Path';
        }
        field(10; "TNI Timestamp"; DateTime)
        {
            Caption = 'Timestamp';
        }
        field(17; "TNI Source ID"; Code[50])
        {
            Caption = 'Source ID';
        }
        field(18; "TNI Source Key Text"; Text[250])
        {
            Caption = 'Source Key Text', Locked = true;
        }
        field(55; "TNI Status"; Enum "TNI Interfaces Entries Status")
        {
            Caption = 'Status';
        }
        field(56; "TNI Error Text"; Text[250])
        {
            Caption = 'Error Text';
        }
        field(57; "TNI File Format"; Enum "TNI File Format")
        {
            Caption = 'File Format';
        }
        field(60; "TNI Result"; Text[2048])
        {
            Caption = 'Result';
        }
        field(65; "TNI Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(70; "TNI Posted Document No."; Code[20])
        {
            Caption = 'Posted Document No.';
        }
        field(57003; "Entry No."; Integer)
        {
            AutoIncrement = true;
            InitValue = 0;
            Editable = false;
            Caption = 'Entry No.';
        }
    }

    keys
    {
        key(Key1; "TNI Interface Code", "TNI Flow Code", "TNI Transaction ID")
        {
            Clustered = true;
        }
        key(key2; "TNI Timestamp")
        {
        }
        key(Key3; "Entry No.")
        {
        }
    }

    trigger OnDelete()
    var
        TNIInterfacesLog: Record "TNI Interfaces Log";
    begin
        TNIInterfacesLog.Reset();
        TNIInterfacesLog.SetRange("TNI Interface Code", Rec."TNI Interface Code");
        TNIInterfacesLog.SetRange("TNI Flow Code", Rec."TNI Flow Code");
        TNIInterfacesLog.SetRange("TNI Transaction ID", Rec."TNI Transaction ID");
        TNIInterfacesLog.DeleteAll();
    end;
}