enum 50042 "TNI Log Type"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; "Warning")
    {
        Caption = 'Warning';
    }
    value(2; "Error")
    {
        Caption = 'Error';
    }
    value(3; "Information")
    {
        Caption = 'Processed';
    }
    value(4; "Block")
    {
        Caption = 'Block';
    }
}