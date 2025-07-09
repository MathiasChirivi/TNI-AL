codeunit 50064 "TNI Write File"
{
    TableNo = "TNI Interfaces OUT Entry";

    trigger OnRun()
    begin
        WriteFile(Rec);
    end;

    local procedure WriteFile(var TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry")
    var
        TNIFlows: Record "TNI Flows";
        TempBlob: Record TempBlob;
        FileOutStr: OutStream;
        FileInStr: InStream;
        FilePath: Text[250];
    begin
        TNIFlows.Get(InterfaceCode, FlowCode);
        TNIFlows.TestField(Enable);

        case TNIFlows."TNI Interface Type" of
            TNIFlows."TNI Interface Type"::"Fixed Text":
                begin
                    if FileName = '' then
                        Error(FileNameErr);

                    FileName += '.txt';
                    FilePath := TNIFlows."TNI File Path" + '\' + FileName;
                end;
            TNIFlows."TNI Interface Type"::Json:
                FileName := Format(TNIInterfacesOUTEntry."Entry No.") + '.json';
            TNIFlows."TNI Interface Type"::Xml:
                FileName := Format(TNIInterfacesOUTEntry."Entry No.") + '.xml';
        end;

        TempBlob.Blob.CreateOutStream(FileOutStr, TextEncoding::UTF8);
        OnBeforeCreateFile(FileOutStr, TNIFlows, RecRef);

        TNIInterfacesOUTEntry."TNI File Name" := CopyStr(FileName, 1, MaxStrLen(TNIInterfacesOUTEntry."TNI File Name"));
        TNIInterfacesOUTEntry."TNI File Path" := FilePath;

        TempBlob.Blob.CreateInStream(FileInStr);
        TNIInterfacesOUTEntry."TNI Sent File".CreateOutStream(FileOutStr);
        CopyStream(FileOutStr, FileInStr);
    end;

    procedure SetDatas(inInterfaceCode: Code[20]; inFlowCode: Code[20]; var inRecRecRef: RecordRef; inFileName: Text)
    begin
        RecRef.Open(inRecRecRef.Number);
        // RecRef.Copy(inRecRecRef);
        RecRef := inRecRecRef;
        InterfaceCode := inInterfaceCode;
        FlowCode := inFlowCode;
        FileName := inFileName;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFile(var FileOutStr: OutStream; TNIFlows: Record "TNI Flows"; var RecRef: RecordRef)
    begin
    end;

    var
        RecRef: RecordRef;
        InterfaceCode: Code[20];
        FlowCode: Code[20];
        FileName: Text;
        FileNameErr: Label 'File name cannot be empty';
}