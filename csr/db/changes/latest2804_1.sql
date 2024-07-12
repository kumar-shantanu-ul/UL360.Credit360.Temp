-- Please update version.sql too -- this keeps clean builds in sync
define version=2804
define minor_version=1
define is_combined=0
@update_header

UPDATE csr.std_alert_type
   SET description = REGEXP_REPLACE(description, 'Corporate Reporter', 'Framework Manager')
 WHERE description LIKE 'Corporate Reporter%';
 
UPDATE csr.std_alert_type_group
   SET description = 'Framework Manager'
 WHERE description = 'Corporate Reporter';
	
 
@update_tail