#include "protheus.ch"
#include "restful.ch"

#define ID_KEY_GLB "GlbDnlTestingREST"

//-------------------------------------------------------------------
/*/{Protheus.doc} DnlTestingREST
API REST para efetuar testes de REST no Protheus - Apenas para estudos da oficna de 
"Uso pratico de API's Proteus" ministrada pelo professor Maicon Macedo inicio: 09/03

Todos os metodos gravam, consultam e apagam os dados somente em
memoria, portanto nenhum deles impacta no ambiente Protheus

Professor: Maicon Macedo (maiconsoft.tecnologia@gmail.com)
Aluno: Neemias Borges (neemiasb.dev@gmail.com)


@author Neemias Borges
@since 09/03/2024
@version 1.0
/*/
//-------------------------------------------------------------------
WSRESTFUL DnlTestingREST DESCRIPTION "REST para testes! =)"

WSDATA idJSON    AS CHAR    OPTIONAL
WSDATA HTTP_Code AS NUMERIC OPTIONAL

WSMETHOD POST   DESCRIPTION "Recebe um JSON e armazena o mesmo em memoria" WSSYNTAX "dnltestingrest/v1/jsoninmemory" PATH "dnltestingrest/v1/jsoninmemory"
WSMETHOD GET    DESCRIPTION "Retorna o JSON armazenado do ID informado" WSSYNTAX "dnltestingrest/v1/jsoninmemory/{idJSON}" PATH "dnltestingrest/v1/jsoninmemory/{idJSON}"
WSMETHOD DELETE DESCRIPTION "Deleta o JSON do ID informado" WSSYNTAX "dnltestingrest/v1/jsoninmemory/{idJSON}" PATH "dnltestingrest/v1/jsoninmemory/{idJSON}"
WSMETHOD PUT    DESCRIPTION "Atualiza o JSON do ID informado" WSSYNTAX "dnltestingrest/v1/jsoninmemory/{idJSON}" PATH "dnltestingrest/v1/jsoninmemory/{idJSON}"
WSMETHOD POST   HTTPCODE DESCRIPTION "Retorna o proprio codigo HTTP enviado, caso não seja enviado, possui um retorno aleatorio" WSSYNTAX "dnltestingrest/v1/httpcode" PATH "dnltestingrest/v1/httpcode"
WSMETHOD GET    HTTPCODE DESCRIPTION "Retorna o proprio codigo HTTP enviado, caso não seja enviado, possui um retorno aleatorio" WSSYNTAX "dnltestingrest/v1/httpcode" PATH "dnltestingrest/v1/httpcode"
WSMETHOD DELETE HTTPCODE DESCRIPTION "Retorna o proprio codigo HTTP enviado, caso não seja enviado, possui um retorno aleatorio" WSSYNTAX "dnltestingrest/v1/httpcode" PATH "dnltestingrest/v1/httpcode"
WSMETHOD PUT    HTTPCODE DESCRIPTION "Retorna o proprio codigo HTTP enviado, caso não seja enviado, possui um retorno aleatorio" WSSYNTAX "dnltestingrest/v1/httpcode" PATH "dnltestingrest/v1/httpcode"

END WSRESTFUL

//-------------------------------------------------------------------
/*/{Protheus.doc} POST
Coloca em memoria o JSON informado

@author Neemias Borges
@since 09/03/2024
@version 1.0
/*/
//-------------------------------------------------------------------
WSMETHOD POST WSSERVICE DnlTestingREST
local lResult as logical
local cID as char

if isJSONValid(self)
    lResult := .T.
    cID := postJSON(self:getContent())
    self:setStatus(201)
    self:setResponse( '{"id": "' + cID + '"}' )
else
    lResult := .F.
endif

Return lResult

//-------------------------------------------------------------------
/*/{Protheus.doc} GET
Retorna o JSON do ID informado

@author Neemias Borges
@since 09/03/2024
@version 1.0
/*/
//-------------------------------------------------------------------
WSMETHOD GET WSSERVICE DnlTestingREST
local lResult as logical
local cJSON as char

if existJSON(self)
    cJSON := GetGlbValue( ID_KEY_GLB + self:idJSON )
    lResult := .T.
    self:setStatus(200)
    self:setResponse(cJSON)
else
    lResult := .F.
endif

Return lResult

