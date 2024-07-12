-- Please update version.sql too -- this keeps clean builds in sync
define version=2254
@update_header

INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, field_name, description, help_text, repeats, display_pos)
   VALUES (3, 'FOR_REGIONS_DESCRIPTION', 'Regions description', 'The description of the regions relating to the delegation', 1, 11);

@../sheet_body

@update_tail
