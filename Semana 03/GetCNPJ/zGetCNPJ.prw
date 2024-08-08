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
		Regra		: u_zGetCNPJ('SA1',M->A1_CGC) ou u_zGetCNPJ('SA2',M->A2_CGC) 
		Posiciona	: 2
		Condicao	: !Empty(M->A1_CGC) ou !Empty(M->A2_CGC)
	@see
		https://github.com/cnpj-ws/protheus
		https://www.cnpj.ws/docs/intro 
	@history 
/*/
User Function zGetCNPJ(cTab,cCNPJ)
	Local aAreaIni := FWGetArea()
	Local aAreaCC3 := CC3->(FWGetArea()) 
	Local aAreaSYA := SYA->(FWGetArea())
	Local cRet 	   := ''
	Default cTab   := 'SA1'
	Default cCNPJ  := ''

	cCNPJ:= AllTrim(cCNPJ)

	If !Empty(cTab) .and. Len(cCNPJ) == 14
		If isBlind()
			cRet:= consulta(cTab,cCNPJ)
		Else
			FWMsgRun(,{||cRet := consulta(cTab,cCNPJ)},'CNPJ.ws','Consultando o CNPJ '+Transform(AllTrim(cCNPJ),"@R 99.999.999/9999-99")+'...')
		EndIf
	EndIf

	SYA->(FWRestArea(aAreaSYA))
	CC3->(FWRestArea(aAreaCC3))
	FWRestArea(aAreaIni)

Return cRet

/*/{Protheus.doc} consulta 
		Função utilizada para evocar a Classe CNPJws e  
	@type Function 
	@author Maicon Macedo 
	@since 12/10/2023 
