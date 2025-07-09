codeunit 50065 "TNI WS Internal Library"
{
    TableNo = "TNI Interfaces IN Entry";
    Permissions = tabledata "TNI Interfaces IN Entry" = RIMD;

    trigger OnRun()
    begin
        TryInsertInterfacesINEntry(Rec);
    end;

    procedure TryInsertInterfacesINEntry(var TNIInterfacesINEntry: Record "TNI Interfaces IN Entry")
    var
        TypeHelper: Codeunit "Type Helper";
        MessageOutStream: OutStream;
    begin
        TNIFlows.Get(TNIInterfacesINEntry."TNI Interface Code", TNIInterfacesINEntry."TNI Flow Code");
        TNIFlows.TestField(Enable);

        TNIInterfacesINEntry."TNI Transaction ID" := CreateGuid();

        case TNIInterfacesINEntry."TNI File Format" of
            TNIInterfacesINEntry."TNI File Format"::zip:
                begin
                    TNIInterfacesINEntry."TNI File".CreateOutStream(MessageOutStream);
                    MessageOutStream.Write(TypeHelper.ConvertValueFromBase64(Message));
                end;
            else begin
                TNIInterfacesINEntry."TNI File".CreateOutStream(MessageOutStream, TextEncoding::UTF8);
                MessageOutStream.WriteText(TypeHelper.ConvertValueFromBase64(Message));
            end;
        end;

        TNIInterfacesINEntry."TNI Timestamp" := CurrentDateTime;

        OnBeforeSaveDataInStagingTable(TNIInterfacesINEntry);
    end;

    procedure InsertInterfacesProcessedINEntry(var inTNIInterfacesINEntry: Record "TNI Interfaces IN Entry"; LogGroupID: Guid)
    var
        TNIInterfacesINEntry: Record "TNI Interfaces IN Entry";
    begin
        TNIInterfacesINEntry.Init();
        TNIInterfacesINEntry := inTNIInterfacesINEntry;

        TNIInterfacesINEntry."TNI Status" := TNIInterfacesINEntry."TNI Status"::"TNI Received";

        TNIInterfacesINEntry.Insert();

        TNIMgt.WriteInterfacesINLog(TNIInterfacesINEntry, TNILogType::Information, StrSubstNo(SucceededLbl, TNIInterfacesINEntry."TNI File Name"), '', '', 0, Database::"TNI Interfaces IN Entry", CreateGuid(), LogGroupID);
    end;

    procedure InsertInterfacesErrorINEntry(var inTNIInterfacesINEntry: Record "TNI Interfaces IN Entry"; LogGroupID: Guid)
    var
        TNIInterfacesINEntry: Record "TNI Interfaces IN Entry";
    begin
        TNIInterfacesINEntry.Init();
        TNIInterfacesINEntry."TNI Interface Code" := inTNIInterfacesINEntry."TNI Interface Code";
        TNIInterfacesINEntry."TNI Flow Code" := inTNIInterfacesINEntry."TNI Flow Code";
        TNIInterfacesINEntry."TNI Transaction ID" := CreateGuid();

        TNIInterfacesINEntry."TNI Status" := TNIInterfacesINEntry."TNI Status"::"TNI Error";
        TNIInterfacesINEntry."TNI Error Text" := CopyStr(GetLastErrorText(), 1, MaxStrLen(TNIInterfacesINEntry."TNI Error Text"));

        TNIInterfacesINEntry.Insert();

        TNIMgt.WriteInterfacesINLog(TNIInterfacesINEntry, TNILogType::Error, StrSubstNo(FailedLbl), GetLastErrorText(), '', 0, Database::"TNI Interfaces IN Entry", CreateGuid(), LogGroupID);
    end;

    procedure ProcessWSIN()
    var
        InterfacesWSIN: record "TNI Interfaces IN Entry";
        TNIInterfacesFlows: Record "TNI Interfaces";
        FileContent: Text;
        FileContentB64: Text;
        InStreamB64: InStream;
    begin
        Clear(TNIInterfacesFlows);
        InterfacesWSIN.Reset();
        InterfacesWSIN.Setfilter("TNI Interface Code", '<>%1', '');
        InterfacesWSIN.SetFilter("TNI Flow Code", '<>%1', '');
        InterfacesWSIN.SetRange("TNI Status", InterfacesWSIN."TNI Status"::"TNI Received");
        InterfacesWSIN.SetRange("TNI Processed", false);
        InterfacesWSIN.SetAutoCalcFields("TNI File");
        if InterfacesWSIN.FindSet() then
            repeat
                Clear(InStreamB64);
                TNIInterfacesFlows.Get(InterfacesWSIN."TNI Flow Code");
                TNIInterfacesFlows.TestField("TNI Interface Status", TNIInterfacesFlows."TNI Interface Status"::Released);

                InterfacesWSIN."TNI File".CreateInStream(InStreamB64);
                InStreamB64.Read(FileContentB64);
                FileContent := FileContentB64;

                TNI_OnFlowsProcessing(InterfacesWSIN, TNIInterfacesFlows, FileContent);

                Commit();
            until InterfacesWSIN.Next() = 0;
    end;

    procedure ProcessWSIN_SetSelection(var InterfacesWSIN: Record "TNI Interfaces IN Entry")
    var
        TNIInterfacesFlows: Record "TNI Interfaces";
        FileContent: Text;
        FileContentB64: Text;
        InStreamB64: InStream;
    begin
        Clear(TNIInterfacesFlows);

        if InterfacesWSIN.FindSet() then
            repeat
                Clear(InStreamB64);
                TNIInterfacesFlows.Get(InterfacesWSIN."TNI Flow Code");
                TNIInterfacesFlows.TestField("TNI Interface Status", TNIInterfacesFlows."TNI Interface Status"::Released);

                InterfacesWSIN.CalcFields("TNI File");
                InterfacesWSIN."TNI File".CreateInStream(InStreamB64);
                InStreamB64.Read(FileContentB64);
                FileContent := FileContentB64;

                TNI_OnFlowsProcessing(InterfacesWSIN, TNIInterfacesFlows, FileContent);
                Commit();
            until InterfacesWSIN.Next() = 0;
    end;

    procedure SetMessage(inMessage: Text)
    begin
        Message := inMessage;
    end;

    [IntegrationEvent(false, false)]
    local procedure TNI_OnFlowsProcessing(InterfacesWSIN: Record "TNI Interfaces IN Entry"; TNIInterfacesFlows: Record "TNI Interfaces"; FileContent: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveDataInStagingTable(InterfacesWSIN: Record "TNI Interfaces IN Entry")
    begin
    end;

    var
        TNIFlows: Record "TNI Flows";
        TNIMgt: Codeunit "TNI Mgt.";
        Message: Text;
        TNILogType: Enum "TNI Log Type";
        SucceededLbl: Label 'Call succeeded - %1';
        FailedLbl: Label 'Call failed - %1';
}