//-------------------------------------------------------------------
/*/{Protheus.doc} DELETE
Apaga o JSON do ID informado

@author Neemias Borges
@since 09/03/2024
@version 1.0
/*/
//-------------------------------------------------------------------
WSMETHOD DELETE WSSERVICE DnlTestingREST
local lResult as logical

if existJSON(self)
    lResult := .T.
    ClearGlbValue( ID_KEY_GLB + self:idJSON )
    self:setStatus(204)
else
    lResult := .F.
endif

Return lResult

//-------------------------------------------------------------------
/*/{Protheus.doc} PUT
Atualiza o JSON do ID informado

@author Neemias Borges
@since 09/03/2024
@version 1.0
/*/
//-------------------------------------------------------------------
WSMETHOD PUT WSSERVICE DnlTestingREST
local lResult as logical
local cJSON as char

if existJSON(self)
    lResult := .T.
    cJSON := self:getContent()
    putJSON(self:idJSON, cJSON)
    self:setStatus(204)
    self:setResponse(cJSON)
else
    lResult := .F.
endif

Return lResult

//-------------------------------------------------------------------
/*/{Protheus.doc} isJSONValid
Valida se o JSON informado e válido

@param oSelf Objeto da classe REST

@author Neemias Borges
@since 09/03/2024
@version 1.0
/*/
//-------------------------------------------------------------------
static function isJSONValid(oSelf)
local xError
local jJSON

jJSON := JsonObject():New()

xError := jJSON:fromJSON(oSelf:getContent())

if Empty(xError)
    lOk := .T.
else
    oSelf:setStatus(400, xError)
    lOk := .F.
endif

return lOk

//-------------------------------------------------------------------
/*/{Protheus.doc} postJSON
Grava o JSON informado na memoria global do servidor

@param cJSON JSON que será gravado na memoria global do servidor

@return cID ID que foi gerado para gravar o JSON na memoria global do servidor

@author Neemias Borges
@since 09/03/2024
@version 1.0
/*/
//-------------------------------------------------------------------
static function postJSON(cJSON)
local cID as char

cID := makeID()

PutGlbValue( ID_KEY_GLB + cID, cJSON )

return cID

//-------------------------------------------------------------------
/*/{Protheus.doc} putJSON
Atualiza o JSON informado na memoria global do servidor

@param cID ID do JSON na memoria global do servidor
@param cJSON JSON que será gravado na memoria global do servidor

@author Neemias Borges
@since 09/03/2024
@version 1.0
/*/
//-------------------------------------------------------------------
static function putJSON(cID, cJSON)

cID := ID_KEY_GLB + cID

ClearGlbValue(cID)
PutGlbValue( cID, cJSON )

return nil

//-------------------------------------------------------------------
/*/{Protheus.doc} existJSON
Verifica se o ID informado existe na memoria global do servidor

@param oSelf Objeto da classe REST

@return lExist Indica se o JSON foi encontrado na memoria

@author Neemias Borges
@since 09/03/2024
@version 1.0
/*/
//-------------------------------------------------------------------
static function existJSON(oSelf)
local cJSON as char
local lExist as logical

cJSON := GetGlbValue( ID_KEY_GLB + oSelf:idJSON )

if Empty(cJSON)
    oSelf:setStatus(404)
    lExist := .F.
else
    lExist := .T.
endif

return lExist

//-------------------------------------------------------------------
/*/{Protheus.doc} makeID
Encapsula a funcao FWUUIDv4 caso exista a necessidade de alterar
a forma que o ID e gerado

@return cID ID para persistir o JSON em memoria

@author Neemias Borges
@since 09/03/2024
@version 1.0
/*/
//-------------------------------------------------------------------
static function makeID()
local cID as char

cID := FWUUIDv4()

return cID

/* ----------------------------------------------------------------------------------------------------- */
//  Geração de codigos HTTP
/* ----------------------------------------------------------------------------------------------------- */

//-------------------------------------------------------------------
/*/{Protheus.doc} POST HTTPCODE
Retorna um codigo HTTP conforme o recebido,
caso nenhum codigo seja recebido, o retorno e aleatorio

@author Neemias Borges
@since 24/05/2019
@version 1.0
/*/
//-------------------------------------------------------------------
WSMETHOD POST HTTPCODE QUERYPARAM HTTP_Code WSSERVICE DnlTestingREST
Return ReturnHTTPCodeAPI(Self)

