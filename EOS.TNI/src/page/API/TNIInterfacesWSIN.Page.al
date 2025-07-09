page 50150 "TNI Interfaces WS IN"
{
    APIGroup = 'wsin';
    APIPublisher = 'eos';
    APIVersion = 'v2.0';
    DelayedInsert = true;
    EntityName = 'inmessage';
    EntitySetName = 'inmessage';
    PageType = API;
    SourceTable = "TNI Interfaces IN Entry";
    SourceTableTemporary = true;
    InsertAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(interfaceCode; Rec."TNI Interface Code")
                {
                }
                field(flowCode; Rec."TNI Flow Code")
                {
                }
                field(filename; Rec."TNI File Name")
                {
                }
                field(message; Message)
                {
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        TNIMgt.ReadWsInFlow(Rec, Message);
    end;

    var
        TNIMgt: Codeunit "TNI Mgt.";
        Message: Text;
}