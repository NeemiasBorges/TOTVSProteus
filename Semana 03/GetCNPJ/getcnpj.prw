#include 'totvs.ch'

/*/{Protheus.doc} getCNPJ
		Gatilho para o cadastro de cliente e fornecedor. 
	@type function
	@version 1.0 
	@author Maicon Macedo
	@since 01/08/2023
	@param cTab, character, Passar a tabela (SA1 ou SA2)
	@param cCNPJ, character, CNPJ
	@Return character, razão social		
	@obs
		Exemplo de cadastro do gatilho:
		Campo		: A1_CGC ou A2_CGC
		Cnt. Dominio: A1_NOME ou A2_NOME
		Tipo		: 1
		Regra		: u_getCNPJ('SA1',M->A1_CGC) ou u_getCNPJ('SA2',M->A2_CGC) 
		Posiciona	: 2
		Condicao	: !empty(M->A1_CGC) ou !empty(M->A2_CGC)
	@see
		https://github.com/cnpj-ws/protheus
	@history 
/*/
User Function getCNPJ(cTab,cCNPJ)
	Local aArea:= {CC3->(getArea()), SYA->(getArea()), getArea()}
	Local cRet := ''
	Default cTab := 'SA1'
	Default cCNPJ:= ''

	cCNPJ:= allTrim(cCNPJ)

	If !empty(cTab) .and. len(cCNPJ) == 14
		If isBlind()
			cRet:= consulta(cTab,cCNPJ)
		Else
			FWMsgRun(,{||cRet:= consulta(cTab,cCNPJ)},'CNPJ.ws','Consultando...')
		EndIf
	EndIf

	aEval(aArea, {|x| RestArea(x)})

	If Empty(cRet)
		If "A1_" $ ReadVar()
			Left(M->A1_NOME, TAMSX3("A1_NOME")[1])
		Else
			Left(M->A2_NOME, TAMSX3("A2_NOME")[1])
		EndIf
	EndIf

Return cRet

