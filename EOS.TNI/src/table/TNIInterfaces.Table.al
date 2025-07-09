table 50063 "TNI Interfaces"
{
    DataClassification = CustomerContent;
    LookupPageId = "TNI Interfaces List";
    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';

            trigger OnValidate()
            begin
                if IsNullGuid(Rec."TNI GUID") then
                    Rec."TNI GUID" := CreateGuid();
            end;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(5; "Data Exchange Type"; Enum "TNI Data Exchange Type")
        {
            Caption = 'Data Exchange Type';
        }
        field(20; "TNI GUID"; Guid)
        {
            Caption = 'TNI GUID';
            Editable = false;
        }
        field(21; "TNI Interface Status"; Enum "TNI Interface Status")
        {
            Caption = 'Status';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    procedure ImportMapping()
    var
        TempBlob: Record TempBlob;
        FileManagement: Codeunit "File Management";
        ExportImportSetup: XMLport "TNI Import/Export TNI Setup";
        InStr: InStream;
    begin
        if FileManagement.BLOBImport(TempBlob, '') = '' then
            exit;

        TempBlob.Blob.CreateInStream(InStr);
        ExportImportSetup.SetSource(InStr);
        ExportImportSetup.Import();
    end;

    procedure ExportMapping()
    var
        TempBlob: Record TempBlob;
        TNIInterfaces: Record "TNI Interfaces";
        FileManagement: Codeunit "File Management";
        ExportImportSetup: XMLport "TNI Import/Export TNI Setup";
        OutStr: OutStream;
    begin
        TNIInterfaces.SetRange("Code", Rec."Code");

        TempBlob.Blob.CreateOutStream(OutStr);
        ExportImportSetup.SetTableView(TNIInterfaces);
        ExportImportSetup.SetDestination(OutStr);
        ExportImportSetup.Export();

        FileManagement.BLOBExport(TempBlob, Rec."Code" + '.xml', true);
    end;
}