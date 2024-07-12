define version=9
@update_header

@..\chain_link_pkg
@..\chain_link_body

GRANT EXECUTE ON chain_link_pkg TO web_user;

UPDATE customer_options 
	SET company_helper_sp='maersk.maersk_link_pkg' 
  WHERE chain_implementation='MAERSK';

INSERT INTO task_status(
	task_status_id, description
) values (
	9, 'Not Applicable'
);

@update_tail


