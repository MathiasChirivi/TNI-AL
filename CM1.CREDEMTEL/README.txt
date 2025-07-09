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


FLUSSI CREDEMTEL:

- (USCITA) Export Ord. Acquisto (anche c/lavoro) - (webservice), se si tratta di modifica, aggiungere campo. ---- xxxxxxxxxxxxxxxxxxxxx

- (USCITA) Se c/lavoro, export excel in una cartella file (solo quesot flusso è in file) xxxxxxxxxxxxxxxxxxxxxxxxxxx

- (ENTRATA) Ricezione ordini (order response)

- (USCITA) Registrazione carico che rimane manuale (Receipt/advice)  --

- (Uscita) Annullamento carico che rimane manuale (Receipt/advice STORNO) ------

-  (Uscita) Invio di chiusura riga ordine acquisto, funzione custom già aggiunta----xxxxxxxxxxxxxxxxxxxxxxxxxxxx

-  (Uscita) Invio di annulla riga ordine acquisto, funzione custom già aggiunta----xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 