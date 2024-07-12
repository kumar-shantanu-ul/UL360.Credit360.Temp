-- Please update version.sql too -- this keeps clean builds in sync
define version=708
@update_header

update csr.alert_type
   set send_trigger = 'The state of a sheet changes (by submitting, approving or rejecting).',
	   sent_from = 'The user who changed the state.'
 where alert_type_id = 4;

@update_tail
