#INCLUDE "MATA010.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWIZARD.CH"
#INCLUDE "FWADAPTEREAI.CH"
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE "TOPCONN.CH"

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ MATA010  ³ Autor ³ Jorge Queiroz         ³ Data ³          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa de atualizacao de Produtos                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ MATA010(ExpA1,ExpN1)                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpA2 = (ROT.AUT) Array dos campos                         ³±±
±±³          ³ ExpN1 = (ROT.AUT) Numero da opcao selecionada              ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function MATA010(xRotAuto,nOpc)
	Local lCoresPE 		:= .F.
	Local uFilPE		:= Nil
	Local cFiltro       := ""
	Local nX			:= 0
	Local aRotina		:= {}

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Define Variaveis                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	nOpc := If (nOpc == Nil,3,nOpc)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Define Array contendo as Rotinas a executar do programa      ³
	//³ ----------- Elementos contidos por dimensao ------------     ³
	//³ 1. Nome a aparecer no cabecalho                              ³
	//³ 2. Nome da Rotina associada                                  ³
	//³ 3. Usado pela rotina                                         ³
	//³ 4. Tipo de Transa‡„o a ser efetuada                          ³
	//³    1 - Pesquisa e Posiciona em um Banco de Dados             ³
	//³    2 - Simplesmente Mostra os Campos                         ³
	//³    3 - Inclui registros no Bancos de Dados                   ³
	//³    4 - Altera o registro corrente                            ³
	//³    5 - Remove o registro corrente do Banco de Dados          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private l010Auto	:= .F.
	Private aRotAuto	:= Nil
	Private aCpoAltSB1	:= {} // vetor usado na gravacao do historico de alteracoes
	Private aCmpoSB1	:= {} // vetor usado na gravacao do historico de alteracoes

	//Controle de Rotinas Relacionadas
	Private lMATA061	:= NIL
	Private lMATA180	:= NIL
	Private lM010Alter	:= NIL
	Private lDCL		:= NIL
	Private lMATA036	:= NIL
	Private lSVK        := NIL
	Private lLoja110    := NIL
	Private lLoja210    := NIL
	Private lM010Agro	:= NIL

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Define o cabecalho da tela de atualizacoes                   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	PRIVATE cCadastro	:= OemtoAnsi(STR0008)         //"Atualiza‡„o de Produtos"

	PRIVATE INCLUI		:= .F.
	PRIVATE ALTERA		:= .F.
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Definicao de variaveis para rotina de inclusao automatica    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private aMemos := {}

	STATIC lHistFiscal	:= NIL
	Static lMvcMata010	:= NIL

	//Complementa tabela autocontida com o NCM 00000000 conforme NT 2014.004 v. 1.10 Nota fiscal eletronica
	//o Trecho abaixo deverá ser removido a partir da 12.1.21 pois a tabela autocontida deverá criar o cod 00000000
	//foi mantido aqui devido ao merge
	SYD->(dbSetOrder(1))
	If cPaisLoc == "BRA" .And. !SYD->(dbSeek(xFilial('SYD')+'00000000'))
		RecLock("SYD",.T.)
		SYD->YD_FILIAL	:= xFilial('SYD')
		SYD->YD_TEC		:= '00000000'
		SYD->YD_DESC_P	:= 'MATERIAL OU OPERACAO NAO CLASSIFICADOS'
		SYD->(MsUnlock())
	EndIf

	lMvcMata010 := IIF(ValType(lMvcMata010) == "L",lMvcMata010, TableInDic( "G3Q", .F. ))

	If lMvcMata010
		MATA010M(xRotAuto,nOpc)
	Else
		lHistFiscal	:= HistFiscal()

		l010Auto := ( xRotAuto <> NIL )
		aMemos:={{"B1_DESC_I","B1_VM_I"},{"B1_DESC_GI","B1_VM_GI"},{"B1_DESC_P","B1_VM_P"},{"B1_CODOBS","B1_OBS"},{"B1_CODPROC","B1_VM_PROC"}}
		aRotina := MenuDef()

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Ponto de Entrada para Tratamento de Campos Memo - Virtuais   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If ExistBlock( "MT010MEM" )
			aMemUser := ExecBlock( "MT010MEM", .F., .F. )
			If ValType( aMemUser ) == "A"
				AEval( aMemUser, { |x| AAdd( aMemos, x ) } )
			EndIf
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Esta vari vel serve como sem foro para copia ou repeti‡„o de produtos. ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		Private lCopia    := .F.

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Esta variavel serve como validação de vinculação de NVE - SIGAEIC.     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If ExistFunc("EasyNVEChk")
		    EasyNVEChk(.F.)
		EndIf

		Pergunte("MTA010",.F.)

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Ativa tecla F4 para comunicacao com Saldos dos Lotes         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !l010Auto
			Set Key VK_F4 TO MT010F4()
			Set Key VK_F12 TO MT010Perg()
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Seleciona o Alias SYP para garantir a abertura ( NAO RETIRAR ) ³
		//³ do arquivo durante a transacao.(AVERAGE)                       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("SYP")

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Endereca a funcao de BROWSE                                  ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If l010Auto
			aRotAuto := xRotAuto
			M010BrwAuto(nOpc,aRotAuto,"SB1")
		Else
			If ( ExistBlock("MA010FIL") )
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Ponto de Entrada para Expressao em ADVPL. ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				uFilPE := ExecBlock("MA010FIL",.F.,.F.)
				If ValType(uFilPE) == "C"
					cFiltro := AllTrim(uFilPE)
				EndIf
			ElseIf ( ExistBlock("M010FILB") )
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Ponto de Entrada para Expressao em SQL ANSI. ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				cFilPE := ExecBlock("M010FILB",.F.,.F.)
				If Valtype(cFilPE) == "C"
					cFiltro := "@"+AllTrim(cFilPE)
				EndIf
			EndIf

			dbSelectArea("SB1")

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ MT010COR - Ponto de Entrada para customizar o array aCores             ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If ExistBlock("MT010COR")
				lCoresPE := .F.
				aCores := ExecBlock("MT010COR",.F.,.F.)
				If (Valtype(aCores) == "A" .And. Len(aCores) > 0)
					lCoresPE := .T.
				EndIf
			EndIf

			oMBrowse := FWMBrowse():New()
			oMBrowse:SetAlias("SB1")
			oMBrowse:SetDescription(cCadastro)
			oMBrowse:SetAttach(.T.)
			//Se não for SIGACRM inibe a exibição do gráfico
			If nModulo <> 73
				oMBrowse:SetOpenChart( .F. )
			EndIf
			oMBrowse:SetTotalDefault("B1_FILIAL","COUNT",STR0092)//"Total de Registros"

			If lCoresPE
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Adiciona as legendas no browse. ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				For nX := 1 To Len(aCores)
					/*Condição,Legenda,Descrição*/
					oMBrowse:AddLegend(aCores[nX][1],aCores[nX][2],aCores[nX][3])
				Next nX
			EndIf
			If !Empty(cFiltro)
				oMBrowse:SetFilterDefault(cFiltro)
			EndIf

			oMBrowse:Activate()
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Desativa a tecla F4 neste momento por seguranca              ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If !l010Auto
			SET KEY VK_F4 TO
			Set Key VK_F12 To
		EndIF
	EndIf

Return(.T.)

//-----------------------------------------------------------------
/*/{Protheus.doc} ModelDef
Definição do model referente aos produtos

@author Juliane Venteu
@since 27/03/2017
@version P12.1.17

/*/
Static Function ModelDef()
	Local oModel	:= NIL
	Local oStruSB1	:= FWFormStruct(1, 'SB1')
	Local lMA010MEM	:= ExistBlock( "MT010MEM" )
	Local lVeiculo	:= SuperGetMV("MV_VEICULO",.F.,"N") == "S"
	Local aFldNoCopy:= FldNoCopy(lVeiculo)
	Local aAux		:= {}
	Local aMemUser 	:= {}
	Local aVerify	:= {}
	Local aMemos   	:= {	{"B1_DESC_I","B1_VM_I"},;
								{"B1_DESC_GI","B1_VM_GI"},;
								{"B1_DESC_P","B1_VM_P"},;
								{"B1_CODOBS","B1_OBS"},;
								{"B1_CODPROC","B1_VM_PROC"}}

	//Adiciona B1_QTDSER virtual
	oStruSB1:AddField(oStruSb1:GetProperty("B1_QTDSER",MODEL_FIELD_TITULO)		  , ;	// [01] C Titulo do campo
						oStruSb1:GetProperty("B1_QTDSER",MODEL_FIELD_TOOLTIP ) 	  , ;	// [02] C ToolTip do campo
						'B1_VRQTDSER' , ;												// [03] C identificador (ID) do Field
						'C' , ;															// [04] C Tipo do campo
						1 , ;															// [05] N Tamanho do campo
						oStruSb1:GetProperty("B1_QTDSER",MODEL_FIELD_DECIMAL )	  , ;	// [06] N Decimal do campo
						oStruSb1:GetProperty("B1_QTDSER",MODEL_FIELD_VALID )  	  , ;	// [07] B Code-block de validação do campo
						oStruSb1:GetProperty("B1_QTDSER",MODEL_FIELD_WHEN )   	  , ;	// [08] B Code-block de validação When do campo
						oStruSb1:GetProperty("B1_QTDSER",MODEL_FIELD_VALUES )  	  , ;	// [09] A Lista de valores permitido do campo
						oStruSb1:GetProperty("B1_QTDSER",MODEL_FIELD_OBRIGAT )	  , ;	// [10] L Indica se o campo tem preenchimento obrigatório
						FWBuildFeature( STRUCT_FEATURE_INIPAD, "M010IniQtdSer()" ), ;	// [11] B Code-block de inicializacao do campo
						oStruSb1:GetProperty("B1_QTDSER",MODEL_FIELD_KEY) 		  , ;	// [12] L Indica se trata de um campo chave
						oStruSb1:GetProperty("B1_QTDSER",MODEL_FIELD_NOUPD) 	  , ;	// [13] L Indica se o campo pode receber valor em uma operação de update.
						.T. 												)			// [14] L Indica se o campo é virtual //oStruSb1:GetProperty("B1_QTDSER",MODEL_FIELD_VIRTUAL)

						oStruSb1:SetProperty("B1_QTDSER",MODEL_FIELD_VALUES,NIL)
						oStruSb1:SetProperty("B1_COD"	,MODEL_FIELD_INIT	, FWBuildFeature( STRUCT_FEATURE_INIPAD, 'A10InitCod()' ) )

   	//Altera o combo do campo B1_FANTASM
   	A010Fantasm(oStruSb1)

	//Verifica o acesso do usuario as rotinas relacionadas
    If  Type("lMATA061") == "U" .Or. Type("lMATA180") == "U" .Or. Type("lM010Alter") == "U"  .Or. Type("lDcl") == "U"  .Or. Type( "lMATA036" ) == "U" .Or.;
        Type("lSVK") == "U"     .Or. Type("lLoja110") == "U" .Or. Type("lLoja210") == "U" .Or. Type("lM010Agro") == "U"
		//Controle de Rotinas Relacionadas
		aVerify	:= VerifyAccess() //{lMATA061,lMATA019,lMATA180,lDCL,lM010Alter}
		lMATA061	:= IIf( Len( aVerify ) >= 1, IIf( ValType( aVerify[1] ) == 'L', aVerify[1], .F. ) , .F. )
		lMATA180	:= IIf( Len( aVerify ) >= 3, IIf( ValType( aVerify[3] ) == 'L', aVerify[3], .F. ) , .F. )
		lDCL		:= IIf( Len( aVerify ) >= 4, IIf( ValType( aVerify[4] ) == 'L', aVerify[4], .F. ) , .F. )
		lM010Alter	:= IIf( Len( aVerify ) >= 5, IIf( ValType( aVerify[5] ) == 'L', aVerify[5], .F. ) , .F. )
		lMATA036	:= IIf( Len( aVerify ) >= 6, IIf( ValType( aVerify[6] ) == 'L', aVerify[6], .F. ) , .F. )
		lSVK		:= IIf( Len( aVerify ) >= 7, IIf( ValType( aVerify[7] ) == 'L', aVerify[7], .F. ) , .F. )
  	    lLoja110	:= IIf( Len( aVerify ) >= 8, IIf( ValType( aVerify[8] ) == 'L', aVerify[8], .F. ) , .F. )
		lLoja210	:= IIf( Len( aVerify ) >= 9, IIf( ValType( aVerify[9] ) == 'L', aVerify[9], .F. ) , .F. )
		lM010Agro	:= IIf( Len( aVerify ) >= 10, IIf( ValType( aVerify[10] ) == 'L', aVerify[10], .F. ) , .F. )
	EndIf

	//Ponto de entrada para adicao de campos memo do usuario
	If lMA010MEM .And. ValType(aMemUser := ExecBlock("MT010MEM", .F., .F.)) == "A"
		aEval(aMemUser, {|x| aAdd(aMemos, x)})
	EndIf

	FWMemoVirtual(oStruSB1, aMemos)

	//Gatilho para atualizar B1_QTDSER
	aAux := FwStruTrigger("B1_VRQTDSER","B1_QTDSER","Ma010QtdSer()")
	oStruSB1:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])

	If lMATA061
		aAux := FwStruTrigger("B1_MONO","B1_PROC","MTA010Mono()")
		oStruSB1:AddTrigger(aAux[1],aAux[2],aAux[3],aAux[4])
	EndIf

	//---------------------------------------------------
	// Se mudar o ID do model, trate tbm na função MATI010
	//---------------------------------------------------
	oModel := MPFormModel():New('ITEM',,{|oMdl| A010PosVal(oMdl)})
	oModel:SetDescription(OemtoAnsi(STR0008))  //"Atualiza‡„o de Produtos"

	oModel:AddFields("SB1MASTER",,oStruSB1)
	oModel:AddRules("SB1MASTER","B1_MONO","SB1MASTER","B1_PROC",3)

	//Integracao Shopify - Adicionado integração com Shopify SHPXFUN.PRW
	If cPaisLoc == "EUA" .And. SuperGetMv("MV_SHOPIFY",.F.,.F.) 
		SPYPMTA010(@oModel,SB1->B1_COD, MODEL_OPERATION_DELETE, MODEL_OPERATION_UPDATE)
	Endif

	oModel:InstallEvent("PADRAO"	,, MATA010EVDEF():New())
	oModel:InstallEvent("PE"		,, MATA010EVPE():New())
	oModel:InstallEvent("TEMPLATE"	,, MATA010EVTE():New())
	If cPaisLoc != "RUS"
		oModel:InstallEvent("INTTAF"	,, MATA010EVTAF():New())
		oModel:InstallEvent("INTOMS"	,, MATA010EVOMS():New())
	EndIf
	oModel:InstallEvent("BRASIL"    ,, MATA010EVBRA():New())
	If nModulo == 17 .And. ExistFunc("EasyNVEChk")
		oModel:InstallEvent("INTEIC"	,, MATA010EVEIC():New())
	EndIf

	If FindFunction('PCPIntgPPI') .And. PCPIntgPPI()
		oModel:InstallEvent("INT.PPI",, MATA010PPI():New())
	EndIf

	If SuperGetMv("MV_LJGRINT", .F., .F.)
		oModel:InstallEvent("INT.LOJA",, MATA010Loja():New())
	EndIf

	If (( ExisteSFC("SB1") .Or. IntegraDPR())) .And. !IsInCallStack("AUTO010")
		oModel:InstallEvent("INT.DPR",, MATA010DPR():New())
	EndIf

	If FindFunction("RodaNewPCP") .And. RodaNewPCP()
    	oModel:InstallEvent("INT.PCP",, MATA010PCP():New(oModel))
	EndIf

	If (SuperGetMv("MV_INTGIQE", .F., .F.) .Or. SuperGetMv("MV_INTGIQP", .F., .F.)) .And. FindFunction("GIQINT")
    	oModel:InstallEvent("INT.GIQ",, MATA010GIQ():New(oModel))
	EndIf
	If lVeiculo
		oModel:InstallEvent("DMS",, MATA010DMS():New())
	EndIf

	oModel:InstallEvent("FISA180" ,,MATA010FISA180():New("SB1MASTER")) // Complemento Fiscal de Produto

	If lMATA036
		oModel:InstallEvent("MATA036" ,,MATA010MATA036():New("SB1MASTER")) // Complemento Fiscal de Produto
	EndIf

	If lLoja110
		oModel:InstallEvent("LOJA110", , Mata010Loja110():New("SB1MASTER") )    //Dados Adicionais do Loja
	EndIf

	If lLoja210
		oModel:InstallEvent("LOJA210", , Mata010Loja210():New("SB1MASTER") )    //Código de Barras
	EndIf

	If lM010Agro
		oModel:InstallEvent("AGRO", , MATA010AGRO01():New("SB1MASTER") )    //Dados Produto Agronegocio
	EndIf

	// ---------------------------------------------------------------- 
	// Integração GRR - Gestão de Receita Recorrente 
	// Adiciona a seção com os dados de produto recorrente
	// ----------------------------------------------------------------
	If ( FindFunction( 'IsGRRUpdated' ) .And. IsGRRUpdated() )
		oModel:InstallEvent( "INT.GRR", , MATA010GRR():New( "SB1MASTER" ) )    //Recorrência via GRR
	EndIf

	//-- Definicao de campos que nao podem ser copiados
	If Len(aFldNoCopy) > 0
		oModel:GetModel("SB1MASTER"):SetFldNoCopy(aFldNoCopy)
	EndIf

	//-- Adionara outros trechos do modelo (SB5, SBZ, SA5, SGI, DH5...)
	oModel:SetVldActivate({|oModel| MTA010VldActivate(oModel)})

	oModel:SetSource("MATA010")

