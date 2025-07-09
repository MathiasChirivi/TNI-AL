tableextension 50120 "CM1 Purch Doc Sum Buff" extends "Purchase Doc. Summary Buffer"
{
    fields
    {
        field(50020; "CM1 Send to Credemetel"; Boolean)
        {
            Caption = 'Send to Credemetel';
            DataClassification = CustomerContent;
        }
    }
}