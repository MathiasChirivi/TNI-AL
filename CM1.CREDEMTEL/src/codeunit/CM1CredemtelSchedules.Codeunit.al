codeunit 50093 "CM1 Credemtel Schedules"
{
    TableNo = "Job Queue Entry";
    trigger OnRun()
    var
        TNIInterfacesINEntry: Record "TNI Interfaces IN Entry";
        CM1CredemtelStaging: Record "CM1 Credemtel Staging";
        TNIFlows: Record "TNI Flows";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        CM1CredemtelDriver: Codeunit "CM1 Credemtel Driver";
        TNIMgt: Codeunit "TNI Mgt.";
        InStr: InStream;
        ContentText: Text;
        NullFileName: Text[100];
        TNIEntryGuid: Guid;
        TNIGroupGuid: Guid;
        TNILogType: Enum "TNI Log Type";
        OrderResponseSuccessLbl: Label 'Scaricati correttamente gli order response';
    begin
        case
            Rec."Parameter String" of
            'CREDEMTEL_GET_ORDERS':
                begin
                    PurchasesPayablesSetup.Get();
                    PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Interface");
                    PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Ord Response");
                    TNIFlows.Get(PurchasesPayablesSetup."CM1 Credemtel TNI Interface", PurchasesPayablesSetup."CM1 Credemtel TNI Ord Response");

                    TNIEntryGuid := CreateGuid();
                    TNIGroupGuid := CreateGuid();

                    TNIMgt.CreateInternalEntry(TNIInterfacesINEntry, TNIFlows, NullFileName, TNIEntryGuid);
                    Commit();
                    Clear(CM1CREDEMTELDriver);
                    CM1CREDEMTELDriver.SetParametersGetOrders(20, TNIInterfacesINEntry);
                    if not CM1CREDEMTELDriver.Run() then
                        TniMgt.WriteInterfacesINLog(TNIInterfacesINEntry, TNILogType::Error, GetLastErrorText(), GetLastErrorCallStack(), '', 0, Database::"Purchase Header", TNIEntryGuid, TNIGroupGuid)
                    else
                        TniMgt.WriteInterfacesINLog(TNIInterfacesINEntry, TNILogType::Information, OrderResponseSuccessLbl, '', '', 0, Database::"Purchase Header", TNIEntryGuid, TNIGroupGuid);

                end;
            'CREDEMTEL_PROCESS_ORDERS':
                begin

                    PurchasesPayablesSetup.Get();
                    PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Interface");
                    PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Proc Order");
                    TNIFlows.Get(PurchasesPayablesSetup."CM1 Credemtel TNI Interface", PurchasesPayablesSetup."CM1 Credemtel TNI Proc Order");

                    TNIEntryGuid := CreateGuid();
                    TNIGroupGuid := CreateGuid();

                    TNIMgt.CreateInternalEntry(TNIInterfacesINEntry, TNIFlows, NullFileName, TNIEntryGuid);
                    Commit();
                    Clear(CM1CREDEMTELDriver);
                    CM1CREDEMTELDriver.SetParametersProcessOrderResponse(21, CM1CredemtelStaging);
                    if not CM1CREDEMTELDriver.Run() then
                        TniMgt.WriteInterfacesINLog(TNIInterfacesINEntry, TNILogType::Error, GetLastErrorText(), GetLastErrorCallStack(), '', 0, Database::"Purchase Header", TNIEntryGuid, TNIGroupGuid)
                    else
                        TniMgt.WriteInterfacesINLog(TNIInterfacesINEntry, TNILogType::Information, OrderResponseSuccessLbl, '', '', 0, Database::"Purchase Header", TNIEntryGuid, TNIGroupGuid);

                end;
        end;
    end;
}