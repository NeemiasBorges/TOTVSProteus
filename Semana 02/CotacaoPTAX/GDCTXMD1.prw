#include "totvs.ch"
#Include "Tbiconn.ch"
 
/*/{Protheus.doc} GDCTXMD1
        Api | Cotação do Dolar Ptax, Api Oficial do Banco Central
        U_GDCTXMD1()
    @type       function
    @author     Thiago.Andrade
    @since      04/03/2021
    @version    1.0
    @see
        Dólar comercial (venda e compra) - cotações diárias e Taxas de Câmbio - todos os boletins diários - v1
            https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/documentacao
            https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/aplicacao#!/recursos
            https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/$metadata
        FWRest (Efetua uma transação utilizando REST) - https://terminaldeinformacao.com/knowledgebase/fwrest/
        FWRest (Classe Client de REST) - https://tdn.totvs.com/display/framework/FWRest
        DataValida - Verifica data válida no sistema - https://tdn.totvs.com/pages/releaseview.action?pageId=6815098 
        MATA090 - MSEXECAUTO - https://centraldeatendimento.totvs.com/hc/pt-br/articles/360062080753-MP-ADVPL-Rotina-MATA090-via-ExecAuto 
        IsBlind - https://tdn.totvs.com/pages/releaseview.action?pageId=6814878 
        Function no Schedule - https://www.blogadvpl.com/abertura-de-ambiente-em-rotinas-automaticas-parte1/#page-content 
        Função FwLogMsg - https://tdn.totvs.com/display/framework/FWLogMsg 
        Como ativar o FWTRACELOG - https://centraldeatendimento.totvs.com/hc/pt-br/articles/360026026133-RM-Como-habilitar-e-gerar-o-Fwtracelog-no-console-log-do-protheus- 
        JSon - https://tdn.engpro.totvs.com.br/display/tec/Classe+JsonObject 
    @history Maicon Macedo - 20210610 - Adaptação do Fonte zApiDol.prw para a GDBR
    @history Maicon Macedo - 20210610 - Utilização do recurso CotacaoMoedaPeriodoFechamento para retornar os dados de cotação das moedas
    @history Maicon Macedo - 20210726 - Continuação
    @history Maicon Macedo - 20210729 - Inclusão da função IsBlind para tratar as mensagens dentro do Job
    @history Maicon Macedo - 20210810 - Inclusão de informações para o console.log do Schedule
    @history Maicon Macedo - 20210816 - Mudança do comportamento do fonte para que o mesmo efetue a busca da taxa de mais de uma moeda
    @history Maicon Macedo - 20210927 - Regra para Moeda 10
    @history Maicon Macedo - 20211018 - zMoeda10: recurso CotacaoDolarPeriodo
    @history Maicon Macedo - 20211018 - Consultar se a data é de algum feriado em que a Bolsa não opera - Função fFeriado
    @history Maicon Macedo - 20211019 - DataValida() inserida nas datas de Terça a Sexta
/*/
 
