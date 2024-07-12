-- Please update version.sql too -- this keeps clean builds in sync
define version=2594
@update_header

CREATE OR REPLACE VIEW csr.sheet_with_last_action AS
	SELECT sh.app_sid, sh.sheet_id, sh.delegation_sid, sh.start_dtm, sh.end_dtm, sh.reminder_dtm, sh.submission_dtm,
		   she.sheet_action_id last_action_id, she.from_user_sid last_action_from_user_sid, she.action_dtm last_action_dtm, 
		   she.note last_action_note, she.to_delegation_sid last_action_to_delegation_sid, 
		   CASE WHEN SYSTIMESTAMP AT TIME ZONE COALESCE(ut.timezone, a.timezone, 'Etc/GMT') >= from_tz(cast(sh.submission_dtm as timestamp), COALESCE(ut.timezone, a.timezone, 'Etc/GMT'))
                 AND she.sheet_action_id IN (0,10,2) 
                    THEN 1 
				WHEN SYSTIMESTAMP AT TIME ZONE COALESCE(ut.timezone, a.timezone, 'Etc/GMT') >= from_tz(cast(sh.reminder_dtm as timestamp), COALESCE(ut.timezone, a.timezone, 'Etc/GMT')) 
                 AND she.sheet_action_id IN (0,10,2)
                    THEN 2 
				ELSE 3
		   END status, sh.is_visible, sh.last_sheet_history_id, sha.colour last_action_colour, sh.is_read_only, sh.percent_complete,
		   sha.description last_action_desc, sha.downstream_description last_action_downstream_desc
	 FROM sheet sh
		JOIN sheet_history she ON sh.last_sheet_history_id = she.sheet_history_id AND she.sheet_id = sh.sheet_id AND sh.app_sid = she.app_sid
		JOIN sheet_action sha ON she.sheet_action_id = sha.sheet_action_id
        LEFT JOIN csr.csr_user u ON u.csr_user_sid = SYS_CONTEXT('SECURITY','SID') AND u.app_sid = sh.app_sid
        LEFT JOIN security.user_table ut ON ut.sid_id = u.csr_user_sid
        LEFT JOIN security.application a ON a.application_sid_id = u.app_sid;

@update_tail
