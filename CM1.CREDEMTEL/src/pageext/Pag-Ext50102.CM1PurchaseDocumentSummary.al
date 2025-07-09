pageextension 50102 "CM1 Purchase Document Summary" extends "Purchase Document Summary"
{
    layout
    {
        addafter("Expected Receipt Date")
        {
            field("CM1 Send to Credemetel"; Rec."CM1 Send to Credemetel")
            {
                ApplicationArea = All;
                Editable = EditableDocumentOrder;
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    var
    begin
        if Rec."Document Type" = Rec."Document Type"::Order then
            EditableDocumentOrder := true
        else
            EditableDocumentOrder := false;
    end;

    var
        EditableDocumentOrder: Boolean;
}