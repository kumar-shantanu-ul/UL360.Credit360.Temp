define version=86
@update_header

BEGIN
	UPDATE chain.default_message_param 
	   SET css_class = NULL
	 WHERE param_name = 'productMapping' 
	   AND message_definition_id IN (
	   		SELECT message_definition_id
	   		  FROM chain.message_definition_lookup 
	   		 WHERE primary_lookup_id = chain_pkg.PRODUCT_MAPPING_REQUIRED 
	   		   AND secondary_lookup_id = chain_pkg.SUPPLIER_MSG
   		);
END;
/

@..\message_body

@update_tail