Return oModel
//-----------------------------------------------------------------
Static Function ViewDef()
	Local oView		:= NIL
	Local oModel 	:= ModelDef()
	Local aButtons 	:= {}
	Local aVerify	:= {}
	Local nX		:= 0
	Local aUsrBut 	:= {}
	Local oStruSB1	:= FWFormStruct(2, 'SB1')
	Local oStruSB5	:= NIL
	Local oStruDH5	:= NIL
	Local oStruSVK	:= NIL
	Local lMA010BUT	:= ExistBlock( "MA010BUT" )
	Local lNewPCP   := .F.
	Local oEvFISA180 As Object
	Local oEvMATA036 As Object

	If X3Uso(GetSX3Cache('B1_QTDSER', "X3_USADO"))
		//Adiciona B1_QTDSER virtual
		oStruSB1:AddField('B1_VRQTDSER' , ;            								// [01] C Nome do Campo
					oStruSb1:GetProperty("B1_QTDSER",MVC_VIEW_ORDEM ) , ;			// [02] C Ordem
					oStruSb1:GetProperty("B1_QTDSER",MVC_VIEW_TITULO ) ,;			// [03] C Titulo do campo
					oStruSb1:GetProperty("B1_QTDSER",MVC_VIEW_DESCR ) , ; 			// [04] C Descrição do campo
					oStruSb1:GetProperty("B1_QTDSER",MVC_VIEW_HELP ) , ;			// [05] A Array com Help
					'C' , ;                       									// [06] C Tipo do campo
					'9' , ;                    										// [07] C Picture
					NIL , ;                      									// [08] B Bloco de Picture Var
					'' , ;                       								 	// [09] C Consulta F3
					oStruSb1:GetProperty("B1_QTDSER",MVC_VIEW_CANCHANGE ), ;		// [10] L Indica se o campo é evitável
					oStruSb1:GetProperty("B1_QTDSER",MVC_VIEW_FOLDER_NUMBER  ) , ;  // [11] C Pasta do campo
					NIL , ;                       									// [12] C Agrupamento do campo
					oStruSb1:GetProperty("B1_QTDSER",MVC_VIEW_COMBOBOX ) , ; 		// [13] A Lista de valores permitido do campo (Combo)
					NIL , ;                       									// [14] N Tamanho Maximo da maior opção do combo
					oStruSb1:GetProperty("B1_QTDSER",MVC_VIEW_INIBROW ) , ; 		// [15] C Inicializador de Browse
					.T. , ;                      								 	// [16] L Indica se o campo é virtual
					NIL )                        									// [17] C Picture Variável

		//Remove B1_QTDSER real da view
		oStruSB1:RemoveField('B1_QTDSER')
	EndIf

	If X3Uso(GetSX3Cache('B1_IDHIST', "X3_USADO"))
		oStruSB1:RemoveField('B1_IDHIST')
	EndIf

	//Verifica o acesso do usuario as rotinas relacionadas
	If  Type("lMATA180") = "U"  .Or. Type("lM010Alter") = "U"  .Or. Type("lDcl") = "U"  .Or. Type("lMATA036") = "U" .Or. Type("lSVK") = "U" .Or.;
        Type("lLoja110") == "U" .Or. Type("lLoja210") == "U" .Or. Type("lM010Agro") == "U"
		aVerify	:= VerifyAccess()//{lMATA061,lMATA019,lMATA180,lDCL,lM010Alter}
		lMATA180	:= IIf( Len( aVerify ) >= 3, IIf( ValType( aVerify[3] ) == 'L', aVerify[3], .F. ) , .F. )
		lDCL		:= IIf( Len( aVerify ) >= 4, IIf( ValType( aVerify[4] ) == 'L', aVerify[4], .F. ) , .F. )
		lM010Alter	:= IIf( Len( aVerify ) >= 5, IIf( ValType( aVerify[5] ) == 'L', aVerify[5], .F. ) , .F. )
		lMATA036	:= IIf( Len( aVerify ) >= 6, IIf( ValType( aVerify[6] ) == 'L', aVerify[6], .F. ) , .F. )
		lSVK		:= IIf( Len( aVerify ) >= 7, IIf( ValType( aVerify[7] ) == 'L', aVerify[7], .F. ) , .F. )
  	    lLoja110	:= IIf( Len( aVerify ) >= 8, IIf( ValType( aVerify[8] ) == 'L', aVerify[8], .F. ) , .F. )
		lLoja210	:= IIf( Len( aVerify ) >= 9, IIf( ValType( aVerify[9] ) == 'L', aVerify[9], .F. ) , .F. )
		lM010Agro	:= IIf( Len( aVerify ) >= 10, IIf( ValType( aVerify[10] ) == 'L', aVerify[10], .F. ) , .F. )
 	EndIf

	oView := FWFormView():New()

	oView:SetModel(oModel)

	oView:SetContinuousForm(.T.)
	oView:CreateHorizontalBox( 'BOXFORMSB1', 10)
	oView:AddField('FORMSB1' , oStruSB1,'SB1MASTER' )
	oView:SetOwnerView('FORMSB1','BOXFORMSB1')
	oView:EnableTitleView("FORMSB1", FwX2Nome("SB1"))

	//-------------------------------------------------------------------------
	// Se deixa para criar nas funções View180 e ViewDCL, os campos são mostrados como
	// desabilitados, então crio o Field e se o usuario não tiver acesso a
	// operação, as funções View180 e ViewDCL não adiciona na tela o componente
	//-----------------------------------------------------------------------
	If lMATA180
		oStruSB5:= FWFormStruct(2, 'SB5')
		oView:AddField('FORMSB5' , oStruSB5,'SB5DETAIL' )
		oStruSB5:RemoveField('B5_COD')
		oStruSB5:RemoveField('B5_IDHIST')
	EndIf

	If lDCL
		oStruDH5 := FWFormStruct(2, 'DH5', {|cField| !(AllTrim(Upper(cField)) $ "DH5_COD") })
		oView:AddField('FORMDH5' , oStruDH5,'DH5DETAIL' )
	EndIf

	If lSVK
		oStruSVK := FWFormStruct(2, 'SVK', {|cField| !(AllTrim(Upper(cField)) $ "VK_COD") })
		oView:AddField('FORMSVK' , oStruSVK,'SVKDETAIL' )
	EndIf

	If lM010Alter
		lNewPCP := FindFunction("RodaNewPCP") .And. RodaNewPCP()
		If lNewPCP
			If X3Uso(GetSx3Cache("GI_ORDEM","X3_USADO"))
				oStruSGI := FWFormStruct(2, 'SGI', {|cField| (AllTrim(Upper(cField)) == "GI_ESTOQUE") })
				oView:AddField("FORMSGICAB", oStruSGI, "SGIMASTER")
			ENDIF
		EndIf
	EndIf

	// Integra o Complemento de Produto no formulario do produto
	oEvFISA180:= MATA010FISA180():New("SB1MASTER")
	oEvFISA180:ViewDefMata010(oView)
	oEvFISA180:Destroy()
	oEvFISA180 := NIL

	If lMATA036
		// Integra o Complemento de Produto no formulario do produto
		oEvMATA036:= MATA010MATA036():New("SB1MASTER")
		oEvMATA036:ViewDefMATA036(oView)
		oEvMATA036:Destroy()
		oEvMATA036 := NIL
	EndIf
    	//Dados Adicionario do Loja
	If lLoja110
		oEvLoja110:= Mata010Loja110():New("SB1MASTER")
		oEvLoja110:ViewDefLoja110(oView, .T.)
		oEvLoja110:Destroy()
		FwFreeObj(oEvLoja110)
	EndIf

	oView:SetViewCanActivate({|oView| A010CanActivate(oView)})
	oView:SetDescription(OemtoAnsi(STR0008))  //"Atualiza‡„o de Produtos"

	If cPaisLoc == "BRA" .And. FindFunction("FSA172VIEW")
		oView:AddUserButton('Perfis Tributários','',{|| FSA172VIEW({"PRODUTO", oModel:GetValue("SB1MASTER", "B1_COD")})},,,{MODEL_OPERATION_VIEW,MODEL_OPERATION_UPDATE,MODEL_OPERATION_DELETE})
	EndIf

	//Inclusao automatica de botoes atraves de ponto de entrada
	If ExistTemplate( "MA010BUT" )
		If Valtype( aUsrBut := ExecTemplate( "MA010BUT", .f., .f. ) ) == "A"
			AEval( aUsrBut, { |x| AAdd( aButtons, x ) } )
		EndIF
	EndIf

	oView:SetFieldAction( 'B1_CODBAR', { |oView, cIDView| A010RfCbar( oView, cIDView,'B1_CODBAR') } )
	oView:SetFieldAction( 'B1_CODGTIN', { |oView, cIDView| A010RfCbar( oView, cIDView,'B1_CODGTIN') } )

	If lMA010BUT
		If Valtype( aUsrBut := Execblock( "MA010BUT", .f., .f. ) ) == "A"
			AEval( aUsrBut, { |x| AAdd( aButtons, x ) } )
		EndIF
	EndIf

	For nX:=1 to Len(aButtons)
		oView:AddUserButton(aButtons[nX][3],aButtons[nX][1], aButtons[nX][2])
	Next nX

Return oView
//----------------------------------------------------------------


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Funcao criada porque no FINA010 tambem existe A010Deleta     ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Function Mata010Deleta(cAlias,nReg,nOpc)
Local lReturn
Local bSavKeyF4 := Nil
Local cMsg

	lMvcMata010 := IIF(ValType(lMvcMata010) == "L",lMvcMata010, TableInDic( "G3Q", .F. ))

	If lMvcMata010

		//Integracao Shopify - Adicionado integração com Shopify SHPXFUN.PRW
		If cPaisLoc == "EUA" .And. SuperGetMv("MV_SHOPIFY",.F.,.F.)
			Return SPYDMTA010(SB1->B1_COD)
		Endif

		lMnuCRM := .F.
		bSavKeyF4 := SetKey(VK_F4,Nil)
		MMata010De(cAlias,nReg,nOpc)
		SetKey(VK_F4,bSavKeyF4)
	EndIf

Return (lReturn)

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ A010Tipo ³ Autor ³ Jose Lucas            ³ Data ³ 12.11.93 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica a existencia do Tipo na Tabela de Parametros.     ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A010Tipo()                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T. / .F.                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MatA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010Tipo()

	LOCAL cVar, cSavAlias := Alias(), lRet := .T.

	cVar := &(ReadVar())

	dbSelectArea("SX5")
	dbSeek(xFilial("SX5")+"02"+cVar)
	If !Found()
		Help(" ",1,"MA01002")
		lRet := .F.
	EndIf
	dbSelectArea(cSavAlias)
Return(lRet)


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ A010Grupo³ Autor ³ Jose Lucas            ³ Data ³ 12.11.93 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica a existencia do Grupo na Tabela de Parametros.    ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A010Grupo()                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T. / .F.                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MatA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010Grupo()

	LOCAL cVar, cSavAlias := Alias(), lRet := .T.

	cVar := &(ReadVar())

	dbSelectArea("SBM")
	dbSetOrder(1)
	dbSeek(xFilial("SBM")+cVar)

	If !Found()
		Help(" ",1,"MA01002")
		lRet := .F.
	EndIf

	//-- MIL - CODITE - Validação para não permitir mesmo Grupo+Codite quando utilizado o Módulo de Concessionárias
	If lRet .And. SuperGetMV("MV_VEICULO",.F.,"N") == "S" .And. !Empty(M->B1_CODITE)
		lRet := ExistChav("SB1",M->B1_GRUPO+M->B1_CODITE,7)
	EndIf

	dbSelectArea(cSavAlias)
Return(lRet)

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ A010Mult ³ Autor ³ Jose Lucas            ³ Data ³ 26.11.93 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Comsistir se B1_LE e B1_QE sao multiplos.                  ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A010Mult()                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T. / .F.                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MatA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010Mult()

	LOCAL cVar, cCampo, lRet := .T.

	cCampo := ReadVar()
	cVar := &(ReadVar())

	If AllTrim(cCampo) == "B1_LE"
		If !Empty(M->B1_QE) .And. !Empty(M->B1_LE)
			If QtdComp(Mod( M->B1_LE,M->B1_QE )) > QtdComp(0)
				Help(" ",1,"MA01003")
				lRet := .F.
			EndIf
		EndIf
	Else
		If !Empty(M->B1_LE) .And. !Empty(M->B1_QE)
			If QtdComp(Mod( M->B1_LE,M->B1_QE )) > QtdComp(0)
				Help(" ",1,"MA01003")
				lRet := .F.
			EndIf
		EndIf
	EndIf
Return(lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ A010MONO ³ Autor ³ Marcelo B. Abe        ³ Data ³ 04/04/94 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa de Validacao de Fornecedor de Dominio do Canal    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ Void A010MONO(void)                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T. / .F.                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SX3->X3_VALID(B1_MONO)                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Function A010MONO()
Local lRet := .T.

	lMvcMata010 := IIF(ValType(lMvcMata010) == "L",lMvcMata010, TableInDic( "G3Q", .F. ))

	If lMvcMata010
		Return A010MONOX()
	EndIf


	If EMPTY(M->B1_PROC) .And. M->B1_MONO=="S"
		HELP(" ",1,"A010MONO")
		lRet := .F.
	Endif
Return(lRet)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ A010PROC ³ Autor ³ Marcelo B. Abe        ³ Data ³ 04/04/94 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa de Validacao do Fornecedor Padrao.                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ Void A010PROC(void)                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T.                                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ SX3->X3_VALID(B1_PROC)                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010PROC()
Local lRet  	:= .T.
Local aArea		:= GetArea()
Local aAreaSA2	:= SA2->( GetArea()	)

If Empty(M->B1_PROC)
	M->B1_MONO 		:= CriaVar( 'B1_MONO', .F. )
	M->B1_LOJPROC	:= CriaVar( 'B1_LOJPROC', .F. )

	// Habilita a edição do grid SA5
	IIf( lMvcMata010, editGridSA5(.T.), Nil )
Else
	SA2->( dbSetOrder( 1 ) )
	If !SA2->( dbSeek( xFilial( "SA2" ) + Padr( M->B1_PROC, TamSx3( 'B1_PROC' )[ 1 ] ) ) )
		Help("  ",1,"REGNOIS")
		lRet := .F.
	EndIf

EndIf

RestArea( aAreaSA2 )
RestArea( aArea )
Return( lRet )


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³A010Visul ³ Autor ³ Erike Yuri da Silva   ³ Data ³18/04/05  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa para visualizar produto e complemento             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ ExpN1 := A010Visul(ExpC1,ExpN2,ExpN3)                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo                                   ³±±
±±³			 ³ ExpN2 = Numero do registro                                 ³±±
±±³			 ³ ExpN3 = Numero da opcao selecionada                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ ExpN1 = 1(confirmado),2(nao confirmou)					  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ Mata010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010Visul(cAlias,nReg,nOpc)
	Local nOpcA		:= 3
	Local aArea		:= GetArea()
	Local aAreaSB1	:= SB1->(GetArea())
	Local aAreaSB5	:= SB5->(GetArea())
	Local aAreaDH5	:= {}
	Local aUsrBut	:= {}
	Local aButtons	:= {}
	Local aCpos		:= {}
	Local cPerg     := "MTA010"
	Local aMvPar    := {}
	Local nCnt      := 0
	Local aRotAnt   := {}
	Local lDclNew	:= SuperGetMV("MV_DCLNEW",.F.,.F.)
	Local bSavKeyF4 := Nil
	Local cUsrFil   := cFilAnt
	Local aAreaSM0  := SM0->(GetArea())

	lMvcMata010 := IIF(ValType(lMvcMata010) == "L",lMvcMata010, TableInDic( "G3Q", .F. ))

	If lMvcMata010
		lMnuCRM := .T.
		bSavKeyF4 := SetKey(VK_F4,Nil)
		(FWExecView (STR0004, "MATA010",  MODEL_OPERATION_VIEW,,{||.T.},,,,,,,))
		SetKey(VK_F4,bSavKeyF4)

		//Restaura o posicionamento do SIGAMAT
		RestArea(aAreaSM0)
		cFilAnt := cUsrFil

		Return
	EndIf

	If lDclNew
		aAreaDH5 := DH5->(GetArea())
	EndIf

	If Type("cCadastro") == "U"
		Private cCadastro := OemtoAnsi(STR0008) //"Atualização de Produtos"
	EndIf

	DEFAULT cAlias	:= Alias()
	DEFAULT nReg 	:= SB1->(Recno())
	DEFAULT nOpc	:= 2

	For nCnt := 1 To 60
		Aadd( aMvPar, &( "MV_PAR"+STRZERO(nCnt,2) ) )
	Next nCnt

	If Type("aRotina")=='A'
		aRotAnt := aClone(aRotina)
	EndIf
	aRotina := MenuDef() // Atualiza o aRotina com as opcoes do MATA010

	Pergunte(cPerg,.F.)

	//Inclusao automatica de botoes atraves de ponto de entrada
	If ExistTemplate( "MA010BUT" )
		If Valtype( aUsrBut := ExecTemplate( "MA010BUT", .f., .f. ) ) == "A"
			AEval( aUsrBut, { |x| AAdd( aButtons, x ) } )
		EndIF
	EndIf

	If ExistBlock( "MA010BUT" )
		If Valtype( aUsrBut := Execblock( "MA010BUT", .f., .f. ) ) == "A"
			AEval( aUsrBut, { |x| AAdd( aButtons, x ) } )
		EndIF
	EndIf

	//Ponto de Entrada para definir quais campos da SB1 serao carregados na visualizacao
	If ExistBlock("MT010VCP")
		aCpos:= ExecBlock("MT010VCP",.F.,.F.)
		If ValType(aCpos) <> "A"
			aCpos:= {}
		EndIf
	EndIf

	//inclusao dinamica do botao para poder visualizar os opcionais, no minimo quando houver estrutura.
	SG1->(DbSetOrder(1))
	If SG1->(DbSeek(xFilial('SG1')+SB1->B1_COD))
		AAdd(aButtons,{'PRODUTO',{|| A010SeleOpc() },STR0029 }) //"Opcionais Default"
	EndIf

	If MV_PAR02 == 1
		SB5->(DbSetOrder(1))
		If SB5->(DbSeek(xFilial("SB5")+SB1->B1_COD))
			nOpcA:=A010VilPeC( cAlias, nReg, nOpc,aButtons,IIF(Len(aCpos)>0,aCpos,Nil))
		Else
			nOpcA:=AxVisual( cAlias, nReg, nOpc,IIF(Len(aCpos)>0,aCpos,Nil),,,,aButtons)
		EndIf
	Else
		nOpcA:=AxVisual( cAlias, nReg, nOpc,IIF(Len(aCpos)>0,aCpos,Nil),,,,aButtons)
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Restaura o conteudo dos parametros mv_par?? e do aRotina³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Len(aRotAnt) > 0
		aRotina := aClone(aRotAnt)
	EndIf

	For nCnt := 1 To Len( aMvPar )
		&( "MV_PAR"+STRZERO(nCnt,2) ) := aMvPar[ nCnt ]
	Next nCnt

	If lDclNew
		RestArea(aAreaDH5)
	EndIf

	RestArea(aAreaSB1)
	RestArea(aAreaSB5)
	RestArea(aArea)
Return(nOpcA)
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o	 ³A010VilPeC³ Autor ³                       ³ Data ³          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa para visualizar dados complementares do produto   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ ExpN1 := A010VilPeC(ExpC1,ExpN2,ExpN3,ExpA1)               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo                                   ³±±
±±³			 ³ ExpN2 = Numero do registro                                 ³±±
±±³			 ³ ExpN3 = Numero da opcao selecionada                        ³±±
±±³			 ³ ExpA1 = Array contendo os botoes da rotina                 ³±±
±±³			 ³ ExpA2 = Campos da SB1 que serao utilizados na Visualizacao ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ ExpN1 = 1(confirmado),2(nao confirmou)					  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso		 ³ Mata010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010VilPeC(cAlias,nReg,nOpc,aButtons,aCpos)

	Local aArea    := GetArea()
	Local nOpcA    := 3
	Local cCpoFil  := PrefixoCpo(cAlias)+"_FILIAL"
	Local cMemo    := ""
	LOcal nX       := 0
	Local oDlg
	Local nTop
	Local nLeft
	Local nBottom
	Local nRight
	Local nRegSB5	:= SB5->(RecNo())
	Local nRegDH5	:= 0
	Local lDclNew		:= SuperGetMV("MV_DCLNEW",.F.,.F.)

	//enchoice
	Local oFolder
	Private oEnc01
	Private oEnc02
	Private aTELA:=NIL,aGets:=NIL

	Private Altera :=.F.
	Private Inclui :=.F.

	Default aButtons := {}

	If lDclNew
		nRegDH5	:= DH5->(RecNo())
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ajusta a largura para o tamanho padrao Protheus ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aSize := MsAdvSize()

	aObjects := {}
	AAdd( aObjects, { 100, 100, .T., .T. } )
	aInfo    := { aSize[1], aSize[2], aSize[3], aSize[4], 2, 2 }

	aPosObj := MsObjSize(aInfo,aObjects,.T.)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³VerIfica se esta' vizualizando um registro da mesma filial            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	DbSelectArea("SB5")
	DbSelectArea(cAlias)
	If (cAlias)->(FieldPos(cCpoFil))==0 .Or. (cAlias)->(FieldGet(FieldPos(cCpoFil))) == xFilial(cAlias)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Monta a entrada de dados do arquivo						     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		RegToMemory(cAlias, .F., .F. )
		RegToMemory("SB5",.F. , .F. )
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Inicializa variaveis para campos Memos Virtuais						 ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If Type("aMemos")=="A"
			For nX := 1 To Len(aMemos)
				cMemo := aMemos[nX][2]
				If ExistIni(cMemo)
					&cMemo := CriaVar( cMemo, .T. )//InitPad(SX3->X3_RELACAO)
				Else
					&cMemo := ""
				EndIf
			Next nX
		EndIf

		If SetMDIChild()
			oMainWnd:ReadClientCoors()
			nTop := 40
			nLeft := 30
			nBottom := oMainWnd:nBottom-80
			nRight := oMainWnd:nRight-70
		Else
			nTop := 135
			nLeft := 0
			nBottom := TranslateBottom(.T.,28)
			nRight := 632
		EndIf

		DEFINE MSDIALOG oDlg TITLE cCadastro FROM aSize[7],0 TO aSize[6],aSize[5] OF oMainWnd PIXEL
		//	DEFINE MSDIALOG oDlg TITLE cCadastro FROM nTop,nLeft TO nBottom,nRight PIXEL OF oMainWnd
		If lDclNew
			oFolder := TFolder():New(13,,{STR0033,STR0034,STR0128},{STR0033,STR0034,STR0128},oDlg,,,,.t.,.F.,oDlg:nWidth,oDlg:nHeight,)	 //"Produto"###"Complemento"###"Complemento DCL"###"Produto"###"Complemento""Complemento DCL"###
		Else
			oFolder := TFolder():New(13,,{STR0033,STR0034},{STR0033,STR0034},oDlg,,,,.t.,.F.,oDlg:nWidth,oDlg:nHeight,)	 //"Produto"###"Complemento"###"Produto"###"Complemento"
		EndIf
		oFolder:align:= CONTROL_ALIGN_ALLCLIENT
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Enchoice 01                                          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("SB1")
		oEnc01:= MsMGet():New("SB1" ,nReg ,nOpc,,,,IIF(ValType(aCpos)=="A",aCpos,Nil),aPosObj[1],   ,       ,        ,          ,      ,oFolder:aDialogs[1])
		oEnc01:oBox:align:= CONTROL_ALIGN_ALLCLIENT

		If lDclNew
			//Enchoice 03
			dbSelectArea("DH5")
			oEnc03 := MsMGet():New("DH5",nRegDH5,nOpc,,,,/*aAcho*/,aPosObj[1],,,,,,oFolder:aDialogs[3])
			oEnc03:oBox:align:= CONTROL_ALIGN_ALLCLIENT
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Enchoice 02                                          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("SB5")
		oEnc02:=MsMGet():New("SB5",nRegSB5,nOpc,,,,/*aAcho*/,aPosObj[1],,,,,,oFolder:aDialogs[2])
		oEnc02:oBox:align:= CONTROL_ALIGN_ALLCLIENT

		dbSelectArea("SB1")
		ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{|| nOpcA := 1,oDlg:End()},{|| nOpcA := 2,oDlg:End()},,aButtons)
	Else
		Help(" ",1,"A000FI")
		nOpcA := 3
	EndIf
	RestArea(aArea)
