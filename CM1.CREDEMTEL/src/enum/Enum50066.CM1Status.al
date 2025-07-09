enum 50066 "CM1 Status"
{
    Extensible = true;

    value(0; " ")
    {
    }
    value(1; "Pending")
    {
        Caption = 'Pending'; // Da processare
    }
    value(2; "InProgress")
    {
        Caption = 'InProgress'; // Inviato
    }
    value(3; "Completed")
    {
        Caption = 'Completed'; // Processato
    }
    value(4; "Error")
    {
        Caption = 'Error'; // Errore
    }
}