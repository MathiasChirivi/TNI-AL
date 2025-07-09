codeunit 50090 "CM1 Credemtel Gen. Fnc."
{

    trigger OnRun()
    begin
        // ProcessEntry();
    end;

    procedure ReOpenPurchLineCREDEMTEL(var PurchLine: Record "Purchase Line")
    var
        ReOpenLineMsg: Label 'Are you sure you want to reopen the current line?';
    begin
        if not Confirm(ReOpenLineMsg) then
            exit;

        PurchLine.TestField("Line Closed");
        PurchLine."Line Closed" := false;

        PurchLine."CM1 Send to Credemetel" := false;
        PurchLine."CM1 Credemtel Ord Line Status" := PurchLine."CM1 Credemtel Ord Line Status"::" ";

        PurchLine.Modify();
        UpdateOtherPurchaseLinesCredemetel(PurchLine, PurchLine."CM1 Credemtel Ord Line Status"::" ");
    end;

    procedure ClosePurchLineCREDEMTEL(var PurchLine: Record "Purchase Line")
    var
        PurchHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        CAMASet: Record "CAMEOS CAMA Setup";
        TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        CM1CREDEMTELDriver: Codeunit "CM1 Credemtel Driver";
        TNIMgt: Codeunit "TNI Mgt.";
        NullRecRef: RecordRef;
        CloseLineMsg: Label 'Are you sure you want to close the current line?';
        ErrorMsgLbl: Label 'You cannot close the line because it is still linked to a warehouse receipt.';
        ErrorMsgQtyReceivedLbl: Label 'You cannot close the line because it has already been received.';
        OutStr: OutStream;
        XMLSavedSuccLbl: Label 'File XML saved successfully';
    begin
        CAMASet.Get();
        if GuiAllowed() then
            if not Confirm(CloseLineMsg) then
                exit;

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Interface");
        PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Close Order");

        PurchLine.TestField("Document Type", PurchLine."Document Type"::Order);
        PurchLine.Validate("Line Closed", true);
        PurchLine.TestField("CM1 Send to Credemetel", true);

        PurchLine."CM1 Credemtel Ord Line Status" := PurchLine."CM1 Credemtel Ord Line Status"::Closed;

        PurchLine.Modify();

        PurchHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        WarehouseReceiptLine.Reset();
        WarehouseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
        WarehouseReceiptLine.SetRange("Source No.", PurchLine."Document No.");
        WarehouseReceiptLine.SetRange("Source SubType", 1);
        WarehouseReceiptLine.SetRange("Line No.", PurchLine."Line No.");
        if not WarehouseReceiptLine.IsEmpty() then
            Error(ErrorMsgLbl);

        if PurchLine."Quantity Received" <> 0 then
            Error(ErrorMsgQtyReceivedLbl);

        PurchLine."CM1 Close Add Item Prop Tag" := '<ns3:AdditionalItemProperty><ns4:Name>FORCE_ROW_LCO_STATUS</ns4:Name><ns4:Value>CLOSED</ns4:Value></ns3:AdditionalItemProperty>';
        PurchLine.Modify();

        TNIMgt.CreateExternalEntry(TNIInterfacesOUTEntry, PurchasesPayablesSetup."CM1 Credemtel TNI Interface", PurchasesPayablesSetup."CM1 Credemtel TNI Close Order", NullRecRef);
        Commit();
        Clear(CM1CREDEMTELDriver);
        CM1CREDEMTELDriver.SetParametersClose_CancelPurchLine(8, OutStr, PurchHeader, PurchLine);
        if not CM1CREDEMTELDriver.Run() then
            TniMgt.WriteInterfacesOUTLog(TNIInterfacesOUTEntry, GetLastErrorCallStack(), '', '', GetLastErrorText(), '', 0, false)
        else
            TniMgt.WriteInterfacesOUTLog(TNIInterfacesOUTEntry, '', XMLSavedSuccLbl, '', '', '', 0, false);
    end;

    procedure CancelPurchLineCREDEMTEL(var PurchaseLine: Record "Purchase Line")
    var
        Location: Record Location;
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseHeader: Record "Purchase Header";
        TNIInterfacesOUTEntry: Record "TNI Interfaces OUT Entry";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        CM1CREDEMTELDriver: Codeunit "CM1 Credemtel Driver";
        TNIMgt: Codeunit "TNI Mgt.";
        NullRecRef: RecordRef;
        OutStr: OutStream;
        CancelLineMsg: Label 'Are you sure you want to cancel the current line?';
        CancelLineErr: Label 'Operation not allowed. %1 exists.';
        XMLSavedSuccLbl: Label 'File XML saved successfully';
    begin
        if GuiAllowed() then
            if not Confirm(CancelLineMsg) then
                exit;
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Interface");
        PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Cancel Order");

        PurchaseLine.TestField("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.TestField("CM1 Send to Credemetel", true);
        PurchaseLine.TestField("Quantity Received", 0);

        if Location.RequireReceive(PurchaseLine."Location Code") then begin
            WarehouseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
            WarehouseReceiptLine.SetRange("Source Subtype", 1);
            WarehouseReceiptLine.SetRange("Source No.", PurchaseLine."Document No.");
            WarehouseReceiptLine.SetRange("Source Line No.", PurchaseLine."Line No.");
            WarehouseReceiptLine.SetFilter("Qty. to Receive", '>%1', 0);
            if WarehouseReceiptLine.FindLast() then
                Error(CancelLineErr, WarehouseReceiptLine.TABLECAPTION);
        end;
        PurchaseLine."Line Closed" := false;
        PurchaseLine.SuspendStatusCheck(true);
        PurchaseLine.Validate(Quantity, 0);
        if not Location.get(PurchaseLine."Location Code") then
            PurchaseLine.Validate("Qty. to Receive", 0)
        else
            if not Location.RequireReceive(PurchaseLine."Location Code") then
                PurchaseLine.Validate("Qty. to Receive", 0);

        PurchaseLine."CM1 Credemtel Ord Line Status" := PurchaseLine."CM1 Credemtel Ord Line Status"::Closed;
        PurchaseLine.SuspendStatusCheck(false);

        PurchaseLine."CM1 Cancel Add Item Prop Tag" := '<ns3:AdditionalItemProperty><ns4:Name>ROW_CANCELED</ns4:Name><ns4:Value>ROW_CANCELED</ns4:Value></ns3:AdditionalItemProperty>';

        PurchaseLine.Modify();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        TNIMgt.CreateExternalEntry(TNIInterfacesOUTEntry, PurchasesPayablesSetup."CM1 Credemtel TNI Interface", PurchasesPayablesSetup."CM1 Credemtel TNI Cancel Order", NullRecRef);
        Commit();
        Clear(CM1CREDEMTELDriver);
        CM1CREDEMTELDriver.SetParametersClose_CancelPurchLine(9, OutStr, PurchaseHeader, PurchaseLine);
        if not CM1CREDEMTELDriver.Run() then
            TniMgt.WriteInterfacesOUTLog(TNIInterfacesOUTEntry, GetLastErrorCallStack(), '', '', GetLastErrorText(), '', 0, false)
        else
            TniMgt.WriteInterfacesOUTLog(TNIInterfacesOUTEntry, '', XMLSavedSuccLbl, '', '', '', 0, false);
    end;

    procedure UpdateOtherPurchaseLinesCredemetel(var PurchLine: Record "Purchase Line"; CREDEMTELStatus: Enum "CREDEMTEL Status")
    var
        PurchLine2: Record "Purchase Line";
    begin
        PurchLine2.SetRange("Document Type", PurchLine."Document Type");
        PurchLine2.SetRange("Document No.", PurchLine."Document No.");
        PurchLine2.SetFilter("Line No.", '<>%1', PurchLine."Line No.");
        if PurchLine2.FindSet() then
            repeat
                if PurchLine2."CM1 Send to Credemetel" then begin
                    if PurchLine2."Line Closed" then
                        PurchLine2."CM1 Credemtel Ord Line Status" := PurchLine2."CM1 Credemtel Ord Line Status"::Closed
                    else
                        PurchLine2."CM1 Credemtel Ord Line Status" := CREDEMTELStatus;
                    PurchLine2."CM1 Send to Credemetel" := false;
                    PurchLine2.Modify();
                end;
            until PurchLine2.Next() = 0;
    end;

    procedure DeletePurchLineCREDEMTEL(var PurchLine: Record "Purchase Line")
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        CancelLineMsg: Label 'Are you sure you want to cancel the current line?';
        CancelLineErr: Label 'Operation not allowed. %1 exists.';
    begin
        if not Confirm(CancelLineMsg) then
            exit;

        PurchLine.TestField("Document Type", PurchLine."Document Type"::Order);
        PurchLine.TestField("Quantity Received", 0);
        if Location.RequireReceive(PurchLine."Location Code") then begin
            WarehouseReceiptLine.SetRange("Source Type", DATABASE::"Purchase Line");
            WarehouseReceiptLine.SetRange("Source Subtype", 1);
            WarehouseReceiptLine.SetRange("Source No.", PurchLine."Document No.");
            WarehouseReceiptLine.SetRange("Source Line No.", PurchLine."Line No.");
            WarehouseReceiptLine.SetFilter("Qty. to Receive", '>%1', 0);
            if WarehouseReceiptLine.FindLast() then
                Error(CancelLineErr, WarehouseReceiptLine.TABLECAPTION);
        end;
        PurchLine.SuspendStatusCheck(true);
        PurchLine.Validate(Quantity, 0);
        if not Location.get(PurchLine."Location Code") then
            PurchLine.Validate("Qty. to Receive", 0)
        else
            if not Location.RequireReceive(PurchLine."Location Code") then
                PurchLine.Validate("Qty. to Receive", 0);
        PurchLine."Line Closed" := true;

        PurchLine."CM1 Send to Credemetel" := false;
        PurchLine."CM1 Credemtel Ord Line Status" := PurchLine."CM1 Credemtel Ord Line Status"::Closed;
        PurchLine.SuspendStatusCheck(false);

        Clear(PurchaseHeader);
        PurchaseHeader.Get(PurchLine."Document Type", PurchLine."Document No.");
        LogCredemtelOrderTransmissionFlexible(PurchLine, false, "CM1 Movement Type"::"Exit", "CM1 Document Type"::ORDACQDEL, "CM1 Trace Type"::"Order", "CM1 Status"::"InProgress");

        PurchLine.Modify();

        //We rememeber to export a xml file with the status "Closed" to Credemtel
    end;

    procedure GetContactEmail(Vendor: Record Vendor; var PurchMail: Text)
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        ContJobResp: Record "Contact Job Responsibility";
        PurchPayablesSetup: Record "Purchases & Payables Setup";
        OfficeMgt: Codeunit "Office Management";
        ContactFind: Boolean;
    begin
        PurchMail := '';
        if Vendor."No." = '' then
            exit;

        ContactFind := false;
        Contact.Reset();
        PurchPayablesSetup.Get();

        if OfficeMgt.GetContact(Contact, Vendor."No.") and (Contact.Count = 1) THEN
            ContactFind := true
        else begin
            ContBusRel.Reset();
            ContBusRel.SETCURRENTKEY("Link to Table", "No.");
            ContBusRel.SETRANGE("Link to Table", ContBusRel."Link to Table"::Vendor);
            ContBusRel.SETRANGE("No.", Vendor."No.");
            if ContBusRel.FindFirst() then begin
                Contact.SETRANGE("Company No.", ContBusRel."Contact No.");
                ContactFind := not Contact.IsEmpty();
            end;
        end;

        if ContactFind then begin
            Contact.SetRange(Type, Contact.Type::Person);
            if Contact.FindSet() then
                repeat
                    ContJobResp.Reset();
                    ContJobResp.SetRange("Contact No.", Contact."No.");
                    if ContJobResp.FindSet() then
                        repeat
                            if ContJobResp."Job Responsibility Code" = PurchPayablesSetup."CM1 ACQ Professional Role" then
                                if PurchMail = '' then
                                    PurchMail := Contact."E-Mail"
                                else
                                    PurchMail := PurchMail + ';' + Contact."E-Mail";
                        until ContJobResp.Next() = 0;
                until Contact.Next() = 0;
        end;
    end;

    // local procedure XmlEncode(var Value: Text): Text
    // begin
    //     Value := DelStrSubst(Value, '&', '&amp;');
    //     Value := DelStrSubst(Value, '<', '&lt;');
    //     Value := DelStrSubst(Value, '>', '&gt;');
    //     Value := DelStrSubst(Value, '"', '&quot;');
    //     Value := DelStrSubst(Value, '''', '&apos;');
    //     exit(Value);
    // end;

    // local procedure DelStrSubst(Value: Text; FindText: Text; ReplaceText: Text): Text
    // var
    //     Result: Text;
    //     StartPos: Integer;
    // begin
    //     Result := '';
    //     repeat
    //         StartPos := StrPos(Value, FindText);
    //         if StartPos > 0 then begin
    //             Result += CopyStr(Value, 1, StartPos - 1) + ReplaceText;
    //             Value := CopyStr(Value, StartPos + StrLen(FindText));
    //         end;
    //     until StartPos = 0;
    //     exit(Result + Value);
    // end;

    local procedure XmlEncodeSmart(InputText: Text): Text
    var
        Result: Text;
        i: Integer;
        InsideTag: Boolean;
        CurrentChar: Text;
    begin
        InsideTag := false;
        Result := '';

        for i := 1 to StrLen(InputText) do begin
            CurrentChar := CopyStr(InputText, i, 1);

            if CurrentChar = '<' then
                InsideTag := true;

            if InsideTag then begin
                // Dentro tag non cambio nulla
                Result += CurrentChar;

                if CurrentChar = '>' then
                    InsideTag := false;
            end else begin
                // Fuori dai tag, applico escape a tutti e 5
                case CurrentChar of
                    '&':
                        Result += '&amp;';
                    '"':
                        Result += '&quot;';
                    '''':
                        Result += '&apos;';
                    '<':
                        Result += '&lt;';
                    '>':
                        Result += '&gt;';
                    else
                        Result += CurrentChar;
                end;
            end;
        end;

        exit(Result);
    end;


    procedure CreateAndSendOrderXML(var OutStream: OutStream; PurchaseHeader: Record "Purchase Header"): TextBuilder
    var
        CountryRegion: Record "Country/Region";
        DocumentTrackingItem: Record Item;
        PurchaseLine: Record "Purchase Line";
        PaymentMethod: Record "Payment Method";
        DocumentExtendedText: Record "Document Extended Text";
        PurchExtendedTextLine: Record "Purch. Extended Text Line";
        VendorRec: Record Vendor;
        CompanyInfo: Record "Company Information";
        TxtBld: TextBuilder;
        XmlText: Text;
        CurrencyCode: Text;
        PurchEmail: Text;
        AdditionalVendorNo: Text;
    begin
        CompanyInfo.Get();
        CurrencyCode := PurchaseHeader."Currency Code";
        if CurrencyCode = '' then
            CurrencyCode := 'EUR';
        TxtBld.Clear();
        TxtBld.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
        TxtBld.Append('<ns5:Order xmlns:ns2="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" ' +
                      'xmlns:ns3="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" ' +
                      'xmlns:ns4="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" ' +
                      'xmlns:ns5="urn:oasis:names:specification:ubl:schema:xsd:Order-2" ' +
                      'xmlns:ns6="http://fsc.satanet.it">');

        // UBLExtensions
        TxtBld.Append('<ns2:UBLExtensions>');
        TxtBld.Append('<ns2:UBLExtension><ns2:ExtensionContent><ns6:FSCExtension>');
        TxtBld.Append('<FSCAdditionalHeaderProperty>');
        TxtBld.Append('<Name>' + PurchaseHeader.FieldName("CAMEOS Revision No.") + '</Name>');
        TxtBld.Append('<Value>' + PurchaseHeader."CAMEOS Revision No." + '</Value>');
        TxtBld.Append('</FSCAdditionalHeaderProperty>');
        TxtBld.Append('<FSCAdditionalHeaderProperty>');
        TxtBld.Append('<Name>SKIP_NOTIFICATION</Name>');
        TxtBld.Append('<Value>SKIP_NOTIFICATION</Value>');
        TxtBld.Append('</FSCAdditionalHeaderProperty>');
        TxtBld.Append('</ns6:FSCExtension></ns2:ExtensionContent></ns2:UBLExtension>');
        TxtBld.Append('</ns2:UBLExtensions>');

        // Header
        TxtBld.Append('<ns4:CustomizationID>urn:fdc:peppol.eu:poacc:trns:order:3</ns4:CustomizationID>');
        TxtBld.Append('<ns4:ProfileID>urn:fdc:peppol.eu:poacc:bis:order_only:3</ns4:ProfileID>');
        TxtBld.Append('<ns4:ID>' + PurchaseHeader."No." + '</ns4:ID>');
        TxtBld.Append('<ns4:IssueDate>' + Format(PurchaseHeader."Order Date", 0, '<Year4>-<Month,2>-<Day,2>') + '</ns4:IssueDate>');
        TxtBld.Append('<ns4:OrderTypeCode>' + PurchaseHeader."Reason Code" + '</ns4:OrderTypeCode>');
        DocumentExtendedText.SetRange("Source Type", Database::"Purchase Header");
        DocumentExtendedText.SetRange("Source ID", PurchaseHeader."No.");
        DocumentExtendedText.SetRange("Source Subtype", DocumentExtendedText."Source Subtype"::"1");
        DocumentExtendedText.SetRange(Position, DocumentExtendedText.Position::Heading);
        if DocumentExtendedText.FindSet() then
            repeat
                TxtBld.Append('<ns4:Note>' + DocumentExtendedText.Text + '</ns4:Note>');
            until DocumentExtendedText.Next() = 0;
        TxtBld.Append('<ns4:DocumentCurrencyCode>' + CurrencyCode + '</ns4:DocumentCurrencyCode>');
        if PurchaseHeader."CM1 Credemtel Order Date" <> 0D then begin
            TxtBld.Append('<ns3:OrderDocumentReference>');
            TxtBld.Append('<ns4:ID>' +
                     PurchaseHeader."No." + '#' +
                     Format(PurchaseHeader."CM1 Credemtel Order Date", 0, '<Year4>-<Month,2>-<Day,2>') +
                     '##' + GetOrderChangeType(PurchaseHeader) +
                     '</ns4:ID>');
            TxtBld.Append('</ns3:OrderDocumentReference>');
        end;
        // Buyer
        TxtBld.Append('<ns3:BuyerCustomerParty><ns3:Party>');
        TxtBld.Append('<ns4:EndpointID schemeID="0211">' + CompanyInfo."VAT Registration No." + '</ns4:EndpointID>');
        // For Italian buyers, add both CF and ID identifications
        if VendorRec.Get(PurchaseHeader."Buy-from Vendor No.") then
            if VendorRec."Country/Region Code" = 'IT' then begin
                TxtBld.Append('<ns3:PartyIdentification><ns4:ID>CF:' + PurchaseHeader."Fiscal Code" + '</ns4:ID></ns3:PartyIdentification>');
                TxtBld.Append('<ns3:PartyIdentification><ns4:ID>IDCODE:' + PurchaseHeader."Buy-from Vendor No." + '</ns4:ID></ns3:PartyIdentification>');
            end else
                TxtBld.Append('<ns3:PartyIdentification><ns4:ID>IDCODE:' + PurchaseHeader."Buy-from Vendor No." + '</ns4:ID></ns3:PartyIdentification>');
        TxtBld.Append('<ns3:PartyName><ns4:Name>' + CompanyInfo.Name + '</ns4:Name></ns3:PartyName>');
        TxtBld.Append('<ns3:PostalAddress>');
        TxtBld.Append('<ns4:StreetName>' + CompanyInfo.Address + '</ns4:StreetName>');
        TxtBld.Append('<ns4:CityName>' + CompanyInfo.City + '</ns4:CityName>');
        TxtBld.Append('<ns4:PostalZone>' + CompanyInfo."Post Code" + '</ns4:PostalZone>');
        TxtBld.Append('<ns3:Country><ns4:IdentificationCode>' + CompanyInfo."Country/Region Code" + '</ns4:IdentificationCode></ns3:Country>');
        TxtBld.Append('</ns3:PostalAddress>');
        TxtBld.Append('<ns3:Contact><ns4:Name>' + PurchaseHeader."Assigned User ID" + '</ns4:Name></ns3:Contact>');
        TxtBld.Append('</ns3:Party></ns3:BuyerCustomerParty>');

        // Seller
        if VendorRec.Get(PurchaseHeader."Buy-from Vendor No.") then begin
            TxtBld.Append('<ns3:SellerSupplierParty><ns3:Party>');
            TxtBld.Append('<ns4:EndpointID schemeID="0211">' + VendorRec."Country/Region Code" + VendorRec."VAT Registration No." + '</ns4:EndpointID>');
            TxtBld.Append('<ns3:PartyIdentification><ns4:ID>CF:' + VendorRec."Fiscal Code" + '</ns4:ID></ns3:PartyIdentification>');
            TxtBld.Append('<ns3:PartyIdentification><ns4:ID>IDCODE:' + PurchaseHeader."Buy-from Vendor No." + '</ns4:ID></ns3:PartyIdentification>');
            TxtBld.Append('<ns3:PartyName><ns4:Name>' + PurchaseHeader."Buy-from Vendor Name" + '</ns4:Name></ns3:PartyName>');
            TxtBld.Append('<ns3:PostalAddress>');
            TxtBld.Append('<ns4:StreetName>' + PurchaseHeader."Buy-from Address" + '</ns4:StreetName>');
            TxtBld.Append('<ns4:CityName>' + PurchaseHeader."Buy-from City" + '</ns4:CityName>');
            TxtBld.Append('<ns4:PostalZone>' + PurchaseHeader."Buy-from Post Code" + '</ns4:PostalZone>');
            TxtBld.Append('<ns3:Country><ns4:IdentificationCode>' + PurchaseHeader."Buy-from Country/Region Code" + '</ns4:IdentificationCode></ns3:Country>');
            TxtBld.Append('</ns3:PostalAddress>');
            TxtBld.Append('<ns3:Contact>');
            Clear(PurchEmail);
            GetContactEmail(vendorRec, PurchEmail);
            TxtBld.Append('<ns4:ElectronicMail>' + PurchEmail + '</ns4:ElectronicMail>');
            TxtBld.Append('</ns3:Contact>');
            TxtBld.Append('</ns3:Party></ns3:SellerSupplierParty>');
        end;

        PaymentMethod.Get(PurchaseHeader."Payment Method Code");
        // Terms
        if PurchaseHeader."Shipment Method Code" <> '' then
            TxtBld.Append('<ns3:DeliveryTerms><ns4:ID>' + PurchaseHeader."Payment Method Code" + '</ns4:ID></ns3:DeliveryTerms>');
        if PurchaseHeader."Payment Terms Code" <> '' then
            TxtBld.Append('<ns3:PaymentTerms><ns4:Note>' + PaymentMethod.Description + '</ns4:Note></ns3:PaymentTerms>');

        // Order Lines
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                TxtBld.Append('<ns3:OrderLine>');
                Clear(PurchExtendedTextLine);
                PurchExtendedTextLine.Reset();
                PurchExtendedTextLine.SetRange("Document Type", PurchaseLine."Document Type");
                PurchExtendedTextLine.SetRange("Document No.", PurchaseLine."Document No.");
                PurchExtendedTextLine.SetRange("Text Position", PurchExtendedTextLine."Text Position"::Line);
                PurchExtendedTextLine.SetRange("Document Line No.", 10000);
                if PurchExtendedTextLine.FindSet() then
                    repeat
                        TxtBld.Append('<ns4:Note>' + PurchExtendedTextLine.Text + '</ns4:Note>');
                    until PurchExtendedTextLine.Next() = 0;
                TxtBld.Append('<ns4:Note>' + PurchaseLine."Description 2" + '</ns4:Note>');
                TxtBld.Append('<ns3:LineItem>');
                TxtBld.Append('<ns4:ID>' + Format(PurchaseLine."Line No.") + '</ns4:ID>');
                TxtBld.Append('<ns4:Quantity unitCode="' + PurchaseLine."Unit of Measure Code" + '">' + Format(PurchaseLine.Quantity, 0, '<Precision,2><Standard Format,2>') + '</ns4:Quantity>');
                TxtBld.Append('<ns4:LineExtensionAmount currencyID="' + CurrencyCode + '">' + Format(PurchaseLine.Amount, 0, '<Precision,2><Standard Format,2>') + '</ns4:LineExtensionAmount>');

                // Delivery
                TxtBld.Append('<ns3:Delivery>');
                TxtBld.Append('<ns4:ID>' + PurchaseHeader."Buy-from Vendor No." + '</ns4:ID>');
                if PurchaseHeader."Ship-to Address" <> '' then begin
                    TxtBld.Append('<ns3:DeliveryLocation><ns3:Address>');
                    TxtBld.Append('<ns4:StreetName>' + PurchaseHeader."Ship-to Address" + '</ns4:StreetName>');
                    TxtBld.Append('<ns4:CityName>' + PurchaseHeader."Ship-to City" + '</ns4:CityName>');
                    TxtBld.Append('<ns4:PostalZone>' + PurchaseHeader."Ship-to Post Code" + '</ns4:PostalZone>');
                    TxtBld.Append('<ns3:Country><ns4:IdentificationCode>' + PurchaseHeader."Ship-to Country/Region Code" + '</ns4:IdentificationCode>');
                    if CountryRegion.Get(PurchaseHeader."Ship-to Country/Region Code") then
                        TxtBld.Append('<ns4:Name>' + CountryRegion.Name + '</ns4:Name>');
                    TxtBld.Append('</ns3:Country>');
                    TxtBld.Append('</ns3:Address>');
                    TxtBld.Append('</ns3:DeliveryLocation >');
                end;
                if PurchaseLine."Promised Receipt Date" <> 0D then
                    TxtBld.Append('<ns3:RequestedDeliveryPeriod><ns4:StartDate>' + Format(PurchaseLine."Promised Receipt Date", 0, '<Year4>-<Month,2>-<Day,2>') + '</ns4:StartDate></ns3:RequestedDeliveryPeriod>')
                else
                    TxtBld.Append('<ns3:RequestedDeliveryPeriod><ns4:StartDate>' + Format(PurchaseLine."Requested Receipt Date", 0, '<Year4>-<Month,2>-<Day,2>') + '</ns4:StartDate></ns3:RequestedDeliveryPeriod>');
                // if PurchaseHeader."Subcontracting Order" then begin
                PurchaseHeader.CalcFields("Subcontracting Order");
                if PurchaseHeader."Subcontracting Order" then begin
                    TxtBld.Append('<ns3:DeliveryParty>');
                    TxtBld.Append('<ns4:EndpointID schemeID="0211">' + PurchaseHeader."VAT Country/Region Code" + PurchaseHeader."VAT Registration No." + '</ns4:EndpointID>');

                    // For Italian vendor - add both CF and ID identifications
                    if VendorRec.Get(PurchaseHeader."Buy-from Vendor No.") then
                        if VendorRec."Country/Region Code" = 'IT' then begin
                            TxtBld.Append('<ns3:PartyIdentification><ns4:ID>CF:' + PurchaseHeader."Fiscal Code" + '</ns4:ID></ns3:PartyIdentification>');
                            TxtBld.Append('<ns3:PartyIdentification><ns4:ID>IDCODE:' + PurchaseHeader."Buy-from Vendor No." + '</ns4:ID></ns3:PartyIdentification>');
                        end else begin
                            TxtBld.Append('<ns3:PartyIdentification><ns4:ID>CF:' + VendorRec."Fiscal Code" + '</ns4:ID></ns3:PartyIdentification>');
                            TxtBld.Append('<ns3:PartyIdentification><ns4:ID>IDCODE:' + PurchaseHeader."Buy-from Vendor No." + '</ns4:ID></ns3:PartyIdentification>');
                        end;
                    TxtBld.Append('<ns3:PartyName><ns4:Name>' + PurchaseHeader."Buy-from Vendor Name" + '</ns4:Name></ns3:PartyName>');
                    TxtBld.Append('<ns3:PostalAddress>');
                    TxtBld.Append('<ns4:StreetName>' + PurchaseHeader."Buy-from Address" + '</ns4:StreetName>');
                    TxtBld.Append('<ns4:CityName>' + PurchaseHeader."Buy-from City" + '</ns4:CityName>');
                    TxtBld.Append('<ns4:PostalZone>' + PurchaseHeader."Buy-from Post Code" + '</ns4:PostalZone>');
                    TxtBld.Append('<ns3:Country><ns4:IdentificationCode>' + PurchaseHeader."Buy-from Country/Region Code" + '</ns4:IdentificationCode></ns3:Country>');
                    TxtBld.Append('</ns3:PostalAddress>');

                    // Add contact email if available
                    Clear(PurchEmail);
                    GetContactEmail(VendorRec, PurchEmail);
                    TxtBld.Append('<ns3:Contact><ns4:ElectronicMail>' + PurchEmail + '</ns4:ElectronicMail></ns3:Contact>');

                    TxtBld.Append('</ns3:DeliveryParty>');
                end;
                // end;
                TxtBld.Append('</ns3:Delivery>');
                TxtBld.Append('<ns3:Price><ns4:PriceAmount currencyID="' + CurrencyCode + '">' + Format(PurchaseLine."Direct Unit Cost", 0, '<Precision,2><Standard Format,2>') + '</ns4:PriceAmount></ns3:Price>');

                // Item corrected
                TxtBld.Append('<ns3:Item>');
                TxtBld.Append('<ns4:Name>' + PurchaseLine.Description + '</ns4:Name>');
                TxtBld.Append('<ns3:BuyersItemIdentification><ns4:ID>' + PurchaseLine."No." + '</ns4:ID></ns3:BuyersItemIdentification>');
                if PurchaseLine."Cross-Reference No." <> '' then
                    TxtBld.Append('<ns3:SellersItemIdentification><ns4:ID>' + PurchaseLine."Cross-Reference No." + '</ns4:ID></ns3:SellersItemIdentification>');
                if DocumentTrackingItem.Get(PurchaseLine."No.") then begin
                    TxtBld.Append('<ns3:AdditionalItemProperty><ns4:Name>' + DocumentTrackingItem.FieldCaption(Description) + '</ns4:Name>');
                    TxtBld.Append('<ns4:Value>' + DocumentTrackingItem.Description + DocumentTrackingItem."Description 2" + '</ns4:Value></ns3:AdditionalItemProperty>');
                end;
                TxtBld.Append('<ns3:AdditionalItemProperty><ns4:Name>' + PurchaseLine.FieldCaption("CAMEOS Origin Group") + '</ns4:Name>');
                TxtBld.Append('<ns4:Value>' + PurchaseLine."CAMEOS Origin Group" + '</ns4:Value></ns3:AdditionalItemProperty>');
                PurchaseLine.CalcFields("CAMEOS Standard Task Code");
                TxtBld.Append('<ns3:AdditionalItemProperty><ns4:Name>' + PurchaseLine.FieldCaption("CAMEOS Standard Task Code") + '</ns4:Name>');
                TxtBld.Append('<ns4:Value>' + PurchaseLine."CAMEOS Standard Task Code" + '</ns4:Value></ns3:AdditionalItemProperty>');
                TxtBld.Append('<ns3:AdditionalItemProperty><ns4:Name>' + PurchaseLine.FieldCaption("Buy-from Vendor No.") + '</ns4:Name>');
                TxtBld.Append('<ns4:Value>' + PurchaseHeader."Buy-from Vendor No." + '</ns4:Value></ns3:AdditionalItemProperty>');
                TxtBld.Append('<ns3:AdditionalItemProperty><ns4:Name>' + PurchaseLine.FieldCaption("CM1 Country/Region Origin Code") + '</ns4:Name>');
                TxtBld.Append('<ns4:Value>' + PurchaseLine."CM1 Country/Region Origin Code" + '</ns4:Value></ns3:AdditionalItemProperty>');
                TxtBld.Append('<ns3:AdditionalItemProperty><ns4:Name>' + 'Tracciabilita Documento' + '</ns4:Name>');
                TxtBld.Append('<ns4:Value>' + PurchaseLine."CAMEOS Document Tracking" + '</ns4:Value></ns3:AdditionalItemProperty>');
                //Line Closed
                if PurchaseLine."CM1 Close Add Item Prop Tag" <> '' then
                    TxtBld.Append(PurchaseLine."CM1 Close Add Item Prop Tag");

                if PurchaseLine."CM1 Cancel Add Item Prop Tag" <> '' then
                    TxtBld.Append(PurchaseLine."CM1 Cancel Add Item Prop Tag");

                if PurchaseHeader."Ship-to Code" <> '' then begin
                    if VendorRec.Get(PurchaseHeader."Buy-from Vendor No.") then
                        if VendorRec."Location Code" = PurchaseHeader."Ship-to Code" then
                            AdditionalVendorNo := VendorRec."No.";
                    if AdditionalVendorNo <> '' then begin
                        PurchaseLine."CM1 Additional Vendor No." := copystr(AdditionalVendorNo, 1, MaxStrLen(PurchaseLine."CM1 Additional Vendor No."));
                        PurchaseLine.Modify();

                        TxtBld.Append('<AuxRow3>' + AdditionalVendorNo + '</AuxRow3>');
                    end;
                end;
                TxtBld.Append('</ns3:Item>');
                TxtBld.Append('</ns3:LineItem>');
                TxtBld.Append('</ns3:OrderLine>');
            until PurchaseLine.Next() = 0;

        TxtBld.Append('</ns5:Order>');

        XmlText := TxtBld.ToText();
        XmlText := XmlEncodeSmart(XmlText);
        OutStream.WriteText(XmlText);
    end;

    procedure WriteOrderChangeXML(var OutStream: OutStream; PurchaseHeader: Record "Purchase Header"): TextBuilder
    var
        CountryRegion: Record "Country/Region";
        DocumentTrackingItem: Record Item;
        PurchaseLine: Record "Purchase Line";
        PaymentMethod: Record "Payment Method";
        DocumentExtendedText: Record "Document Extended Text";
        PurchExtendedTextLine: Record "Purch. Extended Text Line";
        VendorRec: Record Vendor;
        CompanyInfo: Record "Company Information";
        TxtBld: TextBuilder;
        XmlText: Text;
        CurrencyCode: Text;
        PurchEmail: Text;
    begin
        CompanyInfo.Get();
        CurrencyCode := PurchaseHeader."Currency Code";
        if CurrencyCode = '' then
            CurrencyCode := 'EUR';
        TxtBld.Clear();
        TxtBld.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
        TxtBld.Append('<ns5:Order xmlns:ns2="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" ' +
                      'xmlns:ns3="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" ' +
                      'xmlns:ns4="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" ' +
                      'xmlns:ns5="urn:oasis:names:specification:ubl:schema:xsd:Order-2" ' +
                      'xmlns:ns6="http://fsc.satanet.it">');

        // UBLExtensions
        TxtBld.Append('<ns2:UBLExtensions>');
        TxtBld.Append('<ns2:UBLExtension><ns2:ExtensionContent><ns6:FSCExtension>');
        TxtBld.Append('<FSCAdditionalHeaderProperty>');
        TxtBld.Append('<Name>' + PurchaseHeader.FieldName("CAMEOS Revision No.") + '</Name>');
        TxtBld.Append('<Value>' + PurchaseHeader."CAMEOS Revision No." + '</Value>');
        TxtBld.Append('</FSCAdditionalHeaderProperty>');
        TxtBld.Append('<FSCAdditionalHeaderProperty>');
        TxtBld.Append('<Name>SKIP_NOTIFICATION</Name>');
        TxtBld.Append('<Value>SKIP_NOTIFICATION</Value>');
        TxtBld.Append('</FSCAdditionalHeaderProperty>');
        TxtBld.Append('</ns6:FSCExtension></ns2:ExtensionContent></ns2:UBLExtension>');
        TxtBld.Append('</ns2:UBLExtensions>');

        // Header
        TxtBld.Append('<ns4:CustomizationID>urn:fdc:peppol.eu:poacc:trns:order:3</ns4:CustomizationID>');
        TxtBld.Append('<ns4:ProfileID>urn:fdc:peppol.eu:poacc:bis:order_only:3</ns4:ProfileID>');
        TxtBld.Append('<ns4:ID>' + PurchaseHeader."No." + '</ns4:ID>');
        TxtBld.Append('<ns4:IssueDate>' + Format(PurchaseHeader."Order Date", 0, '<Year4>-<Month,2>-<Day,2>') + '</ns4:IssueDate>');
        TxtBld.Append('<ns4:OrderTypeCode>' + PurchaseHeader."Reason Code" + '</ns4:OrderTypeCode>');
        DocumentExtendedText.SetRange("Source Type", Database::"Purchase Header");
        DocumentExtendedText.SetRange("Source ID", PurchaseHeader."No.");
        DocumentExtendedText.SetRange("Source Subtype", DocumentExtendedText."Source Subtype"::"1");
        DocumentExtendedText.SetRange(Position, DocumentExtendedText.Position::Heading);
        if DocumentExtendedText.FindSet() then
            repeat
                TxtBld.Append('<ns4:Note>' + DocumentExtendedText.Text + '</ns4:Note>');
            until DocumentExtendedText.Next() = 0;
        TxtBld.Append('<ns4:DocumentCurrencyCode>' + CurrencyCode + '</ns4:DocumentCurrencyCode>');
        // ** OrderDocumentReference per Change **
        if PurchaseHeader."CM1 Credemtel Order Date" <> 0D then begin
            TxtBld.Append('<ns3:OrderDocumentReference>');
            TxtBld.Append('<ns4:ID>' +
                     PurchaseHeader."No." + '#' +
                     Format(PurchaseHeader."CM1 Credemtel Order Date", 0, '<Year4>-<Month,2>-<Day,2>') +
                     '##' + GetOrderChangeType(PurchaseHeader) +
                     '</ns4:ID>');
            TxtBld.Append('</ns3:OrderDocumentReference>');
        end;

        // Buyer
        TxtBld.Append('<ns3:BuyerCustomerParty><ns3:Party>');
        TxtBld.Append('<ns4:EndpointID schemeID="0211">' + CompanyInfo."VAT Registration No." + '</ns4:EndpointID>');
        // For Italian buyers, add both CF and ID identifications
        if VendorRec.Get(PurchaseHeader."Buy-from Vendor No.") then
            if VendorRec."Country/Region Code" = 'IT' then begin
                TxtBld.Append('<ns3:PartyIdentification><ns4:ID>CF:' + PurchaseHeader."Fiscal Code" + '</ns4:ID></ns3:PartyIdentification>');
                TxtBld.Append('<ns3:PartyIdentification><ns4:ID>IDCODE:' + PurchaseHeader."Buy-from Vendor No." + '</ns4:ID></ns3:PartyIdentification>');
            end else
                TxtBld.Append('<ns3:PartyIdentification><ns4:ID>IDCODE:' + PurchaseHeader."Buy-from Vendor No." + '</ns4:ID></ns3:PartyIdentification>');
        TxtBld.Append('<ns3:PartyName><ns4:Name>' + CompanyInfo.Name + '</ns4:Name></ns3:PartyName>');
        TxtBld.Append('<ns3:PostalAddress>');
        TxtBld.Append('<ns4:StreetName>' + CompanyInfo.Address + '</ns4:StreetName>');
        TxtBld.Append('<ns4:CityName>' + CompanyInfo.City + '</ns4:CityName>');
        TxtBld.Append('<ns4:PostalZone>' + CompanyInfo."Post Code" + '</ns4:PostalZone>');
        TxtBld.Append('<ns3:Country><ns4:IdentificationCode>' + CompanyInfo."Country/Region Code" + '</ns4:IdentificationCode></ns3:Country>');
        TxtBld.Append('</ns3:PostalAddress>');
        TxtBld.Append('<ns3:Contact><ns4:Name>' + PurchaseHeader."Assigned User ID" + '</ns4:Name></ns3:Contact>');
        TxtBld.Append('</ns3:Party></ns3:BuyerCustomerParty>');

        // Seller
        if VendorRec.Get(PurchaseHeader."Buy-from Vendor No.") then begin
            TxtBld.Append('<ns3:SellerSupplierParty><ns3:Party>');
            TxtBld.Append('<ns4:EndpointID schemeID="0211">' + VendorRec."Country/Region Code" + VendorRec."VAT Registration No." + '</ns4:EndpointID>');
            TxtBld.Append('<ns3:PartyIdentification><ns4:ID>CF:' + VendorRec."Fiscal Code" + '</ns4:ID></ns3:PartyIdentification>');
            TxtBld.Append('<ns3:PartyIdentification><ns4:ID>IDCODE:' + PurchaseHeader."Buy-from Vendor No." + '</ns4:ID></ns3:PartyIdentification>');
            TxtBld.Append('<ns3:PartyName><ns4:Name>' + PurchaseHeader."Buy-from Vendor Name" + '</ns4:Name></ns3:PartyName>');
            TxtBld.Append('<ns3:PostalAddress>');
            TxtBld.Append('<ns4:StreetName>' + PurchaseHeader."Buy-from Address" + '</ns4:StreetName>');
            TxtBld.Append('<ns4:CityName>' + PurchaseHeader."Buy-from City" + '</ns4:CityName>');
            TxtBld.Append('<ns4:PostalZone>' + PurchaseHeader."Buy-from Post Code" + '</ns4:PostalZone>');
            TxtBld.Append('<ns3:Country><ns4:IdentificationCode>' + PurchaseHeader."Buy-from Country/Region Code" + '</ns4:IdentificationCode></ns3:Country>');
            TxtBld.Append('</ns3:PostalAddress>');
            TxtBld.Append('<ns3:Contact>');
            Clear(PurchEmail);
            GetContactEmail(vendorRec, PurchEmail);
            TxtBld.Append('<ns4:ElectronicMail>' + PurchEmail + '</ns4:ElectronicMail>');
            TxtBld.Append('</ns3:Contact>');
            TxtBld.Append('</ns3:Party></ns3:SellerSupplierParty>');
        end;

        PaymentMethod.Get(PurchaseHeader."Payment Method Code");
        // Terms
        if PurchaseHeader."Shipment Method Code" <> '' then
            TxtBld.Append('<ns3:DeliveryTerms><ns4:ID>' + PurchaseHeader."Payment Method Code" + '</ns4:ID></ns3:DeliveryTerms>');
        if PurchaseHeader."Payment Terms Code" <> '' then
            TxtBld.Append('<ns3:PaymentTerms><ns4:Note>' + PaymentMethod."Description" + '</ns4:Note></ns3:PaymentTerms>');


        // Order Lines
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                TxtBld.Append('<ns3:OrderLine>');
                Clear(PurchExtendedTextLine);
                PurchExtendedTextLine.Reset();
                PurchExtendedTextLine.SetRange("Document Type", PurchaseLine."Document Type");
                PurchExtendedTextLine.SetRange("Document No.", PurchaseLine."Document No.");
                PurchExtendedTextLine.SetRange("Text Position", PurchExtendedTextLine."Text Position"::Line);
                PurchExtendedTextLine.SetRange("Document Line No.", 10000);
                if PurchExtendedTextLine.FindSet() then
                    repeat
                        TxtBld.Append('<ns4:Note>' + PurchExtendedTextLine.Text + '</ns4:Note>');
                    until PurchExtendedTextLine.Next() = 0;
                TxtBld.Append('<ns4:Note>' + PurchaseLine."Description 2" + '</ns4:Note>');
                TxtBld.Append('<ns3:LineItem>');
                TxtBld.Append('<ns4:ID>' + Format(PurchaseLine."Line No.") + '</ns4:ID>');
                TxtBld.Append('<ns4:Quantity unitCode="' + PurchaseLine."Unit of Measure Code" + '">' + Format(PurchaseLine.Quantity, 0, '<Precision,2><Standard Format,2>') + '</ns4:Quantity>');
                TxtBld.Append('<ns4:LineExtensionAmount currencyID="' + CurrencyCode + '">' + Format(PurchaseLine.Amount, 0, '<Precision,2><Standard Format,2>') + '</ns4:LineExtensionAmount>');

                // Delivery
                TxtBld.Append('<ns3:Delivery>');
                TxtBld.Append('<ns4:ID>' + PurchaseHeader."Buy-from Vendor No." + '</ns4:ID>');
                if PurchaseHeader."Ship-to Address" <> '' then begin
                    TxtBld.Append('<ns3:DeliveryLocation><ns3:Address>');
                    TxtBld.Append('<ns4:StreetName>' + PurchaseHeader."Ship-to Address" + '</ns4:StreetName>');
                    TxtBld.Append('<ns4:CityName>' + PurchaseHeader."Ship-to City" + '</ns4:CityName>');
                    TxtBld.Append('<ns4:PostalZone>' + PurchaseHeader."Ship-to Post Code" + '</ns4:PostalZone>');
                    TxtBld.Append('<ns3:Country><ns4:IdentificationCode>' + PurchaseHeader."Ship-to Country/Region Code" + '</ns4:IdentificationCode>');
                    if CountryRegion.Get(PurchaseHeader."Ship-to Country/Region Code") then
                        TxtBld.Append('<ns4:Name>' + CountryRegion.Name + '</ns4:Name>');
                    TxtBld.Append('</ns3:Country>');
                    TxtBld.Append('</ns3:Address>');
                    TxtBld.Append('</ns3:DeliveryLocation >');
                end;
                if PurchaseLine."Promised Receipt Date" <> 0D then
                    TxtBld.Append('<ns3:RequestedDeliveryPeriod><ns4:StartDate>' + Format(PurchaseLine."Promised Receipt Date", 0, '<Year4>-<Month,2>-<Day,2>') + '</ns4:StartDate></ns3:RequestedDeliveryPeriod>')
                else
                    TxtBld.Append('<ns3:RequestedDeliveryPeriod><ns4:StartDate>' + Format(PurchaseLine."Requested Receipt Date", 0, '<Year4>-<Month,2>-<Day,2>') + '</ns4:StartDate></ns3:RequestedDeliveryPeriod>');
                PurchaseHeader.CalcFields("Subcontracting Order");
                if PurchaseHeader."Subcontracting Order" then begin
                    TxtBld.Append('<ns3:DeliveryParty>');
                    TxtBld.Append('<ns4:EndpointID schemeID="0211">' + PurchaseHeader."VAT Country/Region Code" + PurchaseHeader."VAT Registration No." + '</ns4:EndpointID>');

                    // For Italian vendor - add both CF and ID identifications
                    if VendorRec.Get(PurchaseHeader."Buy-from Vendor No.") then begin
                        if VendorRec."Country/Region Code" = 'IT' then begin
                            TxtBld.Append('<ns3:PartyIdentification><ns4:ID>CF:' + PurchaseHeader."Fiscal Code" + '</ns4:ID></ns3:PartyIdentification>');
                            TxtBld.Append('<ns3:PartyIdentification><ns4:ID>IDCODE:' + PurchaseHeader."Buy-from Vendor No." + '</ns4:ID></ns3:PartyIdentification>');
                        end else begin
                            TxtBld.Append('<ns3:PartyIdentification><ns4:ID>CF:' + VendorRec."Fiscal Code" + '</ns4:ID></ns3:PartyIdentification>');
                            TxtBld.Append('<ns3:PartyIdentification><ns4:ID>IDCODE:' + PurchaseHeader."Buy-from Vendor No." + '</ns4:ID></ns3:PartyIdentification>');
                        end;
                    end;
                    TxtBld.Append('<ns3:PartyName><ns4:Name>' + PurchaseHeader."Buy-from Vendor Name" + '</ns4:Name></ns3:PartyName>');
                    TxtBld.Append('<ns3:PostalAddress>');
                    TxtBld.Append('<ns4:StreetName>' + PurchaseHeader."Buy-from Address" + '</ns4:StreetName>');
                    TxtBld.Append('<ns4:CityName>' + PurchaseHeader."Buy-from City" + '</ns4:CityName>');
                    TxtBld.Append('<ns4:PostalZone>' + PurchaseHeader."Buy-from Post Code" + '</ns4:PostalZone>');
                    TxtBld.Append('<ns3:Country><ns4:IdentificationCode>' + PurchaseHeader."Buy-from Country/Region Code" + '</ns4:IdentificationCode></ns3:Country>');
                    TxtBld.Append('</ns3:PostalAddress>');

                    // Add contact email if available
                    Clear(PurchEmail);
                    GetContactEmail(VendorRec, PurchEmail);
                    TxtBld.Append('<ns3:Contact><ns4:ElectronicMail>' + PurchEmail + '</ns4:ElectronicMail></ns3:Contact>');

                    TxtBld.Append('</ns3:DeliveryParty>');
                end;
                TxtBld.Append('</ns3:Delivery>');
                TxtBld.Append('<ns3:Price><ns4:PriceAmount currencyID="' + CurrencyCode + '">' + Format(PurchaseLine."Direct Unit Cost", 0, '<Precision,2><Standard Format,2>') + '</ns4:PriceAmount></ns3:Price>');

                //Line Closed
                if PurchaseLine."CM1 Close Add Item Prop Tag" <> '' then
                    TxtBld.Append(PurchaseLine."CM1 Close Add Item Prop Tag");

                if PurchaseLine."CM1 Cancel Add Item Prop Tag" <> '' then
                    TxtBld.Append(PurchaseLine."CM1 Cancel Add Item Prop Tag");

                // Item corrected
                TxtBld.Append('<ns3:Item>');
                TxtBld.Append('<ns4:Name>' + PurchaseLine.Description + '</ns4:Name>');
                TxtBld.Append('<ns3:BuyersItemIdentification><ns4:ID>' + PurchaseLine."No." + '</ns4:ID></ns3:BuyersItemIdentification>');
                if PurchaseLine."Cross-Reference No." <> '' then
                    TxtBld.Append('<ns3:SellersItemIdentification><ns4:ID>' + PurchaseLine."Cross-Reference No." + '</ns4:ID></ns3:SellersItemIdentification>');
                if DocumentTrackingItem.Get(PurchaseLine."No.") then begin
                    TxtBld.Append('<ns3:AdditionalItemProperty><ns4:Name>' + DocumentTrackingItem.FieldCaption(Description) + '</ns4:Name>');
                    TxtBld.Append('<ns4:Value>' + DocumentTrackingItem.Description + DocumentTrackingItem."Description 2" + '</ns4:Value></ns3:AdditionalItemProperty>');
                end;
                TxtBld.Append('<ns3:AdditionalItemProperty><ns4:Name>' + PurchaseLine.FieldCaption("CAMEOS Origin Group") + '</ns4:Name>');
                TxtBld.Append('<ns4:Value>' + PurchaseLine."CAMEOS Origin Group" + '</ns4:Value></ns3:AdditionalItemProperty>');
                PurchaseLine.CalcFields("CAMEOS Standard Task Code");
                TxtBld.Append('<ns3:AdditionalItemProperty><ns4:Name>' + PurchaseLine.FieldCaption("CAMEOS Standard Task Code") + '</ns4:Name>');
                TxtBld.Append('<ns4:Value>' + PurchaseLine."CAMEOS Standard Task Code" + '</ns4:Value></ns3:AdditionalItemProperty>');
                TxtBld.Append('<ns3:AdditionalItemProperty><ns4:Name>' + PurchaseLine.FieldCaption("Buy-from Vendor No.") + '</ns4:Name>');
                TxtBld.Append('<ns4:Value>' + PurchaseHeader."Buy-from Vendor No." + '</ns4:Value></ns3:AdditionalItemProperty>');
                TxtBld.Append('<ns3:AdditionalItemProperty><ns4:Name>' + PurchaseLine.FieldCaption("CM1 Country/Region Origin Code") + '</ns4:Name>');
                TxtBld.Append('<ns4:Value>' + PurchaseLine."CM1 Country/Region Origin Code" + '</ns4:Value></ns3:AdditionalItemProperty>');
                TxtBld.Append('<ns3:AdditionalItemProperty><ns4:Name>' + 'Tracciabilita Documento' + '</ns4:Name>');
                TxtBld.Append('<ns4:Value>' + PurchaseLine."CAMEOS Document Tracking" + '</ns4:Value></ns3:AdditionalItemProperty>');
                TxtBld.Append('</ns3:Item>');
                TxtBld.Append('</ns3:LineItem>');
                TxtBld.Append('</ns3:OrderLine>');
            until PurchaseLine.Next() = 0;

        TxtBld.Append('</ns5:Order>');

        XmlText := TxtBld.ToText();
        XmlText := XmlEncodeSmart(XmlText);
        OutStream.WriteText(XmlText);
    end;

    procedure GetOrderChangeType(PurchaseHeader: Record "Purchase Header"): Text
    var
        PurchaseLine: Record "Purchase Line";
        ChangeTypes: List of [Text];
        ChangeType: Text;
    begin
        ChangeType := 'Revised';

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        if PurchaseLine.FindSet() then
            repeat
                case PurchaseLine."CM1 Credemtel Change Type" of
                    PurchaseLine."CM1 Credemtel Change Type"::Revised:
                        ChangeType := 'Revised';
                    PurchaseLine."CM1 Credemtel Change Type"::Cancelled:
                        ChangeType := 'Cancelled';
                end;
            until PurchaseLine.Next() = 0;

        if ChangeTypes.Count() > 0 then
            if ChangeTypes.Contains('Cancelled') then
                ChangeType := 'Cancelled'
            else
                if ChangeTypes.Contains('Revised') then
                    ChangeType := 'Revised';
        exit(ChangeType);
    end;


    // REGISTRAZIONE CARICO: 
    procedure WriteReceiptAdviceXML(var OutStream: OutStream; RcptHeader: Record "Purch. Rcpt. Header")
    var
        RcptLine: Record "Purch. Rcpt. Line";
        CompanyInfo: Record "Company Information";
        TxtBld: TextBuilder;
        XmlText: Text;
    begin
        CompanyInfo.Get();
        // Inizio generazione XML
        TxtBld.Clear();
        TxtBld.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
        TxtBld.Append('<ns5:ReceiptAdvice xmlns:ns2="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" ' +
                      'xmlns:ns3="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" ' +
                      'xmlns:ns4="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" ' +
                      'xmlns:ns5="urn:oasis:names:specification:ubl:schema:xsd:ReceiptAdvice-2" ' +
                      'xmlns:ns6="http://fsc.satanet.it">');

        // Customization and Profile
        TxtBld.Append('<ns4:CustomizationID>urn:fdc:peppol.eu:poacc:trns:ReceiptAdvice:3</ns4:CustomizationID>');
        TxtBld.Append('<ns4:ProfileID>urn:fdc:peppol.eu:poacc:bis:ReceiptAdvice_only:3</ns4:ProfileID>');

        // Header cbc:ID and cbc:IssueDate
        TxtBld.Append('<ns4:ID>' + RcptHeader."No." + '</ns4:ID>');
        TxtBld.Append('<ns4:IssueDate>' + Format(RcptHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>') + '</ns4:IssueDate>');

        // cac:DeliveryCustomerParty
        TxtBld.Append('<ns3:DeliveryCustomerParty>');
        TxtBld.Append('<ns3:Party>');
        TxtBld.Append('<ns4:EndpointID schemeID="0211">' + CompanyInfo."VAT Registration No." + '</ns4:EndpointID>');
        TxtBld.Append('<ns3:PartyName>');
        TxtBld.Append('<ns4:Name>' + CompanyInfo.Name + '</ns4:Name>');
        TxtBld.Append('</ns3:PartyName>');
        TxtBld.Append('<ns3:PostalAddress>');
        TxtBld.Append('<ns4:StreetName>' + CompanyInfo.Address + '</ns4:StreetName>');
        TxtBld.Append('<ns4:CityName>' + CompanyInfo.City + '</ns4:CityName>');
        TxtBld.Append('<ns4:PostalZone>' + CompanyInfo."Post Code" + '</ns4:PostalZone>');
        TxtBld.Append('<ns3:Country>');
        TxtBld.Append('<ns4:IdentificationCode>' + CompanyInfo."Country/Region Code" + '</ns4:IdentificationCode>');
        TxtBld.Append('</ns3:Country>');
        TxtBld.Append('</ns3:PostalAddress>');
        TxtBld.Append('</ns3:Party>');
        TxtBld.Append('</ns3:DeliveryCustomerParty>');

        // cac:DespatchSupplierParty (dati dalla testata Receipt Header)
        TxtBld.Append('<ns3:DespatchSupplierParty>');
        TxtBld.Append('<ns3:Party>');
        // TxtBld.Append('<ns4:EndpointID>' + RcptHeader."VAT Registration No." + '</ns4:EndpointID>');
        TxtBld.Append('<ns4:EndpointID schemeID="0211">' + RcptHeader."VAT Country/Region Code" + RcptHeader."VAT Registration No." + '</ns4:EndpointID>');
        TxtBld.Append('<ns3:PartyIdentification>');
        TxtBld.Append('<ns4:ID>IDCODE:' + RcptHeader."Buy-from Vendor No." + '</ns4:ID>');
        TxtBld.Append('</ns3:PartyIdentification>');
        if RcptHeader."Buy-from Vendor Name" <> '' then begin
            TxtBld.Append('<ns3:PartyName>');
            TxtBld.Append('<ns4:Name>' + RcptHeader."Buy-from Vendor Name" + '</ns4:Name>');
            TxtBld.Append('</ns3:PartyName>');
        end;
        TxtBld.Append('</ns3:Party>');
        TxtBld.Append('</ns3:DespatchSupplierParty>');

        // cac:ReceiptLine
        RcptLine.SetRange("Document No.", RcptHeader."No.");
        if RcptLine.FindSet() then
            repeat
                TxtBld.Append('<ns3:ReceiptLine>');
                TxtBld.Append('<ns4:ID>' + Format(RcptLine."Line No.") + '</ns4:ID>');
                TxtBld.Append('<ns4:ReceivedQuantity unitCode="' + RcptLine."Unit of Measure Code" + '">' +
                              Format(RcptLine.Quantity, 0, '<Precision,2><Standard Format,2>') +
                              '</ns4:ReceivedQuantity>');
                TxtBld.Append('<ns3:OrderLineReference>');
                TxtBld.Append('<ns4:LineID>' + Format(RcptLine."Order Line No.") + '</ns4:LineID>');
                TxtBld.Append('<ns3:OrderReference>');
                TxtBld.Append('<ns4:ID>' + RcptLine."Order No." + '</ns4:ID>');
                if RcptLine."Order Date" <> 0D then
                    TxtBld.Append('<ns4:IssueDate>' + Format(RcptLine."CAMEOS Real Order Date", 0, '<Year4>-<Month,2>-<Day,2>') + '</ns4:IssueDate>');
                TxtBld.Append('</ns3:OrderReference>');
                TxtBld.Append('</ns3:OrderLineReference>');
                TxtBld.Append('<ns3:Item>');
                TxtBld.Append('<ns4:Name>' + RcptLine.Description + '</ns4:Name>');
                if RcptLine."No." <> '' then
                    TxtBld.Append('<ns3:BuyersItemIdentification><ns4:ID>' + RcptLine."No." + '</ns4:ID></ns3:BuyersItemIdentification>');
                TxtBld.Append('</ns3:Item>');
                TxtBld.Append('</ns3:ReceiptLine>');
            until RcptLine.Next() = 0;

        // Chiusura root
        TxtBld.Append('</ns5:ReceiptAdvice>');

        XmlText := TxtBld.ToText();
        XmlText := XmlEncodeSmart(XmlText);
        OutStream.WriteText(XmlText);
    end;

    //STORNO XML
    // Genera un XML di tipo ReceiptAdvice per lo storno di una ricevuta d'acquisto
    procedure WriteReceiptAdviceStornoXML(var OutStream: OutStream; RcptHeader: Record "Purch. Rcpt. Header")
    var
        CompanyInfo: Record "Company Information";
        TxtBld: TextBuilder;
        RcptLine: Record "Purch. Rcpt. Line";
        XmlText: Text;
        StornoID: Text;
    begin
        CompanyInfo.Get();
        TxtBld.Clear();
        // Header UBL ReceiptAdvice-2 with correct namespace/prefix
        TxtBld.Append('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
        TxtBld.Append('<ReceiptAdvice xmlns="urn:oasis:names:specification:ubl:schema:xsd:ReceiptAdvice-2" ' +
                      'xmlns:ns2="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" ' +
                      'xmlns:ns3="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" ' +
                      'xmlns:ns4="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" ' +
                      'xmlns:ns6="http://fsc.satanet.it">');

        // Customization and Profile
        TxtBld.Append('<ns4:CustomizationID>urn:fdc:peppol.eu:poacc:trns:ReceiptAdvice:3</ns4:CustomizationID>');
        TxtBld.Append('<ns4:ProfileID>urn:fdc:peppol.eu:poacc:bis:ReceiptAdvice_only:3</ns4:ProfileID>');

        // ID e Data del documento di storno
        // ID and IssueDate of the storno document
        TxtBld.Append('<ns4:ID>' + RcptHeader."No." + '</ns4:ID>');
        TxtBld.Append('<ns4:IssueDate>' + Format(RcptHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>') + '</ns4:IssueDate>');

        // DeliveryCustomerParty (Buyer)
        TxtBld.Append('<ns3:DeliveryCustomerParty><ns3:Party>');
        TxtBld.Append('<ns4:EndpointID schemeID="0211">' + CompanyInfo."VAT Registration No." + '</ns4:EndpointID>');
        TxtBld.Append('<ns3:PartyIdentification><ns4:ID schemeID="0211">' + CompanyInfo."VAT Registration No." + '</ns4:ID></ns3:PartyIdentification>');
        TxtBld.Append('<ns3:PostalAddress>');
        TxtBld.Append('<ns4:StreetName>' + CompanyInfo.Address + '</ns4:StreetName>');
        TxtBld.Append('<ns4:CityName>' + CompanyInfo.City + '</ns4:CityName>');
        TxtBld.Append('<ns4:PostalZone>' + CompanyInfo."Post Code" + '</ns4:PostalZone>');
        TxtBld.Append('<ns3:Country><ns4:IdentificationCode>' + CompanyInfo."Country/Region Code" + '</ns4:IdentificationCode></ns3:Country>');
        TxtBld.Append('</ns3:PostalAddress>');
        TxtBld.Append('<ns3:PartyLegalEntity><ns4:RegistrationName>' + CompanyInfo.Name + '</ns4:RegistrationName></ns3:PartyLegalEntity>');
        TxtBld.Append('</ns3:Party></ns3:DeliveryCustomerParty>');

        // DespatchSupplierParty (supplier dati dalla testata storno)
        TxtBld.Append('<ns3:DespatchSupplierParty><ns3:Party>');
        TxtBld.Append('<ns3:PartyIdentification><ns4:ID schemeID="0211">' + RcptHeader."VAT Country/Region Code" + RcptHeader."VAT Registration No." + '</ns4:ID></ns3:PartyIdentification>');
        // eventuale secondo PartyIdentification con IDCODE dal campo "Buy-from Vendor No."
        TxtBld.Append('<ns3:PartyIdentification><ns4:ID>IDCODE:' + RcptHeader."Buy-from Vendor No." + '</ns4:ID></ns3:PartyIdentification>');
        TxtBld.Append('<ns3:PostalAddress>');
        TxtBld.Append('<ns4:StreetName>' + RcptHeader."Buy-from Address" + '</ns4:StreetName>');
        TxtBld.Append('<ns4:CityName>' + RcptHeader."Buy-from City" + '</ns4:CityName>');
        TxtBld.Append('<ns4:PostalZone>' + RcptHeader."Buy-from Post Code" + '</ns4:PostalZone>');
        TxtBld.Append('<ns4:CountrySubentity>' + RcptHeader."Buy-from County" + '</ns4:CountrySubentity>');
        TxtBld.Append('<ns3:Country><ns4:IdentificationCode listID="ISO3166-1:Alpha2">' + RcptHeader."Buy-from Country/Region Code" + '</ns4:IdentificationCode></ns3:Country>');
        TxtBld.Append('</ns3:PostalAddress>');
        TxtBld.Append('<ns3:PartyLegalEntity><ns4:RegistrationName>' + RcptHeader."Buy-from Vendor Name" + '</ns4:RegistrationName></ns3:PartyLegalEntity>');
        TxtBld.Append('</ns3:Party></ns3:DespatchSupplierParty>');

        // ReceiptLine elements for storno
        RcptLine.SetRange("Document No.", RcptHeader."No.");
        RcptLine.SetFilter(Quantity, '>%1', 0); // Only include lines with positive quantity
        RcptLine.SetRange(Correction, true); // Only include lines marked as corrections (storno)
        if RcptLine.FindSet() then
            repeat
                // Build unique storno ID per line: DOC#DATE#LINENO
                StornoID := RcptLine."Document No." + '#' +
                           Format(RcptHeader."Document Date", 0, '<Year4>-<Month,2>-<Day,2>') + '#' +
                           Format(RcptLine."Line No.");

                TxtBld.Append('<ns3:ReceiptLine>');
                TxtBld.Append('<ns4:ID>' + Format(RcptLine."Line No.") + '</ns4:ID>'); // questo è il punto critico
                if RcptLine."Order Date" <> 0D then
                    TxtBld.Append('<ns4:IssueDate>' + Format(RcptLine."CAMEOS Real Order Date", 0, '<Year4>-<Month,2>-<Day,2>') + '</ns4:IssueDate>');
                TxtBld.Append('<ns4:ReceivedQuantity unitCode="' + RcptLine."Unit of Measure Code" + '">' +
                              Format(-RcptLine.Quantity, 0, '<Precision,2><Standard Format,2>') +
                              '</ns4:ReceivedQuantity>');
                // DocumentReference: ID then DocumentType
                TxtBld.Append('<ns3:DocumentReference>');
                TxtBld.Append('<ns4:ID>' + StornoID + '</ns4:ID>');
                TxtBld.Append('<ns4:DocumentType>RECEIPT_ADVICE_LINE_TRANSFER</ns4:DocumentType>');
                TxtBld.Append('</ns3:DocumentReference>');

                // Item block
                TxtBld.Append('<ns3:Item>');
                TxtBld.Append('<ns4:Description>' + RcptLine.Description + '</ns4:Description>');
                TxtBld.Append('<ns4:Name>' + RcptLine.Description + '</ns4:Name>');

                TxtBld.Append('</ns3:Item>');
                TxtBld.Append('</ns3:ReceiptLine>');
            until RcptLine.Next() = 0;


        TxtBld.Append('</ReceiptAdvice>');

        XmlText := TxtBld.ToText();
        XmlText := XmlEncodeSmart(XmlText);
        OutStream.WriteText(XmlText);
    end;

    procedure ExportSubcontractingComponents(PurchaseHeader: Record "Purchase Header"; ReceiptNo: Code[20]; Filename: Text)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        PurchPayablesSetup: Record "Purchases & Payables Setup";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempBlob: Record TempBlob temporary;
        ExcelFileName: Text;
        OutStr: OutStream;
    begin
        PurchaseHeader.CalcFields("Subcontracting Order");
        if not PurchaseHeader."Subcontracting Order" then
            exit;

        PurchPayablesSetup.Get();
        PurchPayablesSetup.TestField("CM1 Credemtel Component Path");

        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        IF ReceiptNo = '' THEN
            PurchaseLine.SetRange("CM1 Send to Credemetel", false);
        if PurchaseLine.FindSet() then
            repeat
                ProdOrderComponent.Reset();
                ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
                ProdOrderComponent.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
                ProdOrderComponent.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
                if ProdOrderComponent.FindSet() then begin
                    TempExcelBuffer.DeleteAll();
                    Clear(TempExcelBuffer);
                    Clear(OutStr);

                    TempExcelBuffer.NewRow();
                    TempExcelBuffer.AddColumn(ProdOrderComponent.FieldCaption("Item No."), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn(ProdOrderComponent.FieldCaption(Description), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn(ProdOrderComponent.FieldCaption(Quantity), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);//La caption è volutamente rimasta disallineata rispetto al campo esportato
                    TempExcelBuffer.AddColumn(ProdOrderComponent.FieldCaption("Unit of Measure Code"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn(ProdOrderComponent.FieldCaption("CAMEOS Disable Item "), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn(ProdOrderComponent.FieldCaption("Location Code"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn(ProdOrderComponent.FieldCaption("Bin Code"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    TempExcelBuffer.AddColumn(ProdOrderComponent.FieldCaption("CAMEOS Item Category Code"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    repeat
                        ProdOrderComponent.CalcFields("CAMEOS Disable Item ");
                        TempExcelBuffer.NewRow();
                        TempExcelBuffer.AddColumn(ProdOrderComponent."Item No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                        TempExcelBuffer.AddColumn(ProdOrderComponent.Description, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                        TempExcelBuffer.AddColumn(Format(ProdOrderComponent."Expected Quantity"), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);//Cambiato su richiesta del cliente. Vedi punto 187 dell'excel
                        TempExcelBuffer.AddColumn(ProdOrderComponent."Unit of Measure Code", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                        TempExcelBuffer.AddColumn(Format(ProdOrderComponent."CAMEOS Disable Item "), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                        TempExcelBuffer.AddColumn(ProdOrderComponent."Location Code", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                        TempExcelBuffer.AddColumn(ProdOrderComponent."Bin Code", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                        TempExcelBuffer.AddColumn(ProdOrderComponent."CAMEOS Item Category Code", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                    until ProdOrderComponent.Next() = 0;

                    ExcelFileName := PurchPayablesSetup."CM1 Credemtel Component Path" + '\' + Filename + '_' + Format(PurchaseLine."Line No.") + '.xlsx';
                    TempExcelBuffer.CreateNewBook(PurchaseLine."Document No." + '_' + Format(PurchaseLine."Line No."));
                    TempExcelBuffer.WriteSheet(PurchaseLine."Document No." + '_' + Format(PurchaseLine."Line No."), CompanyName, UserId);
                    TempExcelBuffer.CloseBook();
                    TempBlob.Blob.CreateOutStream(OutStr);
                    TempExcelBuffer.SaveToStream(OutStr, true);
                    TempBlob.Blob.Export(ExcelFileName); //TBD on the next versions

                    TempPurchaseLine.Init();
                    TempPurchaseLine."Document Type" := PurchaseLine."Document Type";
                    TempPurchaseLine."Document No." := PurchaseLine."Document No.";
                    TempPurchaseLine."Line No." := PurchaseLine."Line No.";
                    TempPurchaseLine.Type := TempPurchaseLine.Type::" ";
                    TempPurchaseLine.Description := Filename + '_' + Format(PurchaseLine."Line No.") + '.xlsx';
                    TempPurchaseLine.Insert();
                end;
            until PurchaseLine.Next() = 0;
    end;

    procedure LogCredemtelOrderTransmission(PurchaseLine: Record "Purchase Line"; CM1MovementType: Enum "CM1 Movement Type"; CM1DocumentType: Enum "CM1 Document Type";
                                                                                                       TraceType: Enum "CM1 Trace Type";
                                                                                                       StatusMovement: Enum "CM1 Status")
    var
        PurchHeader: Record "Purchase Header";
        CredemtelStaging: Record "CM1 Credemtel Staging";
        UserID: Code[50];
        LastEntryNumber: Integer;
    begin
        UserID := copystr(UserId(), 1, MaxStrLen(UserID));

        if not PurchHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then
            exit;
        // Assegna un nuovo Entry No. univoco
        if not CredemtelStaging.FindLast() then
            LastEntryNumber := 1
        else
            LastEntryNumber := CredemtelStaging."Entry No.";

        Clear(CredemtelStaging);
        CredemtelStaging.Init();
        CredemtelStaging."Entry No." := LastEntryNumber + 1;
        CredemtelStaging."Order No." := PurchaseLine."Document No.";
        CredemtelStaging."Order Line No." := PurchaseLine."Line No.";
        CredemtelStaging."Movement Type" := CM1MovementType;
        CredemtelStaging."Document Type" := CM1DocumentType;
        CredemtelStaging."Trace Type" := TraceType;
        CredemtelStaging.Status := StatusMovement;
        CredemtelStaging."Order Date" := PurchaseLine."Document Date";
        CredemtelStaging."Vendor No." := PurchaseLine."Buy-from Vendor No.";
        CredemtelStaging."Item No." := PurchaseLine."No.";
        CredemtelStaging."Item Description" := PurchaseLine.Description;
        CredemtelStaging."Cross Reference No." := PurchaseLine."Cross-Reference No.";
        CredemtelStaging."Unit of Measure Code" := PurchaseLine."Unit of Measure";
        CredemtelStaging.Quantity := PurchaseLine.Quantity;
        CredemtelStaging."Direct Unit Cost" := PurchaseLine."Direct Unit Cost";
        CredemtelStaging."Promised Receipt Date" := PurchaseLine."Promised Receipt Date";
        CredemtelStaging."Received Quantity" := PurchaseLine."Quantity Received";
        CredemtelStaging."Line Discount %" := PurchaseLine."Line Discount %";
        CredemtelStaging."Location Code" := PurchaseLine."Location Code";
        CredemtelStaging."Country of Origin Code" := PurchaseLine."CM1 Country/Region Origin Code";
        // CredemtelStaging."Order Confirmation No." := PurchaseLine."CM1 Order Confirmation No."; // se c'è un campo del genere

        if CredemtelStaging."Movement Type" = CredemtelStaging."Movement Type"::"Exit" then begin
            CredemtelStaging."Send DateTime" := CreateDateTime(WorkDate(), Time());
            CredemtelStaging."Import Date" := 0D; // Non usato per le uscite
            CredemtelStaging."Import Time" := 0T; // Non usato per le uscite
        end else begin
            CredemtelStaging."Send DateTime" := 0DT; // Non usato per le entrate
            CredemtelStaging."Import Date" := WorkDate();
            CredemtelStaging."Import Time" := Time();
        end;

        CredemtelStaging."Processing Date" := 0D;
        CredemtelStaging."Processing Time" := 0T;
        CredemtelStaging."User ID" := UserID;

        CredemtelStaging.Insert(true);
    end;

    procedure LogCredemtelOrderTransmissionFlexible(PurchaseLine: Record "Purchase Line"; IncludeAllLines: Boolean; CM1MovementType: Enum "CM1 Movement Type"; CM1DocumentType: Enum "CM1 Document Type";
                                                                                                                                         TraceType: Enum "CM1 Trace Type";
                                                                                                                                         StatusMovement: Enum "CM1 Status")
    var
        PurchLine: Record "Purchase Line";
    begin
        if IncludeAllLines then begin
            PurchLine.Reset();
            PurchLine.SetRange("Document Type", PurchaseLine."Document Type");
            PurchLine.SetRange("Document No.", PurchaseLine."Document No.");
            if PurchLine.FindSet() then
                repeat
                    LogCredemtelOrderTransmission(PurchLine, CM1MovementType, CM1DocumentType, TraceType, StatusMovement);
                until PurchLine.Next() = 0;
        end else
            LogCredemtelOrderTransmission(PurchaseLine, CM1MovementType, CM1DocumentType, TraceType, StatusMovement);
    end;

    procedure LogCredemtelOrderTransmissionFlexibleRcpt(PurchRcptLine: Record "Purch. Rcpt. Line"; IncludeAllLines: Boolean; CM1MovementType: Enum "CM1 Movement Type"; CM1DocumentType: Enum "CM1 Document Type";
                                                                                                                                                  TraceType: Enum "CM1 Trace Type";
                                                                                                                                                  StatusMovement: Enum "CM1 Status")
    var
        PurRcptLine: Record "Purch. Rcpt. Line";
    begin
        if IncludeAllLines then begin
            PurRcptLine.Reset();
            PurRcptLine.SetRange("Document No.", PurchRcptLine."Document No.");
            if PurRcptLine.FindSet() then
                repeat
                    LogCredemtelOrderTransmissionRcptLine(PurRcptLine, CM1MovementType, CM1DocumentType, TraceType, StatusMovement);
                until PurRcptLine.Next() = 0;
        end else
            LogCredemtelOrderTransmissionRcptLine(PurchRcptLine, CM1MovementType, CM1DocumentType, TraceType, StatusMovement);
    end;

    procedure LogCredemtelOrderTransmissionRcptLine(PurchRcptLine: Record "Purch. Rcpt. Line"; CM1MovementType: Enum "CM1 Movement Type"; CM1DocumentType: Enum "CM1 Document Type";
                                                                                                                    TraceType: Enum "CM1 Trace Type";
                                                                                                                    StatusMovement: Enum "CM1 Status")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        CredemtelStaging: Record "CM1 Credemtel Staging";
        UserID: Code[50];
        NowTime: Time;
        LastEntryNumber: Integer;
    begin
        UserID := copystr(UserId(), 1, MaxStrLen(UserID));
        NowTime := Time();

        if PurchRcptHeader.Get(PurchRcptLine."Document No.") then begin

            if not CredemtelStaging.FindLast() then
                LastEntryNumber := 1
            else
                LastEntryNumber := CredemtelStaging."Entry No.";

            Clear(CredemtelStaging);
            CredemtelStaging.Init();
            CredemtelStaging."Entry No." := LastEntryNumber + 1;
            CredemtelStaging."Order No." := PurchRcptLine."Document No.";
            CredemtelStaging."Order Line No." := PurchRcptLine."Line No.";
            CredemtelStaging."Movement Type" := CM1MovementType;
            CredemtelStaging."Document Type" := CM1DocumentType;
            CredemtelStaging."Trace Type" := TraceType;
            CredemtelStaging.Status := StatusMovement;
            CredemtelStaging."Order Date" := PurchRcptLine."Order Date";
            CredemtelStaging."Vendor No." := PurchRcptLine."Buy-from Vendor No.";
            CredemtelStaging."Item No." := PurchRcptLine."No.";
            CredemtelStaging."Item Description" := PurchRcptLine.Description;
            CredemtelStaging."Cross Reference No." := PurchRcptLine."Cross-Reference No.";
            CredemtelStaging."Unit of Measure Code" := PurchRcptLine."Unit of Measure";
            CredemtelStaging.Quantity := PurchRcptLine.Quantity;
            CredemtelStaging."Direct Unit Cost" := PurchRcptLine."Direct Unit Cost";
            CredemtelStaging."Promised Receipt Date" := PurchRcptLine."Promised Receipt Date";

            CredemtelStaging."Received Quantity" := PurchRcptLine."Quantity";
            CredemtelStaging."Line Discount %" := PurchRcptLine."Line Discount %";
            CredemtelStaging."Location Code" := PurchRcptLine."Location Code";
            // CredemtelStaging."Order Confirmation No." := PurchRcptLine."CM1 Order Confirmation No."; // se c'è un campo del genere

            if CredemtelStaging."Movement Type" = CredemtelStaging."Movement Type"::"Exit" then begin
                CredemtelStaging."Send DateTime" := CreateDateTime(WorkDate(), Time());
                CredemtelStaging."Import Date" := 0D; // Non usato per le uscite
                CredemtelStaging."Import Time" := 0T; // Non usato per le uscite
            end else begin
                CredemtelStaging."Send DateTime" := 0DT; // Non usato per le entrate
                CredemtelStaging."Import Date" := WorkDate();
                CredemtelStaging."Import Time" := NowTime;
            end;

            CredemtelStaging."Processing Date" := 0D;
            CredemtelStaging."Processing Time" := 0T;
            CredemtelStaging."User ID" := UserID;

            CredemtelStaging.Insert(true);
        end;
    end;

    procedure LogMessage(iIntTableID: Integer;
        TableRecEntryNo: Integer;
        iTxtMessage: Text[250];
        IintType: Integer;
        OrderNo: Code[20];
        OrderLineNo: Integer)
    var
        CM1CredemtelErrorLog: Record "CM1 Credemtel Error Log";
        lIntEntryNo: Integer;
    begin
        if not CM1CredemtelErrorLog.FindLast() then
            lIntEntryNo := 0
        else
            lIntEntryNo := CM1CredemtelErrorLog."Entry No.";

        CM1CredemtelErrorLog."Entry No." := lIntEntryNo + 1;
        CM1CredemtelErrorLog."Order No." := OrderNo;
        CM1CredemtelErrorLog."Order Line No." := OrderLineNo;
        CM1CredemtelErrorLog."Error Message" := iTxtMessage;
        CM1CredemtelErrorLog."Interface Entry No." := TableRecEntryNo;
        CM1CredemtelErrorLog."Table ID" := iIntTableID;
        CM1CredemtelErrorLog."Error Date" := WorkDate();
        CM1CredemtelErrorLog."Error Time" := Time();
        case IintType of
            0:
                CM1CredemtelErrorLog."Error Type" := CM1CredemtelErrorLog."Error Type"::Error;
            1:
                CM1CredemtelErrorLog."Error Type" := CM1CredemtelErrorLog."Error Type"::"Begin";
            2:
                CM1CredemtelErrorLog."Error Type" := CM1CredemtelErrorLog."Error Type"::"End";
            3:
                CM1CredemtelErrorLog."Error Type" := CM1CredemtelErrorLog."Error Type"::Warning;
        end;
        CM1CredemtelErrorLog.Insert();
    end;

    procedure WriteLog(TableID: Integer; TableRecEntryNo: Integer; ExecutionDateTime: DateTime; TxtMessage: Text[250]; OrderNo: Code[20]; OrderLineNo: Integer)
    begin
        LogMessage(DATABASE::"CM1 Credemtel Staging", TableRecEntryNo, TxtMessage, 0, OrderNo, OrderLineNo);
    end;

    procedure LogError(var CM1CredemtelStaging: Record "CM1 Credemtel Staging"; TxtErrorMsg: Text[250])
    begin
        CM1CredemtelStaging."Processing Date" := WorkDate();
        CM1CredemtelStaging."Processing Time" := Time();
        CM1CredemtelStaging.Status := CM1CredemtelStaging.Status::Error;
        CM1CredemtelStaging."Is Error" := true;
        CM1CredemtelStaging."Error Message" := TxtErrorMsg;
        CM1CredemtelStaging."Is Process" := false;
    end;

    procedure CheckLocationNonWorkingDate(iCodLocationCode: Code[10]; iDatDate: Date; iIntFieldNo: Integer): Boolean
    var
        lRecLocation: Record Location;
        lRecSalesLine: Record "Sales Line";
        lCduCalendarMgmt: Codeunit "Calendar Management";
        lBlnNonworking: Boolean;
        lTxtDescription: Text[50];
        lCodCurrentCalendarCode: Code[10];
        lCtxText001Lbl: Label '%1 %2 in not workin day for Location %3.\Impossible continue.';
    begin
        if iCodLocationCode = '' then
            exit(lBlnNonworking);
        if iDatDate = 0D then
            exit(lBlnNonworking);
        lRecLocation.Get(iCodLocationCode);
        if lRecLocation."Base Calendar Code" = '' then
            exit(lBlnNonworking);
        lCodCurrentCalendarCode := lRecLocation."Base Calendar Code";
        lBlnNonworking := lCduCalendarMgmt.CheckDateStatus(lCodCurrentCalendarCode, iDatDate, lTxtDescription);
        if lBlnNonworking then
            if iIntFieldNo = lRecSalesLine.FieldNo("Shipment Date") then
                Error(lCtxText001Lbl, lRecSalesLine.FieldCaption("Shipment Date"), iDatDate, iCodLocationCode);
        exit(lBlnNonworking);
    end;

    procedure ResolveDiscountText(strDiscount: Text; var ErrorMessage: Text[250]): Decimal;
    var
        decDiscount: Decimal;
        FinalDisc: Decimal;
        DiscValue: Decimal;
        PlusIndex: Integer;
        DiscText: Text;
        TmpDiscText: Text;
        ErrorOccurred: Boolean;
        ErrorTextLbl: Label 'The value %1 is not a valid discount.';
    begin
        if strDiscount = '' then
            strDiscount := '0';

        TmpDiscText := strDiscount;
        DiscText := '';
        FinalDisc := -1;
        ErrorMessage := '';

        repeat
            PlusIndex := StrPos(TmpDiscText, '+');
            if PlusIndex <> 0 then begin
                DiscText := CopyStr(TmpDiscText, 1, PlusIndex - 1);
                TmpDiscText := DelStr(TmpDiscText, 1, PlusIndex);
            end
            else begin
                DiscText := CopyStr(TmpDiscText, 1, STRLEN(TmpDiscText));
                TmpDiscText := '';
            end;

            if Evaluate(DiscValue, DiscText) then begin
                if FinalDisc = -1 then
                    FinalDisc := 1 - DiscValue / 100
                else
                    FinalDisc := FinalDisc * (1 - DiscValue / 100);
            end else
                ErrorOccurred := TRUE;

        until (TmpDiscText = '') OR (ErrorOccurred);

        if not ErrorOccurred then begin
            decDiscount := (1 - FinalDisc) * 100;
            exit(decDiscount);
        end
        else
            ErrorMessage := STRSUBSTNO(ErrorTextLbl, strDiscount);
    end;

    procedure ProcessingRefreshRecord(var CM1CredemtelStaging: Record "CM1 Credemtel Staging")
    var
    begin
        CM1CredemtelStaging."Is Error" := false;
        if not CM1CredemtelStaging.Warning then
            CM1CredemtelStaging."Error Message" := '';
        CM1CredemtelStaging."Is Process" := true;
    end;

    procedure CheckRecord(var CM1CredemtelStaging: Record "CM1 Credemtel Staging"): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        HasError: Boolean;
        ErrorMessage: Text[250];
        DiscErrorMessage: Text[250];
        TextDiscount: Text;
    begin
        HasError := false;
        ErrorMessage := '';

        //check if the order exists
        if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, CM1CredemtelStaging."Order No.") then begin
            HasError := true;
            ErrorMessage := StrSubstNo(ErrImp000, CM1CredemtelStaging."Order No.");
            WriteLog(Database::"CM1 Credemtel Staging", CM1CredemtelStaging."Entry No.", CreateDateTime(DatToday, TimTime), ErrorMessage, CM1CredemtelStaging."Order No.", CM1CredemtelStaging."Order Line No.");
            LogError(CM1CredemtelStaging, ErrorMessage);
            CM1CredemtelStaging.Modify();
            exit;
        end;

        //check if the order line exists
        if not PurchaseLine.Get(PurchaseHeader."Document Type"::Order, CM1CredemtelStaging."Order No.", CM1CredemtelStaging."Order Line No.") then begin
            HasError := true;
            ErrorMessage := StrSubstNo(ErrImp001, CM1CredemtelStaging."Order Line No.", CM1CredemtelStaging."Order No.");
            WriteLog(Database::"CM1 Credemtel Staging", CM1CredemtelStaging."Entry No.", CreateDateTime(DatToday, TimTime), ErrorMessage, CM1CredemtelStaging."Order No.", CM1CredemtelStaging."Order Line No.");
            LogError(CM1CredemtelStaging, ErrorMessage);
            // CM1CredemtelStaging.Modify();
            exit;
        end;

        //check vendor
        if CM1CredemtelStaging."Vendor No." <> PurchaseHeader."Buy-from Vendor No." then begin
            HasError := true;
            ErrorMessage := StrSubstNo(ErrImp007, CM1CredemtelStaging."Vendor No.", PurchaseHeader."Buy-from Vendor No.", PurchaseLine."Document No.");
            WriteLog(Database::"CM1 Credemtel Staging", CM1CredemtelStaging."Entry No.", CreateDateTime(DatToday, TimTime), ErrorMessage, CM1CredemtelStaging."Order No.", CM1CredemtelStaging."Order Line No.");
            LogError(CM1CredemtelStaging, ErrorMessage);
        end;

        //check Date
        if CM1CredemtelStaging."Promised Receipt Date" <> 0D then
            if CM1CredemtelStaging."Promised Receipt Date" <> PurchaseLine."Promised Receipt Date" then
                if CheckLocationNonWorkingDate(PurchaseLine."Location Code", CM1CredemtelStaging."Promised Receipt Date", 0) then begin
                    HasError := true;
                    ErrorMessage := StrSubstNo(ErrImp005, PurchaseLine.FieldCaption("Promised Receipt Date"), CM1CredemtelStaging."Promised Receipt Date", PurchaseLine."Location Code");
                    WriteLog(Database::"CM1 Credemtel Staging", CM1CredemtelStaging."Entry No.", CreateDateTime(DatToday, TimTime), ErrorMessage, CM1CredemtelStaging."Order No.", CM1CredemtelStaging."Order Line No.");
                    LogError(CM1CredemtelStaging, ErrorMessage);
                end;

        //check Quantity
        if CM1CredemtelStaging.Quantity <> 0 then
            if (CM1CredemtelStaging.Quantity * PurchaseLine."Quantity Received" < 0) or ((Abs(CM1CredemtelStaging.Quantity) < Abs(PurchaseLine."Quantity Received")) and (PurchaseLine."Receipt No." = '')) then begin
                HasError := true;
                ErrorMessage := StrSubstNo(ErrImp003, PurchaseLine.FieldCaption("Quantity Received"));
                WriteLog(Database::"CM1 Credemtel Staging", CM1CredemtelStaging."Entry No.", CreateDateTime(DatToday, TimTime), ErrorMessage, CM1CredemtelStaging."Order No.", CM1CredemtelStaging."Order Line No.");
                LogError(CM1CredemtelStaging, ErrorMessage);
            end;

        //check cost

        if CM1CredemtelStaging."Direct Unit Cost" <> 0 then
            if CM1CredemtelStaging."Direct Unit Cost" < 0 then begin
                HasError := true;
                ErrorMessage := StrSubstNo(ErrImp006, PurchaseLine.FieldCaption("Direct Unit Cost"));
                WriteLog(Database::"CM1 Credemtel Staging", CM1CredemtelStaging."Entry No.", CreateDateTime(DatToday, TimTime), ErrorMessage, CM1CredemtelStaging."Order No.", CM1CredemtelStaging."Order Line No.");
                LogError(CM1CredemtelStaging, ErrorMessage);
            end;

        //Check discount 
        TextDiscount := '';
        TextDiscount := Format(CM1CredemtelStaging."Line Discount %");
        if CM1CredemtelStaging."Line Discount % 2" <> 0 then
            TextDiscount := TextDiscount + '+' + Format(CM1CredemtelStaging."Line Discount % 2");
        ResolveDiscountText(TextDiscount, DiscErrorMessage);
        if DiscErrorMessage <> '' then begin
            HasError := true;
            WriteLog(DATABASE::"CM1 Credemtel Staging", CM1CredemtelStaging."Entry No.", CreateDateTime(DatToday, TimTime),
                     DiscErrorMessage, CM1CredemtelStaging."Order No.", CM1CredemtelStaging."Order Line No.");
            ErrorMessage := DiscErrorMessage;
            LogError(CM1CredemtelStaging, ErrorMessage);
        end;

        //check if the line is closed
        if PurchaseLine."Line Closed" then begin
            HasError := true;
            ErrorMessage := StrSubstNo(ErrImp008, CM1CredemtelStaging."Order No.", CM1CredemtelStaging."Order Line No.");
            WriteLog(DATABASE::"CM1 Credemtel Staging", CM1CredemtelStaging."Entry No.", CreateDateTime(DatToday, TimTime),
                     ErrorMessage, CM1CredemtelStaging."Order No.", CM1CredemtelStaging."Order Line No.");
            LogError(CM1CredemtelStaging, ErrorMessage);
        end;

        if HasError then begin
            LogError(CM1CredemtelStaging, ErrorMessage);
            exit(false);
        end;

        ProcessingRefreshRecord(CM1CredemtelStaging);
        exit(true);
    end;

    procedure ProcessEntry(EntryNo: Integer)
    var
        StagingRec: Record "CM1 Credemtel Staging";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        if not StagingRec.Get(EntryNo) then
            exit;

        if StagingRec."Movement Type" <> StagingRec."Movement Type"::Entry then
            exit;

        if not CheckRecord(StagingRec) then begin
            StagingRec.Status := StagingRec.Status::Error;
            StagingRec."Is Error" := true;
            StagingRec."Is Process" := false;
            StagingRec.Modify(true);
            Commit();
            Error(StagingRec."Error Message");
        end;

        // Record valido: aggiorno l’ODA
        if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, StagingRec."Order No.") then
            Error('Ordine %1 non trovato.', StagingRec."Order No.");

        if not PurchaseLine.Get(PurchaseHeader."Document Type"::Order, StagingRec."Order No.", StagingRec."Order Line No.") then
            Error('Riga %1 dell''ordine %2 non trovata.', StagingRec."Order Line No.", StagingRec."Order No.");

        ReleasePurchaseDocument.PerformManualReopen(PurchaseHeader);
        // Applico i valori se sono stati indicati
        if StagingRec.Quantity <> 0 then begin
            PurchaseLine.Validate(Quantity, StagingRec.Quantity);
            PurchaseLine."CM1 Missed engag Credemtel" := true;
        end;

        if StagingRec."Promised Receipt Date" <> 0D then
            PurchaseLine.Validate("Promised Receipt Date", StagingRec."Promised Receipt Date");

        if StagingRec."Direct Unit Cost" <> 0 then begin
            PurchaseLine.Validate("Direct Unit Cost", StagingRec."Direct Unit Cost");
            PurchaseLine."CM1 Change Price Credemtel" := true;
        end;

        if StagingRec."Order Confirmation No." <> '' then begin
            PurchaseHeader.Validate("Vendor Order No.", StagingRec."Order Confirmation No.");
            PurchaseHeader.Modify(true);
        end;

        // Discount %
        if StagingRec."Line Discount %" <> 0 then
            PurchaseLine.Validate("Discount Text", Format(StagingRec."Line Discount %"))
        else
            PurchaseLine."Line Discount %" := 0;

        if StagingRec."Line Status Code" <> '' then
            if PurchaseLine."CM1 Credemtel Ord Line Status" <> PurchaseLine."CM1 Credemtel Ord Line Status"::Closed then
                case StagingRec."Line Status Code" of
                    'Add':
                        PurchaseLine."CM1 Credemtel Ord Line Status" := PurchaseLine."CM1 Credemtel Ord Line Status"::Addition;
                    'Modify':
                        PurchaseLine."CM1 Credemtel Ord Line Status" := PurchaseLine."CM1 Credemtel Ord Line Status"::Modify;
                    'Confirmed':
                        PurchaseLine."CM1 Credemtel Ord Line Status" := PurchaseLine."CM1 Credemtel Ord Line Status"::Confirm;
                    'Reject':
                        PurchaseLine."CM1 Credemtel Ord Line Status" := PurchaseLine."CM1 Credemtel Ord Line Status"::Rejected;
                    'Closed':
                        PurchaseLine."CM1 Credemtel Ord Line Status" := PurchaseLine."CM1 Credemtel Ord Line Status"::Closed;
                end;
        PurchaseLine.Modify(true);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // Aggiorna stato staging
        StagingRec.Status := StagingRec.Status::Completed;
        StagingRec."Error Message" := '';
        StagingRec."Is Error" := false;
        StagingRec."Is Process" := true;
        StagingRec."Processing Date" := WorkDate();
        StagingRec."Processing Time" := Time;
        StagingRec.Modify(true);
    end;

    procedure DecodeOrderResponse(Content: Text): Boolean
    var
        POHeader: Record "Purchase Header";
        POLine: Record "Purchase Line";
        StagingLine: Record "CM1 Credemtel Staging";
        XmlDoc: XmlDocument;
        XmlNode: XmlNode;
        LineNodes: XmlNodeList;
        LineNode: XmlNode;
        OrderIDText: Text;
        BuyersItemID: Text;
        DiscountLine: Decimal;
        LineQty: Decimal;
        PromisedDate: Date;
        NotePrice: Decimal;
        GrossPrice: Decimal;
        NewEntryNo: Integer;
        FoundPOLine: Boolean;
        LineStatusCode: Text;
        XmlLineIDText: Text;
        XmlLineID: Integer;
        LineStatusCode1Lbl: Label 'Add';
        LineStatusCode2Lbl: Label 'Modify';
        LineStatusCode3Lbl: Label 'Reject';
        LineStatusCode4Lbl: Label 'Confirmed';
        LineStatusCode5Lbl: Label 'Closed';
        NoteText: Text;
        StartPos: Integer;
        PriceText: Text;
        IDOrderConfirm: Text;
    begin
        // Carica XML
        if not XmlDocument.ReadFrom(Content, XmlDoc) then
            Error('Impossibile leggere il documento XML');

        if XmlDoc.SelectSingleNode('//*[local-name()=''ID'']', XmlNode) then
            IDOrderConfirm := XmlNode.AsXmlElement().InnerText;

        // --- HEADER: recupera OrderReference/ID ---
        if not XmlDoc.SelectSingleNode(
            '//*[local-name()=''OrderReference'']/*[local-name()=''ID'']'
            , XmlNode) then
            Error('Nodo OrderReference/ID non trovato nel file XML');

        OrderIDText := XmlNode.AsXmlElement().InnerText;
        if StrPos(OrderIDText, '#') > 0 then
            OrderIDText := CopyStr(OrderIDText, 1, StrPos(OrderIDText, '#') - 1);

        if not POHeader.Get(POHeader."Document Type"::Order, OrderIDText) then
            Error('Ordine %1 non trovato', OrderIDText);

        // --- BODY: processa tutte le LineItem ---
        XmlDoc.SelectNodes(
          '//*[local-name()=''OrderLine'']/*[local-name()=''LineItem'']'
          , LineNodes);

        // Calcola Entry No iniziale per CM1 Credemtel Staging
        if not StagingLine.FindLast() then
            NewEntryNo := 1
        else
            NewEntryNo := StagingLine."Entry No." + 1;

        foreach LineNode in LineNodes do begin
            // Reset variabili
            Clear(BuyersItemID);
            Clear(LineQty);
            Clear(PromisedDate);
            Clear(NotePrice);
            Clear(GrossPrice);
            Clear(DiscountLine);
            // 1) BuyersItemIdentification/ID
            if LineNode.SelectSingleNode(
                   '*[local-name()=''Item'']/*[local-name()=''BuyersItemIdentification'']/*[local-name()=''ID'']'
                   , XmlNode) then
                BuyersItemID := XmlNode.AsXmlElement().InnerText
            else
                BuyersItemID := '';

            // Legge il LineItem/ID dal XML
            if LineNode.SelectSingleNode('*[local-name()="ID"]', XmlNode) then
                XmlLineIDText := XmlNode.AsXmlElement().InnerText;

            Evaluate(XmlLineID, XmlLineIDText);

            POLine.Reset();
            POLine.SetRange("Document Type", POHeader."Document Type");
            POLine.SetRange("Document No.", POHeader."No.");
            POLine.SetRange("Line No.", XmlLineID); // match diretto col Line No.
            if POLine.FindFirst() then
                FoundPOLine := true;

            // 2) Quantità
            if LineNode.SelectSingleNode('*[local-name()=''Quantity'']', XmlNode) then
                Evaluate(LineQty, XmlNode.AsXmlElement().InnerText.Replace('.', ','));
            // POLine."CM1 Missed engag Credemtel" := true;

            // 3) Data di carico promessa
            if LineNode.SelectSingleNode(
                   '*[local-name()=''Delivery'']/*[local-name()=''PromisedDeliveryPeriod'']/*[local-name()=''EndDate'']'
                   , XmlNode) then
                Evaluate(PromisedDate, XmlNode.AsXmlElement().InnerText);

            // 4) Prezzo Lordo da <Note>
            if LineNode.SelectSingleNode('*[local-name()="Note"]', XmlNode) then begin
                NoteText := XmlNode.AsXmlElement().InnerText;

                StartPos := StrPos(NoteText, ':');
                if StartPos > 0 then begin
                    PriceText := CopyStr(NoteText, StartPos + 1);
                    PriceText := DelChr(PriceText, '=', ' '); // Rimuove gli spazi
                    Evaluate(NotePrice, PriceText.Replace('.', ','));
                end;
            end;

            // 5) Sconto da <MultiplierFactorNumeric>
            if LineNode.SelectSingleNode('*[local-name()="Price"]/*[local-name()="AllowanceCharge"]/*[local-name()="MultiplierFactorNumeric"]', XmlNode) then
                Evaluate(DiscountLine, XmlNode.AsXmlElement().InnerText.Replace('.', ','));

            if LineNode.SelectSingleNode('*[local-name()=''LineStatusCode'']', XmlNode) then begin
                LineStatusCode := XmlNode.AsXmlElement().InnerText;
                case LineStatusCode of
                    '1':
                        // Add
                        LineStatusCode := LineStatusCode1Lbl;
                    '3':
                        // Modify
                        LineStatusCode := LineStatusCode2Lbl;
                    '5':
                        // Confirmed
                        LineStatusCode := LineStatusCode4Lbl;
                    '7':
                        // Reject
                        LineStatusCode := LineStatusCode3Lbl;
                    '42':
                        // Closed
                        LineStatusCode := LineStatusCode5Lbl;
                end;
            end;

            // Scrivi nella tabella di staging
            Clear(StagingLine);
            StagingLine.Init();
            StagingLine."Entry No." := NewEntryNo;
            StagingLine."Order No." := POHeader."No.";
            StagingLine."Vendor No." := POHeader."Buy-from Vendor No.";
            StagingLine."Order Confirmation No." := copystr(IDOrderConfirm, 1, MaxStrLen(StagingLine."Order Confirmation No."));
            if FoundPOLine then
                StagingLine."Order Line No." := POLine."Line No.";
            StagingLine."Item No." := copystr(BuyersItemID, 1, MaxStrLen(StagingLine."Item No.")); // se lo hai nel tuo staging
            StagingLine.Quantity := LineQty;
            StagingLine."Promised Receipt Date" := PromisedDate;
            StagingLine."Direct Unit Cost" := NotePrice;
            if DiscountLine = 0 then
                StagingLine."Line Discount %" := 0
            else
                StagingLine."Line Discount %" := DiscountLine;
            StagingLine."Status" := StagingLine."Status"::InProgress;
            StagingLine."Movement Type" := StagingLine."Movement Type"::"Entry";
            StagingLine."Document Type" := StagingLine."Document Type"::ORDACQ;
            StagingLine."Trace Type" := StagingLine."Trace Type"::"OrderResponse";
            StagingLine."Order Date" := POHeader."Document Date";
            StagingLine."Item Description" := POLine.Description;
            StagingLine."Unit of Measure Code" := POLine."Unit of Measure";
            StagingLine."Cross Reference No." := POLine."Cross-Reference No.";
            StagingLine."Location Code" := POLine."Location Code";
            StagingLine."User ID" := copystr(UserId(), 1, MaxStrLen(StagingLine."User ID"));
            StagingLine."Processing Date" := WorkDate();
            StagingLine."Import Date" := WorkDate();
            StagingLine."Import Time" := Time;
            // StagingLine."Send DateTime" := CreateDateTime(WorkDate(), Time);
            StagingLine."Is Error" := false;
            StagingLine."Is Process" := false;
            StagingLine."Line Status Code" := Format(LineStatusCode);
            StagingLine.Insert();
            NewEntryNo += 1;
        end;
        exit(true);
    end;

    procedure Credemtel_GeneralOrder_Seinding(var PurchaseHeader: Record "Purchase Header"): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseLine: Record "Purchase Line";
        TempBlob: Record TempBlob;
        CREDEMENTELGeneralFunct: Codeunit "CM1 Credemtel Gen. Fnc.";
        OutStream: OutStream;
        FileName: Text;
        VarIsSuccessed: Boolean;
        TxtBuildXML: Text;
    begin
        PurchasesPayablesSetup.Get();
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        if not PurchaseLine.FindFirst() then
            exit;
        TempBlob.Blob.CreateOutStream(OutStream);
        if PurchaseHeader."CM1 Credemtel Order Date" <> 0D then begin
            TxtBuildXML := CREDEMENTELGeneralFunct.WriteOrderChangeXML(OutStream, PurchaseHeader).ToText().Replace('&', '&amp;');
            CREDEMENTELGeneralFunct.LogCredemtelOrderTransmissionFlexible(PurchaseLine, true, "CM1 Movement Type"::"Exit", "CM1 Document Type"::ORDACQUPD, "CM1 Trace Type"::"OrderChange", "CM1 Status"::"InProgress");
        end else begin
            TxtBuildXML := CREDEMENTELGeneralFunct.CreateAndSendOrderXML(OutStream, PurchaseHeader).ToText().Replace('&', '&amp;');
            CREDEMENTELGeneralFunct.LogCredemtelOrderTransmissionFlexible(PurchaseLine, true, "CM1 Movement Type"::"Exit", "CM1 Document Type"::ORDACQ, "CM1 Trace Type"::"Order", "CM1 Status"::"InProgress");
        end;

        case PurchasesPayablesSetup."CM1 Debug Enabled" of
            true:
                begin
                    FileName := 'Order_' + PurchaseHeader."No." + '.xml';
                    VarIsSuccessed := DownloadSoapCall(TempBlob, FileName);
                end;
            false:
                VarIsSuccessed := MakePostSoapCall(TempBlob);
        end;

        exit(VarIsSuccessed);
    end;

    procedure Credemtel_ClosePurchLine(var PurchaseLine: Record "Purchase Line"): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        TempBlob: Record TempBlob;
        OutStream: OutStream;
        FileName: Text;
        VarIsSuccessed: Boolean;
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchasesPayablesSetup.Get();

        TempBlob.Blob.CreateOutStream(OutStream);

        CreateAndSendOrderXML(OutStream, PurchaseHeader);
        LogCredemtelOrderTransmissionFlexible(PurchaseLine, false, "CM1 Movement Type"::"Exit", "CM1 Document Type"::ORDACQDEL, "CM1 Trace Type"::"Order", "CM1 Status"::"InProgress");

        Clear(VarIsSuccessed);
        case PurchasesPayablesSetup."CM1 Debug Enabled" of
            true:
                begin
                    FileName := 'OrderCloseLine_' + PurchaseHeader."No." + '.xml';
                    VarIsSuccessed := DownloadSoapCall(TempBlob, FileName);
                end;
            false:
                VarIsSuccessed := MakePostSoapCall(TempBlob);
        end;

        exit(VarIsSuccessed);
    end;

    procedure Credemtel_CancelPurchLine(var PurchaseLine: Record "Purchase Line"): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        TempBlob: Record TempBlob;
        OutStream: OutStream;
        FileName: Text;
        VarIsSuccessed: Boolean;
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchasesPayablesSetup.Get();

        TempBlob.Blob.CreateOutStream(OutStream);

        CreateAndSendOrderXML(OutStream, PurchaseHeader);
        LogCredemtelOrderTransmissionFlexible(PurchaseLine, false, "CM1 Movement Type"::"Exit", "CM1 Document Type"::ORDACQANN, "CM1 Trace Type"::"Order", "CM1 Status"::"InProgress");

        Clear(VarIsSuccessed);
        case PurchasesPayablesSetup."CM1 Debug Enabled" of
            true:
                begin

                    FileName := 'OrderCancelLine_' + PurchaseHeader."No." + '.xml';
                    VarIsSuccessed := DownloadSoapCall(TempBlob, FileName);
                end;
            false:
                VarIsSuccessed := MakePostSoapCall(TempBlob);
        end;

        exit(VarIsSuccessed);
    end;

    procedure Credemtel_WriteReceiptAdviceStornoXML(var PurchRcptHeader: Record "Purch. Rcpt. Header"): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        TempBlob: Record TempBlob;
        OutStream: OutStream;
        FileName: Text;
        VarIsSuccessed: Boolean;
    begin
        PurchasesPayablesSetup.Get();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        if not PurchRcptLine.FindFirst() then
            exit;
        TempBlob.Blob.CreateOutStream(OutStream);

        WriteReceiptAdviceStornoXML(OutStream, PurchRcptHeader);
        LogCredemtelOrderTransmissionFlexibleRcpt(PurchRcptLine, false, "CM1 Movement Type"::"Exit", "CM1 Document Type"::ORDACQANN, "CM1 Trace Type"::"Order", "CM1 Status"::"InProgress");

        Clear(VarIsSuccessed);
        case PurchasesPayablesSetup."CM1 Debug Enabled" of
            true:
                begin

                    FileName := 'ReceiptAdvice STORNO_' + PurchRcptHeader."No." + '.xml';
                    VarIsSuccessed := DownloadSoapCall(TempBlob, FileName);
                end;
            false:
                VarIsSuccessed := MakePostSoapCall(TempBlob);
        end;

        exit(VarIsSuccessed);
    end;

    procedure Credemtel_WriteReceipt(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchRcptLine: Record "Purch. Rcpt. Line"): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        TempBlob: Record TempBlob;
        OutStream: OutStream;
        FileName: Text;
        VarIsSuccessed: Boolean;
    begin
        PurchasesPayablesSetup.Get();
        TempBlob.Blob.CreateOutStream(OutStream);

        WriteReceiptAdviceXML(OutStream, PurchRcptHeader);
        LogCredemtelOrderTransmissionFlexibleRcpt(PurchRcptLine, true, "CM1 Movement Type"::"Exit", "CM1 Document Type"::"CAR", "CM1 Trace Type"::"ReceiptAdvice", "CM1 Status"::"InProgress");

        Clear(VarIsSuccessed);
        case PurchasesPayablesSetup."CM1 Debug Enabled" of
            true:
                begin

                    FileName := 'ReceiptAdvice_' + PurchRcptHeader."No." + '.xml';
                    VarIsSuccessed := DownloadSoapCall(TempBlob, FileName);
                end;
            false:
                VarIsSuccessed := MakePostSoapCall(TempBlob);
        end;

        exit(VarIsSuccessed);
    end;

    procedure CredemtelGetOrderRespose(var TNIInterfacesINEntry: Record "TNI Interfaces IN Entry"): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        TempBlob: Record TempBlob;
        OutStream: OutStream;
        InStr: InStream;
        FileName: Text;
        FinalTextContent: Text;
        TextContent: Text;
        VarIsSuccessed: Boolean;
    begin
        PurchasesPayablesSetup.Get();
        TempBlob.Blob.CreateOutStream(OutStream);

        Clear(VarIsSuccessed);
        case PurchasesPayablesSetup."CM1 Debug Enabled" of
            true:
                begin

                    FileName := 'OrderResponse_' + TNIInterfacesINEntry."TNI Transaction ID" + '.xml';
                    if not UploadIntoStream('Carica file OrderResponse XML', '', 'XML file (*.xml)|*.xml', FileName, InStr) then
                        exit;

                    Clear(FinalTextContent);
                    while not (InStr.EOS) do begin
                        InStr.ReadText(TextContent);
                        FinalTextContent += TextContent;
                    end;

                    VarIsSuccessed := DecodeOrderResponse(FinalTextContent);
                end;
            false:
                begin
                    VarIsSuccessed := MakeGetSoapCall(TempBlob);

                    Clear(InStr);
                    TempBlob.Blob.CreateInStream(InStr);

                    Clear(FinalTextContent);
                    while not (InStr.EOS) do begin
                        InStr.ReadText(TextContent);
                        FinalTextContent += TextContent;
                    end;

                    VarIsSuccessed := DecodeOrderResponse(FinalTextContent);
                end;
        end;

        exit(VarIsSuccessed);
    end;

    procedure CredemtelProcessOrderRespose()
    var
        CM1CredemtelStaging: Record "CM1 Credemtel Staging";
        TNIInterfacesINEntry: Record "TNI Interfaces IN Entry";
        CM1CredemtelGenFnc: Codeunit "CM1 Credemtel Gen. Fnc.";
        CM1CREDEMTELDriver: Codeunit "CM1 Credemtel Driver";
        TNIFlows: Record "TNI Flows";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        TNIMgt: Codeunit "TNI Mgt.";
        InStr: InStream;
        ContentText: Text;
        NullFileName: Text[100];
        TNIEntryGuid: Guid;
        TNIGroupGuid: Guid;
        TNILogType: Enum "TNI Log Type";
        XMLSavedSuccLbl: Label 'XML Processed Successfully';
    begin
        CM1CredemtelStaging.Reset();
        CM1CredemtelStaging.SetRange("Movement Type", CM1CredemtelStaging."Movement Type"::"Entry");
        CM1CredemtelStaging.SetRange("Trace Type", CM1CredemtelStaging."Trace Type"::"OrderResponse");
        CM1CredemtelStaging.SetRange(Status, CM1CredemtelStaging.Status::InProgress);
        if CM1CredemtelStaging.FindSet() then begin
            PurchasesPayablesSetup.Get();
            PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Interface");
            PurchasesPayablesSetup.TestField("CM1 Credemtel TNI Proc Order");
            TNIFlows.Get(PurchasesPayablesSetup."CM1 Credemtel TNI Interface", PurchasesPayablesSetup."CM1 Credemtel TNI Proc Order");
            repeat
                TNIEntryGuid := CreateGuid();
                TNIGroupGuid := CreateGuid();

                TNIMgt.CreateInternalEntry(TNIInterfacesINEntry, TNIFlows, NullFileName, TNIEntryGuid);
                Commit();
                Clear(CM1CREDEMTELDriver);
                CM1CREDEMTELDriver.SetParametersEntryNo(22, CM1CredemtelStaging."Entry No.");
                if not CM1CREDEMTELDriver.Run() then
                    TniMgt.WriteInterfacesINLog(TNIInterfacesINEntry, TNILogType::Error, GetLastErrorText(), GetLastErrorCallStack(), '', 0, Database::"Purchase Header", TNIEntryGuid, TNIGroupGuid)
                else
                    TniMgt.WriteInterfacesINLog(TNIInterfacesINEntry, TNILogType::Information, XMLSavedSuccLbl, '', '', 0, Database::"Purchase Header", TNIEntryGuid, TNIGroupGuid);
            // ProcessEntry(CM1CredemtelStaging."Entry No.");
            until CM1CredemtelStaging.Next() = 0;
        end;
    end;

    procedure DownloadSoapCall(var
                                   TempBlob: Record TempBlob;
                                   ParFileName: Text) IsSuccessed: Boolean;

    var
        BodyInStream: InStream;
    begin
        TempBlob.Blob.CreateInStream(BodyInStream);
        IsSuccessed := DownloadFromStream(BodyInStream, '', '', '', ParFileName);
        exit(IsSuccessed);
    end;

    procedure MakePostSoapCall(var TempBlob: Record TempBlob) IsSuccessed: Boolean
    var
        Client: HttpClient;
        contentHeaders: HttpHeaders;
        BodyInStream: InStream;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        TNIFlows: Record "TNI Flows";
        OutputString: Text;
        BodyXML: Text;
        ChunkText: Text;
        Boundary: Text;
        MultipartBody: Text;
    begin
        TempBlob.Blob.CreateInStream(BodyInStream);
        Clear(BodyXML);
        while not BodyInStream.EOS do begin
            BodyInStream.ReadText(ChunkText);
            BodyXML += ChunkText;
        end;
        RequestContent.WriteFrom(BodyXML);
        RequestContent.GetHeaders(contentHeaders);
        contentHeaders.Clear();
        contentHeaders.Add('Content-Type', 'text/xml;charset=utf-8');
        // contentHeaders.Add('Authorization', 'Basic ' + Base64Convert.ToBase64(CompassSetup."Compass User" + ':' + CompassSetup."Compass Password"));
        // contentHeaders.Add('SOAPAction', 'http://tempuri.org/PacketDataImport');

        RequestContent.ReadAs(OutputString);

        IsSuccessed := Client.Post('DA PRENDERE DA TNI' + '?WSDL', RequestContent, ResponseMessage);
    end;

    procedure MakeGetSoapCall(var TempBlob: Record TempBlob) IsSuccessed: Boolean
    var
        Client: HttpClient;
        contentHeaders: HttpHeaders;
        BodyInStream: InStream;
        RequestContent: HttpContent;
        ResponseMessage: HttpResponseMessage;
        OutputString: Text;
        BodyXML: Text;
        ChunkText: Text;
        Boundary: Text;
        MultipartBody: Text;
    begin
        TempBlob.Blob.CreateInStream(BodyInStream);
        Clear(BodyXML);
        while not BodyInStream.EOS do begin
            BodyInStream.ReadText(ChunkText);
            BodyXML += ChunkText;
        end;
        RequestContent.WriteFrom(BodyXML);
        RequestContent.GetHeaders(contentHeaders);
        contentHeaders.Clear();
        contentHeaders.Add('Content-Type', 'text/xml;charset=utf-8');
        // contentHeaders.Add('Authorization', 'Basic ' + Base64Convert.ToBase64(CompassSetup."Compass User" + ':' + CompassSetup."Compass Password"));
        // contentHeaders.Add('SOAPAction', 'http://tempuri.org/PacketDataImport');

        RequestContent.ReadAs(OutputString);

        IsSuccessed := Client.Get('DA PRENDERE DA TNI' + '?WSDL', ResponseMessage);
    end;

    procedure GetTokenFromLocalApi(): Text
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        ResponseText: Text;
        ErrorLbl: Label 'Error retrieving token from local API';
    begin
        if not HttpClient.Get('http://localhost:5005/jwt', HttpResponse) then
            Error(ErrorLbl);

        if not HttpResponse.IsSuccessStatusCode() then
            Error('Errore nella risposta token: %1', HttpResponse.HttpStatusCode());

        HttpResponse.Content().ReadAs(ResponseText);

        exit(ResponseText);
    end;

    procedure GetAccessTokenFromJwt(Jwt: Text): Text
    var
        HttpClient: HttpClient;
        HttpContent: HttpContent;
        HttpResponse: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        ResponseText: Text;
        PosStart: Integer;
        PosEnd: Integer;
        AccessToken: Text;
        SubString: Text;
        FormBody: Text;
    begin
        // Rimuovi eventuali virgolette esterne
        if CopyStr(Jwt, 1, 1) = '"' then
            Jwt := CopyStr(Jwt, 2);
        if CopyStr(Jwt, StrLen(Jwt), 1) = '"' then
            Jwt := CopyStr(Jwt, 1, StrLen(Jwt) - 1);

        FormBody :=
            'client_id=CCJWT-YVsqnDut1Z65bgAY4u5wM2FK5r4Q4Qfx' +
            '&client_assertion=' + Jwt +
            '&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer' +
            '&grant_type=client_credentials';

        HttpContent.WriteFrom(FormBody);
        HttpContent.GetHeaders(HttpHeaders);
        HttpHeaders.Clear();
        HttpHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');

        if not HttpClient.Post('https://api-oauth.stg.credemtel.it/connect/token', HttpContent, HttpResponse) then
            Error('Chiamata token fallita');

        if not HttpResponse.IsSuccessStatusCode() then
            Error('Errore HTTP: %1', HttpResponse.HttpStatusCode());

        HttpResponse.Content().ReadAs(ResponseText);

        PosStart := STRPOS(ResponseText, '"access_token":"');
        if PosStart = 0 then
            Error('access_token non trovato nella risposta');

        PosStart += STRLEN('"access_token":"');

        SubString := COPYSTR(ResponseText, PosStart);
        PosEnd := STRPOS(SubString, '"');
        if PosEnd = 0 then
            Error('Parsing access_token fallito');

        AccessToken := COPYSTR(SubString, 1, PosEnd - 1);

        exit(AccessToken);
    end;

    procedure UploadXmlFileToCredemtel(
        var FileBlob: Record TempBlob;
        AccessToken: Text;
        FileName: Text;
        DocumentType: Text
    ): Boolean
    var
        Client: HttpClient;
        Content: HttpContent;
        Headers: HttpHeaders;
        Response: HttpResponseMessage;
        MultiPartBody: TextBuilder;
        MultiPartBodyOutStream: OutStream;
        MultiPartBodyInStream: InStream;
        TempMultiBlob: Record TempBlob temporary;
        Boundary: Text;
        FileInStream: InStream;
        IsSuccessful: Boolean;
        HttpStatusCode: Integer;
        ContentString: Text;
    begin
        // Crea lo stream del payload multipart
        TempMultiBlob.Blob.CreateOutStream(MultiPartBodyOutStream);
        Boundary := FORMAT(CREATEGUID);

        // Header della parte "form-data"
        MultiPartBody.AppendLine('--' + Boundary);
        MultiPartBody.AppendLine('Content-Disposition: form-data; name="file"; filename="' + FileName + '"');
        MultiPartBody.AppendLine('Content-Type: application/xml');
        MultiPartBody.AppendLine();

        MultiPartBodyOutStream.WriteText(MultiPartBody.ToText());

        // Corpo file
        FileBlob.Blob.CreateInStream(FileInStream);
        CopyStream(MultiPartBodyOutStream, FileInStream);

        // Footer del boundary
        MultiPartBody.Clear();
        MultiPartBody.AppendLine();
        MultiPartBody.AppendLine('--' + Boundary + '--');
        MultiPartBodyOutStream.WriteText(MultiPartBody.ToText());

        // Costruisce HttpContent
        TempMultiBlob.Blob.CreateInStream(MultiPartBodyInStream);
        Content.WriteFrom(MultiPartBodyInStream);

        // Headers
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'multipart/form-data; boundary="' + Boundary + '"');
        Headers.Add('Authorization', 'Bearer ' + AccessToken);

        // Esegue la POST
        IsSuccessful := Client.Post(
            'https://api-gateway.stg.credemtel.it/apibusinessgawscm/fsc-api/documents/upload?documentType=' + DocumentType,
            Content,
            Response
        );

        // Controllo risultato
        if not IsSuccessful then
            Error('Errore nella chiamata HTTP (invio file).');

        if not Response.IsSuccessStatusCode() then begin
            Response.Content().ReadAs(ContentString);
            Error('Errore Credemtel [%1]: %2', Response.HttpStatusCode(), ContentString);
        end;

        exit(true);
    end;

    procedure DownloadXmlFileFromCredemtel(DocumentType: Text; AccessToken: Text): Text
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        ResponseText: Text;
        Headers: HttpHeaders;
        Url: Text;
    begin
        Url := 'https://api-gateway.stg.credemtel.it/apibusinessgawscm/fsc-api/documents/download?documentType=' + DocumentType;

        Request.SetRequestUri(Url);
        Request.Method := 'GET';

        Request.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Authorization', 'Bearer ' + AccessToken);

        if not Client.Send(Request, Response) then
            Error('Errore nella chiamata GET a Credemtel');

        if not Response.IsSuccessStatusCode() then
            Error('Errore HTTP GET Credemtel: %1', Response.HttpStatusCode());

        Response.Content().ReadAs(ResponseText);
        exit(ResponseText);
    end;

    // procedure SendErrorNotificationViaAdvMail(TNIFlow: Record "TNI Flows"; ErrorMessage: Text)
    // var
    //     CAMEOSCAMASetup: Record "CAMEOS CAMA Setup";
    //     AdvDocRequest: Record "EOS AdvDoc Request";
    //     AdvDocDocuments: Record "EOS AdvDoc Documents";
    //     AdvRptDefaultSetup: Record "EOS AdvRpt Default Setup";
    //     EmailTextHeader: Record "EOS E-Mail Text Header";
    //     AdvDocMngt: Codeunit "EOS AdvDoc Mngt";
    //     AdvMailProcessing: Codeunit "EOS Adv Mail Processing";
    //     SubjectHeader: Text[100];
    //     BodyHeader: Text[250];
    // begin
    //     // 1. Lettura setup generale CAMEOS
    //     CAMEOSCAMASetup.Get();
    //     if CAMEOSCAMASetup."CM1 Error Notification Emails" = '' then
    //         exit;

    //     AdvDocRequest.InitializeRequest();
    //     AdvRptDefaultSetup.SetRange("EOS Table No.", Database::"Warehouse Shipment Header");
    //     AdvRptDefaultSetup.SetRange("EOS Enabled", true);

    //     if AdvRptDefaultSetup.FindFirst() then begin
    //         AdvDocRequest."EOS Report Setup Code" := AdvRptDefaultSetup."EOS Default Report Setup";
    //         AdvDocRequest."EOS Mailbox Code" := AdvRptDefaultSetup."EOS Mailbox Code";

    //         EmailTextHeader.SetRange("EOS Code", AdvRptDefaultSetup."EOS E-Mail Text Code");
    //         if EmailTextHeader.FindFirst() then begin
    //             AdvDocRequest."EOS E-Mail Text Code" := EmailTextHeader."EOS Code";
    //             AdvDocRequest."EOS Language Code" := EmailTextHeader."EOS Language Code";
    //         end;
    //     end;

    //     // 2. Inizializza request
    //     AdvDocRequest.InitializeRequest();
    //     AdvDocRequest."EOS Request Type" := AdvDocRequest."EOS Request Type"::EOSSingleMail;
    //     AdvDocRequest."EOS Request Status" := AdvDocRequest."EOS Request Status"::Ready;

    //     // 3. Prendi il setup di default (scegli tu quale mailbox/report usare)
    //     // AdvDocRequestSetup.SetRange("EOS Table No.", Database::"TNI Flows");
    //     // AdvDocRequestSetup.SetRange("EOS Enabled", true);
    //     // if AdvDocRequestSetup.FindFirst() then begin
    //     //     AdvDocRequest."EOS Report Setup Code" := AdvDocRequestSetup."EOS Default Report Setup";
    //     //     AdvDocRequest."EOS Mailbox Code" := AdvDocRequestSetup."EOS Mailbox Code";

    //     // 4. Testata email: oggetto e corpo predefiniti dal Text Header
    //     // EmailTextHeader.SetRange("EOS Code", AdvDocRequestSetup."EOS E-Mail Text Code");
    //     if EmailTextHeader.FindFirst() then begin
    //         SubjectHeader := EmailTextHeader."EOS Subject";
    //         BodyHeader := EmailTextHeader.GetBody();
    //     end;

    //     AdvDocMngt.BuildRecipientList(AdvDocRequest); // prende i destinatari da setup (Mailbox)
    //                                                   // 7. Processa la richiesta (invia l’email)
    //     AdvMailProcessing.ProcessRequest(AdvDocRequest);
    // end;
    // // end;



    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        DatToday: Date;
        TimTime: Time;
        ErrImp000: Label 'The Order %1 don''t exits';
        ErrImp001: Label 'Order line %1 %2 don''t exits';
        ErrImp003: Label 'Quantity must not be less than %1';
        ErrImp005: Label '%1 %2 in not workin day for Location %3.';
        ErrImp006: Label '%1 must be greater than 0';
        ErrImp007: Label 'Vendor %1 is different from the vendor %2 indicated on order %3';
        ErrImp008: Label 'Order line %1 %2 is closed';
}