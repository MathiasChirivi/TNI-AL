pageextension 50104 "CM1 User Set" extends "User Setup"
{
    layout
    {
        addafter(Email)
        {
            field("CM1 Credemtel Delete Line"; Rec."CM1 Credemtel Delete Line")
            {
                ApplicationArea = All;
            }
        }

    }
}