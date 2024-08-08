#include 'totvs.ch'
#include "APWEBSRV.CH"
#include "TbiConn.ch"
#include "TbiCode.ch"
#include "TOPCONN.ch"
 
WSSERVICE WSPHPCLI DESCRIPTION "WebService INTEGRACAO PHP"
   
    WSDATA CCPF     as STRING
    WSDATA cRetCpf  as STRING 
   
    WSMETHOD VALIDACPF DESCRIPTION "Valida Cpf do cliente"

ENDWSSERVICE

WSMETHOD VALIDACPF WSRECEIVE CCPF WSSEND cRetCpf WSSERVICE WSPHPCLI
    Local cCfpVl := alltrim(::CCPF)
    Local cDupl  := .f.
    Local cRet   := ""
    Local lRet   := .t.

    conout("Pesquisando "+cCfpVl)    
    dbSelectArea("SA1")
    dbSetOrder(3)

    If dbSeek(FWxfilial("SA1")+cCfpVl)
        cDupl:=.t.
        cRet :="JA EXISTE CLIENTE COM ESSE CPF/CNPJ "+alltrim(SA1->A1_NOME)
        ::cRetCpf:=cRet
        Return(.T.)
    EndIf

    If !cDupl
        lRet:=CGC(cCfpVl)
        If lRet
            cRet:="OK"
        Else
            If len(cCfpVl) = 14
                cRet:="CNPJ INVALIDO"
            Else
                cRet:="CPF INVALIDO"
            EndIf
        EndIf
    EndIf

    ::cRetCpf:=cRet

Return(.T.)
