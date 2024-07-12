-- Please update version.sql too -- this keeps clean builds in sync
define version=2564
@update_header

BEGIN
	
	UPDATE chain.MESSAGE_DEFINITION_LOOKUP
	   SET secondary_lookup_id = 1	-- PURCHASER_MSG
	 WHERE primary_lookup_id = 601 --AUDIT_REQUEST_REQUIRED
	   AND secondary_lookup_id = 2; --SUPPLIER_MSG
	
	UPDATE chain.default_message_param
	  SET value = 'create an audit request'
	 WHERE message_definition_id = (
		SELECT message_definition_id
		  FROM chain.message_definition_lookup
		 WHERE primary_lookup_id = 601
	);
END;
/

@../audit_pkg
@../chain/company_type_pkg

@../audit_body
@../chain/audit_request_body
@../chain/company_type_body

@update_tail