Return(nOpcA)


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010Inclui³ Autor ³ Marcelo B. Abe        ³ Data ³ 20/04/94 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa de Inclusao de Produtos                           ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ Void A010Inclui(ExpC1,ExpN1,ExpN2)                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo                                   ³±±
±±³          ³ ExpN1 = Numero do registro                                 ³±±
±±³          ³ ExpN2 = Numero da opcao selecionada 			              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA010()                                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010INCLUI(cAlias,nReg,nOpc)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Monta a entrada de dados do arquivo                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Local aButtons := {}
	Local aUsrBut  := {}
	Local aCampos  := {}
	Local nSaveSX8 := GetSx8Len()
	Local lPIMSINT := (SuperGetMV("MV_PIMSINT",.F.,.F.)) // Indica se Existe Integração Protheus x PIMS Graos
	Local aIntSB1  := {}
	Local aMvPar    := {}
	Local nCnt      := 0
	Local lIniB5	:= .F.
	Local lIniDH5	:= .F.
	Local lDclNew	:= SuperGetMV("MV_DCLNEW",.F.,.F.)
	Local lCopiaBKP
	Local aRetInt	:= {}
	Local lRet 		:= .T.
	Local lMT010INC	:= ExistBlock("MT010INC")
	Local cVEICULO := SuperGetMV("MV_VEICULO",.F.,"N")
	//-- Variavel usada para verificar se o disparo da funcao IntegDef() pode ser feita manualmente
	Local lIntegDef  :=  FWHasEAI("MATA010",.T.,,.T.)
	Local cSx3Cpo := 'BM_CLASGRU'
	Local bSavKeyF4 := Nil

	Private aTELA[0][0],aGETS[0]

	If Type("aMemos") == "U"
		Private aMemos:={{"B1_DESC_I","B1_VM_I"},{"B1_DESC_GI","B1_VM_GI"},{"B1_DESC_P","B1_VM_P"},{"B1_CODOBS","B1_OBS"},{"B1_CODPROC","B1_VM_PROC"}}
	EndIf

	If Type("cCadastro") == "U"
		Private cCadastro := OemtoAnsi(STR0008) //"Atualização de Produtos"
	EndIf

	l010Auto:= If(Type('l010Auto') <> 'L',.f.,l010Auto)
	lCopia  := If(Type('lCopia') <> 'L',.f.,lCopia)
	lCopiaBKP:=lCopia

	If lCopia .And. !IsInCallStack("MATA010")
		lCopia:=.F.
	EndIf

	bCampo := {|nCPO| Field(nCPO) }

	INCLUI := .T.
	ALTERA := .F.

	lMvcMata010 := IIF(ValType(lMvcMata010) == "L",lMvcMata010, TableInDic( "G3Q", .F. ))

	If lMvcMata010
		lMnuCRM := .F.
		MA010Inclu(cAlias,nReg,nOpc)
		A010AtuDesc()
		Return
	EndIf

	For nCnt := 1 To 60
		Aadd( aMvPar, &( "MV_PAR"+STRZERO(nCnt,2) ) )
	Next nCnt

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Desativa a tecla F4                                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	PERGUNTE("MTA010",.F.)

	If !l010Auto
		bSavKeyF4 := SetKey(VK_F4,Nil)
	EndIf

	If ExistTemplate( "MA010BUT" )
		If Valtype( aUsrBut := ExecTemplate( "MA010BUT", .f., .f. ) ) == "A"
			AEval( aUsrBut, { |x| AAdd( aButtons, x ) } )
		EndIF
	EndIf

	If ExistBlock( "MA010BUT" )
		If Valtype( aUsrBut := Execblock( "MA010BUT", .f., .f. ) ) == "A"
			AEval( aUsrBut, { |x| AAdd( aButtons, x ) } )
		EndIF
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Integracao PIMS GRAOS                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lPIMSINT
		// Tratamento para adicinar o campo BM_CLASGRU no layout do arquivo XML
		Aadd( aCampos, { FwX3Titulo( cSx3Cpo ), ESTFwSx3Util():xGetDescription( cSx3Cpo ), cSx3Cpo, TamSx3( cSx3Cpo )[ 3 ], TamSx3( cSx3Cpo )[ 1 ], TamSx3( cSx3Cpo )[ 2 ],NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL})
	EndIf

	While .T.
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Envia para processamento dos Gets          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		nOpcA:=0

		If ( l010Auto )
			Begin Transaction
				nOpcA := AxInclui(cAlias, nReg, nOpc,/*aAcho*/,/*cFunc*/,/*aCpos*/,"A010TudoOk(nOpc)",/*lF3*/,/*cTransact*/,aButtons,,aRotAuto,/*lVirtual*/)
				If __lSX8
					IF nOpcA == 1
						While ( GetSx8Len() > 0 )
							ConfirmSX8()
						Enddo
						A010Int( 2, nOpc, aIntSB1 )
					Else
						While ( GetSx8Len() > 0 )
							RollBackSX8()
						Enddo
					EndIf
				EndIf
			End Transaction
		Else
			If lCopia
				Begin Transaction
					If mv_par02 == 1
						SB5->(DbSetOrder(1))
						lIniB5 := !(SB5->(DbSeek(xFilial("SB5")+SB1->B1_COD)))
						If lDclNew
							DH5->(DbSetOrder(1))
							lIniDH5 := !(DH5->(DbSeek(xFilial("DH5")+SB1->B1_COD)))
						EndIf
						nOpcA:=A010IncPeC( cAlias, nReg, nOpc,"A010LeReg",,"A010TudoOk(nOpc)",aButtons,.T.,lIniB5,lIniDH5)
					Else
						nOpcA:=AxInclui( cAlias, nReg, nOpc,,"A010LeReg",,"A010TudoOk(nOpc)",,,aButtons,,,.T.)
					EndIf

					//Tratamento mensagem unica produto
					If nOpcA == 1 .And. lIntegDef
						aRetInt := FwIntegDef("MATA010",,,,"MATA010")

						If Valtype(aRetInt) == "A"
							If Len(aRetInt) == 2
								If !aRetInt[1]
									If Empty(AllTrim(aRetInt[2]))
										cMsgRet := STR0127 //"Verificar problema no Monitor EAI"
									Else
										cMsgRet := AllTrim(aRetInt[2])
									Endif
									Aviso(STR0032,cMsgRet,{"Ok"},3) //"Atenção"
									DisarmTransaction()
									lRet := .F.
								Endif
							Endif
						Endif
					EndIf
					//Chamada de função para verificar integração OMS x CPL
					If lRet .And. FindFunction("OMSXCPLINT") .And. nOpcA == 1
						OMSXCPLINT("SB1")
					EndIf
					If __lSX8
						IF nOpcA == 1
							While ( GetSx8Len() > nSaveSX8 )
								ConfirmSx8()
							Enddo
							A010Int( 2, nOpc, aIntSB1 )
						Else
							While ( GetSx8Len() > nSaveSX8 )
								RollBackSX8()
							Enddo
						EndIf
					EndIf
				End Transaction
			Else
				Begin Transaction
					If mv_par02 == 1
						nOpcA:=A010IncPeC( cAlias, nReg, nOpc, , ,"A010TudoOk(nOpc)",aButtons) // incluir Produto e complemento
					Else
						nOpcA:=AxInclui( cAlias, nReg, nOpc,,,,"A010TudoOk(nOpc)",,,aButtons)
					EndIf

					//Tratamento mensagem unica produto
					If nOpcA == 1 .And. lIntegDef
						aRetInt := FwIntegDef("MATA010",,,,"MATA010")

						If Valtype(aRetInt) == "A"
							If Len(aRetInt) == 2
								If !aRetInt[1]
									If Empty(AllTrim(aRetInt[2]))
										cMsgRet := STR0127 //"Verificar problema no Monitor EAI"
									Else
										cMsgRet := AllTrim(aRetInt[2])
									Endif
									Aviso(STR0032,cMsgRet,{"Ok"},3) //"Atenção"
									DisarmTransaction()
									lRet := .F.
								Endif
							Endif
						Endif
					EndIf
					//Chamada de função para verificar integração OMS x CPL
					If lRet .And. FindFunction("OMSXCPLINT") .And. nOpcA == 1
						OMSXCPLINT("SB1")
					EndIf
				End Transaction
			EndIf
		EndIf

		If lRet
			dbSelectArea(cAlias)

			IF nOpcA == 1
				A010Int( 2, nOpc, aIntSB1 )

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Faz as Consistencias entre o F.D. do Canal com o SA5.                 ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If B1_MONO == 'S'
					A010FDC()
				Else
					A010AtuDesc()
				Endif

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Se for codigo inteligente acrescenta estrutura                        ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				A093VldCod(B1_COD,.T.,,,,,,,,,.T.)

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Envia e-mail ref. Inclusao de novos produtos - 033 ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				MEnviaMail("033",{B1_FILIAL,B1_COD,B1_DESC,B1_TIPO,B1_LOCPAD,B1_UM,CUSERNAME})

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Pontos de entrada depois da confirma‡Æo.                              ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If ExistTemplate("MT010INC")
					ExecTemplate("MT010INC")
				Endif

				If lMT010INC
					ExecBlock("MT010INC",.F.,.F.)
				Endif
				/*  GRAVACAO DO B1_CODITE QUANDO INTEGRADO COM CONCESSIONARIAS */
				If cVEICULO =="S" .and. Empty(SB1->B1_CODITE)
					Reclock("SB1",.F.)
					SB1->B1_CODITE := SB1->B1_COD
					MSUnlock()
				Endif
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Integracao PIMS GRAOS                             ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If lPIMSINT
					PIMSGeraXML(STR0129,STR0047,"2","SB1",aCampos) //"Item"--## Cadastro de produtos
				EndIf
				/*--------------------*/
				LJ110AltOk()
			Endif
		EndIf

		Exit
	End

	If lRet
		dbSelectArea(cAlias)
		If (ExistBlock("MT010CAN"))
			ExecBlock("MT010CAN",.F.,.F.,{nOpcA})
		EndIf
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ativa tecla  para comunicacao com Saldos dos Lotes           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !l010Auto
		SetKey(VK_F4,bSavKeyF4)
	EndIf

	For nCnt := 1 To Len( aMvPar )
		&( "MV_PAR"+STRZERO(nCnt,2) ) := aMvPar[ nCnt ]
	Next nCnt

	lCopia:=lCopiaBKP

Return lRet


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010Altera³ Autor ³ Marcelo B. Abe        ³ Data ³ 20/04/94 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa de Alteracao de Produtos                          ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe e ³ Void A010Altera(ExpC1,ExpN1,ExpN2)                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo                                   ³±±
±±³          ³ ExpN1 = Numero do registro                                 ³±±
±±³          ³ ExpN2 = Numero da opcao selecionada 			              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA010()                                                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010ALTERA(cAlias,nReg,nOpc)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Monta a entrada de dados do arquivo                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Local aButtons	:= {}
	Local aUsrBut	:= {}
	Local aCampos	:= {}
	Local nX		:= 0
	Local lHistTab	:= SuperGetMV("MV_HISTTAB", .F., .F.)
	Local lPIMSINT	:= (SuperGetMV("MV_PIMSINT",.F.,.F.))// Indica se Existe Integração Protheus x PIMS Graos
	Local lDclNew	:= SuperGetMV("MV_DCLNEW",.F.,.F.)
	Local cFilialAIF:= xFilial("AIF")
	Local cFilialSB1:= xFilial("SB1")
	Local dDataAlt
	Local cHoraAlt
	Local aIntSB1	:= {}
	Local bCampoSB1 := { |x| SB1->(Field(x)) }
	Local aCmps     := {}
	Local cGrpAnt   := SB1->B1_GRUPO
	Local aArea		:= GetArea()
	Local lContinua	:= .T.
	Local lMT010ALT := ExistBlock("MT010ALT")
	Local cVEICULO	:= SuperGetMV("MV_VEICULO",.F.,"N")

	//-- Variavel usada para verificar se o disparo da funcao IntegDef() pode ser feita manualmente
	Local lIntegDef  :=  FWHasEAI("MATA010",.T.,,.T.)
	Local aRetInt		:= {}
	Local cSx3Cpo	:= "BM_CLASGRU"

	Private aTELA[0][0],aGETS[0]

	bCampo := {|nCPO| Field(nCPO) }
	l010Auto := If(Type("l010Auto") == "U", .f.,l010Auto)

	INCLUI := .F.
	ALTERA := .T.

	lMvcMata010 := IIF(ValType(lMvcMata010) == "L",lMvcMata010, TableInDic( "G3Q", .F. ))

	If lMvcMata010
		lMnuCRM := .T.
		MA010Alter(cAlias,nReg,nOpc)
		A010AtuDesc()
		Return
	EndIf

	//inclusao dinamica do botao para poder selecionar os opcionais, no minimo quando houver estrutura.
	SG1->(DbSetOrder(1))
	If SG1->(DbSeek(xFilial('SG1')+SB1->B1_COD))
		AAdd(aButtons,{'PRODUTO',{|| A010SeleOpc(.T.) },STR0029 }) //"Opcionais Default"
		AAdd(aButtons,{'PRODOPC',{|| A010LimpOp() }, STR0112 }) //"Limpa os opcionais"
	EndIf

	//inclusao automatica de botoes atraves de ponto de entrada
	If ExistTemplate( "MA010BUT" )
		If Valtype( aUsrBut := ExecTemplate( "MA010BUT", .f., .f. ) ) == "A"
			AEval( aUsrBut, { |x| AAdd( aButtons, x ) } )
		EndIF
	EndIf

	If ExistBlock( "MA010BUT" )
		If Valtype( aUsrBut := Execblock( "MA010BUT", .f., .f. ) ) == "A"
			AEval( aUsrBut, { |x| AAdd( aButtons, x ) } )
		EndIF
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Salva dados antes da alteracao.³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aCmps :=  RetCmps("SB1",bCampoSB1)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Integracao PIMS GRAOS                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lPIMSINT
		// Tratamento para adicinar o campo BM_CLASGRU no layout do arquivo XML
		Aadd( aCampos, { FwX3Titulo( cSx3Cpo ), ESTFwSx3Util():xGetDescription( cSx3Cpo ), cSx3Cpo, TamSx3( cSx3Cpo )[ 3 ], TamSx3( cSx3Cpo )[ 1 ], TamSx3( cSx3Cpo )[ 2 ],NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL})
	EndIf

	PERGUNTE("MTA010",.F.)

	A010Int( 1, nOpc, aIntSB1 )

	While .T.
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Envia para processamento dos Gets          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		nOpcA:=0

		Begin Transaction
			If ( l010Auto )
				nOpcA := AxAltera( cAlias, nReg, nOpc,,,,,"A010TUDOOK(nOpc)",,, aButtons,, aRotAuto )
			Else
				If MV_PAR02 == 1
					SB5->(DbSetOrder(1))
					If SB5->(DbSeek(xFilial("SB5")+SB1->B1_COD))
						If lDclNew
							DH5->(DbSetOrder(1))
							DH5->(DbSeek(xFilial("DH5")+SB1->B1_COD))
						EndIf
						nOpcA := A010AltPeC(cAlias,nReg,nOpc,,,"A010TUDOOK(nOpc)", ,aButtons)
					Else
						nOpcA := AxAltera( cAlias, nReg, nOpc,,,,,"A010TUDOOK(nOpc)",,,aButtons)
					EndIf
				Else
					nOpcA := AxAltera( cAlias, nReg, nOpc,,,,,"A010TUDOOK(nOpc)",,,aButtons)
				EndIf

				//Tratamento mensagem unica produto
				If nOpcA == 1 .And. lIntegDef
					aRetInt := FwIntegDef("MATA010",,,,"MATA010")

					If Valtype(aRetInt) == "A"
						If Len(aRetInt) == 2
							If !aRetInt[1]
								If Empty(AllTrim(aRetInt[2]))
									cMsgRet := STR0127 //"Verificar problema no Monitor EAI"
								Else
									cMsgRet := AllTrim(aRetInt[2])
								Endif
								Aviso(STR0032,cMsgRet,{"Ok"},3) //"Atenção"
								DisarmTransaction()
								lContinua:= .F.
								Break
							Endif
						Endif
					Endif
				EndIf

				//Chamada de função para verificar integração OMS x CPL
				If FindFunction("OMSXCPLINT") .And. nOpcA == 1
					OMSXCPLINT("SB1")
				EndIf
			EndIf

			dbSelectArea(cAlias)

			If nOpcA == 1

				A010Int( 2, nOpc, aIntSB1 )

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Atualiza a tabela QE6 - Especificacao de Produtos                     ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				QAtuB12QE6()	//SIGAQIE

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Atualiza a tabela QP6 - Especificacao de Produtos                     ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				QAtuB12QP6()	//SIGAQIP


				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Atualiza a tabela EIM - N.V.E. por Produto - SIGAEIC                  ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If ExistFunc("EasyNVEChk") .And. EasyNVEChk()
					EasyValNVE("MATA010")	//SIGAEIC
				EndIf

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Faz as Consistencias entre o F.D. do Canal com o SA5.                 ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If B1_MONO=="S"
					A010FDC()
				Else
					A010AtuDesc()
				Endif
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Pontos de entrada depois da confirma‡ao da altera‡ao.                 ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If ExistTemplate("MT010ALT")
					ExecTemplate("MT010ALT",.f.,.f.)
				Endif

				If lMT010ALT
					ExecBlock("MT010ALT",.f.,.f.)
				Endif

				/*  GRAVACAO DO B1_CODITE QUANDO INTEGRADO COM CONCESSIONARIAS */
				If cVEICULO =="S"
					If(Empty(SB1->B1_CODITE))
						Reclock("SB1",.F.)
						SB1->B1_CODITE := SB1->B1_COD
						MSUnlock()
					EndIf

					If cGrpAnt != SB1->B1_GRUPO // Se grupo foi modificado roda rotina de alteracao de grupo
						If ExistFunc('FGX_ALTGRU')
							FGX_ALTGRU( SB1->B1_COD, SB1->B1_CODITE, cGrpAnt, SB1->B1_GRUPO )
						EndIf
					EndIf
				Endif
				/*--------------------*/

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Gravar o historico das alteracoes realizadas pelo usuario    ³
				//³na tabela AIF usando o vetor aCpoAltSB1 que foi carregado na ³
				//³funcao A010TdOk().                                         ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If lHistTab .And. Len(aCpoAltSB1) > 0
					dDataAlt := Date()
					cHoraAlt := Time()
					For nX := 1 To Len(aCpoAltSB1)
						MSGrvHist(cFilialAIF,;			// Filial de AIF
						cFilialSB1,;			// Filial da tabela SB1
						"SB1",;				// Tabela SB1
						"",;					// Codigo do cliente
						"",;					// Loja do cliente
						aCpoAltSB1[nX][1],;	// Campo alterado
						aCpoAltSB1[nX][2],;	// Conteudo antes da alteracao
						dDataAlt,;			// Data da alteracao
						cHoraAlt,;			// Hora da alteracao
						SB1->B1_COD)			// Codigo do produto
					Next nX
					aCpoAltSB1 := {} // limpar o vetor
				EndIf
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Gravacao do historico das alteracoes.³
				//³                                     ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If lHistFiscal .And. Len(aCmpoSB1) > 0
					GrvHistFis("SB1", "SS4", aCmps)
					aCmpoSB1 := {} // limpar o vetor
					aCmps    := {}
				EndIf

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Integracao PIMS GRAOS                             ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If lPIMSINT
					SBM->(DbSeek(xFilial("SBM")+SB1->B1_GRUPO))
					PIMSGeraXML(STR0129,STR0047,"2","SB1",aCampos) //"Item"--## Cadastro de produtos
				EndIf

				LJ110AltOk()

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Atualiza o campo B5_INTDI - Integração DI
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				SB5->(DbSetOrder(1))
				If SB5->(DbSeek(xFilial("SB5")+SB1->B1_COD))
					RecLock("SB5",.F.)
					SB5->B5_INTDI := '2'
					MsUnlock()
				EndIf
			Endif
		End Transaction
		Exit
	End

	If lContinua
		If (ExistBlock("MT010CAN"))
			ExecBlock("MT010CAN",.F.,.F.,{nOpcA})
		EndIf
	EndIf

	RestArea(aArea)

	dbSelectArea(cAlias)
