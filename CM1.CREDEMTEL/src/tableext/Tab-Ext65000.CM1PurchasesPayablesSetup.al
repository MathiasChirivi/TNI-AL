tableextension 65000 "CM1 Purchases & Payables Setup" extends "Purchases & Payables Setup"
{
    fields
    {
        field(50000; "CM1 Credemtel Enabled"; Boolean)
        {
            Caption = 'Credemtel Enabled';
            DataClassification = CustomerContent;
        }
        field(50001; "CM1 Debug Enabled"; Boolean)
        {
            Caption = 'Debug Enabled';
            DataClassification = CustomerContent;
        }
        field(50002; "CM1 ACQ Professional Role"; Code[20])
        {
            Caption = 'ACQ Professional Role';
            DataClassification = CustomerContent;
            TableRelation = "Job Responsibility".Code;
        }
        field(50003; "CM1 Delivery Plan Prof. Role"; Code[20])
        {
            Caption = 'Delivery Plan Professional Role';
            DataClassification = CustomerContent;
            TableRelation = "Job Responsibility".Code;
        }
        field(50004; "CM1 Go Live Date"; Date)
        {
            Caption = 'Go Live Date';
            DataClassification = CustomerContent;
        }
        field(50005; "CM1 Credemtel Component Path"; Text[250])
        {
            Caption = 'Credemtel Component Path';
            DataClassification = CustomerContent;
        }
        field(50006; "CM1 Credemtel TNI Interface"; Code[20])
        {
            Caption = 'Credemtel TNI Interface';
            DataClassification = CustomerContent;
            TableRelation = "TNI Interfaces".Code;
        }
        field(50007; "CM1 Credemtel TNI Flow"; Code[20]) //send
        {
            Caption = 'Credemtel TNI Flow';
            DataClassification = CustomerContent;
            TableRelation = "TNI Flows"."TNI Flow Code";
        }
        field(50008; "CM1 Credemtel TNI Change Order"; Code[20]) //change
        {
            Caption = 'Credemtel TNI Change Order';
            DataClassification = CustomerContent;
            TableRelation = "TNI Flows"."TNI Flow Code";
        }
        field(50009; "CM1 Credemtel TNI Close Order"; Code[20]) // close
        {
            Caption = 'Credemtel TNI Close Order';
            DataClassification = CustomerContent;
            TableRelation = "TNI Flows"."TNI Flow Code";
        }
        field(50010; "CM1 Credemtel TNI Rcpt Adv St"; Code[20]) // Receipt Advice Storno
        {
            Caption = 'Credemtel TNI Receipt Advice Storno';
            DataClassification = CustomerContent;
            TableRelation = "TNI Flows"."TNI Flow Code";
        }
        field(50011; "CM1 Credemtel TNI Cancel Order"; Code[20]) // Annula
        {
            Caption = 'Credemtel TNI Cancel Order';
            DataClassification = CustomerContent;
            TableRelation = "TNI Flows"."TNI Flow Code";
        }
        field(50012; "CM1 Credemtel TNI Rcpt Adv"; Code[20]) // Receipt Advice
        {
            Caption = 'Credemtel TNI Receipt Advice';
            DataClassification = CustomerContent;
            TableRelation = "TNI Flows"."TNI Flow Code";
        }
        field(50013; "CM1 Credemtel TNI Ord Response"; Code[20]) // Receipt Order Response
        {
            Caption = 'Credemtel TNI Order Response';
            DataClassification = CustomerContent;
            TableRelation = "TNI Flows"."TNI Flow Code";
        }
        field(50014; "CM1 Credemtel TNI Proc Order"; Code[20])
        {
            Caption = 'Credemtel TNI Process Order';
            DataClassification = CustomerContent;
            TableRelation = "TNI Flows"."TNI Flow Code";
        }
    }
}