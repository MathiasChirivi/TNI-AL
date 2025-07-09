table 50062 "TNI Flows"
{
    DataClassification = CustomerContent;
    Caption = 'Flows (TNI)';
    LookupPageId = "TNI Flows";

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
        field(3; "WS Uri"; Text[308])
        {
            Caption = 'WS Uri';
        }
        field(8; "TNI Credential Code"; Code[20])
        {
            Caption = 'Credential Code';
            TableRelation = "TNI Interfaces Credentials"."Credential Code";
        }
        field(9; Description; Text[150])
        {
            Caption = 'Description';
        }
        field(10; Enable; Boolean)
        {
            Caption = 'Enable';
        }
        field(11; "TNI Interface Type"; Enum "TNI Interfaces Types")
        {
            Caption = 'Interface Type';
        }
        field(12; "TNI Flow Type"; Enum "TNI Flow Type")
        {
            Caption = 'Flow Type';
        }
        field(13; "TNI Delete File After Read"; Boolean)
        {
            Caption = 'Delete File After Read';
            ObsoleteState = Removed;
            ObsoleteReason = 'Removed';
        }
        field(14; "TNI Import Mode"; Enum "TNI Import Mode")
        {
            Caption = 'Import Mode';
        }
        field(15; "TNI Process"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Process';
        }
        field(20; "TNI GUID"; Guid)
        {
            Caption = 'TNI GUID';
            Editable = false;
        }
        field(30; "TNI File Path"; Text[250])
        {
            Caption = 'File Path';
        }
        field(35; "TNI Archived File Path"; Text[250])
        {
            Caption = 'Archived File Path';
        }
        field(40; "EOS Function API Code"; Code[20])
        {
            Caption = 'EOS Function API Code';
        }
        field(45; "TNI File Name Code"; Code[20])
        {
            Caption = 'File Name Code';
            TableRelation = "No. Series".Code;
        }
        field(50; "Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = filter(Table));
        }
        field(55; "WS Method"; Enum "TNI WS Method")
        {
            Caption = 'WS Method';
        }
        field(60; "Process Single Record"; Boolean)
        {
            Caption = 'Process Single Record';
        }
        field(2000; "Access Token"; Blob)
        {
            Caption = 'Access Token';
        }
        field(2010; "Token Duration"; Duration)
        {
            Caption = 'Token Duration';
        }
        field(2020; "Token Generated at"; DateTime)
        {
            Caption = 'Token Generated at';
        }
        field(2030; "Token Expires In"; Decimal)
        {
            Caption = 'Token Expires In';
        }
    }
    keys
    {
        key(PK; "TNI Interface Code", "TNI Flow Code")
        {
            Clustered = true;
        }
    }
}