-- Please update version.sql too -- this keeps clean builds in sync
define version=1657
@update_header

BEGIN
	--Add new FOR_REGIONS_DESCRIPTION std_alert_type_param for 'Delegation data reminder'
 	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5, 1, 'FOR_REGIONS_DESCRIPTION', 'Regions description', 'The description of the regions relating to the delegation', 12);
end;
/

@../delegation_pkg
@../delegation_body

@../sheet_body
							 
@update_tail