Return Nil


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010FDC   ³ Autor ³ Marcelo B. Abe        ³ Data ³ 20/04/94 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa de Alteracao de Produtos                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe e ³ Void A010FDC (void)                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .F.                                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ A010INCLUI e A010ALTERA                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function A010FDC(void)
	// Migrado para o fonte MATA010M com novo nome de A010FDCANAL
	A010FDCANAL()
Return(.F.)

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010Preco ³ Autor ³ Marcos Bregantim      ³ Data ³ 17.05.94 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Validar Data de Referencia do Preco                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A010Preco()                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T.                                                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
FUNCTION A010Preco()

	LOCAL cPer := Substr(ReadVar(),10,1), cVar
	If "B1_"$ReadVar()
		cVar := "B1_DTREFP" + cPer
	Elseif "B5_"$ReadVar()
		cVar := "B5_DTREFP" + cPer
	Endif

	If &(ReadVar()) > 0
		M->&cVar := dDataBase
	Endif
Return(.T.)


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010Grade ³ Autor ³ Rosane Luciane Chene  ³ Data ³ 23.10.95 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica se o produto nao foi cadastrado como referencia   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A010Grade()                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T./.F.                                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ Generico                                                   ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010Grade()

	Local aArea
	Local cProduto	  :=&(ReadVar())
	Local cMascara    := SuperGetMv("MV_MASCGRD")
	Local lRet		  :=.T.
	Local nTamRef     := Val(Substr(cMascara,1,2))

	lGrade	  := SuperGetMV("MV_GRADE")


	If lGrade
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³So salva ambiente se o parametro MV_GRADE estiver habilitado            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aArea := GetArea()

		cProduto := Substr(cProduto,1,nTamRef)

		dbSelectArea("SB4")
		dbSetOrder(1)
		If ( MsSeek(xFilial("SB4")+cProduto,.F.) .And. !Empty(cProduto) .And. ;
				AllTrim(SubStr(cProduto,nTamRef+1)) == "" )
			Help(" ",1,"A010GRADE")
			lRet := .F.
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Restaura a entrada da Rotina                                            ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		RestArea(aArea)
	Endif
	if lRet
		lRet := A010VlStr ()
	EndIf
Return(lRet)


/*/{Protheus.doc} A010Mod
Verifica se o centro de custos cadastrado p/ a MOD existe
@author Rodrigo de A. Sartorio
@since 15/07/97
@version 1.0
@return logico, Verdadeiro se o produto infomarmado é valido

@type function
/*/
Function A010Mod()
Local cCC		:= ""
Local cAliasCC	:= "CTT"
Local nTamCCust	:= 0
Local lRet		:= .T.

nTamCCust := TamSX3("CTT_CUSTO")[1]

cCC := PadR(Substr(&(ReadVar()),4),nTamCCust," ")

dbSelectArea(cAliasCC)
If dbSeek(xFilial(cAliasCC)+cCC)
	lRet := CTB105CC(cCC)
Else
	Help(" ",1,"A010MOD")
	lRet := .F.
EndIf

Return(lRet)


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010Contr ³ Autor ³ Cristina Ogura        ³ Data ³ 18/07/97 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Verifica a existencia de contratos para o produto           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³A010Contr()                                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T. / .F.                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³MATA010                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010Contr()

	Local cSavAlias := Alias()
	Local nSavOrd
	Local lRet		:= .T.
	// Funcao sera descontinuada na versão de janeiro da 12.1.17
	dbSelectArea("SC3")
	nSavOrd := IndexOrd()
	dbSetOrder(3)

	If Altera .And. !(cPaisLoc $ "ARG|POR|EUA") .And. M->B1_CONTRAT == "N"
		If dbSeek(xFilial("SC3")+M->B1_COD)
			While !Eof() .And. SC3->C3_FILIAL+SC3->C3_PRODUTO == xFilial("SC3")+M->B1_COD
				If SC3->C3_ENCER != "E"
					Help(" ",1,"A010AE")
					lRet := .F.
					Exit
				EndIf
				dbSkip()
			EndDo
		EndIf
	EndIf

	dbSelectArea("SC3")
	dbSetOrder(nSavOrd)
	dbSelectArea(cSavAlias)

Return(lRet)


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010Import³ Autor ³ MICROSIGA/AVERAGE     ³ Data ³ 20/08/97 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Consiste campos relativos a Importacao (SIGAEIC)            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³A010Import()                                                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T. / .F.                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³MATA010                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010Import()

	Local lRet:=.T.

	If M->B1_IMPORT == "S" .And. Empty(M->B1_UNI)
		Help("",1,"A010UNI")
		lRet:=.F.
	Endif
Return(lRet)


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010TudoOk³ Autor ³Rodrigo de A. Sartorio ³ Data ³ 17/07/97 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Verifica se o registro nao foi incluido por outra estacao   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³A010TudoOk(ExpN1)		                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpN1 - Numero da opcao selecionada                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T. / .F.                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³MATA010                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010TudoOk(nOpc)

	Local lRet      := .T.
	Local l010TOkT  := ExistTemplate("A010TOK")
	Local l010TOk   := Existblock("A010TOK")
	Local nX        := 0
	Local nY  		 := 0
	Local lHistTab  := SuperGetMV("MV_HISTTAB", .F., .F.)
	Local bCampoSB1 := { |x| SB1->(Field(x)) }
	Local aArea     := GetArea()
	Local lIntSFC  	:=  ExisteSFC("SB1") .And. !IsInCallStack("AUTO010")
	Local lIntDPR 	:= IntegraDPR() .And. !IsInCallStack("AUTO010")// Determina se existe integracao com o DPR
	Local lDAmarCt	:= SuperGetMV("MV_DAMARCT",.F.,.F.)
	Local nOpcSFC	:= If(lCopia,3,nOpc) //Quando copia do registro, muda operação para inclusão
	Local cFilialSB1:= xFilial("SB1")
	Local cFilialAIF:= xFilial("AIF")

	// ====================================================================
	// VERIFICA INTEGRACAO COM SIGATAF
	Local lIntTAF  := FindFunction("TAFExstInt") .AND. TAFExstInt()

	lRet:=ExistChav("SB1",M->B1_COD)
	If lRet
		If SuperGetMv("MV_DCLNEW",.F.,.F.)
			lRet := DCLA010TOK()
		ElseIf l010TOkT
			lRet:= ExecTemplate("A010TOK",.F.,.F.)
			If ValType(lRet) # "L"
				lRet :=.T.
			EndIf
		EndIf

		If lRet
			If l010TOk
				lRet:= Execblock("A010TOK",.F.,.F.)
				If ValType(lRet) # "L"
					lRet :=.T.
				EndIf
			EndIf
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Carregar o vetor aCpoAltSB1 caso o campo B1_DESC tenha  ³
		//³sido alterado. Somente sera gravado na tabela AIF apos  ³
		//³a validacao completa da rotina.                         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Alterado por Patricia Rajao em 24/05/2010               ³
		//³Carregar o vetor aCpoAltSB1 caso os campos: B1_DESC,    ³
		//³B1_PICMENT e B1_PICMRET tenham sido alterados.          ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lRet .And. !Inclui .And. lHistTab
			aCpoAltSB1 := {}
			DbSelectArea("SB1")
			For nX := 1 to FCount()
				IF(eVal( bCampoSB1, nX) == "B1_DESC") .OR. (eVal( bCampoSB1, nX) == "B1_PICMENT") .OR. (eVal( bCampoSB1, nX) == "B1_PICMRET") .OR. (eVal( bCampoSB1, nX) == "B1_CODANT")
					If !(M->&( eVal( bCampoSB1, nX) ) == &( eVal( bCampoSB1, nX) ))
						aAdd( aCpoAltSB1, { eVal( bCampoSB1, nX), &( eVal( bCampoSB1, nX) ) } )
					EndIf
				EndIf
			Next nX
		EndIf

		If  lRet .And. lHistTab .And. !Empty(M->B1_CODANT) .And. Inclui .And. FindFunction("MSGrvHist")
			aCpoAltSB1 :={{"B1_CODANT",""}}
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Gravar o historico das inclusão realizadas pelo usuario    ³
		//³na tabela AIF usando o vetor aCpoAltSB1                    ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lHistTab .And. Iif(Type('aCpoAltSB1')<> "U",Len(aCpoAltSB1) > 0,.F.) .And. (!Empty(M->B1_CODANT) .And. Inclui)
			dDataAlt := Date()
			cHoraAlt := Time()
			For nX := 1 To Len(aCpoAltSB1)
				MSGrvHist(	cFilialAIF,;			// Filial de AIF
							cFilialSB1,;			// Filial da tabela SB1
							"SB1",;				// Tabela SB1
							"",;					// Codigo do cliente
							"",;					// Loja do cliente
							aCpoAltSB1[nX][1],;	// Campo alterado
							aCpoAltSB1[nX][2],;	// Conteudo antes da alteracao
							dDataAlt,;			// Data da alteracao
							cHoraAlt,;			// Hora da alteracao
							M->B1_COD)			// Codigo do produto
			Next nX
			aCpoAltSB1 := {} // limpar o vetor
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Valida o campo B1_LOCALIZ   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lRet .And. M->B1_LOCALIZ <> "S" .And. M->B1_LOCALIZ <> "N"
			Help(" ",1,"B1_LOCALIZ")
			lRet := .F.
		EndIf

		If lRet
			lRet := AvalLocali(M->B1_COD,.F.)
		Endif

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Gravacao do log de produtos ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If lRet .And. ALTERA
			A013GrvLog("SB1",M->B1_COD)
		Endif
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Chama rotina para integracao com SFC(Chao de Fabrica) ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lRet .And. (lIntSFC .Or. lIntDPR)
		lRet := A010IntSFC(nOpcSFC)
	EndIf

	//Consiste amarração da Conta Contábil X Centro de Custo
	If lRet .And. lDAmarCt
		If !Empty(M->B1_CONTA) .And. !Empty(M->B1_CC) .And. (!CtbAmarra(M->B1_CONTA,M->B1_CC,M->B1_ITEMCC,M->B1_CLVL))
			lRet:=.F.
		EndIf
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
	//³Carrega array, caso algum campo tenha sido alterado.³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
	If lRet .And. !Inclui .And. lHistFiscal
		aCmpoSB1 := {}
		DbSelectArea("SB1")
		For nY := 1 to FCount()
			If !(M->&( eVal( bCampoSB1, nY) ) == &( eVal( bCampoSB1, nY) ))
				aAdd( aCmpoSB1, { eVal( bCampoSB1, nY), &( eVal( bCampoSB1, nY) ) } )
			EndIf
		Next nY

		If Len(aCmpoSB1)>0 .And. lHistFiscal
			M->B1_IDHIST := IdHistFis()
		EndIf
	EndIf

	//-- MIL - CODITE - Validação para não permitir mesmo Grupo+Codite quando utilizado o Módulo de Concessionárias
	If lRet .And. SuperGetMV("MV_VEICULO",.F.,"N") == "S" .And. !Empty(M->B1_CODITE)
		lRet := ExistChav("SB1",M->B1_GRUPO+M->B1_CODITE,7)
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Valida Custeio de OP com produto de Apropriacao Indireta³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lRet .And. M->B1_APROPRI = "I" .And. M->B1_AGREGCU = "1"
		Help(" ",1,"M010APR")
		lRet := .F.
	EndIf

	If lRet .And. !Empty(M->B1_PROC) .And. !Empty(M->B1_LOJPROC)
		lRet := ExistCpo('SA2', M->B1_PROC + M->B1_LOJPROC, 1)
	EndIf

// ==============================================
// Demetrio - 11/2014 - Integração TAF
// ==============================================
If lRet .AND. lIntTAF
	MsgRun( STR0051, STR0130, {|| TAFIntOnLn("T007",nOpc,cFilAnt) } ) // "Aguarde" "Realizando integração do produto com SIGATAF"
EndIf

// Integração com PC-Factory (PPI Multitask)
If lRet .And. FindFunction('PCPIntgPPI') .And. PCPIntgPPI()
	//Realiza a integração.
	lRet := MATA010PPI(,,.F.)
EndIf

//-- Integracao Protheus x DRP NeoGrid (ALTERACAO)
If lRet .And. Altera
	If SB5->(ColumnPos("B5_DRPEXP")) > 0
		SB5->(dbSetOrder(1)) //B5_FILIAL+B5_COD
		If SB5->(dbSeek(xFilial("SB5") + M->B1_COD))
			RecLock("SB5", .F.)
			SB5->B5_DRPEXP := ""
			SB5->(MsUnLock())
		EndIf
	EndIf
EndIf

RestArea(aArea)
Return(lRet)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ AVALF4   ³ Autor ³ Rodrigo de A. Sartorio³ Data ³ 01/12/95 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Chamada da funcao F4                                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum 	                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA241                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function MT010F4()
	Local cFilBkp := cFilAnt
	Set Key VK_F4 TO
	If FWModeAccess("SB1")=="E"
		cFilAnt := SB1->B1_FILIAL
	EndIf
	MaViewSB2(SB1->B1_COD)
	cFilAnt := cFilBkp
	Set Key VK_F4 TO MT010F4()
Return Nil


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ MTA010OK ³ Autor ³ AVERAGE               ³ Data ³ 28/07/00 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Verifica se existe Solic. de Importacao               	  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T. / .F.                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                   		  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function Mta010ok()

	Local lRet := .t.
	Local cArea:= ALIAS()

	If nModulo == 17	// SIGAEIC
		dbSelectArea("SW1")
		dbSetOrder(3)
		If dbSeek(xFilial("SW1")+SB1->B1_COD)
			MsgInfo(STR0014) //"Produto possui Solicitacao de Importacao em andamento"
			lRet:=.F.
		else
			lRet:=.T.
		endif
		dbSetOrder(1)
		dbSelectArea(cArea)
	Endif
Return(lRet)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ MTA010E  ³ Autor ³ AVERAGE               ³ Data ³ 28/07/00 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Grava campo memo     do EIC                          	  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum 	                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³                                                   		  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function Mta010e()

	If nModulo == 17			//SIGAEIC
		MSMM(SB1->B1_DESC_I,,,,2)
		MSMM(SB1->B1_DESC_GI,,,,2)
		MSMM(SB1->B1_DESC_P,,,,2)
	Endif
Return Nil


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³ A010Copia  ³ Autor ³ Larson Zordan         ³ Data ³ 17.07.01 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Ativa o sem foro informado que, na inclus„o, ser  usado      ³±±
±±³          ³ o produto corrente como modelo para o produto novo.          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum               	                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T.     	                                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ SIGAEST                                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
Function A010Copia()

	Local aArea   	:= { Alias(), IndexOrd(), Recno() }
	Local nPosSB1 	:= aArea[3]
	Local aRots
	Local lContinua	:= .T.
	Local lMT010VLD := ExistBlock("MT010VLD")
	Local bSavKeyF4 := Nil
	Local cUsrFil   := cFilAnt
	Local aAreaSM0  := SM0->(GetArea())
	Local nOpcMVC   := 0
	Local nOpcPE    := 0

	If lMT010VLD
		lContinua := ExecBlock("MT010VLD",.F.,.F.)
		If ValType(lContinua) <> "L"
			lContinua := .T.
		EndIf
	EndIf

	If lContinua
		If lMvcMata010
			lMnuCRM := .F.
			bSavKeyF4 := SetKey(VK_F4,Nil)
			nOpcMVC := (FWExecView (STR0015, "MATA010",  OP_COPIA,,{||.T.},,,,,,,))

			//Manter compatibilidade com MT010CAN, conforme TDN:
			//https://tdn.totvs.com.br/pages/releaseview.action?pageId=6087683

			If (ExistBlock("MT010CPCAN"))
				If nOpcMVC == 0
					nOpcPE := 1 //Confirma
				Else
					nOpcPE := 3 //Cancela
				EndIf

				ExecBlock("MT010CPCAN",.F.,.F.,{nOpcPE})
			EndIf

			SetKey(VK_F4,bSavKeyF4)

			//Restaura o posicionamento do SIGAMAT
			RestArea(aAreaSM0)
			cFilAnt := cUsrFil

			Return
		EndIf

		If Type("aRotina") == "A"
			aRots 	:= AClone(aRotina)
		EndIf

		aRotina := { { OemtoAnsi(STR0015) ,"A010Copia" , 0, 3, 0, .F. }}           //"Copia"

		If xFilial("SB1") # SB1->B1_FILIAL .or. (SB1->(EOF()) .and. SB1->(BOF()))
			HELP(" ",1,"ARQVAZIO")
			lContinua := .F.
		Endif

		If lContinua
			lCopia := .T.

			A010Inclui("SB1",nPosSB1,1)

			dbSelectArea( aArea[1] )
			dbSetOrder( aArea[2] )
			lCopia := .F.
			If Type("aRots") == "A"
				aRotina := AClone(aRots)
			EndIf

		EndIf
	EndIf

Return(.T.)


