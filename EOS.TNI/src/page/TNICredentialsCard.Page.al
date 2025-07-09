page 50140 "TNI Credentials Card"
{
    PageType = Document;
    Caption = 'Credentials Card (TNI)';
    UsageCategory = None;
    SourceTable = "TNI Interfaces Credentials";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Credential Code"; Rec."Credential Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Authentication Type"; Rec."Authentication Type")
                {
                }
            }
            group("Basic Authentication")
            {
                Caption = 'Basic Authentication';
                Visible = "Authentication Type" = "Authentication Type"::"TNI Basic Auth";
                field("TNI UserName Basic"; Rec."UserName")
                {
                }
                field("TNI Password Basic"; Rec."Password")
                {
                }
            }
            group(OAuth20_)
            {
                Caption = 'OAuth 2.0 Setup';
                Visible = "Authentication Type" = "Authentication Type"::"TNI OAuth 2.0";
                group(OAuthGeneral)
                {
                    Caption = 'OAuth General';
                    field("Access Token Url"; Rec."Access Token Url")
                    {
                    }
                }
                group(OAuthAppDetails)
                {
                    Caption = 'OAuth. App Details';
                    field("OAuth Have Service To Service"; Rec."OAuth Have Service To Service")
                    {
                    }
                    field("Client ID"; Rec."Client ID")
                    {
                    }
                    field("Client Secret"; Rec."Client Secret")
                    {
                    }
                    field("Grant Type"; Rec."Grant Type")
                    {
                    }
                    field(Scope; Rec.Scope)
                    {
                    }
                    field(Resource; Rec.Resource)
                    {
                    }
                }
            }
            group(FTP)
            {
                Caption = 'FTP';
                Visible = "Authentication Type" = "Authentication Type"::"TNI FTP";
                field("Server Address"; Rec."Server Address")
                {
                }
                field("Server Port"; Rec."Server Port")
                {
                }
                field("TNI UserName FTP"; Rec."UserName")
                {
                }
                field("TNI Password FTP"; Rec."Password")
                {
                }
            }
        }
    }

    actions
    {
    }
}