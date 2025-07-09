codeunit 50094 "CM1 Credemtel Sched Process"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        ProcessAllEntries();
    end;

    local procedure ProcessAllEntries()
    var
        StagingRec: Record "CM1 Credemtel Staging";
        CredemtelGenFunct: Codeunit "CM1 Credemtel Gen. Fnc.";
    begin
        StagingRec.Reset();
        StagingRec.SetRange("Movement Type", StagingRec."Movement Type"::Entry);
        StagingRec.SetRange(Status, StagingRec.Status::"InProgress");
        if StagingRec.FindSet() then
            repeat
                CredemtelGenFunct.ProcessEntry(StagingRec."Entry No.");
            until StagingRec.Next() = 0;
    end;
}
