#include "TOTVS.CH"
#include "RESTFUL.CH"


WSRESTFUL WSRESTCLI DESCRIPTION "Serviço REST para INTEGRAÇÃO DE CLIENTES|SA1"

    WSDATA CODCLIENTEDE     AS STRING
    WSDATA CODCLIENTEATE    AS STRING

    WSMETHOD GET buscarcliente;
        DESCRIPTION "Retorna dados do Cliente";
            WSSYNTAX "/buscarcliente";
                PATH "buscarcliente";
                    PRODUCES APPLICATION_JSON

    WSMETHOD POST incluircliente;
        DESCRIPTION "Insere dados do Cliente";
            WSSYNTAX "/incluircliente";
                PATH "incluircliente";
                    PRODUCES APPLICATION_JSON                

    WSMETHOD PUT atualizarcliente;
        DESCRIPTION "Atualiza dados do Cliente";
            WSSYNTAX "/atualizarcliente";
                PATH "atualizarcliente";
                    PRODUCES APPLICATION_JSON  

    WSMETHOD DELETE deletarcliente;
        DESCRIPTION "Deleta o cliente através do parametro";
            WSSYNTAX "/deletarcliente";
                PATH "deletarcliente";
                    PRODUCES APPLICATION_JSON 

ENDWSRESTFUL


//Criando método GET buscarcliente
//     [VERBO]  [DESCRICAO/ID]       [    PARAMETROS           ]             [WEBSERVICE A QUAL O MÉDOTO PERTENCE]
WSMETHOD GET    buscarcliente       WSRECEIVE CODCLIENTEDE, CODCLIENTEATE        WSREST WSRESTCLI
    Local lRet          := .T.
    Local nCount        := 1  // Contador do laço de repetição WHILE que será utilizado como índice do array com Json
    Local nRegistros    := 0  //Conta o número de registros vindos no SELECT feito em SQL
    //Variáveis que recebem os parametros | convertemos em caractere justamente porque elas serão concatenadas com texto, e elas são número
    Local cCodDe        :=  cValtoChar(Self:CODCLIENTEDE)
    Local cCodAte       :=  cValToChar(Self:CODCLIENTEATE)
    Local aListClientes := {}  //Array que receberá os dados dos clientes que virão do banco de dados
    //Objeto e string Json para recebimento do array com Json Serializado e depois como texto
    Local oJson         := JsonObject():New()
    Local cJson         := ""
    /*Pega um nome de Alias automaticamente para armazenamento dos dados do SELECT 
    evitando que fique travado caso várias pessoas acessem o mesmo aAlias*/
    Local cAlias        := GetNextAlias()
    //Armazenará o filtro do SELECT
    Local cWhere        := "" 

    //Imagine que o usuário para testar a aplicação coloque um códigoDe maior que um CódigoAté
    IF Self:CODCLIENTEDE > Self:CODCLIENTEATE
        cCodDe   :=  cValToChar(Self:CODCLIENTEATE) 
        cCodAte  :=  cValtoChar(Self:CODCLIENTEDE)
    ENDIF

    //Por isso o motivo de convertermos as variávies de parametro para caracter
    cWhere  := " AND SA1.A1_COD BETWEEN '"+cCodDe+"' AND '"+cCodAte+"' AND SA1.A1_FILIAL = '"+xFilial("SA1")+"' "

    //Dica para transformar o cWhere em filtro / Tratamento para retirar as aspas que ficam automaticamente
    cWhere  := "%"+cWhere+"%"

    /*Buscaremos os seguintes campos:
        CODIGO, LOJA, NOME, NOMEREDUZIDO, ENDEREÇO, ESTADO, BAIRRO, CIDADE, CGC
    */
    BEGINSQL Alias cAlias
        SELECT SA1.A1_COD, SA1.A1_LOJA, SA1.A1_NOME, SA1.A1_NREDUZ, SA1.A1_END, SA1.A1_EST, SA1.A1_BAIRRO, SA1.A1_MUN, SA1.A1_CGC
            FROM %table:SA1% SA1
        WHERE SA1.%notDel% 
        %exp:cWhere%
    ENDSQL

    //Conto quantos registros vieram e armazeno na variável nRegistros
    Count to nRegistros

    //Posiciono no primeiro registro
    (cAlias)->(DbGoTop())

    //Enquanto não chegar ao final do arquivo End Of Files(EOF)
    WHILE (cAlias)->(!EOF())
        aAdd(aListClientes,JsonObject():New())
            aListClientes[nCount]["clicodigo"]      := (cAlias)->A1_COD
            aListClientes[nCount]["cliloja"]        := (cAlias)->A1_LOJA
            aListClientes[nCount]["clinome"]        := AllTrim(EncodeUTF8((cAlias)->A1_NOME))
            aListClientes[nCount]["clinomereduz"]   := AllTrim(EncodeUTF8((cAlias)->A1_NREDUZ))
            aListClientes[nCount]["cliendereco"]    := (cAlias)->A1_END
            aListClientes[nCount]["cliestado"]      := (cAlias)->A1_EST
            aListClientes[nCount]["clicidade"]      := (cAlias)->A1_MUN
            aListClientes[nCount]["clibairro"]      := (cAlias)->A1_BAIRRO
            aListClientes[nCount]["clicgc"]         := (cAlias)->A1_CGC
        nCount++ //Incremento a variável para pegar o próximo índice do array correspondente ao próximo registro

        (cAlias)->(DbSkip()) //Passo para o próximo registro
    ENDDO

    //Fecho a área/alias aberto
    (cAlias)->(DbCloseArea())

    IF nRegistros > 0
        oJson["clientes"]   := aListClientes //Atribuo ao objeto oJson o array com dados dos clientes

        cJson := FwJsonSerialize(oJson) //Serializo o Json e passo para a variável texto

        ::SetResponse(cJson) //Retorno o Json para o usuário
    ELSE //Se não tiver registros ele retorna um erro
        SetRestFault(400,EncodeUTF8("Não existem registros/CLIENTES para os filtros informados! Por favor VERIFIQUE e tente novamente."))
        lRet    := .F.
        Return(lRet)
    ENDIF

    //Libero o Objeto de Json
    FreeObj(oJson)

