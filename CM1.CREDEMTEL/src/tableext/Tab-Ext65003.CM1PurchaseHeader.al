tableextension 65003 "CM1 Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(50010; "CM1 Credemtel Order Date"; Date)
        {
            Caption = 'Credemtel Order Date';
            DataClassification = CustomerContent;
        }
        field(50020; "CM1 Send to Credemetel"; Boolean)
        {
            Caption = 'Send to Credemetel';
            DataClassification = CustomerContent;
        }
    }
}