/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³ A010LeReg  ³ Autor ³ Larson Zordan         ³ Data ³ 17.07.01 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Duplica um registro usando como base o registro posicionado  ³±±
±±³          ³ pelo MBrowse. Ser  chamada pela inclus„o quando o sem foro   ³±±
±±³          ³ lCopia estiver ligado na rotina de inclus„o.                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                    	³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum 	                                                 	³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ SIGAEST                                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
Function A010LeReg()

	Local aCpoNot   := {}
	Local bCampo := { |nCPO| Field(nCPO) }
	Local nScan  := 0
	Local cCodMem:= ""
	Local cMemo  := ""
	Local i      := 0

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ponto que Indica os campos que nao devem ser copiados    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If ExistBlock( "MTA010NC" )
		If Valtype( aCpoNot := ExecBlock( "MTA010NC", .F., .F. ) ) <> "A"
			aCpoNot   := {}
		EndIf
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Copia os campos do produto de referˆncia para a mem¢ria. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SB1")
	FOR i := 1 TO FCount()
		If !(FieldName( i ) == "B1_COD"		.Or. ;
				FieldName( i ) == "B1_CODITE" .Or. ;
				FieldName( i ) == "B1_OPC"    .Or. ;
				FieldName( i ) == "B1_UCALSTD"	.Or. ;
				FieldName( i ) == "B1_UPRC"    .Or. ;
				FieldName( i ) == "B1_UCOM"    .Or. ;
				FieldName( i ) == "B1_UREV"    .Or. ;
				FieldName( i ) == "B1_DATREF"  	.Or. ;
				FieldName( i ) == "B1_DTREFP1"	.Or. ;
				FieldName( i ) == "B1_CONINI"	.Or. ;
				FieldName( i ) == "B1_REVATU"	.Or. ;
				FieldName( i ) == "B1_MOPC" )	.And. ;
				Empty( AScan( aCpoNot,{|x| x == Upper(allTrim(FieldName( I )))} ) )

			If Empty( nScan := AScan( aMemos, { |x| x[1] == FieldName( i ) } ) )
				M->&(EVAL(bCampo,i)) := FieldGet(i)
			Else
				cCodMem := FieldGet(i)
				cMemo   := MSMM( cCodMem )
				M->&(aMemos[nScan,2]) := cMemo
			EndIf
		EndIf
	NEXT i

Return Nil


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡„o    ³ A010Potenci³ Autor ³Rodrigo de A. Sartorio ³ Data ³ 31.07.02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡„o ³ Valida potencia padrao digitada                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                    	³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T. / .F.                                                 	³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ SIGAEST                                                      ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
*/
Function A010Potenci()

	LOCAL lRet := .T.
	If !Empty(&(ReadVar()))
		HELP(" ",1,"MA010NAOP")
		lRet:=.F.
	EndIf
Return(lRet)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010LotQlt³ Autor ³Paulo Emidio de Barros ³ Data ³29/08/2001³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Sugere o tipo de Rastreaabilidade, quando o produto estiver³±±
±±³ 		 ³ com opcao de envio para Inspecao no Quality				  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T. / .F.                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function a010LotQlt()

	Local lRet := .T.
Return(lRet)


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010AtuDesc³ Autor ³ Henry Fila           ³ Data ³ 23/09/02 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Programa de Atualizacao da descricao dos produtos no SA5   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe e ³ A010AtuDesc()                                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ A010INCLUI e A010ALTERA                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010AtuDesc()

	Local aArea    := GetArea()
	Local aAreaSB1 := SB1->(GetArea())
	Local aAreaSA5 := SA5->(GetArea())


	PERGUNTE("MTA010",.F.) // para restaurar as perguntas da rotina
	SA5->(dbSetOrder(2))
	SA5->(MsSeek(xFilial("SA5")+SB1->B1_COD))
	While SA5->(!Eof()) .And. (SA5->A5_FILIAL+SA5->A5_PRODUTO == xFilial("SA5")+SB1->B1_COD)
		If mv_par01 == 1
			RecLock("SA5",.F.)           //Eliminar outros Fornecedores
			SA5->A5_NOMPROD := SB1->B1_DESC
			MsUnLock()
		EndIf
		SA5->(dbSkip())
	EndDo
	RestArea(aAreaSB1)
	RestArea(aAreaSA5)
	RestArea(aArea)
Return Nil


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ MT010Perg ³ Autor ³                      ³ Data ³          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Carrega o 'pergunte' para o grupo do programa              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe e ³ MT010Perg()  	                                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA010               	 	                              ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function MT010Perg()

	Pergunte("MTA010",.T.)
Return Nil


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010VLSB1 ³ Autor ³Rodrigo de A. Sartorio ³ Data ³ 06/10/04 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida a gravacao do registro no SB1 e grava o registro    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ ExpL1 := A010VLSB1(ExpO1)			                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpO1 =  Objeto que contem a enchoice no SB1               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ ExpL1 = .T. (valida p/gravar) ou .T. (nao valida gravacao) ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010VLSB1(oEncSB1)

	Local lGrava:=Obrigatorio(oEncSB1:aGets,oEncSB1:aTela) .And. A010Tudook()
	LOCAL bCampo:= {|nCPO| Field(nCPO) }
	Local ix
	If lGrava
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Cria o registro do produto                                   ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		Begin Transaction
			RecLock("SB1",.T.)
			For ix := 1 TO FCount()
				FieldPut(ix,M->&(EVAL(bCampo,ix)))
			Next ix
			Replace B1_FILIAL With xFilial("SB1")
			MsUnlock()
		End Transaction
		// Inicializa o codigo do produto no complemento de produto
		// com o conteudo do campo B1_COD
		M->B5_COD:=M->B1_COD
	EndIf
RETURN(lGrava)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010VLSB5 ³ Autor ³Rodrigo de A. Sartorio ³ Data ³ 06/10/04 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Valida a gravacao do registro no SB5 e grava o registro    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ ExpL1 := A010VLSB5(ExpO1,ExpO2)		                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpO1 =  Objeto que contem a enchoice no SB5               ³±±
±±³          ³ ExpO2 =  Objeto do BITMAP de checagem                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ ExpL1 = .T. (validacao OK) ou .T. (validacao nao Ok)		  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010VLSB5(oEncSB5,oBmpDC3)

	Local lGrava:=Obrigatorio(oEncSB5:aGets,oEncSB5:aTela)
	LOCAL bCampo:= {|nCPO| Field(nCPO) }
	Local ix
	If lGrava
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Cria o registro do complemento do produto                    ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		Begin Transaction
			RecLock("SB5",.T.)
			For ix := 1 TO FCount()
				FieldPut(ix,M->&(EVAL(bCampo,ix)))
			Next ix
			Replace B5_FILIAL With xFilial("SB5")
			MsUnlock()
		End Transaction
		DLA030AWMS(M->B1_LOCPAD,M->B1_COD,M->B1_DESC)
		DC3->(dbSetOrder(1))
		If !DC3->(dbSeek(xFilial("DC3")+M->B1_COD))
			oBmpDC3:Load("NOCHECKED")
		EndIf
	EndIf
RETURN(lGrava)


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010IncPeC³ Autor ³Alex Sandro Valario    ³ Data ³ 16/09/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Inclusao de produto junto com o complemento                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A010IncPeC(ExpC1,ExpN1,ExpN2,ExpC2,ExpA1,ExpC3,ExpA2,ExpL1)³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 =  Alias do arquivo								  ³±±
±±³          ³ ExpN1 =  Numero do registro			                      ³±±
±±³          ³ ExpN2 =  Numero da opcao selecionada	                      ³±±
±±³          ³ ExpC2 =  Nome da funcao para duplicar o reg.na inclusao,   ³±±
±±³          ³          qdo semaforo lcopia estiver ligado.            	  ³±±
±±³          ³ ExpA1 =  Array dos campos                                  ³±±
±±³          ³ ExpC3 =  Nome da funcao para TUDOOK		                  ³±±
±±³          ³ ExpA2 =  Array dos botoes								  ³±±
±±³          ³ ExpL1 =  Qdo .F. carrega inicializ.padrao p/campos virtuais³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum													  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010IncPeC(cAlias,nReg,nOpc,cFunc,aCpos,cTudoOk,aButtons,lVirtual,lIniB5,lIniDH5)

	Local aArea    := GetArea(cAlias)
	Local aSvRot   := Nil
	Local cMemo    := ""
	Local lM010B5CP:= ExistBlock("M010B5CP")
	Local lB5Descri:= .T.
	Local lDclNew		:= SuperGetMV("MV_DCLNEW",.F.,.F.)
	Local nX       := 0
	Local nPosCodB5:= 1
	Local nPosCodDH5:= 1
	Local nOpcA    := 0
	Local bCampo   := {|nCPO| Field(nCPO) }
	Local bOk      := Nil
	Local bOk2     := {|| .T.}
	Local bOk3     := {|| a010Refresh(oFolder)}
	Local oDlg
	Local aObjects    := {}
	Local aSize       := {}
	Local aInfo       := {}
	Local aPosObj     := {}
	Local lMemos	:= .F.

	//enchoice
	Local oFolder
	Private oEnc01
	Private oEnc02
	Private aTELA:=Nil,aGets:= Nil
	DEFAULT cTudoOk := ".T."
	DEFAULT bOk     := &("{|| "+cTudoOk+"}")
	DEFAULT lIniB5 	  := .F.
	DEFAULT lIniDH5 	  := .F.


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Monta a entrada de dados do arquivo							 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If nOpc == Nil
		nOpc := 3
		If Type("aRotina") == "A"
			aSvRot := aClone(aRotina)
		EndIf
		Private aRotina := { { " "," ",0,1 } ,{ " "," ",0,2 },{ " "," ",0,3 } }
	EndIf
	RegToMemory(cAlias, .T., .F. )
	RegToMemory("SB5",IIF(lIniB5 ,.T., !lCopia) , .F. )
	If lDclNew
		dbSelectArea("DH5")
		RegToMemory("DH5",IIF(lIniDH5 ,.T., !lCopia) , .F. )
	EndIf
	If lCopia
		M->B5_COD:=Space(TamSX3("B5_COD")[1])
		M->B1_COD:=CriaVar("B1_COD")
		If lM010B5CP .And. MV_PAR02 == 1
			lB5Descri:= ExecBlock("M010B5CP",.F.,.F.)
			If ValType (lB5Descri) != "L"
				lB5Descri:= .T.
			EndIf
		EndIf
		If lDclNew
			M->DH5_COD:=Space(TamSX3("DH5_COD")[1])
		EndIf
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Inicializa variaveis para campos Memos Virtuais (GILSON)			 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If Type("aMemos")=="A"
		For nX :=1 To Len(aMemos)
			cMemo := aMemos[nX][2]
			If ExistIni(cMemo)
				&cMemo := CriaVar( cMemo, .T. ) //InitPad(SX3->X3_RELACAO)
			Else
				&cMemo := ""
			EndIf
		Next nX
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Funcoes executadas antes da chamada da Enchoice      ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If cFunc != NIL
		&cFunc.()
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ajusta a largura para o tamanho padrao Protheus ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aSize := MsAdvSize()

	aObjects := {}
	AAdd( aObjects, { 100, 100, .T., .T. } )
	aInfo    := { aSize[1], aSize[2], aSize[3], aSize[4], 2, 2 }

	aPosObj := MsObjSize(aInfo,aObjects,.T.)

	DEFINE MSDIALOG oDlg TITLE cCadastro FROM aSize[7],0 TO aSize[6],aSize[5] OF oMainWnd PIXEL
	If lDclNew
		oFolder := TFolder():New(13,,{STR0033,STR0034,STR0128},{STR0033,STR0034,STR0128},oDlg,,,,.t.,.F.,oDlg:nWidth,oDlg:nHeight,) //"Produto"###"Complemento"###"Complemento DCL"###"Produto"###"Complemento""Complemento DCL"###
	Else
		oFolder := TFolder():New(13,,{STR0033,STR0034},{STR0033,STR0034},oDlg,,,,.t.,.F.,oDlg:nWidth,oDlg:nHeight,) //"Produto"###"Complemento"###"Produto"###"Complemento"
	EndIf

	oFolder:bSetOption := {|nAtu| Al_MudaEnc(nAtu,oFolder:nOption,lB5Descri)}
	oFolder:align:= CONTROL_ALIGN_ALLCLIENT
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Enchoice 01                                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aPos:={}
	dbSelectArea("SB1")
	oEnc01:= MsMGet():New("SB1" ,nReg ,nOpc,,,,,aPosObj[1],aCpos,       ,        ,          ,cTudoOk ,oFolder:aDialogs[1], ,.F.)
	oEnc01:oBox:align:= CONTROL_ALIGN_ALLCLIENT
	If lDclNew
		//³ Enchoice 03
		dbSelectArea("DH5")
		oEnc03:=MsMGet():New("DH5",nReg,nOpc,,,, ,aPosObj[1],     ,       ,        ,          ,        ,oFolder:aDialogs[3], ,lVirtual)
		nPosCodDH5 := AsCan(oEnc03:aENTRYCTRLS,{|x| UPPER(TRIM(x:cReadVar))=="M->DH5_COD"})
		If !Empty(nPosCodDH5)
			oEnc03:AENTRYCTRLS[nPosCodDH5]:bWhen	:= {|| .F.}
		EndIf
		oEnc03:oBox:align:= CONTROL_ALIGN_ALLCLIENT
		aTela3 := aClone(oEnc03:aTela)
		aGets3 := aClone(oEnc03:aGets)
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Enchoice 02                                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SB5")
	oEnc02:=MsMGet():New("SB5",nReg,nOpc,,,, ,aPosObj[1],     ,       ,        ,          ,        ,oFolder:aDialogs[2], ,lVirtual)
	nPosCodB5 := AsCan(oEnc02:aENTRYCTRLS,{|x| UPPER(TRIM(x:cReadVar))=="M->B5_COD"})
	If !Empty(nPosCodB5)
		oEnc02:AENTRYCTRLS[nPosCodB5]:bWhen	:= {|| .F.}
	EndIf
	oEnc02:oBox:align:= CONTROL_ALIGN_ALLCLIENT
	aTela := aClone(oEnc02:aTela)
	aGets := aClone(oEnc02:aGets)

	dbSelectArea("SB1")
	If lDclNew
		ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg,{|| nOpcA := 1, Eval(bOk3) .And.;
			If(Obrigatorio(oEnc01:aGets,oEnc01:aTela).And.Obrigatorio(oEnc02:aGets,oEnc02:aTela) .and.;
			Obrigatorio(oEnc03:aGets,oEnc03:aTela) .And. ;
			Eval(bOk).And.Eval(bOk2,nOpc),oDlg:End(),(nOpcA:=3,.f.))},;
			{|| nOpcA := 3,oDlg:End()},,aButtons)) CENTERED
	Else
		ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg,{|| nOpcA := 1, Eval(bOk3) .And.;
			If(Obrigatorio(oEnc01:aGets,oEnc01:aTela).And.Obrigatorio(oEnc02:aGets,oEnc02:aTela) .and.;
			Eval(bOk).And.Eval(bOk2,nOpc),oDlg:End(),(nOpcA:=3,.f.))},;
			{|| nOpcA := 3,oDlg:End()},,aButtons)) CENTERED
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Gravacao da enchoice                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If nOpcA == 1
		lMemos := Type("aMemos") == "A"
		Begin Transaction
			M->B5_COD:=M->B1_COD
			If lDclNew
				M->DH5_COD:=M->B1_COD
			EndIf
			DBSelectArea(cAlias)
			RecLock(cAlias,.T.)
			For nX := 1 TO FCount()
				If "_FILIAL"$FieldName(nX)
					FieldPut(nX,xFilial(cAlias))
				Else
					FieldPut(nX,M->&(EVAL(bCampo,nX)))
				EndIf
			Next nX
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Grava os campos Memos Virtuais					 				  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If lMemos
				For nX := 1 to Len(aMemos)
					cVar := aMemos[nX][2]
					MSMM(,TamSx3(aMemos[nX][2])[1],,&cVar,1,,,cAlias,aMemos[nX][1])
				Next nX
			EndIf
			If __lSX8
				ConfirmSX8()
			EndIf
			dbSelectArea("SB5")
			dbSetOrder(1)
			If dbSeek(xFilial("SB5")+M->B1_COD)
				RecLock("SB5",.F.)
			Else
				RecLock("SB5",.T.)
			EndIf
			For nX := 1 TO FCount()
				If "_FILIAL"$FieldName(nX)
					FieldPut(nX,xFilial("SB5"))
				Else
					FieldPut(nX,M->&(EVAL(bCampo,nX)))
				EndIf
			Next nX
			If lDclNew
				dbSelectArea("DH5")
				dbSetOrder(1)
				If dbSeek(xFilial("DH5")+M->B1_COD)
					RecLock("DH5",.F.)
				Else
					RecLock("DH5",.T.)
				EndIf
				For nX := 1 TO FCount()
					If "_FILIAL"$FieldName(nX)
						FieldPut(nX,xFilial("DH5"))
					Else
						FieldPut(nX,M->&(EVAL(bCampo,nX)))
					EndIf
				Next nX
			EndIf
		End Transaction
	Else
		If __lSX8
			RollBackSX8()
		EndIf
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Restaura a integridade dos dados                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If aSvRot != Nil
		aRotina := aClone(aSvRot)
	EndIf
	RestArea(aArea)
	lRefresh := .T.
Return(nOpcA)


Static Function Al_MudaEnc(nAtu,oFolder,lB5Descri)
	Local lDclNew		:= SuperGetMV("MV_DCLNEW",.F.,.F.)
	DEFAULT lB5Descri:= .T.

	If nAtu== 1
		dbSelectArea("SB1")
		oEnc01:oBox:align:= CONTROL_ALIGN_ALLCLIENT
		oEnc01:Refresh()
	ElseIf nAtu == 3 .And. lDclNew
		dbSelectArea("DH5")
		M->DH5_COD := M->B1_COD
		oEnc03:oBox:align:= CONTROL_ALIGN_ALLCLIENT
		oEnc03:Refresh()
	Else
		dbSelectArea("SB5")
		M->B5_COD:=M->B1_COD
		If lB5Descri
			M->B5_CEME:=If(Empty(M->B5_CEME),PADR(M->B1_DESC,Len(SB5->B5_CEME)),PADR(M->B5_CEME,Len(SB5->B5_CEME)))
		EndIf
		oEnc02:oBox:align:= CONTROL_ALIGN_ALLCLIENT
		oEnc02:Refresh()
	EndIf