User function GDCTXMD1()
    Local bError 
    Local aHeader     := {}
    Local aIdMoeda    := {} // Codigo da Moeda, Cotacao Venda, Cotacao Compra
    Local cDtCot      := '' // MM-DD-AAAA
    Local oRestClient
    Local oJsObj 
    Local cJsonRt     := ''
    Local cMsg        := ''
    Local n           := 0
    Local aParam      := {}
    Private nTxMd10   := 0
    Private cPerMd10  := ""
    Private cMsgMd10  := ""
    
    bError := ErrorBlock( {|e| cError := e:Description } )

    ConOut("GDCTXMD1 - INICIO")

    FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
             "STEP01","MSG01","STEP01 - Iniciando abertura do ambiente")
    ConOut("STEP01 - Iniciando abertura do ambiente")

    RPCSetType(3)  //Nao consome licensas
    //Abertura do ambiente em rotinas automáticas
    //RpcSetEnv(cRpcEmp,cRpcFil,cEnvUser,cEnvPass,cEnvMod,cFunName,aTables,lShowFinal,lAbend,lOpenSX,lConnect)
    RpcSetEnv("99","01",/*cEnvUser*/,/*cEnvPass*/,/*cEnvMod*/,/*cFunName*/,{ }) 

    FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
             "STEP02","MSG02","STEP02 - Ambiente aberto")
    ConOut("STEP02 - Ambiente aberto")

    Begin Sequence

        //Cabeçalho
        AAdd(aHeader,'User-Agent: Mozilla/5.0 (compatible; Protheus ' + GetBuild() + ')')
        AAdd(aHeader,'Content-Type: application/json; charset=utf-8')
        
        FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                "STEP03","MSG03","STEP03 - BEGIN SEQUENCE iniciado")
        ConOut("STEP03 - BEGIN SEQUENCE iniciado")

        //Ajusta Padrão da Data para MM-DD-AAAA
        If cValToChar(DoW(dDataBase)) $ '7_1' //Sábado e Domingo
            cDtCot := DToS( DataValida(dDataBase, .F. ) )
        ElseIf cValToChar(DoW(dDataBase)) $ '2' //Segunda-feira
            cDtCot := DToS( DataValida(dDataBase-1, .F. ) )
        Else //de Terça à Sexta
            cDtCot := DToS( DataValida(dDataBase-1,.F.) )
        EndIf
        cDtCot := SubStr(cDtCot,5,2) + '-' + SubStr(cDtCot,7,2) + '-' + SubStr(cDtCot,1,4)

        FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                "STEP04","MSG04","STEP04 - Data da consulta obtida: " + cDtCot)
        ConOut("STEP04 - Data da consulta obtida: " + cDtCot)
        
        AAdd(aIdMoeda,{"USD",0,0,''})
        AAdd(aIdMoeda,{"EUR",0,0,''})
        AAdd(aIdMoeda,{"JPY",0,0,''})
        AAdd(aIdMoeda,{"CAD",0,0,''})
        AAdd(aIdMoeda,{"THB",0,0,''})
        AAdd(aIdMoeda,{"ARS",0,0,''})

     //[GET] Consulta Dados na Api
        oRestClient := FWRest():New("https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata")
        For n := 1 To Len(aIdMoeda)
            oRestClient:setPath("/CotacaoMoedaPeriodoFechamento(codigoMoeda=@idMD,dataInicialCotacao=@dtIniCt,dataFinalCotacao=@dtFinCt)?@idMD='"+aIdMoeda[n][1]+"'&@dtIniCt='"+cDtCot+"'&@dtFinCt='"+cDtCot+"'&$format=json&$select=cotacaoCompra,cotacaoVenda,dataHoraCotacao,tipoBoletim")
            oRestClient:Get(aHeader)

            FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                    "STEP05","MSG05","STEP05 - Requisao REST executada " + aIdMoeda[n][1] )

            oJsObj := JsonObject():New()

            cJsonRt := oJsObj:FromJson(oRestClient:CRESULT)

            FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                    "STEP06","MSG06","STEP06 - Resultado da requisicao: "+cValToChar(cJsonRt))

            If ValType(cJsonRt) == 'U' //NIL
                FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                        "STEP07","MSG07","STEP07 - Entrou na condicao IF ")
                //Valida se a Cotação já está liberada para o dia - oJsObj:hasProperty("value")
                If Len(oJsObj["value"]) > 0

                    FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                            "STEP08","MSG08","STEP08 - Cotacao valida ")

                    cMsg  := ""
                    cMsg  += "<b>Data:</b> " + DToC(SToD(StrTran(SubStr(oJsObj["value"][1]["dataHoraCotacao"],1,10),'-','')))
                    cMsg  += " - " + SubStr(oJsObj["value"][1]["dataHoraCotacao"],12,5) + "h<br>"
                    cMsg  += "<b>Moeda: </b> " + aIdMoeda[n][1] + "<br>"
                    cMsg  += "<b>Cotação de Compra:</b> " + cValToChar(oJsObj["value"][1]["cotacaoCompra"]) + "<br>"
                    cMsg  += "<b>Cotação de Venda:</b> " + cValToChar(oJsObj["value"][1]["cotacaoVenda"]) + "<br>"
            
                    If (!IsBlind())
                        MsgInfo( cMsg ,":: Cotação Moeda PTAX - BC API Olinda ::")
                    Else
                        FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                                "STEP09","MSG11","STEP09 - Cotacao obtida: "+ cValToChar( oJsObj["value"][1]["cotacaoCompra"]) )
                    EndIf

                    aIdMoeda[n][2] := oJsObj["value"][1]["cotacaoVenda"]
                    aIdMoeda[n][3] := oJsObj["value"][1]["cotacaoCompra"]
                    aIdMoeda[n][4] := DToC(SToD(StrTran(SubStr(oJsObj["value"][1]["dataHoraCotacao"],1,10),'-',''))) + " - " + SubStr(oJsObj["value"][1]["dataHoraCotacao"],12,5) + "h
                Endif
            
                //Limpa Objeto
                FreeObj(oJsObj)
            Else
                If (IsBlind())
                    //ConOut(PadC("Automatic routine ended with error", 80))
                    //ConOut("Error: "+ oRestClient:GetLastError())

                    FWLogMsg("ERROR", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                        "ERROR01","MSG09","ERROR01 Automatic routine ended with error" , 0, 0, {})
                    FWLogMsg("ERROR", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                        "ERROR02","MSG10","ERROR02: "+ oRestClient:GetLastError() , 0, 0, {})
                Else
                    MsgInfo(oRestClient:GetLastError(),":: Cotação Moeda PTAX - BC API Olinda ::")
                EndIf
            Endif
        Next

     //Calculo da Média do Dólar
        FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
            "STEP16","MSG16","STEP16 - Moeda 10 - Calculo da media ")
        //zMedia10()
        //AAdd(aIdMoeda,{"MUSD",nTxMd10,0,cPerMd10})

        //MATA090 - SM2 -> M2_DATA / M2_MOEDA8
        DbSelectArea('SM2')
        SM2->(DbSetOrder(1)) //M2_DATA
        SM2->(DbGoTop())

        FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                 "STEP10","MSG12","STEP10 - Tabela SM2 posicionada: " + cValToChar(SM2->M2_DATA))

        If SM2->( MsSeek(dDataBase) )
            FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                        "STEP11","MSG13","STEP11 - Tabela SM2 posicionada na " + cValToChar(SM2->M2_DATA) + " conforme filtro "+ cValToChar(dDataBase))

            RecLock('SM2', .F.)
                M2_MOEDA2  := aIdMoeda[1][3] 
                M2_MOEDA4  := aIdMoeda[2][2]
                M2_MOEDA5  := aIdMoeda[3][2]
                M2_MOEDA6  := aIdMoeda[4][2]
                M2_MOEDA7  := aIdMoeda[5][2]
                M2_MOEDA8  := aIdMoeda[1][3]
            //    M2_MOEDA9  := aIdMoeda[6][2]
            //    M2_MOEDA10 := nTxMd10
            SM2->(MsUnlock())

            FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                        "STEP12","MSG14","STEP12 - RecLok executado " )

        EndIf

        SM2->(DbCloseArea())

        aParam := AClone( zMntMail(aIdMoeda) )
        U_GDMAIL01( aParam[1][1], aParam[1][2], aParam[1][3])


        FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
            "STEP15","MSG15","STEP15 - Disparo do e-mail " )

    Recover
		ErrorBlock( bError )

        If (IsBlind())
            //ConOut(PadC("Automatic routine ended with error", 80))
            //ConOut("Error: "+ oRestClient:GetLastError())
            FWLogMsg("ERROR", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                "ERROR03","MSG15","ERROR03 Automatic routine ended with error" , 0, 0, {})
            FWLogMsg("ERROR", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                "ERROR04","MSG16","ERROR04: "+ oRestClient:GetLastError() , 0, 0, {})
        Else
            MsgStop( cError ,":: Cotação Moeda PTAX - BC API Olinda ::")
        EndIf

	End Sequence

    FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
            "STEP13","MSG17","STEP13 - END SEQUENCE" )

    RpcClearEnv()   //Libera o Ambiente

    FWLogMsg("INFO", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
        "STEP14","MSG18","STEP14- Ambiente liberado. FIM." )

    ConOut("GDCTXMD1 - FIM")
        
