----------------------------------------------------------------------------------------------------------------------------------------

Codeunit "TNI Mgt."

FUNZIONI
    SendFlow    =   Inviare / salvare file in base al tipo flusso ecc...
    ReadFlow    =   Leggere file

EVENTI
    OnAfterWriteFileName    =   Evento da sottoscrivere se si vuole dare un nome custom al file 

----------------------------------------------------------------------------------------------------------------------------------------

Codeunit "TNI Write File"

EVENTI
    OnBeforeCreateFile    =    Evento da sottoscrivere per scrivere un tracciato personalizzato

----------------------------------------------------------------------------------------------------------------------------------------

Codeunit "TNI Send WS"

EVENTI
    OnBeforeAddAuthorizationHeader    =    Evento da sottoscrivere per recuperare l'autenticazione della chiamata WS in maniera custom

----------------------------------------------------------------------------------------------------------------------------------------