Return Nil


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³ Fun‡…o   ³A010AltPeC³ Autor ³Alex Sandro Valario    ³ Data ³ 16/09/05 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Descri‡…o³ Alteracao de produto junto com o complemento               ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ ExpN1 := A010IncPeC(ExpC1,ExpN2,ExpN3,ExpA1,ExpA2,ExpC2,	  ³±±
±±³          ³          ExpC3,ExpA3)				                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 =  Alias do arquivo								  ³±±
±±³          ³ ExpN2 =  Numero do registro			                      ³±±
±±³          ³ ExpN3 =  Numero da opcao selecionada	                      ³±±
±±³          ³ ExpA1 =  nao utilizado									  ³±±
±±³          ³ ExpA2 =  Array dos campos                                  ³±±
±±³          ³ ExpC2 =  Nome da funcao para TUDOOK		                  ³±±
±±³          ³ ExpC3 =  Nome da funcao para duplicar o reg.na inclusao,   ³±±
±±³          ³          qdo semaforo lcopia estiver ligado.            	  ³±±
±±³          ³ ExpA3 =  Array dos botoes								  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ ExpN1 = nOpca											  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010AltPeC(cAlias,nReg,nOpc,aAcho,aCpos,cTudoOk,cFunc,aButtons)

	Local aArea    := GetArea(cAlias)
	Local bCampo   := {|nCPO| Field(nCPO) }
	Local bOk      := Nil
	Local bOk2     := {|| .T.}
	Local cCpoFil  := PrefixoCpo(cAlias)+"_FILIAL"
	Local cMemo    := ""
	Local nOpcA    := 0
	Local nX       := 0
	Local nPosInsPat:= 0
	Local nPosCodAtv:= 0
	Local oDlg
	Local cAliasMemo
	Local aObjects    := {}
	Local aSize       := {}
	Local aInfo       := {}
	Local aPosObj     := {}
	Local nG
	Local lDclNew		:= SuperGetMV("MV_DCLNEW",.F.,.F.)
	Local lMemos	:= .F.
	Local nPosSimpDH5		:= 1

	//enchoice
	Local oFolder
	Private oEnc01
	Private oEnc02
	Private oEnc03
	Private aTELA:= NIL,aGets:=NIL

	DEFAULT cTudoOk := ".T."
	DEFAULT nReg    := (cAlias)->(RecNO())
	DEFAULT bOk 	 := &("{|| "+cTudoOk+"}")

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ajusta a largura para o tamanho padrao Protheus ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aSize := MsAdvSize()

	aObjects := {}
	AAdd( aObjects, { 100, 100, .T., .T. } )
	aInfo    := { aSize[1], aSize[2], aSize[3], aSize[4], 2, 2 }

	aPosObj := MsObjSize(aInfo,aObjects,.T.)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³VerIfica se esta' alterando um registro da mesma filial               ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lDclNew
		DbSelectArea("DH5")
	EndIf
	DbSelectArea("SB5")
	DbSelectArea(cAlias)
	If (cAlias)->(FieldPos(cCpoFil))==0 .Or. (cAlias)->(FieldGet(FieldPos(cCpoFil))) == xFilial(cAlias)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Monta a entrada de dados do arquivo						     ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If SoftLock(cAlias) .AND.SoftLock("SB5")
			RegToMemory(cAlias,.F.,.F.)
			RegToMemory("SB5",.F. ,.F. )
			If lDclNew
				If DH5->(Eof())
					RegToMemory("DH5",.T.)
				Else
					If SoftLock("DH5")
						RegToMemory("DH5",.F. ,.F. )
					EndIf
				EndIf
			EndIf

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Inicializa variaveis para campos Memos Virtuais		 			  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If Type("aMemos")=="A"
				For nX:=1 to Len(aMemos)
					cMemo := aMemos[nX][2]
					If ExistIni(cMemo)
						&cMemo := CriaVar( cMemo, .T. ) //InitPad(SX3->X3_RELACAO)
					Else
						&cMemo := ""
					EndIf
				Next nX
			EndIf
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Inicializa variaveis para campos Memos Virtuais		 			  ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If ( ValType( cFunc ) == 'C' )
				If ( !("(" $ cFunc) )
					cFunc+= "()"
				EndIf
				&cFunc
			EndIf

			DEFINE MSDIALOG oDlg TITLE cCadastro FROM aSize[7],0 TO aSize[6],aSize[5] OF oMainWnd PIXEL
			If lDclNew
				oFolder := TFolder():New(13,,{STR0033,STR0034,STR0128},{STR0033,STR0034,STR0128},oDlg,,,,.t.,.F.,oDlg:nWidth,oDlg:nHeight,) //"Produto"###"Complemento"###"Complemento DCL"###"Produto"###"Complemento""Complemento DCL"###
			Else
				oFolder := TFolder():New(13,,{STR0033,STR0034},{STR0033,STR0034},oDlg,,,,.t.,.F.,oDlg:nWidth,oDlg:nHeight,) //"Produto"###"Complemento"###"Produto"###"Complemento"
			EndIf

			oFolder:bSetOption := {|nAtu| Al_MudaEnc(nAtu,oFolder:nOption)}
			oFolder:align:= CONTROL_ALIGN_ALLCLIENT
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Enchoice 01                                          ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			aPos:={}
			dbSelectArea("SB1")
			oEnc01:= MsMGet():New("SB1" ,nReg ,nOpc,,,,,aPosObj[1],aCpos,       ,        ,          ,cTudoOk ,oFolder:aDialogs[1], ,)
			oEnc01:oBox:align:= CONTROL_ALIGN_ALLCLIENT

			If lDclNew
				//Enchoice 03
				dbSelectArea("DH5")
				oEnc03:=MsMGet():New("DH5",nReg,nOpc,,,,,aPosObj[1],     ,       ,        ,          ,        ,oFolder:aDialogs[3], ,)
				nPosCodDH5	:= AsCan(oEnc03:aENTRYCTRLS,{|x| UPPER(TRIM(x:cReadVar))=="M->DH5_COD"})
				nPosSimpDH5	:= AsCan(oEnc03:aENTRYCTRLS,{|x| UPPER(TRIM(x:cReadVar))=="M->DH5_CODSIM"})
				If !Empty(nPosCodDH5)
					oEnc03:AENTRYCTRLS[nPosCodDH5]:bWhen	:= {|| .F.}
				EndIf
				oEnc03:oBox:align:= CONTROL_ALIGN_ALLCLIENT
				aTela3 := aClone(oEnc03:aTela)
				aGets3 := aClone(oEnc03:aGets)
			EndIf

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Enchoice 02                                          ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dbSelectArea("SB5")
			oEnc02:=MsMGet():New("SB5",nReg,nOpc,,,,,aPosObj[1],     ,       ,        ,          ,        ,oFolder:aDialogs[2], ,)
			nPosCodB5 := AsCan(oEnc02:aENTRYCTRLS,{|x| UPPER(TRIM(x:cReadVar))=="M->B5_COD"})
			nPosInsPat 	:= AsCan(oEnc02:aENTRYCTRLS,{|x| UPPER(TRIM(x:cReadVar))=="M->B5_INSPAT"})
			nPosCodAtv 	:= AsCan(oEnc02:aENTRYCTRLS,{|x| UPPER(TRIM(x:cReadVar))=="M->B5_CODATIV"})
			If !Empty(nPosCodB5)
				oEnc02:AENTRYCTRLS[nPosCodB5]:bWhen	:= {|| .F.}
			EndIf
			If nPosInsPat >0 .And. nPosCodAtv >0
				oEnc02:AENTRYCTRLS[nPosInsPat]:bWhen	:= {|| .T.}
				oEnc02:AENTRYCTRLS[nPosCodAtv]:bWhen	:= {|| .T.}
			EndIf
			oEnc02:oBox:align:= CONTROL_ALIGN_ALLCLIENT
			aTela := aClone(oEnc02:aTela)
			aGets := aClone(oEnc01:aGets)
			For nG := 1 TO Len(oEnc02:aGets)
				aADD(aGets,oEnc02:aGets[nG])
			Next nG

			If lDclNew
				ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg,{|| nOpcA := 1,;
					If(Obrigatorio(oEnc01:aGets,oEnc01:aTela).And.Obrigatorio(oEnc02:aGets,oEnc02:aTela) .and.;
					Obrigatorio(oEnc03:aGets,oEnc03:aTela) .And. ;
					Eval(bOk).And.Eval(bOk2,nOpc),oDlg:End(),(nOpcA:=3,.f.))},;
					{|| nOpcA := 3,oDlg:End()},,aButtons,nReg,cAlias))
			Else

				ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg,{|| nOpcA := 1,;
					If(Obrigatorio(oEnc01:aGets,oEnc01:aTela).And.Obrigatorio(oEnc02:aGets,oEnc02:aTela) .and.;
					Eval(bOk).And.Eval(bOk2,nOpc),oDlg:End(),(nOpcA:=3,.f.))},;
					{|| nOpcA := 3,oDlg:End()},,aButtons,nReg,cAlias))
			EndIf

			(cAlias)->(MsGoTo(nReg))
			If nOpcA == 1
				lMemos := Type("aMemos") == "A"
				Begin Transaction
					RecLock(cAlias,.F.)
					For nX := 1 TO FCount()
						FieldPut(nX,M->&(EVAL(bCampo,nX)))
					Next nX
					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³Grava os campos Memos Virtuais					  				  ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					If lMemos
						For nX := 1 to Len(aMemos)
							cVar := aMemos[nX][2]
							cVar1:= aMemos[nX][1]
							//Incluído parametro com o nome da tabela de memos => para módulo APT
							cAliasMemo := If(len(aMemos[nX]) == 3,aMemos[nX][3],Nil)
							MSMM(&cVar1,TamSx3(aMemos[nX][2])[1],,&cVar,1,,,cAlias,aMemos[nX][1],cAliasMemo)
						Next nX
					EndIf

					DBSelectArea("SB5")
					RecLock("SB5",SB5->(Eof()))
					For nX := 1 TO FCount()
						If SB5->(FieldName(nX)) =="B5_FILIAL"
							SB5->B5_FILIAL:= xFilial("SB5")
						Else
							FieldPut(nX,M->&(EVAL(bCampo,nX)))
						EndIf
					Next nX

					If lDclNew
						DBSelectArea("DH5")
						RecLock("DH5",DH5->(Eof()))
						For nX := 1 TO FCount()
							If DH5->(FieldName(nX)) =="DH5_FILIAL"
								DH5->DH5_FILIAL:= xFilial("DH5")
							Else
								FieldPut(nX,M->&(EVAL(bCampo,nX)))
							EndIf
						Next nX
					EndIf

				End Transaction
			EndIf
		Else
			nOpcA := 3
		EndIf
	Else
		Help(" ",1,"A000FI")
		nOpcA := 3
	EndIf
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Restaura a integridade dos dados                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	MsUnLockAll()
	RestArea(aArea)
Return(nOpcA)


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010Consul ³ Autor ³Alexandre Inacio Lemes³ Data ³31/03/2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Excuta a chamada da funcao MC050con para consulta do produto³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum 	                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010Consul()

	Local aArea    := GetArea()

	SetKey( VK_F12, { || pergunte("MTC050",.T.) } )
	If pergunte("MTC050",.T.)
		MC050Con()
	EndIf

	Set Key VK_F4 TO MT010F4()

	SetKey( VK_F12, { || pergunte("MTA010",.T.) } )
	Pergunte("MTA010",.F.)

	RestArea(aArea)
Return Nil


/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A010SeleOpc³ Autor ³Alex Sandro Valario   ³ Data ³04/05/2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Funcao p/ selecao de Opcionais                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum 	                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function A010SeleOpc(lAltera)

	Local cAntOpc  := M->B1_OPC
	Local cAntmOpc := M->B1_MOPC
	Local cRet:=""
	Local oModel
	Local lOpcPadrao := GetNewPar("MV_REPGOPC","N") == "N"
	Local nQtdMax := Val(Replicate('9',TamSX3("C2_QUANT")[1]))
	Local lPCPREVATU	:= FindFunction('PCPREVATU')
	Local cRevisao		:= ''

	Default lAltera := .F.

	lMvcMata010 := IIF(ValType(lMvcMata010) == "L",lMvcMata010, TableInDic( "G3Q", .F. ))

	If lMvcMata010
		oModel := FwModelActive()
		cRevisao :=	IIF(lPCPREVATU , PCPREVATU(oModel:GetValue("SB1MASTER","B1_COD")), oModel:GetValue("SB1MASTER","B1_REVATU") )
		SeleOpc(1,"MATA010",oModel:GetValue("SB1MASTER","B1_COD"),Nil,@cRet,oModel:GetValue("SB1MASTER",IIf(lOpcPadrao,"B1_OPC","B1_MOPC")),,!lAltera,nQtdMax,dDataBase,cRevisao )
	Else

		cRevisao :=	IIF(lPCPREVATU , PCPREVATU(SB1->B1_COD), M->B1_REVATU )
		If !SeleOpc(1,"MATA010",SB1->B1_COD,Nil,@cRet,IIf(lOpcPadrao,M->B1_OPC,M->B1_MOPC),,!lAltera,nQtdMax,dDataBase,cRevisao ) .And. lAltera
			M->B1_OPC  := cAntOpc
			M->B1_MOPC := cAntmOpc
		EndIf
	EndIf
Return Nil

