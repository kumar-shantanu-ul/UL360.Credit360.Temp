-- Please update version.sql too -- this keeps clean builds in sync
define version=1539
@update_header

CREATE TABLE CSR.AUDIT_ALERT(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    INTERNAL_AUDIT_SID    NUMBER(10, 0)    NOT NULL,
    CSR_USER_SID          NUMBER(10, 0)    NOT NULL,
    REMINDER_SENT_DTM     DATE,
    OVERDUE_SENT_DTM      DATE,
    CONSTRAINT PK_AUDIT_ALERT PRIMARY KEY (APP_SID, INTERNAL_AUDIT_SID, CSR_USER_SID)
)
;

CREATE INDEX CSR.IX_AUDIT_ALERT_AUDIT ON CSR.AUDIT_ALERT(APP_SID, INTERNAL_AUDIT_SID)
;
CREATE INDEX CSR.IX_AUDIT_ALERT_USER ON CSR.AUDIT_ALERT(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.AUDIT_ALERT ADD CONSTRAINT FK_AUDIT_ALERT_AUDIT 
    FOREIGN KEY (APP_SID, INTERNAL_AUDIT_SID)
    REFERENCES CSR.INTERNAL_AUDIT(APP_SID, INTERNAL_AUDIT_SID)
;

ALTER TABLE CSR.AUDIT_ALERT ADD CONSTRAINT FK_AUDIT_ALERT_USER 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

CREATE TABLE CSRIMP.AUDIT_ALERT(
   CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    INTERNAL_AUDIT_SID    NUMBER(10, 0)    NOT NULL,
    CSR_USER_SID          NUMBER(10, 0)    NOT NULL,
    REMINDER_SENT_DTM     DATE,
    OVERDUE_SENT_DTM      DATE,
    CONSTRAINT PK_AUDIT_ALERT PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_SID, CSR_USER_SID),
    CONSTRAINT FK_AUDIT_ALERT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
)
;

grant select,insert,update,delete on csrimp.audit_alert to web_user;
grant insert on csr.audit_alert to csrimp;


CREATE OR REPLACE VIEW csr.v$deleg_plan_delegs AS
	SELECT dpc.deleg_plan_sid, dpcd.delegation_sid template_deleg_sid, dpdrd.maps_to_root_deleg_sid,
		   d.delegation_sid applied_to_delegation_sid
	  FROM deleg_plan_col dpc
	  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id AND dpc.app_sid = dpcd.app_sid
	  JOIN deleg_plan_deleg_region_deleg dpdrd ON dpcd.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id AND dpcd.app_sid = dpdrd.app_sid
	  JOIN (
		SELECT CONNECT_BY_ROOT delegation_sid root_delegation_sid, delegation_sid
		  FROM delegation
		 START WITH parent_sid = app_sid
		CONNECT BY PRIOR delegation_sid = parent_sid AND PRIOR app_sid = app_sid
	  ) d ON d.root_delegation_sid = dpdrd.maps_to_root_deleg_sid;

-- new alert types
DECLARE
	v_default_alert_frame_id	NUMBER;
	v_customer_alert_type_id	NUMBER;
BEGIN

	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (45, 'Audits due to expire (reminder)',
		'There are audits that are about to expire that haven''t had a follow-up audit scheduled. This is sent daily.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);
	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (46, 'Audits expired (overdue)',
		'There are audits that have expired that haven''t had a follow-up audit scheduled. This is sent daily.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);

	-- Expiring audits (reminder)
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (45, 0, 'TO_FULL_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (45, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (45, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (45, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (45, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (45, 1, 'AUDIT_TYPE_LABEL', 'Audit type', 'The name of the audit type that is about to expire', 6);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (45, 1, 'AUDIT_REGION', 'Region name', 'The name of the region that the audit relates to', 7);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (45, 1, 'DUE_DTM', 'Due date', 'The date a re-audit or follow-up audit is due', 8);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (45, 1, 'SCHEDULE_LINK', 'Schedule link', 'A link to schedule an audit of this type at this location', 9);

	-- Expired audits (overdue)
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (46, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (46, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (46, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (46, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (46, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (46, 1, 'AUDIT_TYPE_LABEL', 'Audit type', 'The name of the audit type that is about to expire', 6);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (46, 1, 'AUDIT_REGION', 'Region name', 'The name of the region that the audit relates to', 7);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (46, 1, 'DUE_DTM', 'Due date', 'The date a re-audit or follow-up audit is due', 8);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (46, 1, 'SCHEDULE_LINK', 'Schedule link', 'A link to schedule an audit of this type at this location', 9);

	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (45, v_default_alert_frame_id, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (46, v_default_alert_frame_id, 'manual');


	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (45, 'en',
		'<template>Audits are about to expire</template>',
		'<template><p>Dear <mergefield name="TO_NAME"/>,</p><p>The following audits are about to expire:</p><mergefield name="ITEMS"/></template>', 
		'<template><p><mergefield name="AUDIT_TYPE_LABEL"/> at <mergefield name="AUDIT_REGION"/> expires on <mergefield name="DUE_DTM"/>. <mergefield name="SCHEDULE_LINK"/></p></template>'
		);
	
	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (46, 'en',
		'<template>Audits have expired</template>',
		'<template><p>Dear <mergefield name="TO_NAME"/>,</p><p>The following audits have expired:</p><mergefield name="ITEMS"/></template>', 
		'<template><p><mergefield name="AUDIT_TYPE_LABEL"/> at <mergefield name="AUDIT_REGION"/> expires on <mergefield name="DUE_DTM"/>. <mergefield name="SCHEDULE_LINK"/></p></template>'
		);

	-- add new alert to all customers that use audits
	FOR r IN (
		SELECT c.app_sid
		  FROM csr.customer c
		  JOIN security.securable_object so ON so.parent_sid_id = c.app_sid
		 WHERE so.name='Audits'
	) LOOP
		BEGIN
			INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (r.app_sid, csr.customer_alert_type_id_seq.nextval, 45);
			
			INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
			VALUES (r.app_sid, csr.customer_alert_type_id_seq.nextval, 46);

			INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
			SELECT r.app_sid, cat.customer_alert_type_id, MIN(af.alert_frame_id), 'manual'
			  FROM csr.alert_frame af
			  JOIN csr.customer_alert_type cat ON af.app_sid = cat.app_sid
			 WHERE af.app_sid = r.app_sid
			   AND cat.std_alert_type_id IN (45, 46)
			 GROUP BY cat.customer_alert_type_id
			HAVING MIN(af.alert_frame_id) > 0;
			
			
			INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
			SELECT r.app_sid, cat.customer_alert_type_id, t.lang, d.subject, d.body_html, d.item_html
			  FROM csr.default_alert_template_body d
			  JOIN csr.customer_alert_type cat ON d.std_alert_type_id = cat.std_alert_type_id
			  JOIN csr.alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
			  CROSS JOIN aspen2.translation_set t
			 WHERE d.std_alert_type_id IN (45, 46)
			   AND d.lang='en'
			   AND t.application_sid = r.app_sid
			   AND cat.app_sid = r.app_sid;
		EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
		END;
	END LOOP;
	
END;
/

@..\csr_data_pkg
@..\audit_pkg
@..\schema_pkg

@..\csr_data_body
@..\audit_body
@..\schema_body
@..\csrimp\imp_body

@update_tail