Return

/*/{Protheus.doc} zMntMail 
        Monta o texto em HTML que será exibido no corpo do e-mail 
    @type Function 
    @author Maicon Macedo 
    @since 20/08/2021 
    @version 1.0 
/*/
Static Function zMntMail(aDados)
    Local cAssunto := ''
    Local cTexto   := ''
    Local cPara    := ''
    Local aRet     := {}
    Local n        := 0

    cAssunto := '[GDCTXMD1 - Cotação das Moedas] - Enviado em '+dToC(Date())+ ' ' + Time() 

    cPara := 'maicon.macedo@fatec.sp.gov.br'

    cTexto   += '<html xmlns="http://www.w3.org/1999/xhtml">' 
    cTexto   += '<head><title></title><meta charset="utf-8">'

    cTexto   += '<style type="text/css"> '
    cTexto   += '   p { font-family: "Lucida Sans Unicode", "Lucida Grande", Sans-Serif; font-size: 18px; text-align: left; } '
    cTexto   += '   p:first-line { font-family: "Lucida Sans Unicode", "Lucida Grande", Sans-Serif; font-size: 22px; text-align: left; font-weight: bold; }'
    cTexto   += '</style> '
    cTexto   += '</head>'
    cTexto   += '<body>'
    cTexto   += '<ul>'
    cTexto   += '<p>'+cAssunto+'.</p>'

    For n := 1 To Len(aDados)
        If !Empty( aDados[n][4] )
            cTexto   += '<hr>'
            cTexto   += '<p>Cotação da Moeda: ' + aDados[n][1] + '<br>'
            cTexto   += '<b>Data:</b> ' + aDados[n][4] + '<br>'
            cTexto   += '<b>Cotação de Compra:</b> ' + Transform( aDados[n][3], "@E 999.999999") + '<br>'
            cTexto   += '<b>Cotação de Venda:</b> '  + Transform( aDados[n][2], "@E 999.999999") + '<br><br></p>'
        EndIf
    Next

    cTexto   += '<br><br>'
    cTexto   += '<hr>'
    cTexto   += '<p>Fonte: Banco Central do Brasil<br>'
    cTexto   += 'Recurso: https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/aplicacao#!/recursos/CotacaoMoedaPeriodoFechamento </p>'
    cTexto   += '</ul>'

    If !Empty(cMsgMd10)
        cTexto   += '<ul>'
        cTexto   += '<hr>'
        cTexto   += '<p><b>Média do Dólar para Moeda 10: '+ Transform( nTxMd10, "@E 999.999999")+'</b></p>'
        cTexto   += '<p>Cotação do Período de: '+cPerMd10+':</p>'
        cTexto   += '<table border="1">'
        cTexto   += '<tr> <td>Data</td> <td>Cotação de Compra</td> <td>Cotação de Venda</td> </tr>'
        cTexto   += cMsgMd10
        cTexto   += '</table>'
        cTexto   += '<p>Fonte: Banco Central do Brasil<br>'
        cTexto   += 'Recurso: https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/aplicacao#!/recursos/CotacaoDolarPeriodo </p>'
        cTexto   += '</ul>'
    EndIf

    cTexto   += '<br><br>'
    cTexto   += '<hr>'
    cTexto   += '<p>Gerado automaticamente por Protheus '+ GetRPORelease() +' ('+GetBuild()+') <br>'
    cTexto   += ' Equipe de TI - MaicoSoft </p>'
    cTexto   += '</ul>'
    cTexto   += '</body>'
    cTexto   += '</html>'

    AAdd(aRet,{cAssunto,cTexto,cPara})

