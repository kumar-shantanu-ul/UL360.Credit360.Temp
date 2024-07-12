-- Please update version.sql too -- this keeps clean builds in sync
define version=2705
@update_header

update csr.std_alert_type_param 
   set description = 'Region name'
 where std_alert_type_id = 18
   and field_name = 'REGION_DESCRIPTION'
   and description = 'Region';

@update_tail
