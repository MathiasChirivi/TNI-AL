table 50070 "CM1 Credemtel Staging"
{
    Caption = 'Credemtel Staging';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }

        field(2; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = CustomerContent;
        }

        field(3; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            DataClassification = CustomerContent;
        }

        field(4; "Movement Type"; Enum "CM1 Movement Type")
        {
            Caption = 'Movement Type';
            DataClassification = CustomerContent;
        }

        field(5; "Document Type"; Enum "CM1 Document Type")
        {
            Caption = 'Document Type';
            DataClassification = CustomerContent;
        }

        field(6; "Trace Type"; Enum "CM1 Trace Type")
        {
            Caption = 'Trace Type';
            DataClassification = CustomerContent;
        }

        field(7; "Status"; Enum "CM1 Status")
        {
            Caption = 'Status';
            DataClassification = CustomerContent;
        }

        field(8; "Order Date"; Date)
        {
            Caption = 'Order Date';
            DataClassification = CustomerContent;
        }

        field(9; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = CustomerContent;
        }

        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
        }

        field(11; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
            DataClassification = CustomerContent;
        }

        field(12; "Cross Reference No."; Code[20])
        {
            Caption = 'Cross Reference No.';
            DataClassification = CustomerContent;
        }

        field(13; "Unit of Measure Code"; Code[50])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = CustomerContent;
        }

        field(14; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
        }

        field(15; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            DataClassification = CustomerContent;
        }

        field(16; "Promised Receipt Date"; Date)
        {
            Caption = 'Promised Receipt Date';
            DataClassification = CustomerContent;
        }

        field(17; "Received Quantity"; Decimal)
        {
            Caption = 'Received Quantity';
            DataClassification = CustomerContent;
        }

        field(18; "Line Discount %"; Decimal)
        {
            Caption = 'Line Discount %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }

        field(19; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = CustomerContent;
        }

        field(20; "Order Confirmation No."; Code[20])
        {
            Caption = 'Order Confirmation No.';
            DataClassification = CustomerContent;
        }

        field(21; "Import Date"; Date)
        {
            Caption = 'Import Date';
            DataClassification = SystemMetadata;
        }

        field(22; "Import Time"; Time)
        {
            Caption = 'Import Time';
            DataClassification = SystemMetadata;
        }

        field(23; "Processing Date"; Date)
        {
            Caption = 'Processing Date';
            DataClassification = SystemMetadata;
        }

        field(24; "Processing Time"; Time)
        {
            Caption = 'Processing Time';
            DataClassification = SystemMetadata;
        }

        field(25; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = SystemMetadata;
        }

        field(26; "Send DateTime"; DateTime)
        {
            Caption = 'Send DateTime';
            DataClassification = SystemMetadata;
        }
        field(28; "Is Process"; Boolean)
        {
            Caption = 'Is Process';
            DataClassification = CustomerContent;
        }
        field(29; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = SystemMetadata;
        }
        field(30; "Is Error"; Boolean)
        {
            Caption = 'Is Error';
            DataClassification = CustomerContent;
        }
        field(31; "Line Discount % 2"; Decimal)
        {
            Caption = 'Line Discount % 2';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(32; Warning; Boolean)
        {
            Caption = 'Warning';
            DataClassification = CustomerContent;
        }
        field(33; "Line Status Code"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Line Status Code';
        }
        field(34; "Country of Origin Code"; Code[20])
        {
            Caption = 'Country of Origin Code';
            DataClassification = ToBeClassified;
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