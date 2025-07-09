codeunit 50063 "TNI Send WS"
{
    TableNo = "TNI Interfaces OUT Entry";

    trigger OnRun()
    begin
        SendWS(Rec);
    end;

    local procedure SendWS(var TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry")
    var
        TNIFlows: Record "TNI Flows";
        TNIInterfacesCredentials: Record "TNI Interfaces Credentials";
        FileInStr: InStream;
        Content: HttpContent;
        Client: HttpClient;
        ContentHeaders: HttpHeaders;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        AuthText: Text;
        OutStr2: OutStream;
    begin
        TNIFlows.Get(TNIInterfacesOUTEntry."TNI Interface Code", TNIInterfacesOUTEntry."TNI Flow Code");
        TNIFlows.TestField("WS Uri");
        TNIFlows.TestField("WS Method");

        //header
        ContentHeaders.Clear();
        RequestMessage.GetHeaders(ContentHeaders);

        AuthText := '';

        if TNIFlows."TNI Credential Code" <> '' then begin
            TNIInterfacesCredentials.Get(TNIFlows."TNI Credential Code");

            AuthText := GetAuthenticationTag(TNIInterfacesCredentials);
        end;

        OnBeforeAddAuthorizationHeader(TNIFlows, TNIInterfacesOUTEntry, AuthText);

        ContentHeaders.Add('Authorization', AuthText);

        //body
        TNIInterfacesOUTEntry."TNI Sent File".CreateInStream(FileInStr);
        Content.WriteFrom(FileInStr);

        RequestMessage.SetRequestUri(TNIFlows."WS Uri");
        RequestMessage.Method(Format(TNIFlows."WS Method"));
        RequestMessage.Content(Content);

        Client.Send(RequestMessage, ResponseMessage);

        if not ResponseMessage.IsSuccessStatusCode() then begin
            ResponseMessage.Content.ReadAs(ResponseText);

            Error(Err001Err, ResponseMessage.HttpStatusCode, ResponseText);
        end else begin
            ResponseMessage.Content.ReadAs(ResponseText);
            TNIInterfacesOUTEntry."TNI Response File".CreateOutStream(OutStr2, TextEncoding::UTF8);
            OutStr2.WriteText(ResponseText);
        end;
    end;

    local procedure GetAuthenticationTag(TNIInterfacesCredentials: Record "TNI Interfaces Credentials") Authorization: Text
    begin
        case TNIInterfacesCredentials."Authentication Type" of
            TNIInterfacesCredentials."Authentication Type"::"TNI Basic Auth":
                Authorization := GetBasicAuthentication(TNIInterfacesCredentials);
            TNIInterfacesCredentials."Authentication Type"::"TNI OAuth 2.0":
                Authorization := GetOauth2Token(TNIInterfacesCredentials);
        end;
    end;

    local procedure GetBasicAuthentication(TNIInterfacesCredentials: Record "TNI Interfaces Credentials") AccessText: Text;
    var
        TypeHelper: Codeunit "Type Helper";
        BasicAuthStringLbl: Label 'Basic %1', Locked = true;
        UserPasswordLbl: Label '%1:%2', Locked = true;
        AccessTextBase64: Text;
    begin
        TNIInterfacesCredentials.TestField(UserName);
        TNIInterfacesCredentials.TestField(Password);

        AccessTextBase64 := TypeHelper.ConvertValueToBase64(StrSubstNo(UserPasswordLbl, TNIInterfacesCredentials.UserName, TNIInterfacesCredentials.Password));
        AccessText := StrSubstNo(BasicAuthStringLbl, AccessTextBase64);
    end;

    local procedure GetOauth2Token(TNIInterfacesCredentials: Record "TNI Interfaces Credentials") AccessToken: Text;
    var
        IsSuccess: Boolean;
        BearerAuthStringLbl: Label 'Bearer %1', Locked = true;
        Error001Err: Label 'Unable to retrieve Bearer access token', Locked = true;
    begin
        TNIInterfacesCredentials.TestField("Access Token Url");
        TNIInterfacesCredentials.TestField("Client ID");
        TNIInterfacesCredentials.TestField("Client Secret");
        TNIInterfacesCredentials.TestField(Scope);

        IsSuccess := AcquireToken(TNIInterfacesCredentials."Client ID", TNIInterfacesCredentials."Client Secret", TNIInterfacesCredentials."Access Token Url", TNIInterfacesCredentials.Scope, AccessToken);

        if not IsSuccess then
            Error(Error001Err);

        AccessToken := StrSubstNo(BearerAuthStringLbl, AccessToken);
    end;

    local procedure AcquireToken(OAuthClientID: Text[250]; OAuthSecret: Text[250]; BearerWSUrl: Text[250]; BearerScope: Text[250]; var AccessToken: Text): Boolean
    var
        OAuth2: Codeunit "OAuth 2.0 Mgt.";
        Scopes: List of [Text];
    begin
        if BearerScope <> '' then
            Scopes.Add(BearerScope);

        exit(false);

        // if OAuth2.AcquireTokenWithClientCredentials(OAuthClientID, OAuthSecret, BearerWSUrl, '', Scopes, AccessToken) then
        //     exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddAuthorizationHeader(TNIFlows: Record "TNI Flows"; TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry"; var AuthText: Text)
    begin
    end;

    var
        Err001Err: Label 'Impossible to send WS: \ %1 \ %2';
}