Return lRet


//Criando o método POST / INCLUIR CLIENTES
WSMETHOD POST incluircliente WSRECEIVE WSREST WSRESTCLI
    Local lRet  := .T.
    Local aArea := GetArea()
    //Instancia da Classe JSonObject
    Local oJson     := JsonObject():New()
    Local oReturn   := JSonObject():New()

    //Vai carregar os dados vindos da String/Body/Corpo da requisção que estará em Json
    oJson:FromJson(Self:GetContent()) //GetContent pega o conteúdo do Json

    //Verificamos se o CÓDIGO  e LOJA estão preenchidos
    IF Empty(oJson["clientes"]:GetJsonObject("clicodigo")) .OR. Empty(oJson["clientes"]:GetJsonObject("cliloja"))
        SetRestFault(400,EncodeUTF8('CÓDIGO OU LOJA DO CLIENTE ESTÃO EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
        lRet := .F.
        Return(lRet)

    ELSE //Se não estiverem em branco ele busca e verifica se o cliente já existe
        DbSelectArea("SA1")
        SA1->(DbSetOrder(1))

        IF SA1->(DbSeek(xFilial("SA1")+oJson["clientes"]:GetJsonObject("clicodigo")+oJson["clientes"]:GetJsonObject("cliloja")))
            SetRestFault(401,EncodeUTF8('CÓDIGO/LOJA JÁ EXISTEM, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)    
        //Senão encontrar ele verificará se existe algum campo em branco

        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("clinome"))
            SetRestFault(402,EncodeUTF8('NOME EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)   

        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("clinomereduz"))
            SetRestFault(403,EncodeUTF8('NOME REDUZIDO EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)  

        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("cliendereco"))
            SetRestFault(404,EncodeUTF8('ENDEREÇO EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)   
        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("cliestado"))
            SetRestFault(405,EncodeUTF8('ESTADO EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)   

        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("clicidade"))
            SetRestFault(406,EncodeUTF8('CIDADE EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)   

        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("clibairro"))
            SetRestFault(407,EncodeUTF8('BAIRRO EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)       

        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("clicgc"))
            SetRestFault(408,EncodeUTF8('CGC/CPF EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)  
        ELSE //SE ESTIVER TUDO CERTO, FARÁ UM RECLOCK  
            RECLOCK("SA1",.T.)        
                SA1->A1_COD         :=  oJson["clientes"]:GetJsonObject("clicodigo")
                SA1->A1_LOJA        :=  oJson["clientes"]:GetJsonObject("cliloja")
                SA1->A1_NOME        :=  oJson["clientes"]:GetJsonObject("clinome")
                SA1->A1_NREDUZ      :=  oJson["clientes"]:GetJsonObject("clinomereduz")
                SA1->A1_END         :=  oJson["clientes"]:GetJsonObject("cliendereco")
                SA1->A1_EST         :=  oJson["clientes"]:GetJsonObject("cliestado")
                SA1->A1_MUN         :=  oJson["clientes"]:GetJsonObject("clicidade")
                SA1->A1_BAIRRO      :=  oJson["clientes"]:GetJsonObject("clibairro")
                SA1->A1_CGC         :=  oJson["clientes"]:GetJsonObject("clicgc")
                SA1->A1_MSBLQL      := "1"
            SA1->(MsUnlock())
        ENDIF

        SA1->(DbCloseArea())

        oReturn["clicodigo"]    := oJson["clientes"]:GetJsonObject("clicodigo")
        oReturn["cliloja"]      := oJson["clientes"]:GetJsonObject("cliloja")
        oReturn["clinome"]      := EncodeUTF8(oJson["clientes"]:GetJsonObject("clinome"))
        oReturn["cRet"]     := "201 - Sucesso!"
        oReturn["cMessage"] := EncodeUTF8("Registro Incluído com Sucesso no Banco de dados, por favor insira o restante dos dados via Protheus")

        Self:SetStatus(201)
        Self:SetContentType(APPLICATION_JSON) //Tipo de conteúdo retornado JSON
        Self:SetResponse(FwJSonSerialize(oReturn)) //Serializo o objeto oReturn para Json e retorno para o usuário

    ENDIF

    RestArea(aArea)
    FreeObj(oJson)
    FreeObj(oReturn)

return lRet


//Criando o método PUT / ATUALIZAR CLIENTES
WSMETHOD PUT atualizarcliente WSRECEIVE WSREST WSRESTCLI
    Local lRet  := .T.
    Local aArea := GetArea()
    //Instancia da Classe JSonObject
    Local oJson     := JsonObject():New()
    Local oReturn   := JSonObject():New()

    //Vai carregar os dados vindos da String/Body/Corpo da requisção que estará em Json
    oJson:FromJson(Self:GetContent()) //GetContent pega o conteúdo do Json

    //Verificamos se o CÓDIGO  e LOJA estão preenchidos
    IF Empty(oJson["clientes"]:GetJsonObject("clicodigo")) .OR. Empty(oJson["clientes"]:GetJsonObject("cliloja"))
        SetRestFault(400,EncodeUTF8('CÓDIGO OU LOJA DO CLIENTE ESTÃO EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
        lRet := .F.
        Return(lRet)

    ELSE //Se não estiverem em branco ele busca e verifica se o cliente já existe
        DbSelectArea("SA1")
        SA1->(DbSetOrder(1))

        IF !SA1->(DbSeek(xFilial("SA1")+oJson["clientes"]:GetJsonObject("clicodigo")+oJson["clientes"]:GetJsonObject("cliloja")))
            SetRestFault(401,EncodeUTF8('CÓDIGO/LOJA NÃO EXISTEM NO SISTEMA, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)    
        //Senão encontrar ele verificará se existe algum campo em branco
        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("clinome"))
            SetRestFault(402,EncodeUTF8('NOME EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)   

        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("clinomereduz"))
            SetRestFault(403,EncodeUTF8('NOME REDUZIDO EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)  

        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("cliendereco"))
            SetRestFault(404,EncodeUTF8('ENDEREÇO EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)   
        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("cliestado"))
            SetRestFault(405,EncodeUTF8('ESTADO EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)   

        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("clicidade"))
            SetRestFault(406,EncodeUTF8('CIDADE EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)   

        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("clibairro"))
            SetRestFault(407,EncodeUTF8('BAIRRO EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)       

        ELSEIF  Empty(oJson["clientes"]:GetJsonObject("clicgc"))
            SetRestFault(408,EncodeUTF8('CGC/CPF EM BRANCO, OPERAÇÃO INVÁLIDA')) //Setando um erro
            lRet := .F.
            Return(lRet)  
        ELSE //SE ESTIVER TUDO CERTO, FARÁ UM RECLOCK  
            RECLOCK("SA1",.F.)        
                SA1->A1_NOME        :=  oJson["clientes"]:GetJsonObject("clinome")
                SA1->A1_NREDUZ      :=  oJson["clientes"]:GetJsonObject("clinomereduz")
                SA1->A1_END         :=  oJson["clientes"]:GetJsonObject("cliendereco")
                SA1->A1_EST         :=  oJson["clientes"]:GetJsonObject("cliestado")
                SA1->A1_MUN         :=  oJson["clientes"]:GetJsonObject("clicidade")
                SA1->A1_BAIRRO      :=  oJson["clientes"]:GetJsonObject("clibairro")
                SA1->A1_CGC         :=  oJson["clientes"]:GetJsonObject("clicgc")
            SA1->(MsUnlock())
        ENDIF

        SA1->(DbCloseArea())

        oReturn["clicodigo"]    := oJson["clientes"]:GetJsonObject("clicodigo")
        oReturn["cliloja"]      := oJson["clientes"]:GetJsonObject("cliloja")
        oReturn["clinome"]      := EncodeUTF8(oJson["clientes"]:GetJsonObject("clinome"))
        oReturn["cRet"]     := "201 - Sucesso!"
        oReturn["cMessage"] := EncodeUTF8("Registro ALTERADO com Sucesso no Banco de dados")

        Self:SetStatus(201)
        Self:SetContentType(APPLICATION_JSON) //Tipo de conteúdo retornado JSON
        Self:SetResponse(FwJSonSerialize(oReturn)) //Serializo o objeto oReturn para Json e retorno para o usuário
    ENDIF

    RestArea(aArea)
    FreeObj(oJson)
    FreeObj(oReturn)

return lRet

//Criando método DELETE para excluir vários CLIENTES desconsiderando loja
WSMETHOD DELETE deletarcliente WSRECEIVE CODCLIENTEDE, CODCLIENTEATE WSREST WSRESTCLI
    Local lRet      := .T.
    Local cCodDe    := SELF:CODCLIENTEDE
    Local cCodAte   := Self:CODCLIENTEATE
    Local aArea     := GetArea()
    Local oReturn   := JsonObject():New()
    Local nCount    := 0 //Contará a quantidade de clientes DELETADOS

    //Imagine que o usuário para testar a aplicação coloque um códigoDe maior que um CódigoAté
    IF Self:CODCLIENTEDE > Self:CODCLIENTEATE
        cCodDe        :=  cValToChar(Self:CODCLIENTEATE) 
        cCodAte       :=  cValtoChar(Self:CODCLIENTEDE)
    ENDIF

    //Seleciono a área
    DbSelectArea("SA1")
    SA1->(DbSetOrder(1)) //Ordeno pelo índice 1 FILIAL+CODIGO

    SA1->(DbGoTop()) //Posiciona no Primeiro Registro

    //Começará o While com o que foi posicionado
    WHILE SA1->(!EOF()) .AND. (SA1->A1_COD >= cCodDe .AND. SA1->A1_COD  <= cCodAte)

        IF SA1->(DbSeek(xFilial("SA1")+SA1->A1_COD))    
            RecLock("SA1",.F.) //Se encontrar o produto que está no filtro, ele irá deletar
                DbDelete()
            SA1->(MsUnlock())
            
            nCount++ //Adiciono + 1 ao contador de DELETADOS
        ENDIF

        SA1->(DbSkip())
    ENDDO

    SA1->(dbCloseArea())

        IF nCount > 0
            oReturn["proddeletados"]  := EncodeUTF8("Foram deletados "+cValToChar(nCount)+" registros do banco de dados")
            oReturn["cRet"]     := "201 - Sucesso!"
            oReturn["cMessage"] := "Registro(s) EXCLUIDO(S) com SUCESSO!"

            Self:SetStatus(201)
            Self:SetContentType(APPLICATION_JSON) //Tipo de conteúdo retornado JSON
            Self:SetResponse(FwJSonSerialize(oReturn)) //Serializo o objeto oReturn para Json e retorno para o usuário          
        ELSE
            SetRestFault(401,'NÃO FORAM ENCONTRADOS REGISTROS PARA SEREM DELETADOS')
            lRet := .F.
            Return(lRet)
        ENDIF
        
    RestArea(aArea)
    FreeObj(oReturn)
Return lRet

/* Modelo de Json
    {
    "clientes": 
        {
            "clicodigo": "000040",
            "cliloja": "01",
            "clinome": "MESTRE DOS RESTS WS",
            "clinomereduz": "MESTRE DOS RESTS",
            "cliendereco": "RUA DO WEBSERVICE",
            "cliestado": "BA",
            "clicidade": "TEIXEIRA DE FREITAS",
            "clibairro": "BAIRRO DA INTEGRACAO",
            "clicgc": "00022255589"        
        }
    }
*/





