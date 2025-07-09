codeunit 50052 "TNI Mgt."
{
    procedure SendFlow(InterfaceCode: Code[20]; FlowCode: Code[20]; RecVariant: Variant)
    var
        TNIInterfaces: Record "TNI Interfaces";
        TNIFlows: Record "TNI Flows";
        TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry";
        TNIWriteFile: Codeunit "TNI Write File";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        //NoSeries: Codeunit "No. Series";
        RecRef: RecordRef;
        FileName: Text[100];
        CodeunitID: Integer;
    begin
        TNIInterfaces.Get(InterfaceCode);

        TNIFlows.Get(InterfaceCode, FlowCode);

        case TNIFlows."TNI Interface Type" of
            TNIFlows."TNI Interface Type"::"Fixed Text":
                if TNIFlows."TNI File Name Code" <> '' then
                    // FileName := NoSeries.GetNextNo(TNIFlows."TNI File Name Code", Today, true);
                    FileName := NoSeriesMgt.GetNextNo(TNIFlows."TNI File Name Code", Today, true);
        end;

        RecRef.GetTable(RecVariant);
        CreateExternalEntry(TNIInterfacesOUTEntry, TNIFlows."TNI Interface Code", TNIFlows."TNI Flow Code", RecRef);

        ClearLastError();
        Commit();

        OnAfterWriteFileName(FileName, TNIFlows, RecRef);

        TNIWriteFile.SetDatas(TNIFlows."TNI Interface Code", TNIFlows."TNI Flow Code", RecRef, FileName);
        if TNIWriteFile.Run(TNIInterfacesOUTEntry) then begin
            UpdateSuccededEntry(TNIInterfacesOUTEntry, EntriesStatus::"TNI Created");
            WriteInterfacesOUTLog(TNIInterfacesOUTEntry, '', StrSubstNo(WriteLbl, TNIInterfacesOUTEntry."TNI File Name"), '', '', '', 0, false);

            Commit();
            OnSendFlowsGetCodeunitID(TNIInterfaces, CodeunitID);
            if Codeunit.Run(CodeunitID, TNIInterfacesOUTEntry) then begin
                UpdateSuccededEntry(TNIInterfacesOUTEntry, EntriesStatus::"TNI Sent");

                case TNIInterfaces."Data Exchange Type" of
                    TNIInterfaces."Data Exchange Type"::File:
                        WriteInterfacesOUTLog(TNIInterfacesOUTEntry, '', StrSubstNo(SentLbl, TNIInterfacesOUTEntry."TNI File Name", TNIInterfacesOUTEntry."TNI File Path"), '', '', '', 0, false);
                    TNIInterfaces."Data Exchange Type"::"Web Services":
                        WriteInterfacesOUTLog(TNIInterfacesOUTEntry, '', SentWSLbl, '', '', '', 0, false);
                end;

            end else begin
                UpdateSuccededEntry(TNIInterfacesOUTEntry, EntriesStatus::"TNI Error");
                WriteInterfacesOUTLog(TNIInterfacesOUTEntry, '', StrSubstNo(SentErrorLbl), '', GetLastErrorText(), '', 0, false);
            end;
        end else begin
            UpdateSuccededEntry(TNIInterfacesOUTEntry, EntriesStatus::"TNI Error");
            WriteInterfacesOUTLog(TNIInterfacesOUTEntry, '', StrSubstNo(ErrWriteLbl), '', GetLastErrorText(), '', 0, false);
        end;

        OnAfterSendFlow(InterfaceCode, FlowCode, RecRef, TNIInterfacesOUTEntry, TNIInterfaces);
    end;

    procedure ReadFlow(InterfaceCode: Code[20]; FlowCode: Code[20])
    var
        TNIInterfaces: Record "TNI Interfaces";
        TNIFlows: Record "TNI Flows";
        TNIInterfacesINEntry: Record "TNI Interfaces IN Entry";
        TransactionID: List of [Guid];
        i: Integer;
        LogGroupID: Guid;
    begin
        TNIInterfaces.Get(InterfaceCode);

        TNIFlows.Get(InterfaceCode, FlowCode);
        TNIFlows.TestField(Enable);

        LogGroupID := CreateGuid();

        OnReadFlow(TNIInterfaces, TNIFlows, TransactionID, LogGroupID);

        if not TNIFlows."TNI Process" then
            exit;

        for i := 1 to TransactionID.Count do begin
            TNIInterfacesINEntry.SetRange("TNI Interface Code", TNIFlows."TNI Interface Code");
            TNIInterfacesINEntry.SetRange("TNI Flow Code", TNIFlows."TNI Flow Code");
            TNIInterfacesINEntry.SetRange("TNI Transaction ID", TransactionID.Get(i));
            TNIInterfacesINEntry.SetRange("TNI Status", TNIInterfacesINEntry."TNI Status"::"TNI Received");
            if TNIInterfacesINEntry.FindFirst() then
                ProcessReadFlow(TNIInterfacesINEntry, TNIFlows, LogGroupID);
        end;
    end;

    procedure ReadWsInFlow(var Rec: Record "TNI Interfaces IN Entry"; ParContent: Text)
    var
        TNIFlows: Record "TNI Flows";
        TNIInterfacesINEntry: Record "TNI Interfaces IN Entry";
        LogGroupID: Guid;
    begin
        LogGroupID := CreateGuid();

        TNIWSInternalLibrary.SetMessage(ParContent);
        if TNIWSInternalLibrary.Run(Rec) then begin

            TNIWSInternalLibrary.InsertInterfacesProcessedINEntry(Rec, LogGroupID);

            TNIFlows.Get(Rec."TNI Interface Code", Rec."TNI Flow Code");
            if not TNIFlows."TNI Process" then
                exit;

            TNIInterfacesINEntry.Get(Rec."TNI Interface Code", Rec."TNI Flow Code", Rec."TNI Transaction ID");

            ProcessReadFlow(TNIInterfacesINEntry, TNIFlows, LogGroupID);
        end else
            TNIWSInternalLibrary.InsertInterfacesErrorINEntry(Rec, LogGroupID);
    end;

    procedure ProcessReadFlow(var TNIInterfacesINEntry: Record "TNI Interfaces IN Entry"; TNIFlows: Record "TNI Flows"; LogGroupID: Guid)
    var
        CodeunitID: Integer;
        EmptyGUID: Guid;
    begin
        OnBeforeRunProcessSetCodeunitID(TNIInterfacesINEntry, TNIFlows, CodeunitID);

        if LogGroupID = EmptyGUID then
            LogGroupID := CreateGuid();

        if CodeunitID = 0 then begin
            OnProcessSingleRecord(TNIInterfacesINEntry, TNIFlows, LogGroupID);
            exit;
        end;

        Commit();
        if Codeunit.Run(CodeunitID, TNIInterfacesINEntry) then
            SetProcessEntryLog(TNIInterfacesINEntry, '', '', 0, Database::"TNI Interfaces IN Entry", CreateGuid(), LogGroupID)
        else
            SetProcessEntryLog(TNIInterfacesINEntry, GetLastErrorText(), '', 0, Database::"TNI Interfaces IN Entry", CreateGuid(), LogGroupID)
    end;

    procedure SetProcessEntryLog(var TNIInterfacesINEntry: Record "TNI Interfaces IN Entry"; LastStackError: Text; SourceID: Code[20]; SourceLineNo: Integer; TableNo: Integer; SystemID: Guid; LogGroupID: Guid)
    begin
        if LastStackError = '' then begin
            UpdateSuccededEntry(TNIInterfacesINEntry, EntriesStatus::"TNI Processed");
            WriteInterfacesINLog(TNIInterfacesINEntry, TNILogType::Information, StrSubstNo(ProcessLbl, TNIInterfacesINEntry."TNI File Name"), LastStackError, SourceID, SourceLineNo, TableNo, SystemID, LogGroupID);
        end else begin
            UpdateSuccededEntry(TNIInterfacesINEntry, EntriesStatus::"TNI Error");
            WriteInterfacesINLog(TNIInterfacesINEntry, TNILogType::Error, StrSubstNo(ErrProcessLbl), LastStackError, SourceID, SourceLineNo, TableNo, SystemID, LogGroupID);
        end;
    end;

    procedure CreateExternalEntry(var TNIInterfacesOUT: Record "TNI Interfaces OUT Entry"; InterfaceCode: Code[20]; FlowCode: Code[20]; RecRef: RecordRef)
    begin
        Clear(TNIInterfacesOUT);

        TNIInterfacesOUT.Init();
        TNIInterfacesOUT."TNI Interface Code" := InterfaceCode;
        TNIInterfacesOUT."TNI Flow Code" := FlowCode;

        if IsNullGuid(TNIInterfacesOUT."TNI Transaction ID") then
            TNIInterfacesOUT."TNI Transaction ID" := CreateGuid();

        TNIInterfacesOUT."TNI Timestamp" := CurrentDateTime;

        // TNIInterfacesOUT."TNI Source Key Text" := CopyStr(RecRef.GetPosition(true), 1, MaxStrLen(TNIInterfacesOUT."TNI Source Key Text"));

        OnBeforeInsert_TNI_ExternalEntry(TNIInterfacesOUT, RecRef);

        TNIInterfacesOUT.Insert();
    end;

    procedure CreateInternalEntry(var TNIInterfacesIN: Record "TNI Interfaces IN Entry"; TNIFlows: Record "TNI Flows"; FileName: Text[100]; var TransactionID: Guid)
    begin
        Clear(TNIInterfacesIN);

        TNIInterfacesIN.Init();
        TNIInterfacesIN."TNI Interface Code" := TNIFlows."TNI Interface Code";
        TNIInterfacesIN."TNI Flow Code" := TNIFlows."TNI Flow Code";

        if IsNullGuid(TNIInterfacesIN."TNI Transaction ID") then begin
            TNIInterfacesIN."TNI Transaction ID" := CreateGuid();
            TransactionID := TNIInterfacesIN."TNI Transaction ID";
        end;

        TNIInterfacesIN."TNI Timestamp" := CurrentDateTime;

        TNIInterfacesIN."TNI File Name" := FileName;
        TNIInterfacesIN."TNI File Path" := CopyStr(TNIFlows."TNI File Path" + '\' + FileName, 1, MaxStrLen(TNIInterfacesIN."TNI File Path"));

        OnBeforeInsert_TNI_InternalEntry(TNIInterfacesIN);

        TNIInterfacesIN.Insert();
    end;

    procedure WriteInterfacesINLog(var TNIInterfacesINEntry: record "TNI Interfaces IN Entry"; LogType: Enum "TNI Log Type"; LogDescription: Text; LastStackError: Text; SourceID: Code[20]; SourceLineNo: Integer; TableNo: Integer; SystemID: Guid; LogGroupID: Guid)
    var
        TNIInterfacesLog: Record "TNI Interfaces Log";
    begin
        TNIInterfacesLog.Init();
        TNIInterfacesLog."TNI Interface Code" := TNIInterfacesINEntry."TNI Interface Code";
        TNIInterfacesLog."TNI Flow Code" := TNIInterfacesINEntry."TNI Flow Code";
        TNIInterfacesLog."TNI Transaction ID" := TNIInterfacesINEntry."TNI Transaction ID";

        TNIInterfacesINEntry."TNI Status" := TNIInterfacesINEntry."TNI Status"::"TNI Processed";

        TNIInterfacesLog."TNI Log Type" := LogType;

        if LogDescription <> '' then
            TNIInterfacesLog."TNI Log Description" := copystr(LogDescription, 1, maxstrlen(TNIInterfacesLog."TNI Log Description"));

        if LastStackError <> '' then begin
            TNIInterfacesLog."TNI Last Stack Error" := CopyStr(LastStackError, 1, MaxStrLen(TNIInterfacesLog."TNI Last Stack Error"));
            TNIInterfacesINEntry."TNI Status" := TNIInterfacesINEntry."TNI Status"::"TNI Error";
        end;

        TNIInterfacesLog."TNI Direction" := TNIInterfacesLog."TNI Direction"::"IN Flow";
        TNIInterfacesLog."TNI Log Line ID" := CreateGuid();
        TNIInterfacesLog."TNI Timestamp" := CurrentDateTime;

        TNIInterfacesLog."TNI Source ID" := SourceID;
        TNIInterfacesLog."TNI Source Line No." := SourceLineNo;

        TNIInterfacesLog."Table No." := TableNo;
        TNIInterfacesLog."Table System ID" := SystemID;

        TNIInterfacesLog."Log Group ID" := LogGroupID;

        OnBeforeInsert_TNI_Log(TNIInterfacesLog);

        TNIInterfacesINEntry.Modify();
        TNIInterfacesLog.Insert();
    end;

    procedure WriteInterfacesOUTLog(var ParInterfacesWSOUT: Record "TNI Interfaces OUT Entry"; ParLastStack: Text; ParInfoDescription: Text; ParWarningDescription: Text; ParErrorDescription: Text; SourceID: Code[20]; SourceLineNo: Integer; SkipEntryModify: Boolean)
    var
        TNIInterfacesLog: Record "TNI Interfaces Log";
    begin
        Clear(TNIInterfacesLog);
        TNIInterfacesLog.Init();
        TNIInterfacesLog."TNI Interface Code" := ParInterfacesWSOUT."TNI Interface Code";
        TNIInterfacesLog."TNI Flow Code" := ParInterfacesWSOUT."TNI Flow Code";
        TNIInterfacesLog."TNI Source ID" := SourceID;
        TNIInterfacesLog."TNI Source Line No." := SourceLineNo;

        if ParInfoDescription <> '' then begin
            TNIInterfacesLog."TNI Log Type" := TNIInterfacesLog."TNI Log Type"::Information;
            TNIInterfacesLog."TNI Log Description" := copystr(ParInfoDescription, 1, MaxStrLen(TNIInterfacesLog."TNI Log Description"));
        end;

        if ParWarningDescription <> '' then begin
            TNIInterfacesLog."TNI Log Type" := TNIInterfacesLog."TNI Log Type"::Warning;
            TNIInterfacesLog."TNI Log Description" := copystr(ParWarningDescription, 1, MaxStrLen(TNIInterfacesLog."TNI Log Description"));
        end;

        if ParErrorDescription <> '' then begin
            TNIInterfacesLog."TNI Log Type" := TNIInterfacesLog."TNI Log Type"::Error;
            TNIInterfacesLog."TNI Log Description" := copystr(ParInfoDescription, 1, maxstrlen(TNIInterfacesLog."TNI Log Description"));
            TNIInterfacesLog."TNI Last Stack Error" := CopyStr(ParErrorDescription, 1, MaxStrLen(TNIInterfacesLog."TNI Last Stack Error"));
            if not SkipEntryModify then begin
                ParInterfacesWSOUT."TNI Status" := ParInterfacesWSOUT."TNI Status"::"TNI Error";
                ParInterfacesWSOUT.Modify();
            end;
        end;

        if TNIInterfacesLog."TNI Log Type" = TNIInterfacesLog."TNI Log Type"::" " then
            TNIInterfacesLog."TNI Log Type" := TNIInterfacesLog."TNI Log Type"::Warning;

        TNIInterfacesLog."TNI Direction" := TNIInterfacesLog."TNI Direction"::"IN Flow";
        TNIInterfacesLog."TNI Log Line ID" := CreateGuid();
        TNIInterfacesLog."TNI Transaction ID" := ParInterfacesWSOUT."TNI Transaction ID";
        TNIInterfacesLog."TNI Timestamp" := CurrentDateTime;

        OnBeforeInsert_TNI_Log(TNIInterfacesLog);

        TNIInterfacesLog.Insert();

        if not SkipEntryModify then
            if (ParErrorDescription = '') and (ParInterfacesWSOUT."TNI Status" <> ParInterfacesWSOUT."TNI Status"::"TNI Error") then
                ParInterfacesWSOUT."TNI Status" := ParInterfacesWSOUT."TNI Status"::"TNI Sent";

        if not SkipEntryModify then begin
            ParInterfacesWSOUT."TNI Sent" := true;
            OnBeforeModify_TNI_ExternalEntry_AfterLogInsert(ParInterfacesWSOUT);
            ParInterfacesWSOUT.Modify();
        end;
    end;

    procedure TrimContent(var ContentToTrim: Text; var TrimmedContent: Text; MaxLen: Integer): Boolean
    begin
        TrimmedContent := CopyStr(ContentToTrim, 1, MaxLen);
        if StrLen(ContentToTrim) > MaxLen then begin
            ContentToTrim := CopyStr(ContentToTrim, MaxLen + 1, StrLen(ContentToTrim) - MaxLen);
            exit(true);
        end else begin
            ContentToTrim := '';
            exit(false);
        end;
    end;

    procedure UpdateSuccededEntry(var TNIInterfacesINEntry: Record "TNI Interfaces IN Entry"; inEntriesStatus: Enum "TNI Interfaces Entries Status")
    begin
        TNIInterfacesINEntry."TNI Status" := inEntriesStatus;
        TNIInterfacesINEntry."TNI Error Text" := '';
        TNIInterfacesINEntry.Modify();
    end;

    procedure UpdateSuccededEntry(var TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry"; inEntriesStatus: Enum "TNI Interfaces Entries Status")
    begin
        TNIInterfacesOUTEntry."TNI Status" := inEntriesStatus;
        TNIInterfacesOUTEntry."TNI Error Text" := '';
        TNIInterfacesOUTEntry.Modify();
    end;

    procedure UpdateErrorEntry(var TNIInterfacesINEntry: Record "TNI Interfaces IN Entry"; inEntriesStatus: Enum "TNI Interfaces Entries Status")
    begin
        TNIInterfacesINEntry."TNI Status" := inEntriesStatus;
        TNIInterfacesINEntry."TNI Error Text" := CopyStr(GetLastErrorText(), 1, MaxStrLen(TNIInterfacesINEntry."TNI Error Text"));
        TNIInterfacesINEntry.Modify();
    end;

    procedure UpdateErrorEntry(var TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry"; inEntriesStatus: Enum "TNI Interfaces Entries Status")
    begin
        TNIInterfacesOUTEntry."TNI Status" := inEntriesStatus;
        TNIInterfacesOUTEntry."TNI Error Text" := CopyStr(GetLastErrorText(), 1, MaxStrLen(TNIInterfacesOUTEntry."TNI Error Text"));
        TNIInterfacesOUTEntry.Modify();
    end;

    procedure UpdateErrorINEntry(var TNIInterfacesINEntry: Record "TNI Interfaces IN Entry"; inEntriesStatus: Enum "TNI Interfaces Entries Status")
    begin
        TNIInterfacesINEntry."TNI Status" := inEntriesStatus;
        TNIInterfacesINEntry."TNI Error Text" := CopyStr(GetLastErrorText(), 1, MaxStrLen(TNIInterfacesINEntry."TNI Error Text"));
        TNIInterfacesINEntry.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TNI Mgt.", 'OnSendFlowsGetCodeunitID', '', true, false)]
    local procedure TNIMgt_OnSendFlowsGetCodeunitID(TNIInterfaces: Record "TNI Interfaces"; var CodeunitID: Integer)
    begin
        if TNIInterfaces."Data Exchange Type" <> TNIInterfaces."Data Exchange Type"::"Web Services" then
            exit;

        CodeunitID := Codeunit::"TNI Send WS";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsert_TNI_InternalEntry(Rec: Record "TNI Interfaces IN Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsert_TNI_Log(Rec: Record "TNI Interfaces Log")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsert_TNI_ExternalEntry(var Rec: Record "TNI Interfaces OUT Entry"; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModify_TNI_ExternalEntry_AfterLogInsert(Rec: Record "TNI Interfaces OUT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendFlowsGetCodeunitID(TNIInterfaces: Record "TNI Interfaces"; var CodeunitID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWriteFileName(var FileName: Text[100]; TNIFlows: Record "TNI Flows"; RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReadFlow(TNIInterfaces: Record "TNI Interfaces"; inTNIFlows: Record "TNI Flows"; var TransactionID: List of [Guid]; LogGroupID: Guid)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunProcessSetCodeunitID(var TNIInterfacesINEntry: Record "TNI Interfaces IN Entry"; TNIFlows: Record "TNI Flows"; var CodeunitID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessSingleRecord(var TNIInterfacesINEntry: Record "TNI Interfaces IN Entry"; TNIFlows: Record "TNI Flows"; LogGroupID: Guid)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendFlow(InterfaceCode: Code[20]; FlowCode: Code[20]; RecRef: RecordRef; TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry"; TNIInterfaces: Record "TNI Interfaces")
    begin
    end;

    var
        TNIWSInternalLibrary: Codeunit "TNI WS Internal Library";
        EntriesStatus: Enum "TNI Interfaces Entries Status";
        TNILogType: Enum "TNI Log Type";
        WriteLbl: Label 'File %1 created';
        ErrWriteLbl: Label 'File not created';
        SentLbl: Label 'File %1 stored in path %2';
        SentWSLbl: Label 'Call succedeed';
        SentErrorLbl: Label 'File not stored correctly';
        ProcessLbl: Label 'File %1 processed';
        ErrProcessLbl: Label 'File not processed';
}