/*
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³a010Refresh³ Autor ³Patricia A. Salomao   ³ Data ³08/06/2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Funcao executada pela TudoOk();Carrega as Variaveis de memo ³±±
±±³          ³ria e efetua o refresh da pasta em que nao esta posicionado.³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ Objeto Folder                                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T.    	                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA010                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function a010Refresh(oFolder)
	Local nPasta1 := oFolder:nOption     //-- Pasta em que esta posionado
	Local nPasta2 := IIf(nPasta1==1,2,1)
	Al_MudaEnc(nPasta2) //-- Efetua a atualizacao das variaveis e Refresh da outra pasta
Return .T.

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³MenuDef   ³ Autor ³ Fabio Alves Silva     ³ Data ³01/11/2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Utilizacao de menu Funcional                               ³±±
±±³          ³                                                            ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Array com opcoes da rotina.                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Parametros do array a Rotina:                               ³±±
±±³          ³1. Nome a aparecer no cabecalho                             ³±±
±±³          ³2. Nome da Rotina associada                                 ³±±
±±³          ³3. Reservado                                                ³±±
±±³          ³4. Tipo de Transa‡„o a ser efetuada:                        ³±±
±±³          ³    1 - Pesquisa e Posiciona em um Banco de Dados           ³±±
±±³          ³    2 - Simplesmente Mostra os Campos                       ³±±
±±³          ³    3 - Inclui registros no Bancos de Dados                 ³±±
±±³          ³    4 - Altera o registro corrente                          ³±±
±±³          ³    5 - Remove o registro corrente do Banco de Dados        ³±±
±±³          ³5. Nivel de acesso                                          ³±±
±±³          ³6. Habilita Menu Funcional                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function MenuDef()

	Local aRotAdic
	Local nPos		:= 0
	Local aEntRelac	:= {}
	Local aAtiv		:= {}
	Local aAnotac	:= {}
	Local aPermissoes
	Local lHistFisca:= HistFiscal()
	Local lMTA010MNU:= ExistBlock("MTA010MNU")
	Local lMT010BRW	:= ExistBlock("MT010BRW")

	PRIVATE aRotina	:= {}
	Private lIntLox := SuperGetMv("MV_QALOGIX") == "1"

	If !lIntLox

		aRotina	:= { 	{ OemToAnsi(STR0003) ,"AxPesqui"		, 0 , 1, 0, .F.}}		//"Pesquisar"

		If IsInCallStack("FATA320")
			aPermissoes := FT060Permi(__cUserId, "ACA_ACPROD")
		Else
			aPermissoes := {.T.,.T.,.T.,.T.}
		EndIf

		If aPermissoes[4]
			aAdd(aRotina, { OemtoAnsi(STR0004) ,"A010Visul"	  		, 0 , 2, 0, nil} )	//"Visualizar"
		EndIf

		If aPermissoes[1]
			aAdd(aRotina, { OemtoAnsi(STR0005) ,"A010Inclui"		, 0 , 3, 0, nil} )	//"Incluir"
		EndIf
		If aPermissoes[2]
			aAdd(aRotina, { OemtoAnsi(STR0006) ,"A010Altera"		, 0 , 4, 2, nil} )	//"Alterar"
		EndIf

		If aPermissoes[3]
			aAdd(aRotina, { OemtoAnsi(STR0007) ,"Mata010Deleta"	, 0 , 5, 1, nil} )		//"Excluir"
		EndIf

		aAdd(aRotina, { OemtoAnsi(STR0017) ,"A010Consul"		, 0 , 2, 0, .F.} )		//"Consulta"
		aAdd(aRotina, { OemtoAnsi(STR0015) ,"A010Copia"		, 0 , 9, 0, nil} )			//"Copia"

	Else
		aRotina	:= 	{ 	{ OemToAnsi(STR0003) ,"AxPesqui"		, 0 , 1, 0, .F.},;		//"Pesquisar"
						{ OemtoAnsi(STR0004) ,"A010Visul"		, 0 , 2, 0, nil},;		//"Visualizar"
						{ OemtoAnsi(STR0017) ,"A010Consul"		, 0 , 2, 0, .F.}}		   	//"Consulta"
		l010Auto  := IIf(Type("l010Auto") == "U",.T.,l010Auto)
		If l010Auto //Adicionar caso seja rotina automatica - integracao com o Logix
			aAdd(aRotina, { OemtoAnsi(STR0005) ,"A010Inclui"		, 0 , 3, 0, nil} )	//"Incluir"
			aAdd(aRotina, { OemtoAnsi(STR0006) ,"A010Altera"		, 0 , 4, 2, nil} )	//"Alterar"
			aAdd(aRotina, { OemtoAnsi(STR0007) ,"Mata010Deleta"	, 0 , 5, 1, nil} )	//"Excluir"
		Endif
	EndIf

	aAdd(aRotina,{OemtoAnsi(STR0040), "A010WizFac", 0, 4, 2, .F.})	//"Facilitador"

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Ponto de entrada utilizado para inserir novas opcoes no array aRotina  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lMTA010MNU
		ExecBlock("MTA010MNU",.F.,.F.)
	EndIf

	// Banco de conhecimento para Série 3 e Série T
	AAdd( aEntRelac, { STR0018, "A010doc()", 0, 6 } )  //"Conhecimento"
	AAdd( aEntRelac, { STR0084, "CRMA160()", 0, 3} )//"Adic. Tab. Preço"

	If SuperGetMv("MV_EIC0011",,.F.)  // NCF - 08/06/2018
	   AAdd( aRotina, {"Classificação N.V.E.", "Easy010NVE()", 0, 4, 2 , nil} )  //"Classificação N.V.E."
	EndIf

	If lHistFisca
		Aadd(aRotina, { OemtoAnsi(STR0066),  "A010Hist()" , 0 ,0,0, NIL })//"Histórico
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ P.E. utilizado para adicionar items no Menu da mBrowse       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lMT010BRW
		aRotAdic := ExecBlock("MT010BRW",.f.,.f.)
		If ValType(aRotAdic) == "A"
			AEval(aRotAdic,{|x| AAdd(aRotina,x)})
		EndIf
	EndIf

	If cPaisLoc == "RUS"
      Set Key VK_F4 TO MT010F4()
	   Set Key VK_F12 TO MT010Perg()
    EndIf

	// Pode ser acessado pelos modulos SIGAEST, SIGAPCP e SIGACFG
	If nModulo == 4 .Or. nModulo == 10 .Or. nModulo == 99
		AAdd(aRotina,{OemToAnsi(STR0042), "A010ProdAl", 0, 4, 0, .F.}) //"Alternativos"
	EndIf

	If nModulo == 73

		AAdd( aEntRelac, { STR0090 ,"Ma180Alt('SB1',SB1->(RecNo()),4)", 0 , 4})//"Complemento do produto"

		aEntRelac := CRMXINCROT("SB1",aEntRelac)

		nPos := ASCAN(aEntRelac, { |x| IIF(ValType(x[2]) == "C", x[2] == "CRMA190Con()", Nil) })
		If nPos > 0
			ADD OPTION aRotina TITLE aEntRelac[nPos][1] ACTION aEntRelac[nPos][2] OPERATION 8  ACCESS 0//"Conectar"
			Adel(aEntRelac,nPos)
			Asize(aEntRelac,Len(aEntRelac)-1)
		EndIf

		nPos := ASCAN(aEntRelac, { |x|  IIF(ValType(x[2]) == "C", x[2] == "CRMA180()", Nil) })
		If nPos > 0
			ADD OPTION aAtiv   TITLE STR0085 ACTION "CRMA180(,,,3,,)" OPERATION 3  ACCESS 0 //"Nova Atividade"
			ADD OPTION aAtiv   TITLE STR0086 ACTION "CRMA180()" OPERATION 8  ACCESS 0 //"Todas as ATividades"
			aEntRelac[nPos][2] := aAtiv
		EndIf

		nPos := ASCAN(aEntRelac, { |x| IIF(ValType(x[2]) == "C", x[2] == "CRMA090()", Nil)})
		If nPos > 0
			ADD OPTION aAnotac   TITLE STR0087 ACTION "CRMA090(3)" OPERATION 3  ACCESS 0 //"Nova Anotação"
			ADD OPTION aAnotac   TITLE STR0088 ACTION "CRMA090()" OPERATION 8  ACCESS 0 //"Todas as Anotações"
			aEntRelac[nPos][2] := aAnotac
		EndIf

	EndIf

	Asort(aEntRelac,,,{ | x,y | y[1] > x[1] } )
	AAdd( aRotina, { STR0089 ,aEntRelac, 0 , 8})//"Relacionadas"

	If cPaisLoc == "RUS"
      Set Key VK_F4 TO MT010F4()
	   Set Key VK_F12 TO MT010Perg()
    EndIf

Return(aRotina)

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³A010WizFac³ Autor ³ Gustavo G. Rueda      ³ Data ³27/11/2007³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Chamada da rotina que permite uma manutencao facil no      ³±±
±±³          ³ cadastro.                                                  ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³.T.                                                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Nenhum                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Function A010WizFac()

	Local	cCmps		:=	""
	Local	aPar 		:=	{}
	Local	cMVA010FAC	:=	GetNewPar("MV_A010FAC","")

	cCmps	:=	"B1_TIPO/B1_CODITE/B1_UM/B1_LOCPAD/B1_GRUPO/B1_PICM/B1_IPI/B1_ESPECIE/B1_ALIQISS/B1_MSBLQL/"
	cCmps	+=	"B1_CODISS/B1_TE/B1_TS/B1_PICMRET/B1_PICMENT/B1_IMPZFRC/B1_SEGUM/B1_CONV/B1_TIPCONV/B1_CONTA/B1_CC/B1_ITEMCC/B1_ORIGEM/"
	cCmps	+=	"B1_CLASFIS/B1_GRTRIB/B1_CONTSOC/B1_IRRF/B1_IMPORT/B1_CODOBS/B1_OBS/B1_SITPROD/B1_INSS/B1_REDINSS/B1_REDIRRF/B1_TAB_IPI/"
	cCmps	+=	"B1_REDPIS/B1_REDCOF/B1_PCSLL/B1_PCOFINS/B1_PPIS/B1_VLR_IPI/B1_CLVL/B1_ATIVO/B1_VLR_ICM/B1_INT_ICM/B1_VLRSELO/B1_SELO/B1_PIS/"
	cCmps	+=	"B1_CLASSE/B1_VLR_PIS/B1_COFINS/B1_CSLL/B1_FRETISS/B1_CALCFET/B1_PAUTFET/B1_VLR_COF/B1_PRFDSUL/B1_RETOPER/B1_CNAE/B1_CRDEST/"
	cCmps	+=	cMVA010FAC

	aAdd(aPar,{"SB1","B1_COD+' - '+B1_DESC", cCmps,""})

	MATA984(aPar[1,1],aPar[1,2],aPar[1,3],,aPar[1,4])

Return .T.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³MATA010   ºAutor  ³Andre Anjos         º Data ³  27/02/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³Valida o campo B1_ESTRORI                                   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ MATA010                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010EstOri()
	Local aArea := GetArea()
	Local lRet := .T.

	dbSelectArea("SG1")
	dbSetOrder(1)
	If !Empty(M->B1_ESTRORI) .And. !dbSeek(xFilial("SG1")+M->B1_ESTRORI+M->B1_COD) .Or. G1_QUANT > 0
		Help(" ",1,"REGNOIS")
		lRet := .F.
	EndIf

	RestArea(aArea)
Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³A010ProdAlºAutor  |Andre Anjos         º Data ³  19/03/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³Interface para cadastramento dos produtos alternativos.     º±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Alias do arquivo                                   ³±±
±±³          ³ ExpN1 = Numero do registro                                 ³±±
±±³          ³ ExpN2 = Numero da opcao selecionada 			              ³±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ MATA010                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010ProdAl(cAlias,nReg,nOpc)
Return A010AltPCP(cAlias,nReg,nOpc)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³A010FldOk ºAutor  ³Andre Anjos		 º Data ³  20/03/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Valida campos dos produtos alternativos.                   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ MATA010                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010FldOk()
Return PCPAltVlFd()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³A010VldAltºAutor  ³Andre Anjos	     º Data ³  31/03/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Valida produto alternativo digitado                        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ MATA010                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010VldAlt()
Return PCPAltVld()

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³AlterLinOkºAutor  ³Andre Anjos	     º Data ³  01/04/09   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Valida linha do alternativo		                          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ MATA010                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function AlterLinOK()
Return PCPAltLiOK()

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³A010Int³ Autor ³ Vendas CRM               ³ Data ³ 15/09/2009 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Realiza integracao com a criterium ou outra integracao       ³±±
±±³          ³que utiliza o framework do SIGALOJA de integracao.            ³±±
±±³          ³ O parâmetro aIntSB1 normalmente é vazio.                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³A010Int()                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpN1: Momento da chamada, sendo:                             ³±±
±±³          ³           1: Antes de qualquer alteração                     ³±±
±±³          ³           2: Depois das alterações                           ³±±
±±³          ³ExpN2: Opção da rotina                                        ³±±
±±³          ³ExpA3: Array contendo o número do registro e adaptador do SB1.³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function A010Int( nMomento, nOpc, aIntSB1 )
	Local lIntegra 		:= SuperGetMv("MV_LJGRINT", .F., .F.)	// Se há integração ou não
	Local aArea			:= GetArea()

	If lIntegra
		If nMomento == 1
			MsgRun( STR0051, STR0050, {|| A010IniInt( nOpc, aIntSB1 ) } ) // "Aguarde" "Anotando registros para integração"
		ElseIf nMomento == 2
			MsgRun( STR0052, STR0050, {|| A010FimInt( nOpc, aIntSB1 ) } ) // "Aguarde" "Executando integração"
		EndIf
	EndIf

	RestArea( aArea )
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³A010IniInt   ³ Autor ³ Vendas CRM         ³ Data ³ 15/09/2009 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Faz o cache dos itens antes de serem excluídos, possibilitan-³±±
±±³          ³do o envio dos mesmos, mesmo após de serem apagados.          ³±±
±±³          ³ O parâmetro aIntSB1 normalmente é vazio.                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³A010IniInt()                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpN1: Opção da rotina                                        ³±±
±±³          ³ExpA2: Array contendo o número do registro e adaptador do SB1.³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function A010IniInt( nOpc, aIntSB1 )
	Local oFactory		:= LJCAdapXmlEnvFactory():New()
	Local cChave		:= ""

	// Se houver integração e não for inclusão ou copia, anota todos os registros para exclusão, caso algum seja excluído
	If nOpc != 3 .AND. !lCopia
		aIntSB1 :=	{ SB1->(Recno()), oFactory:Create( "SB1" ), oFactory:CreateByProcess( "025" ) }
		cChave 	:= xFilial( "SB1" ) + SB1->B1_COD
		aIntSB1[2]:Inserir( "SB1", cChave, "1", "5" )
		aIntSB1[3]:Inserir( "SB1", cChave, "1", "5" )
		aIntSB1[2]:Gerar()
		aIntSB1[3]:Gerar()
	EndIf
Return

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Função    ³A010FimInt   ³ Autor ³ Vendas CRM         ³ Data ³ 15/09/2009 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descrição ³ Envia os itens apagados e todos os outros itens.             ³±±
±±³          ³ O parâmetro aIntSB1 normalmente é vazio.                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³A010FimInt()                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpN1: Opção da rotina                                        ³±±
±±³          ³ExpA2: Array contendo o número do registro e adaptador do SB1.³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function A010FimInt( nOpc, aIntSB1 )
	Local oFactory			:= LJCAdapXmlEnvFactory():New( )	// Cria a fabrica de Adaptadores de envio
	Local oEntidadeFactory	:= LJCEntidadeFactory():New()
	Local cChave			:= ""
	Local oEntidadeSBM		:= Nil
	Local oRecords			:= Nil

	Default aIntSB1  		:= {}

	// Verifica se houve algum registro apagado, e gera a integração desse registro
	If nOpc != 3 .AND. !lCopia .And. Len(aIntSB1) > 0
		// Procura pelo registro do cabeçalho
		SB1->(msGoTo( aIntSB1[1] ) )

		// Se não encontrar, significa que o cabeçalho foi apagado, então envia somente a exclusão do cabeçalho
		If SB1->( DELETED() )
			aIntSB1[2]:Finalizar()
		EndIf
	EndIf

	// Independente de ter registros apagados ou não, gera quando não for exclusão, todos os outros registros
	If nOpc != 5
		aIntSB1 := { SB1->( Recno() ), oFactory:Create( "SB1" ), oFactory:CreateByProcess( "025" )  }
		cChave 	:= xFilial( "SB1" ) + SB1->B1_COD

		// Para a tabela SB1
		aIntSB1[2]:Inserir( "SB1", cChave, "1", cValToChar( nOpc ) )
		aIntSB1[2]:Gerar()
		aIntSB1[2]:Finalizar()

		// Para o processo 025
		oEntidadeSBM := oEntidadeFactory:Create( "SBM" )
		If oEntidadeSBM != Nil
			oEntidadeSBM:DadosSet( "BM_GRUPO", SB1->B1_GRUPO )
			oRecords := oEntidadeSBM:Consultar(1)

			// Insere os registros no adapter e envia pro EAI.
			If aIntSB1[3] != NIL	.And. oRecords:Count() > 0
				//Insere os dados da carga
				aIntSB1[3]:Inserir( "SBM", xFilial("SBM") + oRecords:Elements( 1 ):DadosGet( "BM_GRUPO" ) , "1", cValToChar( nOpc ))
			EndIf
		EndIf
		aIntSB1[3]:Inserir( "SB1", cChave, "1", cValToChar( nOpc ) )
		aIntSB1[3]:Gerar()
		aIntSB1[3]:Finalizar()
	EndIf
Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡ao    ³A010IntSFC ³ Autor ³ Aecio Ferreira Gomes    ³ Data ³30/04/11 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡ao ³Atualiza tabelas do SFC conforme modelagem dos dados(MVC)     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³A010IntSFC(ExpN1)                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpN1 = Rotina a ser processada(3-Inc, 4-Alt, 5-Exc)          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³MATA770                                                       ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010IntSFC(nOpc,cError,cNome,oModel)
	Local aArea   := GetArea()	// Salva area atual para posterior restauracao
	Local lRet    := .T.		// Conteudo de retorno
	Local aCampos := {}			// Array dos campos a serem atualizados pelo modelo
	Local aAux    := {}			// Array auxiliar com o conteudo dos campos
	Local nX	  := 0			// Indexadora de laco For/Next
	Default oModel  := FWLoadModel("SFCC101")		// Objeto de modelo de dados

	lMvcMata010 := IIF(ValType(lMvcMata010) == "L",lMvcMata010, TableInDic( "G3Q", .F. ))

	If lMvcMata010
		Return A010IntSFX(nOpc,@cError,cNome,oModel)
	EndIf

	If nOpc == 3
		aAdd(aCampos,{"CZ3_CDAC",M->B1_COD})
		aAdd(aCampos,{"CZ3_DTBG",dDataBase})
		aAdd(aCampos,{"CZ3_TPAC","1"})
	EndIf

	If nOpc # 5
		aAdd(aCampos,{"CZ3_DSAC"	,M->B1_DESC })
		aAdd(aCampos,{"CZ3_CDUN"	,M->B1_UM})
		aAdd(aCampos,{"CZ3_DSUN"	,Posicione("SAH",1,xFilial("SAH")+M->B1_UM,"AH_DESCPO")})
		aAdd(aCampos,{"CZ3_CDGR"	,M->B1_GRUPO })
		aAdd(aCampos,{"CZ3_DSGR"	,Posicione("SBM",1,xFilial("SBM")+M->B1_GRUPO,"BM_DESC")})
		aAdd(aCampos,{"CZ3_CDFA"	,M->B1_TIPO })
		aAdd(aCampos,{"CZ3_DSFA"	,PadR(Posicione("SX5",1,xFilial("SX5")+"02"+M->B1_TIPO,"X5_DESCRI"),TamSX3("CZ3_DSFA")[1])})
		aAdd(aCampos,{"CZ3_CDDP"	,M->B1_LOCPAD })
		aAdd(aCampos,{"CZ3_QTLOEC"	,M->B1_LE })
		aAdd(aCampos,{"CZ3_QTLOMI"	,M->B1_LM })
		aAdd(aCampos,{"CZ3_VLPSBR"	,M->B1_PESBRU })
		aAdd(aCampos,{"CZ3_VLPSLQ"	,M->B1_PESO })
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Instancia modelo de dados(Model) do cadastro de Item - SFC ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	//oModel  := FWLoadModel("SFCC101")		// Objeto de modelo de dados
	oModel:SetOperation(nOpc)

	If nOpc # 3
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Quando se tratar de alteracao ou exclusao primeiramente o registro devera ser posicionado ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		CZ3->(dbSetOrder(1))
		CZ3->(dbSeek(xFilial("CZ3")+SB1->B1_COD))
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Ativa o modelo de dados ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If (lRet := oModel:Activate())
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Obtem a estrutura de dados do Model ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aAux := oModel:GetModel("CZ3MASTER"):GetStruct():GetFields()

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Loop para validacao e atribuicao de dados dos campos do Model ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		For nX := 1 To Len(aCampos)
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Valida os campos existentes na estrutura do Model ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If aScan(aAux,{|x| AllTrim(x[3]) ==  AllTrim(aCampos[nX,1])}) > 0
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³Atribui os valores aos campos do Model caso passem pela validacao do formulario ³
				//³referente a tipos de dados, tamanho ou outras incompatibilidades estruturais.   ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If !(oModel:SetValue("CZ3MASTER",aCampos[nX,1],aCampos[nX,2]))
					lRet := .F.
					Exit
				EndIf
			EndIf
		Next nX
	Endif

	If lRet
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Valida os dados e integridade conforme dicionario do Model ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If (lRet := oModel:VldData())
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Efetiva gravacao dos dados na tabela ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			lRet := oModel:CommitData()
		EndIf
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Gera log de erro caso nao tenha passado pela validacao ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If !lRet
		A010SFCErr(oModel,@cError,NIL,cNome,SB1->B1_COD)
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Desativa o Model ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oModel:DeActivate()

	RestArea(aArea)
Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³A010SFCErrºAutor  ³ Andre Anjos  		 º Data ³  30/05/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Tratamento de erro da integracao com Chao de Fabrica.      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao SFC                                             º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010SFCErr(oModel,cError,nItErro,cNome,cChave)
	Local aErro  := {}
	Local lCarga := ValType(cError) == "C"

	l010Auto:= If(Type('l010Auto') <> 'L',.f.,l010Auto)
	aErro := oModel:GetErrorMessage()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Estrutura do vetor com erro ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//[1] Id do formulário de origem
	//[2] Id do campo de origem
	//[3] Id do formulário de erro
	//[4] Id do campo de erro
	//[5] Id do erro
	//[6] mensagem do erro
	//[7] mensagem da solução
	//[8] Valor atribuido
	//[9] Valor anterior

	If lCarga
		cError := ""
		If !Empty(AllToChar(aErro[2]))
			cError += cNome +" " +AllTrim(cChave) +": " +AllToChar(aErro[6])+ '. ' +STR0132 +AllToChar(aErro[2]) +CRLF
		Else
			cError += cNome +" " +AllTrim(cChave) +": " +AllToChar(aErro[6]) +CRLF
		EndIf
	Else
		AutoGrLog(STR0131 +'[' +AllToChar(aErro[1]) +']') //"Id do formulário de origem: "
		AutoGrLog(STR0132 +'[' +AllToChar(aErro[2]) +']') //"Id do campo de origem:      "
		AutoGrLog(STR0133 +'[' +AllToChar(aErro[3]) +']') //"Id do formulário de erro:   "
		AutoGrLog(STR0134 +'[' +AllToChar(aErro[4]) +']') //"Id do campo de erro:        "
		AutoGrLog(STR0135 +'[' +AllToChar(aErro[5]) +']') //"Id do erro:                 "
		AutoGrLog(STR0136 +'[' +AllToChar(aErro[6]) +']') //"Mensagem do erro:           "
		AutoGrLog(STR0137 +'[' +AllToChar(aErro[7]) +']') //"Mensagem da solução:        "
		AutoGrLog(STR0138 +'[' +AllToChar(aErro[8]) +']') //"Valor atribuido:            "
		AutoGrLog(STR0139 +'[' +AllToChar(aErro[9]) +']') //"Valor anterior:             "

		HELP(" ",1,STR0140,,AllToChar(aErro[6]),1,1) //"Integração"

		If !Empty(nItErro)
			AutoGrLog(STR0141 +'[' +AllTrim(AllToChar(nItErro)) +']') //"Erro no Item:               "
		EndIf

		If !l010Auto
			MostraErro()
		EndIf
	EndIf

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³IntegraSFCºAutor  ³ Aecio Ferreira Gomes º Data ³  29/09/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Valida Integração com SFC								    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao SFC                                            	º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function IntegraSFC()
	Local lRet		:= .F.
	Local xIntSFC	:= SuperGetMV("MV_INTSFC",.F.,0)

	If ValType(xIntSFC) # "N"
		lRet := xIntSFC
	Else
		lRet := xIntSFC == 1
	EndIf

Return(lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³IntegraSFCº    Autor  ³ Michele Girardi  º Data ³  08/01/13   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Valida Integração com SFC - Parametro/Compartilhamento tabelaº±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao SFC                                            	º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function ExisteSFC(cTabela)
Local lRet		:= .F.

lRet := ExisteSFCPcp(@cTabela)

Return(lRet)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±º Function  ³ IntegDef º Autor ³ Marcelo C. Coutinho  º Data ³  28/10/11   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º Descricao ³ Funcao de tratamento para o recebimento/envio de mensagem    º±±
±±º           ³ unica de cadastro de produtos.                               º±±
±±ÌÍÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±º Uso       ³ MATA010                                                      º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function IntegDef( xEnt, nTypeTrans, cTypeMessage, cVersion, cTransac, lEAIObj )
Default xEnt := ""
Default nTypeTrans := ""
Default cTypeMessage := ""
Default cVersion := ""
Default cTransac := ""
Default lEAIObj := .F.

Return MATI010(xEnt,nTypeTrans,cTypeMessage, cVersion, cTransac, lEAIObj )

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³IntegraDPRºAutor  ³ Leonardo Quintania   º Data ³  06/11/12   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Valida Integração com o DPR(Desenvolvedor de Produtos)	    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Integracao DPR                                               º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function IntegraDPR()
	Local lRet		:= .F.

	lRet := SuperGetMv("MV_INTDPR",.F.,0) == 1

Return lRet

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ A010Hist     ºAutor  ³Wemerson Randolfo     º Data ³ 03/09/12 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Visualizacao do historico das alteracoes                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºParametros³ Nao ha                                                        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºRetorno   ³ .T. ou .F.                                                    º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºAplicacao ³ Funcao chamada pelo menu                                      º±±
±±º          ³                                                               º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Function A010Hist()
	Local lRet

	lRet := HistOperFis("SS4",SB1->B1_COD,SB1->B1_DESC,"S4_COD")
Return lRet

/*
| Programa : A010VLoc  			 Autor : TOTVS           Data : 26/11/2013
| Descricao: Valida local padrão diferente de MV_CQ
| Retorno  : .T. ou .F.
| Aplicacao: Chamada no valid do B1_LOCAL
*/
Function A010VLoc()
	Local lRet:= .T.

	If M->B1_LOCPAD == GetMvNNR('MV_CQ','98')
		Help(" ",1,"A240LOCCQ")
		lRet := .F.
	Endif
Return lRet


//------------------------------------------------------------------------------
/*/{Protheus.doc} A010ComPrd()

Abre o formulario do Complemento do Produto.

@sample 	A010ComPrd(cCodProd,nOpc)

@param		ExpC1 - Código do Produto
ExpN3 - Numero da Operação

@return	Nenhum

@author	Anderson Silva
@since		11/07/2014
@version	12.0
/*/
//---------------------------------------------------------------------
Function A010ComPrd(cCodProd,nOpc)

	Local aArea 	:= GetArea()
	Local aAreaSB5	:= SB5->(GetArea())

	Private cCadastro	:= ""

	cCodProd := IIf(Empty(cCodProd),SB5->B5_COD,cCodProd)

	DbSelectArea("SB5")
	SB5->(DbSetOrder(1))

	If lMvcMata010
		If DbSeek(xFilial("SB5")+cCodProd)
			FWExecView(STR0093,"MATA180M",nOpc,,{|| .T.})
		Else
			MsgAlert(STR0094) // "Este produto não possui dados complementares."
		EndIf
	Else
		If DbSeek(xFilial("SB5")+cCodProd)
			If nOpc == 2 // Visualizar
				cCadastro := STR0093+Upper(OemtoAnsi(STR0004)) // "Dados Complementares - VISUALIZAR"
				AxVisual("SB5",SB5->(RecNo()),nOpc)
			ElseIf nOpc == 4 // Alterar
				cCadastro := STR0093+Upper(OemtoAnsi(STR0006)) // "Dados Complementares - ALTERAR"
				Ma180Alt("SB5",SB5->(RecNo()),nOpc)
			EndIf
		Else
			MsgAlert(STR0094) // "Este produto não possui dados complementares."
		EndIf
	EndIf

	RestArea(aAreaSB5)
	RestArea(aArea)

