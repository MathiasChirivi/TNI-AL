table 50064 "TNI Interfaces Credentials"
{
    DataClassification = CustomerContent;
    Caption = 'Credentials (TNI)';
    LookupPageId = "TNI Credentials List";

    fields
    {
        field(1; "Credential Code"; Code[20])
        {
            Caption = 'Credential Code';
        }
        field(2; "Description"; Text[250])
        {
            Caption = 'Description';
        }
        field(5; "Authentication Type"; Enum "TNI Authentication Types")
        {
            Caption = 'Authentication Type';
        }
        field(10; "UserName"; Text[100])
        {
            Caption = 'UserName';
        }
        field(11; "Password"; Text[100])
        {
            Caption = 'Password';
        }
        field(20; "Access Token Url"; Text[250])
        {
            Caption = 'Access Token URL';

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Access Token Url" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Access Token Url");
            end;
        }
        field(25; "OAuth Have Service To Service"; Boolean)
        {
            Caption = 'OAuth Have Service To Service';
        }
        field(30; "Client ID"; Text[250])
        {
            Caption = 'Client ID';
        }
        field(35; "Client Secret"; Text[250])
        {
            Caption = 'Client Secret';
        }
        field(40; "Grant Type"; Enum "TNI Auth. Grant Type")
        {
            Caption = 'Grant Type';
        }
        field(45; Scope; Text[250])
        {
            Caption = 'Scope';
        }
        field(50; Resource; Text[250])
        {
            Caption = 'Resource';
        }
        field(55; "Server Address"; Text[250])
        {
            Caption = 'Server Address';
        }
        field(60; "Server Port"; Integer)
        {
            Caption = 'Server Port';
        }
    }

    keys
    {
        key(PK; "Credential Code")
        {
            Clustered = true;
        }
    }
}