Return (aRet)

/*/{Protheus.doc} zMedia10 
        Função utilizada para calcular a média do dólar de venda para Moeda 10 
    @type Function 
    @author Maicon Macedo 
    @since 27/09/2021 
    @version 1.0 
/*/
Static Function zMedia10()
    Local aArea     := GetArea()
    Local aAreaSM2  := SM2->(GetArea())
    Local bError
    Local aHeader   := {}
    Local dData     := dDataBase
    Local dDtIni    := ""
    Local cDtIni    := ""
    Local dDtFin    := ""
    Local cDtFin    := ""
    Local oRest
    Local jJsObj
    Local cJsonRt2  := ''
    Local nSomaTx   := 0
    Local nx        := 0

    bError := ErrorBlock( {|e| cError := e:Description } )

    Begin Sequence
        DbSelectArea('SM2')
        SM2->(DbSetOrder(1)) //M2_DATA
        SM2->(DbGoTop())

        If Day(dData) == 1 //dData := CtoD('01/10/2021') ou StoD('20211001')
            /* Calcular a média da taxa do dólar no mês anterior */
            dData   := dData - 1
            dDtIni  := DToS( FirstDate(dData) )
            cDtIni  := SubStr(dDtIni,5,2) + '-' + SubStr(dDtIni,7,2) + '-' + SubStr(dDtIni,1,4)
            dDtFin  := DToS( LastDate(dData) )
            cDtFin  := SubStr(dDtFin,5,2) + '-' + SubStr(dDtFin,7,2) + '-' + SubStr(dDtFin,1,4)
            
            AAdd(aHeader,'User-Agent: Mozilla/5.0 (compatible; Protheus ' + GetBuild() + ')')
            AAdd(aHeader,'Content-Type: application/json; charset=utf-8')
            oRest := FWRest():New("https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata")
            oRest:setPath("/CotacaoDolarPeriodo(dataInicial=@dataInicial,dataFinalCotacao=@dataFinalCotacao)?@dataInicial='"+cDtIni+"'&@dataFinalCotacao='"+cDtFin+"'&$top=1000&$format=json&$select=cotacaoCompra,cotacaoVenda,dataHoraCotacao")
            oRest:Get(aHeader)

            jJsObj := JsonObject():New()
            cJsonRt2 := jJsObj:FromJson(oRest:GetResult())

            If ValType(cJsonRt2) == 'U' //NIL
                For nx := 1 to Len(jJsObj["value"])
 
                    cMsgMd10 += '<tr>'
                    cMsgMd10 += ' <td>'+DToC(SToD(StrTran(SubStr(jJsObj["value"][nx]["dataHoraCotacao"],1,10),'-',''))) 
                    cMsgMd10 += " - " +SubStr(jJsObj["value"][nx]["dataHoraCotacao"],12,5) + 'h </td>'
                    cMsgMd10 += ' <td>'+Transform(jJsObj["value"][nx]["cotacaoCompra"] , "@E 999.999999")+'</td>
                    cMsgMd10 += ' <td>'+Transform(jJsObj["value"][nx]["cotacaoVenda"]  , "@E 999.999999") +'</td>' 
                    cMsgMd10 += '</tr>'

                    nSomaTx += jJsObj["value"][nx]["cotacaoVenda"]

                Next

                nTxMd10  := ROUND( nSomaTx / --nx , 6)
                cPerMd10 := cValToChar(SToD(dDtIni)) + " a " + cValToChar(SToD(dDtFin))

                FreeObj(jJsObj)

            Else
                If (IsBlind())
                    FWLogMsg("ERROR", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                        "ERROR01","MSG09","ERROR01 Automatic routine ended with error" , 0, 0, {})
                    FWLogMsg("ERROR", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                        "ERROR02","MSG10","ERROR02: "+ oRest:GetLastError() , 0, 0, {})
                Else
                    MsgInfo(oRest:GetLastError(),":: Cotação Moeda PTAX - BC API Olinda ::")
                EndIf
            Endif

        ElseIf SM2->( MsSeek( FirstDate(dDataBase) ) )

            nTxMd10  := SM2->M2_MOEDA10
            cPerMd10 := cValToChar(DToC(FirstDate(dDataBase)))

        Else
            MsgAlert('Erro',"erro")
        EndIf
    Recover
		ErrorBlock( bError )

        If (IsBlind())
            FWLogMsg("ERROR", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                "ERROR03","MSG15","ERROR03 Automatic routine ended with error" , 0, 0, {})
            FWLogMsg("ERROR", /*cTransactionId*/, "API_REST_OLINDA","EVENTVIEWER",;
                "ERROR04","MSG16","ERROR04: "+ oRestClient:GetLastError() , 0, 0, {})
        Else
            MsgStop( cError ,":: Cotação Moeda PTAX - BC API Olinda ::")
        EndIf

    End Sequence

    RestArea(aAreaSM2)
    RestArea(aArea)
