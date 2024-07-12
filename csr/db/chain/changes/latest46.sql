define version=46
@update_header

PROMPT >> Please ensure that you have svnd up:
PROMPT >> svn up c:\cvs\clients\maersk
PROMPT >> svn up c:\cvs\clients\chaindemo
PROMPT >> svn up c:\cvs\clients\rainforestalliance
PROMPT >> 
PROMPT >> ** Note that we will be connecting as these users and rebuilding packages.
PROMPT >> If you do not have the clients created locally, you will want to comment out
PROMPT >> the appropriate lines in the update script.
PROMPT >>
PROMPT >> Press CTRL+C to exit, or any Enter to continue.
define confirm_check = &&1

DROP TABLE ea_country;
DROP TABLE ea_product_service;
DROP TABLE example_answers;

DROP VIEW v$example_prod_serv;

-- only drop the package if it's been built
BEGIN
	FOR r IN (
		select * from user_objects where object_name = 'EXAMPLE_ANSWERS_PKG' and object_type = 'PACKAGE'
	) LOOP
		EXECUTE IMMEDIATE 'DROP PACKAGE example_answers_pkg';
	END LOOP;
END;
/

@..\chain_pkg
@..\action_pkg
@..\company_pkg
@..\questionnaire_pkg

@..\action_body
@..\capability_body
@..\company_body
@..\questionnaire_body


@..\grants

PROMPT >> connecting to chaindemo
connect chaindemo/chaindemo@&_CONNECT_IDENTIFIER
@..\..\..\..\clients\chaindemo\db\supp_reg_task_body

PROMPT >> connecting to maersk
connect maersk/maersk@&_CONNECT_IDENTIFIER
@..\..\..\..\clients\maersk\db\supp_reg_task_body

PROMPT >> connecting to rfa
connect rfa/rfa@&_CONNECT_IDENTIFIER
@..\..\..\..\clients\rainforestalliance\db\sourcing_pkg
@..\..\..\..\clients\rainforestalliance\db\sourcing_body

PROMPT >> connecting to chain
connect chain/chain@&_CONNECT_IDENTIFIER

@update_tail