//-------------------------------------------------------------------
/*/{Protheus.doc} GET HTTPCODE
Retorna um codigo HTTP conforme o recebido,
caso nenhum codigo seja recebido, o retorno e aleatorio

@author Neemias Borges
@since 24/05/2019
@version 1.0
/*/
//-------------------------------------------------------------------
WSMETHOD GET HTTPCODE QUERYPARAM HTTP_Code WSSERVICE DnlTestingREST
Return ReturnHTTPCodeAPI(Self)

//-------------------------------------------------------------------
/*/{Protheus.doc} DELETE HTTPCODE
Retorna um codigo HTTP conforme o recebido,
caso nenhum codigo seja recebido, o retorno e aleatorio

@author Neemias Borges
@since 24/05/2019
@version 1.0
/*/
//-------------------------------------------------------------------
WSMETHOD DELETE HTTPCODE QUERYPARAM HTTP_Code WSSERVICE DnlTestingREST
Return ReturnHTTPCodeAPI(Self)

//-------------------------------------------------------------------
/*/{Protheus.doc} PUT HTTPCODE
Retorna um codigo HTTP conforme o recebido,
caso nenhum codigo seja recebido, o retorno e aleatorio

@author Neemias Borges
@since 24/05/2019
@version 1.0
/*/
//-------------------------------------------------------------------
WSMETHOD PUT HTTPCODE QUERYPARAM HTTP_Code WSSERVICE DnlTestingREST
Return ReturnHTTPCodeAPI(Self)

//-------------------------------------------------------------------
/*/{Protheus.doc} ReturnHTTPCodeAPI
funcao padrão para o retorno da API de testes de codigo HTTP

Gera o codigo HTTP e retorno o Boolean que a API padrão ADVPL espera

@param oSelf Objeto do serviço REST

@return Boolean, se o codigo gerado for um codigo de erro .F., caso contrário .T.

@author Neemias Borges
@since 24/05/2019
@version 1.0
/*/
//-------------------------------------------------------------------
static function ReturnHTTPCodeAPI(oSelf)
local nCode as numeric

nCode := getCode(oSelf)

SetRestFault(nCode)

return !IsErrorCode(nCode)

//-------------------------------------------------------------------
/*/{Protheus.doc} getCode
Retorna um codigo HTTP que será usado no retorno da API

@param oSelf Objeto do serviço REST

@return nCod Codigo HTTP, sendo entre 2XX ate 5XX

@author Neemias Borges
@since 24/05/2019
@version 1.0
/*/
//-------------------------------------------------------------------
static function getCode(oSelf)
local nCod as numeric

if isCodeValid(oSelf)
    nCod := oSelf:HTTP_Code
else
    nCod := getRandomCode()
endif

return nCod

//-------------------------------------------------------------------
/*/{Protheus.doc} isCodeValid
Verifica se o codigo HTTP recebido via query param e válido,
caso seja, a propriedade da classe tambem pode ser convertida para
numerica caso seja recebida como string

@param oSelf Objeto REST

@return lValid Indica se o codigo recebido e válido

@author Neemias Borges
@since 27/05/2019
@version 1.0
/*/
//-------------------------------------------------------------------
static function isCodeValid(oSelf)
local lValid as logical

if oSelf:HTTP_Code != nil
    if ValType(oSelf:HTTP_Code) != "N"
        oSelf:HTTP_Code := Val(oSelf:HTTP_Code)
    endif

    lValid := oSelf:HTTP_Code >= 200 .and. oSelf:HTTP_Code <= 599
else
    lValid := .F.
endif

return lValid

//-------------------------------------------------------------------
/*/{Protheus.doc} getRandomCode
Gera um codigo entre 200, 300, 400 e 500 de forma aleatoria

@return Numeric, Codigo HTTP, sendo entre 2XX ate 5XX

@author Neemias Borges
@since 24/05/2019
@version 1.0
/*/
//-------------------------------------------------------------------
static function getRandomCode()
return Randomize( 2, 6 ) * 100

//-------------------------------------------------------------------
/*/{Protheus.doc} IsErrorCode
Retorna se trata-se de um codigo de erro

@param nCode Codigo HTTP

@return Boolean, Indica se o codigo HTTP e de erro

@author Neemias Borges
@since 24/05/2019
@version 1.0
/*/
//-------------------------------------------------------------------
static function IsErrorCode(nCode)
return nCode >= 400