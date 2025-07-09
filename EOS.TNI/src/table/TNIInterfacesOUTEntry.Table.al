table 50067 "TNI Interfaces OUT Entry"
{
    DataClassification = CustomerContent;
    Caption = 'Interfaces OUT Entries (TNI)';

    fields
    {
        field(1; "TNI Interface Code"; Code[20])
        {
            Caption = 'Interface Code';
        }
        field(2; "TNI Flow Code"; Code[20])
        {
            Caption = 'Flow Code';
        }
        field(3; "TNI Transaction ID"; Guid)
        {
            Caption = 'Transaction ID';
        }
        field(4; "TNI File Name"; text[100])
        {
            Caption = 'File Name';
        }
        field(5; "TNI Response File"; Blob)
        {
            Caption = 'Response File';
        }
        field(6; "TNI Sent"; Boolean)
        {
            Caption = 'Sent';
        }
        field(7; "TNI Timestamp"; DateTime)
        {
            Caption = 'Timestamp';
        }
        field(8; "TNI Sent File"; Blob)
        {
            Caption = 'Sent File';
        }
        field(9; "TNI File Path"; Text[250])
        {
            Caption = 'File Path';
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
        key(key2; "TNI Timestamp") { }
        key(key3; "Entry No.") { }
    }

    trigger OnDelete()
    var
        TNIInterfacesLog: Record "TNI Interfaces Log";
    begin
        TNIInterfacesLog.Reset();
        TNIInterfacesLog.SetRange("TNI Interface Code", Rec."TNI Flow Code");
        TNIInterfacesLog.SetRange("TNI Flow Code", Rec."TNI Flow Code");
        TNIInterfacesLog.SetRange("TNI Transaction ID", Rec."TNI Transaction ID");
        TNIInterfacesLog.DeleteAll();
    end;
}