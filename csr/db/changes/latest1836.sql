-- Please update version.sql too -- this keeps clean builds in sync
define version=1836
@update_header

ALTER TABLE csr.sheet ADD (percent_complete NUMBER(10,0));

ALTER TABLE csr.temp_delegation_detail ADD (percent_complete NUMBER(10,0));

CREATE OR REPLACE VIEW csr.sheet_with_last_action AS
	SELECT sh.app_sid, sh.sheet_id, sh.delegation_sid, sh.start_dtm, sh.end_dtm, sh.reminder_dtm, sh.submission_dtm, 
		   she.sheet_action_id last_action_id, she.from_user_sid last_action_from_user_sid, she.action_dtm last_action_dtm, 
		   she.note last_action_note, she.to_delegation_sid last_action_to_delegation_sid, 
		   CASE WHEN sysdate >= submission_dtm AND she.sheet_action_id IN (0,10,2) THEN 1 --csr_data_pkg.action_waiting, waiting_with_mod, csr_data_pkg.action_returned
				WHEN sysdate >= reminder_dtm AND she.sheet_action_id IN (0,10,2) THEN 2 --csr_data_pkg.action_waiting, waiting_with_mod, csr_data_pkg.action_returned
				ELSE 3
		   END status, sh.is_visible, sh.last_sheet_history_id, sha.colour last_action_colour, sh.is_read_only, sh.percent_complete,
		   sha.description last_action_desc, sha.downstream_description last_action_downstream_desc
	 FROM sheet sh
		JOIN sheet_history she ON sh.last_sheet_history_id = she.sheet_history_id AND she.sheet_id = sh.sheet_id AND sh.app_sid = she.app_sid
		JOIN sheet_action sha ON she.sheet_action_id = sha.sheet_action_id;
		
@../sheet_pkg
@../delegation_pkg
@../sheet_body
@../delegation_body

@update_tail