Return

/*/{Protheus.doc} fFeriado 
        Função utilizada para consultar as datas de feriado federais onde não há expediente do Banco Central
        Resolução 4.880 (23.12.2020) - Conselho Monetário Nacional: os feriados mencionados não são considerados 
        dias úteis para fins de operações praticadas no mercado financeiro e de prestação de informações ao Banco Central do Brasil, 
        incluindo sábados e domingos. 
    @type Function 
    @author Maicon Macedo 
    @since 18/10/2021 
    @version 1.0 
    @see
        FEBRABAN - Feriados Federais: https://feriadosbancarios.febraban.org.br 
        API de Calendários - https://elekto.com.br/Blog/ComoConsumirApiDeCalendarios | https://elekto.com.br/api/Calendars/br-SP 
/*/
Static Function fFeriado()
    Local aFeriado := {} // {"ddmm","descricao"}
    Local aParam   := {}

    AAdd(aFeriado,{'0101','Dia Mundial da Paz'})
    AAdd(aFeriado,{'2104','Dia de Tiradentes'})
    AAdd(aFeriado,{'0105','Dia do Trabalho'})
    AAdd(aFeriado,{'0709','Dia da Independência'})
    AAdd(aFeriado,{'1210','Dia de Nossa Senhora da Conceicão Aparecida'})
    AAdd(aFeriado,{'0211','Dia de Finados'})
    AAdd(aFeriado,{'1511','Dia da Proclamação da República'})
    AAdd(aFeriado,{'2512','Natal'})

    //Feriados móveis
    aParam := AClone( fFeMov() )
    
    AAdd(aFeriado,{Left(cValToChar(aParam[1][1]),4),'Páscoa'            })
    AAdd(aFeriado,{Left(cValToChar(aParam[1][2]),4),'Carnaval Segunda'  })
    AAdd(aFeriado,{Left(cValToChar(aParam[1][3]),4),'Carnaval Terça'    })
    AAdd(aFeriado,{Left(cValToChar(aParam[1][4]),4),'Paixão de Cristo'  })
    AAdd(aFeriado,{Left(cValToChar(aParam[1][5]),4),'Corpus Christi'    })

