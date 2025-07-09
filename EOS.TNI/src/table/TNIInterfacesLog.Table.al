table 50066 "TNI Interfaces Log"
{
    DataClassification = CustomerContent;
    Caption = 'Interfaces Log';

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
        field(3; "TNI Record No."; Integer)
        {
            Caption = 'Record No.';
        }
        field(4; "TNI Log Type"; Enum "TNI Log Type")
        {
            Caption = 'Log Type';
        }
        field(5; "TNI Log Line ID"; Guid)
        {
            Caption = 'Log Line ID';
        }
        field(6; "TNI Transaction ID"; Guid)
        {
            Caption = 'Transaction ID';
        }
        field(7; "TNI Timestamp"; DateTime)
        {
            Caption = 'Timestamp';
        }
        field(8; "TNI Log Description"; Text[250])
        {
            Caption = 'Log Description';
        }
        field(9; "TNI Last Stack Error"; Text[1250])
        {
            Caption = 'Last Stack Error';
        }
        field(10; "TNI Direction"; Enum "TNI Log Direction")
        {
            Caption = 'Log Direction';
        }
        field(20; "TNI Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(21; "TNI Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(70; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(75; "Table System ID"; Guid)
        {
            Caption = 'Table System ID';
        }
        field(80; "Log Group ID"; Guid)
        {
            Caption = 'Log Group ID';
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
        key(Key1; "TNI Interface Code", "TNI Flow Code", "TNI Record No.", "TNI Log Line ID")
        {
            Clustered = true;
        }
        key(key2; "TNI Timestamp") { }
        key(Key3; "Entry No.") { }
        key(Key4; "TNI Source ID") { }
        // key(Key5; SystemCreatedAt) { }
    }
}