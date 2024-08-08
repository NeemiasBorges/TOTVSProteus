#include "totvs.ch"

/*/{Protheus.doc} GDMAIL01
        Função para efetuar o envio de e-mails sem anexo
        O disparo do e-mail utilizará as Classes TMailMessage e TMailManager juntamente com os parâmetros de servidor de e-mail do Protheus.
        U_GDMAIL01()
    @type function    
    @author Maicon Macedo
    @since 17/08/2021
    @version 1.0
    @param cAssunto, Caracter, Assunto do e-mail
    @param cTexto, Caracter, Mensagem do e-mail
    @param cPara, Caracter, Destinários
    @param cAnexo, Caracter, Arquivo que será enviado no Anexo
    @obs Os parâmetros (SX6) abaixo devem estar definidos, pois serão utilizados na função.
        MV_RELACNT (Conta de login do e-Mail)   X6_CONTEUD: endereco@servidor.com.br
        MV_RELPSW  (Senha de login do e-Mail)   X6_CONTEUD: senha
        MV_RELSERV (Servidor SMTP do e-Mail)    X6_CONTEUD: {endereco}:{Porta}
        MV_RELTIME (TimeOut do e-Mail)          X6_CONTEUD: 120
        MV_RELTLS  (SMTP possui conexão segura) X6_CONTEUD: .T.
        * Utilize a rotina CFGSETMAIL no Configurador (SIGACFG > Ambientes > Email/Proxy > Configurar) para definir os dados de conexão com o seu e-mai.
    @history Maicon Macedo - 27/05/2022 - Inclui o parâmetro cAnexo e a possibilidade de anexar um arquivo no e-mail
/*/
 
User Function GDMAIL01(cAssunto,cTexto,cPara,cAnexo)
    Local aArea        := GetArea()
    Local bError 
    // Variáveis para receber os parâmetros SX6
    Local cConta       := AllTrim(GetMV("MV_RELACNT"))
    Local cSenhas      := AllTrim(GetMV("MV_RELPSW"))
    Local cSMTPSv      := AllTrim(GetMV("MV_RELSERV"))
    Local nTimeOut     := GetMV("MV_RELTIME")
    Local lConnSeg     := GetMV("MV_RELTLS")
    //Objeto da Classe TMailManager
    Local oManager     := Nil 
    // Variáveis para conexão com a classe TMailManager
    Local cUsuario     := Left(cConta,At('@', cConta)-1)
    Local cServidor    := IIf( At(':', cSMTPSv) > 0 , Left(cSMTPSv,At(':', cSMTPSv)-1), cSMTPSv)
    Local nPorta       := IIf( At(':', cSMTPSv) > 0 , Val(SubStr(cSMTPSv, At(':', cSMTPSv)+1, Len(cSMTPSv))), 587)
    //Objeto da Classe TMailMessage
    Local oMessage     := Nil

    Local cLog         := ""
    Local lRet         := .T.
    Local nRet         := 0

    bError := ErrorBlock( {|e| cError := e:Description } )

    Begin Sequence
        If !( Empty(cAssunto) .OR. Empty(cTexto) .OR. Empty(cPara) )

            //Instância a classe apra criar uma nova mensagem
            oMessage := TMailMessage():New()
            oMessage:Clear()

            //Define os atributos da classe TMailMessage
            oMessage:cFrom    := cConta
            oMessage:cTo      := cPara
            oMessage:cCc      := ""
            oMessage:cBcc     := ""
            oMessage:cSubject := cAssunto
            oMessage:cBody    := cTexto
            oMessage:MsgBodyType( "text/html" )

            If !(Empty(cAnexo))
                If File(cAnexo)
                    //Anexa o arquivo na mensagem de e-Mail
                    nRet := oMessage:AttachFile(cAnexo)
                    If nRet < 0
                        cLog += "Erro Anexo 01 - Nao foi possivel anexar o arquivo '"+cAnexo+"'!" + CRLF
                    EndIf
                Else
                    cLog += "Erro Anexo 01 - Arquivo '"+cAnexo+"' nao encontrado!" + CRLF
                EndIf
            EndIf

            //Instância o objeto que cria a conexão com o servidor para disparo do e-mail
            oManager := TMailManager():New()

            //Define se irá utilizar o TLS
            If lConnSeg
                oManager:SetUseTLS(.T.)
            EndIf

            nRet := oManager:Init("", cServidor, cUsuario, cSenhas, 0, nPorta)
            If nRet != 0
                cLog += "Erro 01 - Nao foi possivel conectar com o servidor de e-mail: " + oManager:GetErrorString(nRet) + CRLF
                lRet := .F.
            Else //Se conectar no servidor de e-mail
                
                nRet := oManager:SetSMTPTimeout(nTimeOut)
                If nRet != 0
                    cLog += "Erro 02 - Falha ao tentar definir o TimeOut "+cValToChar(nTimeOut)+"s: " + oManager:GetErrorString(nRet) + CRLF
                Else

                    nRet := oManager:SMTPConnect()
                    If nRet != 0
                        cLog += "Erro 03 - Falha ao conectar via SMTP: " + oManager:GetErrorString(nRet) + CRLF
                        lRet := .F.
                    Else

                        nRet := oManager:SmtpAuth(cConta, cSenhas)
                        If nRet != 0
                            cLog += "Erro 04 - Falha na autenticação do servidor SMTP: " + oManager:GetErrorString(nRet) + CRLF
                            lRet := .F.
                        EndIf
                    EndIf
                EndIf
            EndIf
            
            If lRet //Se conectar no servidor de e-mail via SMTP, envia a mensagem para o destinatário
                nRet := oMessage:Send(oManager)
                If nRet != 0
                    cLog += "Erro 05 - Falha no envio da mensagem: " + oManager:GetErrorString(nRet) + CRLF
                    lRet := .F.
                Else
            EndIf

            If lRet
                nRet := oManager:SMTPDisconnect()
                    If nRet != 0
                        cLog += "Erro 06 - Falha ao desconectar do Servidor SMTP: " + oManager:GetErrorString(nRet) + CRLF
                    EndIf
                EndIf
            EndIf
        EndIf
    
        cLog := PadR("GDMAIL01 - ",10) + DToC(Date()) + " " + Time()                             + CRLF + ;
                PadR("Funcao   - ",10) + FunName()                                               + CRLF + ;
                PadR("Para     - ",10) + cPara                                                   + CRLF + ;
                PadR("Assunto  - ",10) + cAssunto                                                + CRLF + ;
                IIF(Empty(cLog),"Mensagem enviada com sucesso!","Existem mensagens de aviso: ")  + CRLF + ;
                AllTrim(cLog)

        If !IsBlind()
            Aviso(":: Resultado ::", cLog, {"Ok"}, 2)
        EndIf

    Recover
		ErrorBlock( bError )

        If (IsBlind())
            //ConOut(PadC("Automatic routine ended with error", 80))
            //ConOut("Error: "+ oRestClient:GetLastError())
            FWLogMsg("ERROR", /*cTransactionId*/, "GDMAIL01","EVENTVIEWER",;
                "ERROR01","ERROR01","ERROR01" + cError , 0, 0, {})
        Else
            MsgStop( cError ,":: GDMAIL01 ::")
        EndIf

 
    End Sequence

    RestArea(aArea)
Return (lRet,cLog)
