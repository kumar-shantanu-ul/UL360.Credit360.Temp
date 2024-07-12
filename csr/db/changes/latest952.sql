-- Please update version.sql too -- this keeps clean builds in sync
define version=952
@update_header

UPDATE csr.std_alert_type_param
SET	repeats = 0
WHERE std_alert_type_id = 17
AND field_name in ('SHEET_LABEL', 'SHEET_URL');

@update_tail
