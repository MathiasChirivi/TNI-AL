tableextension 65001 "CM1 Vendor" extends "Vendor"
{
    fields
    {
        field(65001; "CM1 Credemtel Active"; Boolean)
        {
            Caption = 'Credemtel Active';
            DataClassification = CustomerContent;
        }
        field(65002; "CM1 Credemtel Activation Date"; Date)
        {
            Caption = 'Credemtel Activation Date';
            DataClassification = CustomerContent;
        }
        field(65003; "CM1 Credemtel Auto Send"; Boolean)
        {
            Caption = 'Credemtel Auto Send';
            DataClassification = CustomerContent;
        }
    }
}