/*/
Static Function consulta(cTab,cCNPJ)
	Local lJob as Logical
	Local oCNPJws as Object
	Local oJSON  := nil
	Local nX     := 1
	Local cRet   := ''
	Local oModel := nil

	lJob   := isBlind()

	oCNPJws:= CNPJws():new()

	If oCNPJws:consultarCNPJ(cCNPJ)
		oJSON:= oCNPJws:getResponse()

		cRet:= SubString(oJSON['razao_social'], 1,TamSx3("A2_NOME")[1]) //oJSON['razao_social']

		If oJSON['estabelecimento']['situacao_cadastral'] <> 'Ativa'
			If lJob
				ConOut(cCNPJ + ': A situação cadastral da empresa junto a SEFAZ é ' + oJSON['estabelecimento']['situacao_cadastral'])
			Else
				Alert('A situação cadastral da empresa junto a SEFAZ é ' + oJSON['estabelecimento']['situacao_cadastral'])
			EndIf
		EndIf

		If cTab == 'SA1' //CRMA980
			ConOut('Tabela SA1 (Cliente):'+Transform(cCNPJ,"@R 99.999.999/9999-99") )

			M->A1_MSBLQL:= IIf(oJSON['estabelecimento']['situacao_cadastral'] == 'Ativa','2','1')
			If ExistTrigger('A1_MSBLQL')
				RunTrigger(1,Nil,Nil,,'A1_MSBLQL')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - situacao_cadastral')

			M->A1_CNAE:= oJSON['estabelecimento']['atividade_principal']['id']

			CC3->(dbSetOrder(1))
			If !CC3->(dbSeek(xFilial('CC3')+M->A1_CNAE))
				reclock('CC3',.t.)
				CC3->CC3_FILIAL	:= xFilial('CC3')
				CC3->CC3_COD	:= oJSON['estabelecimento']['atividade_principal']['id']
				CC3->CC3_DESC	:= upper(oJSON['estabelecimento']['atividade_principal']['descricao'])
				CC3->CC3_CSECAO	:= oJSON['estabelecimento']['atividade_principal']['secao']
				CC3->CC3_CDIVIS	:= oJSON['estabelecimento']['atividade_principal']['divisao']
				CC3->CC3_CGRUPO	:= strTran(oJSON['estabelecimento']['atividade_principal']['grupo'],'.')
				CC3->CC3_CCLASS	:= strTran(strTran(oJSON['estabelecimento']['atividade_principal']['classe'],'.'),'-')
				CC3->(msUnlock())
			EndIf
			If ExistTrigger('A1_CNAE')
				RunTrigger(1,Nil,Nil,,'A1_CNAE')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - CNAE')

			M->A1_PESSOA	:= 'J'
			If ExistTrigger('A1_PESSOA')
				RunTrigger(1,Nil,Nil,,'A1_CNAE')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - Tipo de Cliente')

			If !Empty(oJSON['estabelecimento']['pais']['id'])
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
			ConOut('Tabela SA1:'+cCNPJ +' - Codigo Pais')

			M->A1_NOME   := oJSON['estabelecimento']['razao_social']
			If ExistTrigger('A1_NOME')
				RunTrigger(1,Nil,Nil,,'A1_NOME')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - razao_social')

			M->A1_NREDUZ := oJSON['estabelecimento']['nome_fantasia']
			If Empty(M->A1_NREDUZ) //Caso nao possua nome fantasia
				M->A1_NREDUZ := avKey(cRet, 'A1_NREDUZ')
			EndIf
			If ExistTrigger('A1_NREDUZ')
				RunTrigger(1,Nil,Nil,,'A1_NREDUZ')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - Nome Fantasia')

			M->A1_CEP		:= oJSON['estabelecimento']['cep']
			If ExistTrigger('A1_CEP')
				RunTrigger(1,Nil,Nil,,'A1_CEP')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - CEP')

			M->A1_EST		:= oJSON['estabelecimento']['estado']['sigla']
			If ExistTrigger('A1_EST')
				RunTrigger(1,Nil,Nil,,'A1_EST')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - Estado')

			M->A1_COD_MUN:= substring(cValToChar(oJSON['estabelecimento']['cidade']['ibge_id']),3,5)
			If ExistTrigger('A1_COD_MUN')
				RunTrigger(1,Nil,Nil,,'A1_COD_MUN')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - Municipio')

			M->A1_BAIRRO := oJSON['estabelecimento']['bairro']
			If ExistTrigger('A1_BAIRRO')
				RunTrigger(1,Nil,Nil,,'A1_BAIRRO')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - Bairro')

			M->A1_END    := SubString(oJSON['estabelecimento']['logradouro'], 1,TamSx3("A2_END")[1] -5) + ',' + oJSON['estabelecimento']['numero']
			If ExistTrigger('A1_END')
				RunTrigger(1,Nil,Nil,,'A1_END')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - Endereco')

			M->A1_COMPLEM:= oJSON['estabelecimento']['complemento']
			If ExistTrigger('A1_COMPLEM')
				RunTrigger(1,Nil,Nil,,'A1_COMPLEM')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - Complemento Endereco')

			M->A1_DDD		:= oJSON['estabelecimento']['ddd1']
			If ExistTrigger('A1_DDD')
				RunTrigger(1,Nil,Nil,,'A1_DDD')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - DDD')

			M->A1_TEL		:= oJSON['estabelecimento']['telefone1']
			If ExistTrigger('A1_TEL')
				RunTrigger(1,Nil,Nil,,'A1_TEL')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - Telefone')

			M->A1_FAX		:= oJSON['estabelecimento']['ddd_fax']+oJSON['estabelecimento']['fax']
			If ExistTrigger('A1_FAX')
				RunTrigger(1,Nil,Nil,,'A1_FAX')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - FAX')

			M->A1_EMAIL	:= oJSON['estabelecimento']['email']
			If ExistTrigger('A1_EMAIL')
				RunTrigger(1,Nil,Nil,,'A1_EMAIL')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - E-Mail')

			If ValType(oJSON['simples']) == 'J'
				M->A1_SIMPNAC:= If(oJSON['simples']['simples'] == 'Sim', '1', '2')
			Else
				M->A1_SIMPNAC:= '2'
			EndIf
			If ExistTrigger('A1_SIMPNAC')
				RunTrigger(1,Nil,Nil,,'A1_SIMPNAC')
			EndIf
			ConOut('Tabela SA1:'+cCNPJ +' - Regime')

			For nX:=1 to Len(oJSON['estabelecimento']['inscricoes_estaduais'])
				If oJSON['estabelecimento']['estado']['id'] == oJSON['estabelecimento']['inscricoes_estaduais'][nX]['estado']['id']
					M->A1_INSCR:= oJSON['estabelecimento']['inscricoes_estaduais'][nX]['inscricao_estadual']
					If ExistTrigger('A1_INSCR')
						RunTrigger(1,Nil,Nil,,'A1_INSCR')
					EndIf
					EXIT
				EndIf
			Next
			ConOut('Tabela SA1:'+cCNPJ +' - Inscricao Estadual')

		ElseIf cTab == 'SA2' //MATA020
			ConOut('Tabela SA2 (Fornecedor):'+cCNPJ )

			//MATA020 está em MVC
			oModel := FWModelActive()

			oModel:SetValue('SA2MASTER','A2_MSBLQL' ,If(oJSON['estabelecimento']['situacao_cadastral'] == 'Ativa','2','1'))
			ConOut('Tabela SA2:'+cCNPJ +' - Status')

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
			ConOut('Tabela SA2:'+cCNPJ +' - CNAE')

			oModel:SetValue('SA2MASTER','A2_TIPO', 'J')
			ConOut('Tabela SA2:'+cCNPJ +' - Tipo')

			If !Empty(oJSON['estabelecimento']['pais']['id'])
				CCH->(dbSetOrder(1))
				If CCH->(dbSeek(xFilial('CCH') + '0' + oJSON['estabelecimento']['pais']['id']))
					oModel:SetValue('SA2MASTER','A2_CODPAIS', allTrim(CCH->CCH_CODIGO))
				EndIf

				SYA->(dbSetOrder(2))
				If SYA->(dbSeek(xFilial('SYA')+ upper(oJSON['estabelecimento']['pais']['nome'])))
					oModel:SetValue('SA2MASTER','A2_PAIS', allTrim(SYA->YA_CODGI))
				EndIf
			EndIf
			ConOut('Tabela SA2:'+cCNPJ +' - Pais')

			//oModel:SetValue('SA2MASTER','A2_NOME'	, SubString(oJSON['razao_social'], 1,TamSx3("A2_NOME")[1]))
			If !Empty(oJSON['estabelecimento']['nome_fantasia'])
				oModel:SetValue('SA2MASTER','A2_NREDUZ',SubString(oJSON['estabelecimento']['nome_fantasia'], 1,TamSx3("A2_NREDUZ")[1]))
			Else
				oModel:SetValue('SA2MASTER','A2_NREDUZ',SubString(oJSON['razao_social'], 1,TamSx3("A2_NREDUZ")[1]))
			EndIf
			ConOut('Tabela SA2:'+cCNPJ +' - Razao Social/Nome Fantasia')

			oModel:SetValue('SA2MASTER','A2_CEP'	, oJSON['estabelecimento']['cep'])
			ConOut('Tabela SA2:'+cCNPJ +' - CEP')
			oModel:SetValue('SA2MASTER','A2_EST'	, oJSON['estabelecimento']['estado']['sigla'])
			ConOut('Tabela SA2:'+cCNPJ +' - Estado')
			oModel:SetValue('SA2MASTER','A2_COD_MUN', SubString(cValToChar(oJSON['estabelecimento']['cidade']['ibge_id']),3,5))
			ConOut('Tabela SA2:'+cCNPJ +' - Municipio')
			oModel:SetValue('SA2MASTER','A2_BAIRRO'	, oJSON['estabelecimento']['bairro'])
			ConOut('Tabela SA2:'+cCNPJ +' - Bairro')
			oModel:SetValue('SA2MASTER','A2_END'	, SubString(oJSON['estabelecimento']['logradouro'] , 1,TamSx3("A2_END")[1] -5) + ',' + oJSON['estabelecimento']['numero'])
			ConOut('Tabela SA2:'+cCNPJ +' - Endereco')
			oModel:SetValue('SA2MASTER','A2_COMPLEM', oJSON['estabelecimento']['complemento'])
			ConOut('Tabela SA2:'+cCNPJ +' - Complemento')
			oModel:SetValue('SA2MASTER','A2_DDD'	, oJSON['estabelecimento']['ddd1'])
			ConOut('Tabela SA2:'+cCNPJ +' - DDD')
			oModel:SetValue('SA2MASTER','A2_TEL'	, oJSON['estabelecimento']['telefone1'])
			ConOut('Tabela SA2:'+cCNPJ +' - Telefone')
			oModel:SetValue('SA2MASTER','A2_FAX'	, oJSON['estabelecimento']['ddd_fax']+oJSON['estabelecimento']['fax'])
			ConOut('Tabela SA2:'+cCNPJ +' - FAX')
			oModel:SetValue('SA2MASTER','A2_EMAIL'	, oJSON['estabelecimento']['email'])
			ConOut('Tabela SA2:'+cCNPJ +' - E-Mail')

			If valType(oJSON['simples']) == 'J'
				oModel:SetValue('SA2MASTER','A2_SIMPNAC', If(oJSON['simples']['simples'] == 'Sim', '1', '2'))
			Else
				oModel:SetValue('SA2MASTER','A2_SIMPNAC', '2')
			EndIf

			For nX:=1 to len(oJSON['estabelecimento']['inscricoes_estaduais'])
				If oJSON['estabelecimento']['estado']['id'] == oJSON['estabelecimento']['inscricoes_estaduais'][nX]['estado']['id']
					oModel:SetValue('SA2MASTER','A2_INSCR', oJSON['estabelecimento']['inscricoes_estaduais'][nX]['inscricao_estadual'])
					EXIT
				EndIf
			Next

			ConOut('Tabela SA2:'+cCNPJ +' - FIM')
		EndIf

	Else
		If lJob
			ConOut('Erro ao consultar CNPJ: ' + oCNPJws:getError())
		Else
			alert('Erro ao consultar CNPJ: ' + oCNPJws:getError())
		EndIf
	EndIf

Return cRet
