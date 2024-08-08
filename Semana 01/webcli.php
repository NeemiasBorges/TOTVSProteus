
<?php
        try
        {
            $client    = "http://127.0.0.1:6543/ws/WSPHPCLI.apw?WSDL";     // link completo do WSDL
            $Conexao  = new SoapClient($client,array("cache_wsdl"=>WSDL_CACHE_NONE,
                                                        'exceptions' => TRUE, 
                                                        'encoding'   =>'UTF-8'));
            // var_dump($Conexao->__getFunctions());  
            // var_dump($Conexao->__getTypes()); 
         // executa o método
            $params = array('CCPF'=>"03233015482");
            $retorno = $Conexao->validacpf($params);
            $cpf = $retorno->VALIDACPFRESULT ;
            echo($cpf);
 
        }
        catch (Exception $e)
        {
            echo 'Call error: ' . $e->getMessage();
        } 
?>