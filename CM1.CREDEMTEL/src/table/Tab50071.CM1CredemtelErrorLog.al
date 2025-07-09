table 50071 "CM1 Credemtel Error Log"
{
    DataClassification = ToBeClassified;
    Caption = 'Credemtel Error Log';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }

        field(3; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = CustomerContent;
        }

        field(4; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            DataClassification = CustomerContent;
        }

        field(5; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = SystemMetadata;
        }

        field(6; "Error Date"; Date)
        {
            Caption = 'Error Date';
            DataClassification = SystemMetadata;
        }

        field(7; "Error Time"; Time)
        {
            Caption = 'Error Time';
            DataClassification = SystemMetadata;
        }

        field(8; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = SystemMetadata;
        }
        field(9; "Error Type"; Enum "Error Type")
        {
            Caption = 'Processing Date';
            DataClassification = SystemMetadata;
        }
        field(10; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = CustomerContent;
            TableRelation = AllObj."Object ID" WHERE("Object Type" = CONST(Table));

            trigger OnValidate()
            begin
                CalcFields("Table Name");
            end;
        }
        field(12; "Table Name"; Text[80])
        {
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" WHERE("Object Type" = CONST(Table),
                                                                           "Object ID" = FIELD("Table ID")));
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Interface Entry No."; Integer)
        {
            Caption = 'Interface Entry No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}