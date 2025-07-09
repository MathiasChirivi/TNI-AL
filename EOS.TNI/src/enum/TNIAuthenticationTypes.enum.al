enum 50030 "TNI Authentication Types"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; "TNI Basic Auth")
    {
        Caption = 'Basic Authentication';
    }
    value(2; "TNI OAuth 2.0")
    {
        Caption = 'OAuth 2.0';
    }
    value(3; "TNI FTP")
    {
        Caption = 'FTP';
    }
}