Return Nil

//-------------------------------------------------------------------
/*/{Protheus.doc} A010CodBar
Validacao do tamanho dos campos B1_CODBAR e B1_CODGTIN
@author		Andre Anjos
@since		07/05/2018
@version	1.0
@param		cCodBar - conteudo digitado no campo (codigo de barra)
@param		lB1CODBAR - indica se a chamada considerará o parâmetro MV_ACDVLBA
/*/
//-------------------------------------------------------------------
Function A010CodBar(cCodBar,lMVACDVLBA)
	Local lRet       := .T.
	Local nTamB1CBar 
	Local lVldCodBar := SuperGetMV("MV_ACDVLBA",.F.,.T.)
	Local cCampo 	   := StrTran(Readvar(),"M->","")

	Default lMVACDVLBA := .T.

	 nTamB1CBar:= TamSX3(cCampo)[1]

	If ((lMVACDVLBA .and. cCampo == 'B1_CODGTIN') .Or. (lVldCodBar .and. cCampo == 'B1_CODBAR')) .And. (Len(AllTrim(cCodBar)) > nTamB1CBar - 1)
		// "B1_CODBAR" ### "Digite no maximo " ### 15 ## " caracteres, pois o último dígito do código de barras "
		//                                            "será preenchido automaticamente (dígito verificador)."
		Aviso(STR0103,STR0104 + AllTrim(STR(nTamB1CBar - 1)) + STR0105 + STR0106,{STR0031})
		lRet := .F.
	EndIf
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} A010LimpOp
Funcao p/ Limpar o campo de Opcionais
@author		Andre Maximo
@since		17/12/2015
@version	1.0
/*/
//-------------------------------------------------------------------

Static Function A010LimpOp()
	Local lOpcPadrao:= GetNewPar("MV_REPGOPC","N") == "N"
	Local oModel
	lMvcMata010 := IIF(ValType(lMvcMata010) == "L",lMvcMata010, TableInDic( "G3Q", .F. ))

	If lMvcMata010
		oModel := oView:GetModel()
		If lOpcPadrao
			oModel:LoadValue("SB1MASTER","B1_OPC"," ")
		Else
			oModel:LoadValue("SB1MASTER","B1_MOPC"," ")
		EndIf
	Else
		M->B1_OPC:= " "
		M->B1_MOPC:=" "
	EndIf

Return Nil


// -----------------------------------------------------------
/*/{Protheus.doc} A010VlStr
(long_description)
@type function
@author nilton.koyanagui
@since 22/04/2016
@version 1.0
@return ${return}, Possui (T) ou não (F) caracter especial
/*/
// -----------------------------------------------------------
Function A010VlStr ()

	Local lRet       	:= .T.
	Local cConteudo		:= Alltrim(&(ReadVar()))
	Local cCaracPip		:= "|'"
	Local nCont			:= 0

	If existblock("A010BPE")
		lret:= ExecBlock( "A010BPE", .F., .F.,{ReadVar(),cConteudo} )
		If lRet
			return lRet
		Else
			lRet:=.T.
		Endif
	EndIf

	For nCont := 1 to len(cConteudo)
		If substr(cConteudo,nCont,1) $ cCaracPip
			lret := .F.
		EndiF
	Next nCont

	If !lRet
		Alert (STR0113)
	EndIf

Return lRet

//-------------------------------------------------------------------------------------------------
/*/{Protheus.doc} MATA010PPI

Realiza a integração com o PC-Factory - PPI Multitask

@param cXml      - XML que será enviado. Caso não seja passado esse parametro, será realizada
a chamada do Adapter para criação do XML.
Se for passado esse parâmetro, não será exibida a mensagem de erro caso exista,
nem será considerado o filtro da tabela SOE.
@param cProd     - Obrigatório quando utilizado o parâmetro cXml. Contém o código do produto
@param lExclusao - Indica se está chamando para rotina de exclusão de produto.
@param lFiltra   - Identifica se será realizado ou não o filtro do registro.
@param lPendAut  - Indica se será gerada a pendência sem realizar a pergunta para o usuário, caso ocorra algum erro.

@author  Lucas Konrad França
@version P12
@since   13/08/2015
@return  lRet  - Indica se a integração com o PC-Factory foi realizada.
.T. -> Integração Realizada
.F. -> Integração não realizada.
/*/
//-------------------------------------------------------------------------------------------------
Function MATA010PPI(cXml, cProd, lExclusao, lFiltra, lPendAut)
	Local aArea     := GetArea()
	Local lRet      := .T.
	Local aRetXML   := {}
	Local aRetWS    := {}
	Local aRetData  := {}
	Local aRetArq   := {}
	Local cNomeXml  := ""
	Local cProduto  := ""
	Local cGerouXml := ""
	Local cOperacao := ""
	Local cPont     := ""

	//Variável utilizada para identificar que está sendo executada a integração para o PPI dentro do MATI010.
	Private lRunPPI := .T.

	Default cXml      := ""
	Default cProd     := ""
	Default lExclusao := .F.
	Default lFiltra   := .T.
	Default lPendAut  := .F.

	If A010IsMvc()
		Return MATA010PPX(cXml, cProd, lExclusao, lFiltra, lPendAut)
	EndIf

	If Empty(cXml)
		If lExclusao
			cOperacao := Lower(STR0007) //"excluir"
		Else
			If INCLUI
				cOperacao := Lower(STR0005) //"incluir"
			Else
				cOperacao := Lower(STR0006) //"alterar"
			EndIf
		EndIf
	Else
		If PCPEvntXml(cXml) == "delete"
			lExclusao := .T.
		EndIf
	EndIf

	If Empty(cXml)
		If lExclusao
			cProduto := SB1->B1_COD
			cPont    := "SB1"
		Else
			cProduto := M->B1_COD
			cPont    := "M"
		EndIf
	Else
		cProduto := cProd
	EndIf

	//Realiza filtro na tabela SOE, para verificar se o produto entra na integração.
	If !Empty(cXml) .Or. !lFiltra .Or. PCPFiltPPI("SB1", cProduto, cPont)
		//Adapter para criação do XML
		If Empty(cXml)
			aRetXML := MATI010("", TRANS_SEND, EAI_MESSAGE_BUSINESS)
		Else
			aRetXML := {.T.,cXml}
		EndIf
		/*
		aRetXML[1] - Status da criação do XML
		aRetXML[2] - String com o XML
		*/
		If aRetXML[1]
			//Retira os caracteres especiais
			aRetXML[2] := EncodeUTF8(aRetXML[2])

			//Busca a data/hora de geração do XML
			aRetData := PCPxDtXml(aRetXML[2])
			/*
			aRetData[1] - Data de geração AAAAMMDD
			aRetData[1] - Hora de geração HH:MM:SS
			*/

			//Envia o XML para o PCFactory
			aRetWS := PCPWebsPPI(aRetXML[2])
			/*
			aRetWS[1] - Status do envio (1 - OK, 2 - Pendente, 3 - Erro.)
			aRetWS[2] - Mensagem de retorno do PPI
			*/

			If aRetWS[1] != "1" .And. Empty(cXml)
				If lPendAut
					lRet := .T.
				Else
					If Type('l010Auto') == "L" .And. l010Auto
						Help(" ",1,AllTrim(aRetWS[2]))
						lRet := .T.
					Else
						//"Atenção! Ocorreram erros na integração com o PCFactory. Erro: "
						// XXXXXX
						// XXXXXX
						// "Deseja incluir/alterar/excluir o local de estoque no protheus e gerar pendência para integração?"
						If !MsgYesNo(STR0107 + AllTrim(aRetWS[2]) +CHR(10)+;
								STR0108 + AllTrim(cOperacao) +STR0109)
							lRet := .F.
						EndIf
					EndIf
				EndIf
			EndIf

			If lRet
				//Cria o XML fisicamente no diretório parametrizado
				aRetArq := PCPXmLPPI(aRetWS[1],"SB1",cProduto,aRetData[1],aRetData[2],aRetXML[2])
				/*
				aRetArq[1] Status da criação do arquivo. .T./.F.
				aRetArq[2] Nome do XML caso tenha criado. Mensagem de erro caso não tenha criado o XML.
				*/
				If !aRetArq[1]
					If Empty(cXml) .And. (Type('l010Auto') == "L" .And. !l010Auto) .And. !lPendAut
						Alert(aRetArq[2])
					EndIf
				Else
					cNomeXml := aRetArq[2]
				EndIf
				If Empty(cNomeXml)
					cGerouXml := "2"
				Else
					cGerouXml := "1"
				EndIf
				//Cria a tabela SOF
				PCPCriaSOF("SB1",cProduto,aRetWS[1],cGerouXml,cNomeXml,aRetData[1],aRetData[2],__cUserId,aRetWS[2],aRetXML[2])
			EndIf
		EndIf
	EndIf
	//Tratativa para retornar .F. mesmo quando é pendência automática;
	//Utilizado apenas para o programa de sincronização.
	If AllTrim(FunName()) == "PCPA111" .And. aRetWS[1] != "1"
		lRet := .F.
	EndIf
	RestArea(aArea)
Return lRet

// ---------------------------------------------------------
/*/{Protheus.doc} mata010OPC
Visualização dos opcionais do produto
@author Lucas Konrad França
@since 26/09/2016
@version 1.0
/*/
// ---------------------------------------------------------
Function mata010OPC()
	If Empty(SB1->B1_OPC) .And. Empty(SB1->B1_MOPC)
		Help( ,, 'Help',, STR0114 , 1, 0 ) //"Produto não possui opcionais."
	Else
		VisualOpc(SB1->B1_COD,SB1->B1_MOPC,SB1->B1_OPC,2)
	EndIf
Return .T.


//---------------------------------------------------------
/*/{Protheus.doc} M010MenuX
Função de Compatibilidade para que o MATA010M possa enxergar A static function MENUDEF
@author José Eulálio
@since 29/02/2018
@version 1.0
/*/
//---------------------------------------------------------
Function M010MenuX()
Return Menudef()

//---------------------------------------------------------
/*/{Protheus.doc} A010Fantasm
Função de para corrigir a o combo do campo B1_FANTASM
@author José Eulálio
@since 18/03/2018
@param oStruSb1
@version 1.0
/*/
//---------------------------------------------------------
Static Function A010Fantasm(oStruSb1)
	Local aCombo := oStruSb1:GetProperty("B1_FANTASM",MODEL_FIELD_VALUES)

	If '&' $ aCombo[2]
		aCombo[2] := StrTran(aCombo[2],"&","")
		oStruSb1:SetProperty("B1_FANTASM",MODEL_FIELD_VALUES,aCombo)
	EndIf

Return

//---------------------------------------------------------
/*/{Protheus.doc} M010BrwAuto
Função de compatibilidade para enviar aRotina como varíavel
Private, pois, é exigida nesse escopo pela função MBrowseAuto
@author José Eulálio
@since 26/03/2018
@param nOpc,aRotAuto,cAliasRot
@version 1.0
/*/
//---------------------------------------------------------
Static Function M010BrwAuto(nOpc,aRotAuto,cAliasRot)
	Private aRotina := MenuDef()
	MBrowseAuto(nOpc,aRotAuto,cAliasRot)
Return


//---------------------------------------------------------
/*/{Protheus.doc} FldNoCopy
Funcao para definicao de campos que nao podem ser copiados
@author Andre Maximo
@since 10/04/2018
@param lVeiculo: Identifica se o modulo de Veiculos esta em uso
@version 1.0
/*/
//---------------------------------------------------------
Static Function FldNoCopy(lVeiculo)
Local aRet	:= {}

//-- Ponto de entrada para adicionar campos a nao serem copiados
If ExistBlock( "MTA010NC" )
	aRet := ExecBlock( "MTA010NC", .F., .F. )
	If Valtype(aRet) <> "A"
		aRet := {}
	EndIf
EndIf

If lVeiculo
	Aadd(aRet,"B1_CODITE")
EndIf

Aadd(aRet,"B1_OPC") // Opcionais
Aadd(aRet,"B1_MOPC") // Opcionais
Aadd(aRet,"B1_UCALSTD") //Data do último Cálculo de Custo Standard efetuado para o Produto.
Aadd(aRet,"B1_UPRC") // ultimo preço de compra do produto.
Aadd(aRet,"B1_UCOM") // Data da ultima compra do produto Preencher somente na implantaçao do produto ou no caso de um cancelamento de compras.
Aadd(aRet,"B1_UREV") // Data da ultima revisao da estrutura do produto.
Aadd(aRet,"B1_DATREF") // Data de referência do custo standard  do produto. e utilizada para que o sistema faça automaticamente o reajuste daquele custo.
Aadd(aRet,"B1_DTREFP1") // Data de referência do preço 1, usada somente para informação do usuario.
Aadd(aRet,"B1_CONINI") //Data Inicial a ser considerada no cálculo do Consumo Medio.
Aadd(aRet,"B1_REVATU") //Revisao atual da estrutura do produto Utilizado para selecionar componentes na explosao da estrutura.

Return aRet

/*/{Protheus.doc} A010RfCbar
Função para gatilhar o digito verificador do código de barras na view

@author Flavio Lopes Rasta
@since 12/09/2018
@version P12.1.17

/*/

Function A010RfCbar( oView, cIDView, cNamCpo )
Local oModel 	:= FWModelActive()
Local oModelSB1 := oModel:GetModel('SB1MASTER')
Local aTriggers	:= oModelSB1:GetStruct():GetTriggers()
Local nPosTrg	:= 0
Local cCodBar	:= Nil
Local cComplete := Nil

Default cNamCpo := ""

If !( Empty( cNamCpo ) )

	cCodBar		:= oModelSB1:GetValue( cNamCpo )

	If !( Empty( cCodBar ) )
		cComplete 	:= AllTrim( cCodBar ) + EanDigito( AllTrim( cCodBar ) )

		Do Case
		Case AllTrim( cNamCpo ) == 'B1_CODBAR'
			If nModulo <> 12
				nPosTrg := aScan(aTriggers,{|x| AllTrim(x[1]) == cNamCpo .And. AllTrim(x[2]) == cNamCpo })
				If nPosTrg > 0
					oModelSB1:LoadValue( cNamCpo , cComplete )
					oView:Refresh(cIDView)
				Endif
			Endif
		Case AllTrim( cNamCpo ) == 'B1_CODGTIN'
			nPosTrg := aScan(aTriggers,{|x| AllTrim(x[1]) == cNamCpo .And. AllTrim(x[2]) == cNamCpo })
			If nPosTrg > 0
				oModelSB1:LoadValue( cNamCpo, cComplete )
				oView:Refresh(cIDView)
			Endif
		EndCase

	EndIf
EndIf

Return .T.

/*/{Protheus.doc} A010IsMvc
Retorna a variável de controle que indica se o MATA010 está em MVC.
@type  Function
@author lucas.franca
@since 21/03/2019
@version P12
@param param, param_type, param_descr
@return lMvcMata010, Logical, Identifica se o fonte MATA010 está em MVC
/*/
Function A010IsMvc()
	lMvcMata010 := IIF(ValType(lMvcMata010) == "L",lMvcMata010, TableInDic( "G3Q", .F. ))
Return lMvcMata010

/*/{Protheus.doc} A010doc
Chamada para o banco de conhecimento

@type function

@author Leonardo Quintania
@since 29/08/2017
@version P12.1.17

/*/
Function A010doc()
Private aRotina	:= MenuDef()

MsDocument('SB1',SB1->(Recno()),4)
Return

/*/{Protheus.doc} M010GetNCM
	(long_description)
	@type  M010GetNCM
	@author Paulo V. Beraldo
	@since Jan/2020
	@version 1.00
	@return true, logico, retorno da Consulta padrão
/*/
Function M010GetNCM()
Local cTec		:= Space( Len( SYD->YD_TEC ) )
Local lConPadOk := ConPad1( NIL , NIL , NIL , 'SYD' , NIL , NIL , .F. )

SYD->( dbSetOrder( 1 ) )

If !( lConPadOk )
	SYD->( dbSeek( FWxFilial( 'SYD' ) + cTec ) )
	If lMvcMata010
		oModel	:= FWModelActive()
		If oModel != Nil .And. oModel:IsActive()
			oSB1Mod	:= oModel:GetModel( 'SB1MASTER' )
			If oModel:GetOperation() == MODEL_OPERATION_INSERT .Or. oModel:GetOperation() == MODEL_OPERATION_UPDATE
				oSB1Mod:LoadValue( 'B1_POSIPI', CriaVar( 'B1_POSIPI', .F. ) )
				oSB1Mod:LoadValue( 'B1_EX_NCM', CriaVar( 'B1_EX_NCM', .F. ) )
				oSB1Mod:LoadValue( 'B1_EX_NBM', CriaVar( 'B1_EX_NBM', .F. ) )
			EndIf
		EndIf
	Else
		If INCLUI .Or. ALTERA
			SetMemVar( 'B1_POSIPI', CriaVar( 'B1_POSIPI', .F. ) )
			SetMemVar( 'B1_EX_NCM', CriaVar( 'B1_EX_NCM', .F. ) )
			SetMemVar( 'B1_EX_NBM', CriaVar( 'B1_EX_NBM', .F. ) )
		EndIf
	EndIf
Else
	If lMvcMata010
		oModel	:= FWModelActive()
		If oModel != Nil .And. oModel:IsActive()
			oSB1Mod	:= oModel:GetModel( 'SB1MASTER' )
			If oModel:GetOperation() == MODEL_OPERATION_INSERT .Or. oModel:GetOperation() == MODEL_OPERATION_UPDATE
				oSB1Mod:LoadValue( 'B1_POSIPI', SYD->YD_TEC 	)
				oSB1Mod:LoadValue( 'B1_EX_NCM', SYD->YD_EX_NCM 	)
				oSB1Mod:LoadValue( 'B1_EX_NBM', SYD->YD_EX_NBM 	)
			EndIf
		EndIf
	Else
		If INCLUI .Or. ALTERA
			SetMemVar( 'B1_POSIPI', SYD->YD_TEC 	)
			SetMemVar( 'B1_EX_NCM', SYD->YD_EX_NCM 	)
			SetMemVar( 'B1_EX_NBM', SYD->YD_EX_NBM 	)
		EndIf
	EndIf

EndIf

Return .T.

/*/{Protheus.doc} A10InitCod()
	Funcao Responsavel por Realizar a Inicializacao Padrao do Codigo do Produto
	@type Function
	@author Paulo V. Beraldo
	@since Jul/2020
	@version 1.00
	@param param, param_type, param_descr
	@return cRet, Caracter	, Retorna o Conteudo para Inicializacao do Campo B1_COD
/*/
Function A10InitCod()
Local cRet		:= CriaVar( 'B1_COD', .F. )
Local aArea 	:= GetArea()
Local aAreaSB1 	:= SB1->( GetArea() )
Local aAreaSX3 	:= SX3->( GetArea() )
Local cSx3Init	:= AllTrim( GetSx3Cache( 'B1_COD', 'X3_RELACAO' ) )

If !( Empty( cSx3Init ) )
	cRet := &( cSx3Init )

	SB1->( dbSetOrder( 1 ) )
	While SB1->( dbSeek( FWxFilial( 'SB1' ) + cRet ) )
		ConfirmSx8( .T. )
		cRet :=	GetSx8Num( 'SB1', 'B1_COD' )
	EndDo

EndIf

RestArea( aAreaSX3 )
RestArea( aAreaSB1 )
RestArea( aArea )
Return cRet
