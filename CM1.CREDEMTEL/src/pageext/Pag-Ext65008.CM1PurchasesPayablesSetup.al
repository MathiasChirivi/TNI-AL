pageextension 65008 "CM1 Purchases & Payables Setup" extends "Purchases & Payables Setup"
{
    layout
    {
        addafter(IUNGO)
        {
            group(CREDEMTEL)
            {
                Caption = 'CREDEMTEL';
                group(CredemtelTNI)
                {
                    Caption = 'Credemtel - TNI';
                }
                field("CM1 Credemtel Enabled"; Rec."CM1 Credemtel Enabled")
                {
                    ApplicationArea = All;
                }
                field("CM1 Debug Enabled"; Rec."CM1 Debug Enabled")
                {
                    ApplicationArea = All;
                }
                field("CM1 Delivery Plan Prof. Role"; Rec."CM1 Delivery Plan Prof. Role")
                {
                    ApplicationArea = All;
                }
                field("CM1 ACQ Professional Role"; Rec."CM1 ACQ Professional Role")
                {
                    ApplicationArea = All;
                }
                field("CM1 Go Live Date"; Rec."CM1 Go Live Date")
                {
                    ApplicationArea = All;
                }
                field("CM1 Credemtel Component Path"; Rec."CM1 Credemtel Component Path")
                {
                    ApplicationArea = All;
                }
            }
            group(TNI)
            {
                Caption = 'TNI';

                field("CM1 Credemtel TNI Interface"; "CM1 Credemtel TNI Interface")
                { ApplicationArea = All; }
                field("CM1 Credemtel TNI Flow"; "CM1 Credemtel TNI Flow") // Order
                { ApplicationArea = All; }
                field("CM1 Credemtel TNI Cancel Order"; Rec."CM1 Credemtel TNI Cancel Order") // cancel 
                { ApplicationArea = All; }
                field("CM1 Credemtel TNI Change Order"; Rec."CM1 Credemtel TNI Change Order") // change
                { ApplicationArea = All; }
                field("CM1 Credemtel TNI Delete Order"; Rec."CM1 Credemtel TNI Close Order") // delete
                { ApplicationArea = All; }
                field("CM1 Credemtel TNI Rcpt Adv"; Rec."CM1 Credemtel TNI Rcpt Adv") // Receipt Advice
                { ApplicationArea = All; }
                field("CM1 Credemtel TNI Rcpt Adv St"; Rec."CM1 Credemtel TNI Rcpt Adv St") // Receipt Advice Storno
                { ApplicationArea = All; }
                field("CM1 Credemtel TNI Ord Response"; Rec."CM1 Credemtel TNI Ord Response") // Order Response
                { ApplicationArea = All; }
                field("CM1 Credemtel TNI Proc Order"; "CM1 Credemtel TNI Proc Order") // Process Order Response
                { ApplicationArea = All; }
            }
        }
    }
    actions
    {
        addlast(Processing)
        {
            group(Credemtel_TestProcess)
            {
                action(CredemtelTest_JWT)
                {
                    ApplicationArea = All;
                    Caption = 'Credemtel Test JWT';
                    Image = Components;
                    trigger OnAction()
                    var
                        CM1CredemtelGenFnc: Codeunit "CM1 Credemtel Gen. Fnc.";
                    begin
                        Message(CM1CredemtelGenFnc.GetTokenFromLocalApi());
                    end;
                }
                action(CredemtelTest_Token)
                {
                    ApplicationArea = All;
                    Caption = 'Credemtel Test Token';
                    Image = Components;
                    trigger OnAction()
                    var
                        CM1CredemtelGenFnc: Codeunit "CM1 Credemtel Gen. Fnc.";
                        FinalToken: Text;
                    begin
                        FinalToken := CM1CredemtelGenFnc.GetTokenFromLocalApi();
                        FinalToken := CM1CredemtelGenFnc.GetAccessTokenFromJwt(FinalToken);
                        Message(FinalToken);
                    end;
                }
            }
        }
    }
}