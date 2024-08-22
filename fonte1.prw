#include "totvs.ch"
#Include "Protheus.ch"
User Function ExeImportacao()
    If MsgYesNo("Deseja Executar a Importação de Notas Fiscais?", "Menu de Importação")
       u_ImportarArquivo()
    Else
        Alert("Execução finalizada")
    EndIf
Return
 
User Function ImportarArquivo()
    Local cArqAux := '' 

    cArqAux := cGetFile( 'Selecione um Arquivo PDF |*.pdf| Selecione um arquivo XML |*.xml',; 
                         'Seleção de Nota Fiscal',;                                            
                         1,;                                                                   
                         'C:\Users\Fatec\Desktop',;                                       
                         .F.,;                                                                 
                         GETF_LOCALHARD + GETF_NETWORKDRIVE + GETF_NOCHANGEDIR,;               
                         .F.)                                                                  
                         
    If Empty(cArqAux)
        If MsgYesNo("Nenhum arquivo escolhido, deseja realizar novamente a Importaçao?", "Menu de Importação")
            u_ImportarArquivo()
        Else
            Alert("Execução finalizada")
        EndIf
    Else
        u_InserirRegistroBanco(cArqAux) 
    EndIf

Return


User Function InserirRegistroBanco(nomeArquivo)
    Local aArea     := FWGetArea()
    Local cArqAux := nomeArquivo   
    Local cTableTmp := "PRODTMP"
    Local aStruct   := {}

    If MsgYesNo('Arquivo escolhido: ' + cArqAux + ' Deseja Continuar?', 'Atenção') 
 
  
    aAdd(aStruct, {"CODIGO", "C",  6, 0})
    aAdd(aStruct, {"NOME",   "C", 50, 0})
 
    FWDBCreate(cTableTmp, aStruct, "TOPCONN", .T.)
    FWRestArea(aArea)
    
        // c_Qry := " INSERT INTO Arquivos (ID, NomeDoArquivo,CaminhoDoArquivo, StatusIntegracao) VALUES (2,'"+cArqAux+"','"+cArqAux+"','Y');"
        // iRet  := TcSqlExec(c_Qry)

        // if (iRet < 0)
        //     Alert("Erro de Execução")
        // else
        //     MsgInfo("Registro inserido com sucesso!", "Sucesso de Importação")
        // endif
    Else
        Alert("Execução Abortada")
    EndIf   

    FWRestArea(aArea)
Return


User Function OpenARQIMP()
Local nH
Local cFile := "ARQIMP"
Local aStru := {}

// Conecta com o DBAccess configurado no ambiente
nH := TCLink()

If nH < 0
  MsgStop("DBAccess - Erro de conexao "+cValToChar(nH))
  QUIT
Endif

If !tccanopen(cFile)
  // Se o arquivo nao existe no banco, cria
  aadd(aStru,{"ID" ,"C",06,0})
  aadd(aStru,{"NOME" ,"C",50,0})
  aadd(aStru,{"ENDER" ,"C",50,0})
  aadd(aStru,{"COMPL" ,"C",20,0})
  aadd(aStru,{"BAIRR" ,"C",30,0})
  aadd(aStru,{"CIDADE","C",40,0})
  aadd(aStru,{"UF" ,"C",02,0})
  aadd(aStru,{"CEP" ,"C",08,0})
  DBCreate(cFile,aStru,"TOPCONN")
Endif

If !tccanopen(cFile,cFile+'1')
  // Se o Indice por ID nao existe, cria
  USE (cFile) ALIAS (cFile) EXCLUSIVE NEW VIA "TOPCONN"
  INDEX ON ID TO (cFile+'1')
  USE
EndIf

If !tccanopen(cFile,cFile+'2')
  USE (cFile) ALIAS (cFile) EXCLUSIVE NEW VIA "TOPCONN"
  INDEX ON NOME TO (cFile+'2')
  USE
EndIf


USE (cFile) ALIAS ARQIMP SHARED NEW VIA "TOPCONN"

If NetErr()
  MsgStop("Falha ao Abrir a ARQIMP em modo compartilhado.")
  QUIT
Endif

// Liga o filtro para ignorar registros deletados 
SET DELETED ON

// Abre os indices, seleciona ordem por ID
// E Posiciona no primeiro registro 
DbSetIndex(cFile+'1')
DbSetIndex(cFile+'2')
DbSetOrder(1)
DbGoTop()

Return 