static function consulta(cTab,cCNPJ)
	Local oCNPJws:= CNPJws():new()
	Local oJSON  := nil
	Local nX     := 1
	Local cRet   := ''
	Local lJob   := isBlind()
	Local oModel := nil

	If oCNPJws:consultarCNPJ(cCNPJ)
		oJSON:= oCNPJws:getResponse()

		cRet:= oJSON['razao_social']

		If oJSON['estabelecimento']['situacao_cadastral'] <> 'Ativa'
			If lJob
				conout(cCNPJ + ': A situação cadastral da empresa junto a SEFAZ é ' + oJSON['estabelecimento']['situacao_cadastral'])
			Else
				alert('A situação cadastral da empresa junto a SEFAZ é ' + oJSON['estabelecimento']['situacao_cadastral'])
			EndIf
		EndIf

		If cTab == 'SA1'

			M->A1_MSBLQL:= If(oJSON['estabelecimento']['situacao_cadastral'] == 'Ativa','2','1')
			If ExistTrigger('A1_MSBLQL')
				RunTrigger(1,Nil,Nil,,'A1_MSBLQL')
			EndIf

			M->A1_CNAE:= oJSON['estabelecimento']['atividade_principal']['id']

			CC3->(dbSetOrder(1))
			If !CC3->(dbSeek(xFilial('CC3')+M->A1_CNAE))
				reclock('CC3',.t.)
				CC3->CC3_FILIAL	:= xFilial('CC3')
				CC3->CC3_COD		:= oJSON['estabelecimento']['atividade_principal']['id']
				CC3->CC3_DESC		:= upper(oJSON['estabelecimento']['atividade_principal']['descricao'])
				CC3->CC3_CSECAO	:= oJSON['estabelecimento']['atividade_principal']['secao']
				CC3->CC3_CDIVIS	:= oJSON['estabelecimento']['atividade_principal']['divisao']
				CC3->CC3_CGRUPO	:= strTran(oJSON['estabelecimento']['atividade_principal']['grupo'],'.')
				CC3->CC3_CCLASS	:= strTran(strTran(oJSON['estabelecimento']['atividade_principal']['classe'],'.'),'-')
				CC3->(msUnlock())
			EndIf
			If ExistTrigger('A1_CNAE')
				RunTrigger(1,Nil,Nil,,'A1_CNAE')
			EndIf

			M->A1_PESSOA	:= 'J'
			If ExistTrigger('A1_PESSOA')
				RunTrigger(1,Nil,Nil,,'A1_CNAE')
			EndIf

			If !empty(oJSON['estabelecimento']['pais']['id'])
				CCH->(dbSetOrder(1))
				If CCH->(dbSeek(xFilial('CCH')+ '0' + oJSON['estabelecimento']['pais']['id'] ))
					M->A1_CODPAIS	:=  CCH->CCH_CODIGO
					If ExistTrigger('A1_CODPAIS')
						RunTrigger(1,Nil,Nil,,'A1_CODPAIS')
					EndIf
				EndIf

				SYA->(dbSetOrder(2))
				If SYA->(dbSeek(xFilial('SYA')+ upper(oJSON['estabelecimento']['pais']['nome'])))
					M->A1_PAIS	:= SYA->YA_CODGI
					If ExistTrigger('A1_PAIS')
						RunTrigger(1,Nil,Nil,,'A1_PAIS')
					EndIf
				EndIf
			EndIf

			M->A1_NREDUZ := oJSON['estabelecimento']['nome_fantasia']

			If empty(M->A1_NREDUZ) //Caso nao possua nome fantasia
				M->A1_NREDUZ := avKey(cRet, 'A1_NREDUZ')
			EndIf

			If ExistTrigger('A1_NREDUZ')
				RunTrigger(1,Nil,Nil,,'A1_NREDUZ')
			EndIf

			M->A1_CEP		:= oJSON['estabelecimento']['cep']
			If ExistTrigger('A1_CEP')
				RunTrigger(1,Nil,Nil,,'A1_CEP')
			EndIf

			M->A1_EST		:= oJSON['estabelecimento']['estado']['sigla']
			If ExistTrigger('A1_EST')
				RunTrigger(1,Nil,Nil,,'A1_EST')
			EndIf

			M->A1_COD_MUN:= substring(cValToChar(oJSON['estabelecimento']['cidade']['ibge_id']),3,5)
			If ExistTrigger('A1_COD_MUN')
				RunTrigger(1,Nil,Nil,,'A1_COD_MUN')
			EndIf

			M->A1_BAIRRO := oJSON['estabelecimento']['bairro']
			If ExistTrigger('A1_BAIRRO')
				RunTrigger(1,Nil,Nil,,'A1_BAIRRO')
			EndIf

			M->A1_End    := oJSON['estabelecimento']['logradouro'] + ', ' + oJSON['estabelecimento']['numero']
			If ExistTrigger('A1_End')
				RunTrigger(1,Nil,Nil,,'A1_End')
			EndIf

			M->A1_COMPLEM:= oJSON['estabelecimento']['complemento']
			If ExistTrigger('A1_COMPLEM')
				RunTrigger(1,Nil,Nil,,'A1_COMPLEM')
			EndIf

			M->A1_DDD		:= oJSON['estabelecimento']['ddd1']
			If ExistTrigger('A1_DDD')
				RunTrigger(1,Nil,Nil,,'A1_DDD')
			EndIf

			M->A1_TEL		:= oJSON['estabelecimento']['telefone1']
			If ExistTrigger('A1_TEL')
				RunTrigger(1,Nil,Nil,,'A1_TEL')
			EndIf

			M->A1_FAX		:= oJSON['estabelecimento']['ddd_fax']+oJSON['estabelecimento']['fax']
			If ExistTrigger('A1_FAX')
				RunTrigger(1,Nil,Nil,,'A1_FAX')
			EndIf

			M->A1_EMAIL	:= oJSON['estabelecimento']['email']
			If ExistTrigger('A1_EMAIL')
				RunTrigger(1,Nil,Nil,,'A1_EMAIL')
			EndIf

			If valType(oJSON['simples']) == 'J'
				M->A1_SIMPNAC:= If(oJSON['simples']['simples'] == 'Sim', '1', '2')
			Else
				M->A1_SIMPNAC:= '2'
			EndIf
			If ExistTrigger('A1_SIMPNAC')
				RunTrigger(1,Nil,Nil,,'A1_SIMPNAC')
			EndIf

			for nX:=1 to len(oJSON['estabelecimento']['inscricoes_estaduais'])
				If oJSON['estabelecimento']['estado']['id'] == oJSON['estabelecimento']['inscricoes_estaduais'][nX]['estado']['id']
					M->A1_INSCR:= oJSON['estabelecimento']['inscricoes_estaduais'][nX]['inscricao_estadual']
					If ExistTrigger('A1_INSCR')
						RunTrigger(1,Nil,Nil,,'A1_INSCR')
					EndIf
					EXIT
				EndIf
			next

		ElseIf cTab == 'SA2'

			//MATA020 está em MVC
			oModel := FWModelActive()

			oModel:SetValue('SA2MASTER','A2_MSBLQL' ,If(oJSON['estabelecimento']['situacao_cadastral'] == 'Ativa','2','1'))

			CC3->(dbSetOrder(1))
			If !CC3->(dbSeek(xFilial('CC3')+oJSON['estabelecimento']['atividade_principal']['id']))
				reclock('CC3',.t.)
				CC3->CC3_FILIAL	:= xFilial('CC3')
				CC3->CC3_COD		:= oJSON['estabelecimento']['atividade_principal']['id']
				CC3->CC3_DESC		:= upper(oJSON['estabelecimento']['atividade_principal']['descricao'])
				CC3->CC3_CSECAO	:= oJSON['estabelecimento']['atividade_principal']['secao']
				CC3->CC3_CDIVIS	:= oJSON['estabelecimento']['atividade_principal']['divisao']
				CC3->CC3_CGRUPO	:= strTran(oJSON['estabelecimento']['atividade_principal']['grupo'],'.')
				CC3->CC3_CCLASS	:= strTran(strTran(oJSON['estabelecimento']['atividade_principal']['classe'],'.'),'-')
				CC3->(msUnlock())
			EndIf

			oModel:SetValue('SA2MASTER','A2_CNAE',oJSON['estabelecimento']['atividade_principal']['id'])

			oModel:SetValue('SA2MASTER','A2_TIPO', 'J')

			If !empty(oJSON['estabelecimento']['pais']['id'])
				CCH->(dbSetOrder(1))
				If CCH->(dbSeek(xFilial('CCH') + '0' + oJSON['estabelecimento']['pais']['id']))
					oModel:SetValue('SA2MASTER','A2_CODPAIS', allTrim(CCH->CCH_CODIGO))
				EndIf

				SYA->(dbSetOrder(2))
				If SYA->(dbSeek(xFilial('SYA')+ upper(oJSON['estabelecimento']['pais']['nome'])))
					oModel:SetValue('SA2MASTER','A2_PAIS', allTrim(SYA->YA_CODGI))
				EndIf
			EndIf

			If !empty(oJSON['estabelecimento']['nome_fantasia'])
				oModel:SetValue('SA2MASTER','A2_NREDUZ',oJSON['estabelecimento']['nome_fantasia'])
			Else
				oModel:SetValue('SA2MASTER','A2_NREDUZ',avKey(cRet, 'A2_NREDUZ'))
			EndIf

			oModel:SetValue('SA2MASTER','A2_CEP', oJSON['estabelecimento']['cep'])

			oModel:SetValue('SA2MASTER','A2_EST', oJSON['estabelecimento']['estado']['sigla'])

			oModel:SetValue('SA2MASTER','A2_COD_MUN', substring(cValToChar(oJSON['estabelecimento']['cidade']['ibge_id']),3,5))

			oModel:SetValue('SA2MASTER','A2_BAIRRO', oJSON['estabelecimento']['bairro'])

			oModel:SetValue('SA2MASTER','A2_End',oJSON['estabelecimento']['logradouro'] + ', ' + oJSON['estabelecimento']['numero'])

			oModel:SetValue('SA2MASTER','A2_COMPLEM', oJSON['estabelecimento']['complemento'])

			oModel:SetValue('SA2MASTER','A2_DDD', oJSON['estabelecimento']['ddd1'])

			oModel:SetValue('SA2MASTER','A2_TEL', oJSON['estabelecimento']['telefone1'])

			oModel:SetValue('SA2MASTER','A2_FAX', oJSON['estabelecimento']['ddd_fax']+oJSON['estabelecimento']['fax'])

			oModel:SetValue('SA2MASTER','A2_EMAIL', oJSON['estabelecimento']['email'])

			If valType(oJSON['simples']) == 'J'
				oModel:SetValue('SA2MASTER','A2_SIMPNAC', If(oJSON['simples']['simples'] == 'Sim', '1', '2'))
			Else
				oModel:SetValue('SA2MASTER','A2_SIMPNAC', '2')
			EndIf

			for nX:=1 to len(oJSON['estabelecimento']['inscricoes_estaduais'])
				If oJSON['estabelecimento']['estado']['id'] == oJSON['estabelecimento']['inscricoes_estaduais'][nX]['estado']['id']
					oModel:SetValue('SA2MASTER','A2_INSCR', oJSON['estabelecimento']['inscricoes_estaduais'][nX]['inscricao_estadual'])
					EXIT
				EndIf
			next
		EndIf

	Else
		If lJob
			conout('Erro ao consultar CNPJ: ' + oCNPJws:getError())
		Else
			alert('Erro ao consultar CNPJ: ' + oCNPJws:getError())
		EndIf
	EndIf

Return cRet
