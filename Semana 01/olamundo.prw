#include "totvs.ch"

/*/{Protheus.doc} NomeFuncao 
        Descricao 
    @type User Function 
    @author Maicon Macedo 
    @since 30/09/2022 
    @version 1.0 
    @history 17-02-2024: Substitui a função MsgInfo por FWAlertInfo 
/*/

User Function OlaMd()
    Local cTexto as String

    cTexto := "Olá mundo. AdvPL Lovers!"

    FWAlertInfo(cTexto, "Teste Ola mundo")

Return