Return (aFeriado)

/*/{Protheus.doc} fFeMov
        Função utilizada para calcular os feriados móveis do Brasil
    @type Function 
    @author Maicon Macedo 
    @since 18/10/2021 
    @version 1.0 
    @see
        Feriados móveis - https://www.vbweb.com.br/dicas_visual.asp?Codigo=2033 
/*/
Static Function fFeMov()
    Local aRet        := {}
    Local nAno        := Val( Year(dDataBase) )
    Local A,B,C,D,E,F,G,H,I,K,L,M,P,Q
    Local nMesPascoa  := ""
    Local nDiaPascoa  := ""
    Local dPascoa     := ""
    Local dCarnavalS  := ""
    Local dCarnavalT  := ""
    Local dPaixao     := ""
    Local dCorpusC    := ""

    A := nAno % 19
    B := Int(nAno / 100)
    C := nAno % 100
    D := Int(B / 4)
    E := B % 4
    F := Int((B + 8) / 25)
    G := Int((B - F + 1) / 3)
    H := ( (19 * A + B - D - G + 15) % 30)
    I := Int(C / 4)
    K := (C % 4)
    L := ((32 + 2 * E + 2 * I - H - K) % 7)
    M := Int((A + 11 * H + 22 * L) / 451)
    P := Int((H + L - 7 * M + 114) / 31)
    Q := ((H + L - 7 * M + 114) % 31)
    
    nDiaPascoa := Q + 1
    nMesPascoa := P

    dPascoa     := CtoD( PadL(cValToChar(nDiaPascoa),2,'0') +"/"+ PadL(cValToChar(nMesPascoa),2,'0') +"/"+ cValToChar(nAno))
    dCarnavalS  := DaySub(dPascoa, 48)
    dCarnavalT  := DaySub(dPascoa, 47)
    dPaixao     := DaySub(dPascoa, 02)
    dCorpusC    := DaySum(dPascoa, 60)

    AAdd(aRet,{dPascoa,dCarnavalS,dCarnavalT,dPaixao,dCorpusC})
    
Return (aRet)
