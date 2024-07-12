-- Please update version.sql too -- this keeps clean builds in sync
define version=2790
define minor_version=1
define is_combined=0
@update_header

UPDATE csr.std_alert_type
   SET description = REGEXP_REPLACE(description, 'Corporate Reporter', 'Framework Manager')
 WHERE description LIKE 'Corporate Reporter%';
 
@update_tail