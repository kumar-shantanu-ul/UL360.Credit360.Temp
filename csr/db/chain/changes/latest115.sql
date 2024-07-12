define version=115
@update_header

UPDATE chain.default_message_definition
   SET message_priority_id = 1 -- chain_pkg.NEUTRAL
 WHERE message_definition_id IN (
	SELECT message_definition_id
	  FROM chain.message_definition_lookup
	 WHERE primary_lookup_id = 202 -- chain_pkg.INVITATION_REJECTED
	   AND secondary_lookup_id = 1 -- chain_pkg.PURCHASER_MSG
	);

@..\invitation_body
@..\message_body

@update_tail