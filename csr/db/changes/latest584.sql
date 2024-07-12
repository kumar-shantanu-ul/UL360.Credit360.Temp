-- Please update version.sql too -- this keeps clean builds in sync
define version=584
@update_header

begin
	for r in (select 1 from user_tab_columns where table_name='DEFAULT_ALERT_TEMPLATE_BODY' and column_name='APP_SID') loop
		execute immediate 'alter table default_alert_template_body drop column app_sid';
	end loop;
end;
/

create table sheet_alert (
	app_sid number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	sheet_id number(10) not null,
	user_sid number(10) not null,
	reminder_sent_dtm date,
	overdue_sent_dtm date,
	constraint pk_sheet_alert primary key (app_sid, sheet_id, user_sid)
	using index tablespace indx,
	constraint fk_sheet_alert_sheet foreign key (app_sid, sheet_id)
	references sheet(app_sid, sheet_id),
	constraint fk_sheet_alert_csr_user foreign key (app_sid, user_sid)
	references csr_user(app_sid, csr_user_sid)
);

create index ix_sheet_alert_user on sheet_alert(app_sid, user_sid) tablespace indx;

insert into sheet_alert (app_sid, sheet_id, user_sid, reminder_sent_dtm, overdue_sent_dtm)
	select s.app_sid, s.sheet_id, du.user_sid, s.last_reminded_dtm, s.last_overdue_dtm
	  from sheet s, delegation_user du
	 where s.app_sid = du.app_sid and s.delegation_sid = du.delegation_sid;

create table approval_step_sheet_alert (
	app_sid number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	approval_step_id number(10) not null,
	sheet_key varchar2(255) not null,
	user_sid number(10) not null,
	reminder_sent_dtm date,
	overdue_sent_dtm date,
	constraint pk_approval_step_sheet_alert primary key (app_sid, approval_step_id, sheet_key, user_sid)
	using index tablespace indx,
	constraint fk_apss_alert_apss foreign key (app_sid, approval_step_id, sheet_key)
	references approval_step_sheet (app_sid, approval_step_id, sheet_key),
	constraint fk_apss_alert_csr_user foreign key (app_sid, user_sid)
	references csr_user(app_sid, csr_user_sid)
);

insert into approval_step_sheet_alert (app_sid, approval_step_id, sheet_key, user_sid, reminder_sent_dtm, overdue_sent_dtm)
	select apss.app_sid, apss.approval_step_id, apss.sheet_key, apsu.user_sid, apss.reminder_sent_dtm, apss.overdue_sent_dtm
	  from approval_step_sheet apss, approval_step_user apsu
	 where apss.app_sid = apsu.app_sid and apss.approval_step_id = apsu.approval_step_id;

create table delegation_terminated_alert (
	app_sid								number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	deleg_terminated_alert_id			number(10) not null,
	notify_user_sid						number(10) not null,
	raised_by_user_sid					number(10) not null,
	delegation_sid						number(10) not null,
	constraint pk_delegation_terminated_alert primary key (app_sid, deleg_terminated_alert_id)
	using index tablespace indx,
	constraint fk_del_term_alert_notify_user foreign key (app_sid, notify_user_sid)
	references csr_user(app_sid, csr_user_sid),
	constraint fk_del_term_alert_raised_user foreign key (app_sid, raised_by_user_sid)
	references csr_user(app_sid, csr_user_sid)
);

create index ix_del_term_alert_notify_user on delegation_terminated_alert(app_sid, notify_user_sid) tablespace indx;
create index ix_del_term_alert_raised_user on delegation_terminated_alert(app_sid, raised_by_user_sid) tablespace indx;
create sequence deleg_terminated_alert_id_seq;

insert into delegation_terminated_alert (app_sid, deleg_terminated_alert_id, notify_user_sid, raised_by_user_sid, delegation_sid)
	select app_sid, deleg_terminated_alert_id_seq.nextval, notify_user_sid, raised_by_user_sid, params
	  from alert
	 where sent_dtm is null
	   and alert_type_id = 7;

create table user_message_alert (
	app_sid								number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	user_message_alert_id				number(10) not null,
	notify_user_sid						number(10) not null,
	raised_by_user_sid					number(10) not null,
	message								clob,
	constraint pk_user_message_alert primary key (app_sid, user_message_alert_id)
	using index tablespace indx,
	constraint fk_usr_mess_alert_notify_user foreign key (app_sid, notify_user_sid)
	references csr_user(app_sid, csr_user_sid),
	constraint fk_usr_mess_alert_raised_user foreign key (app_sid, raised_by_user_sid)
	references csr_user(app_sid, csr_user_sid)
);

create index ix_user_mess_alrt_notify_user on user_message_alert(app_sid, notify_user_sid) tablespace indx;
create index ix_user_mess_alrt_raised_user on user_message_alert(app_sid, raised_by_user_sid) tablespace indx;
create sequence user_message_alert_id_seq;

insert into user_message_alert (app_sid, user_message_alert_id, notify_user_sid, raised_by_user_sid, message)
	select app_sid, user_message_alert_id_seq.nextval, notify_user_sid, raised_by_user_sid, params
	  from alert
	 where sent_dtm is null
	   and alert_type_id = 1;

create table new_delegation_alert (
	app_sid								number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	new_delegation_alert_id				number(10) not null,
	notify_user_sid						number(10) not null,
	raised_by_user_sid					number(10) not null,
	sheet_id							number(10) not null,
	constraint pk_new_delegation_alert primary key (app_sid, new_delegation_alert_id)
	using index tablespace indx,
	constraint fk_new_deleg_alrt_notify_user foreign key (app_sid, notify_user_sid)
	references csr_user(app_sid, csr_user_sid),
	constraint fk_new_deleg_alrt_raised_user foreign key (app_sid, raised_by_user_sid)
	references csr_user(app_sid, csr_user_sid),
	constraint fk_new_deleg_alrt_sheet foreign key (app_sid, sheet_id)
	references sheet(app_sid, sheet_id)
);

create index ix_new_deleg_alrt_notify_user on new_delegation_alert(app_sid, notify_user_sid) tablespace indx;
create index ix_new_deleg_alrt_raised_user on new_delegation_alert(app_sid, raised_by_user_sid) tablespace indx;
create index ix_new_deleg_alert_sheet on new_delegation_alert(app_sid, sheet_id);
create sequence new_delegation_alert_id_seq;

insert into new_delegation_alert (app_sid, new_delegation_alert_id, notify_user_sid, raised_by_user_sid, sheet_id)
	select app_sid, user_message_alert_id_seq.nextval, notify_user_sid, raised_by_user_sid, params
	  from alert
	 where sent_dtm is null
	   and alert_type_id = 2
	   and params in (select sheet_id from sheet);

create table delegation_change_alert (
	app_sid								number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	delegation_change_alert_id			number(10) not null,
	notify_user_sid						number(10) not null,
	raised_by_user_sid					number(10) not null,
	sheet_id							number(10) not null,
	constraint pk_delegation_change_alert primary key (app_sid, delegation_change_alert_id)
	using index tablespace indx,
	constraint fk_deleg_chg_alrt_notify_user foreign key (app_sid, notify_user_sid)
	references csr_user(app_sid, csr_user_sid),
	constraint fk_deleg_chg_alrt_raised_user foreign key (app_sid, raised_by_user_sid)
	references csr_user(app_sid, csr_user_sid),
	constraint fk_deleg_chg_alrt_sheet foreign key (app_sid, sheet_id)
	references sheet(app_sid, sheet_id)
);

create index ix_deleg_chg_alrt_notify_user on delegation_change_alert(app_sid, notify_user_sid) tablespace indx;
create index ix_deleg_chg_alrt_raised_user on delegation_change_alert(app_sid, raised_by_user_sid) tablespace indx;
create index ix_deleg_chg_alert_sheet on delegation_change_alert(app_sid, sheet_id);
create sequence deleg_change_alert_id_seq;

insert into delegation_change_alert (app_sid, delegation_change_alert_id, notify_user_sid, raised_by_user_sid, sheet_id)
	select app_sid, deleg_change_alert_id_seq.nextval, notify_user_sid, raised_by_user_sid, params
	  from alert
	 where sent_dtm is null
	   and alert_type_id = 4
	   and params in (select sheet_id from sheet);

begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'DELEGATION_CHANGE_ALERT',
        policy_name     => 'DELEGATION_CHANGE_ALER_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'NEW_DELEGATION_ALERT',
        policy_name     => 'NEW_DELEGATION_ALERT_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
        
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'USER_MESSAGE_ALERT',
        policy_name     => 'USER_MESSAGE_ALERT_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'DELEGATION_TERMINATED_ALERT',
        policy_name     => 'DELEGATION_TERMINATE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
end;
/

BEGIN
INSERT INTO ALERT_TYPE (ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (27, 'Approval step data reminder',
	'A sheet has not been submitted, but is is past the reminder date. Reminder notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
);  
INSERT INTO ALERT_TYPE (ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (28, 'Approval step data overdue',
	'A sheet has not been submitted, but is is past the due date. Overdue notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
); 

-- Approval step data reminder
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 8);

-- Approval step data overdue	
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 8);

INSERT INTO default_alert_template (alert_type_id, default_alert_frame_id, send_type)
	SELECT 27, default_alert_frame_id, send_type
	  FROM default_alert_template
	 WHERE alert_type_id = 5;
INSERT INTO default_alert_template_body (alert_type_id, lang, subject, body_html, item_html)
	SELECT 27, lang, subject, body_html, item_html
	  FROM default_alert_template_body
	 WHERE alert_type_id = 5;

INSERT INTO default_alert_template (alert_type_id, default_alert_frame_id, send_type)
	SELECT 28, default_alert_frame_id, send_type
	  FROM default_alert_template
	 WHERE alert_type_id = 3;
INSERT INTO default_alert_template_body (alert_type_id, lang, subject, body_html, item_html)
	SELECT 28, lang, subject, body_html, item_html
	  FROM default_alert_template_body
	 WHERE alert_type_id = 3;

INSERT INTO customer_alert_type (app_sid, alert_type_id)
	SELECT cat.app_sid, 27
	  FROM customer_alert_type cat
	 WHERE cat.alert_type_id = 5
	   AND EXISTS (SELECT 1 FROM customer_alert_type cat2 WHERE cat.app_sid = cat2.app_sid AND alert_type_id BETWEEN 9 AND 18);

INSERT INTO customer_alert_type (app_sid, alert_type_id)
	SELECT cat.app_sid, 28
	  FROM customer_alert_type cat
	 WHERE cat.alert_type_id = 3
	   AND EXISTS (SELECT 1 FROM customer_alert_type cat2 WHERE cat.app_sid = cat2.app_sid AND alert_type_id BETWEEN 9 AND 18);

INSERT INTO alert_template (app_sid, alert_type_id, alert_frame_id, send_type, reply_to_name, reply_to_email)
	SELECT app_sid, 27, alert_frame_id, send_type, reply_to_name, reply_to_email
	  FROM alert_template at
	 WHERE alert_type_id = 5
	   AND EXISTS (SELECT 1 FROM customer_alert_type cat2 WHERE at.app_sid = cat2.app_sid AND alert_type_id BETWEEN 9 AND 18);
	   
INSERT INTO alert_template_body (app_sid, alert_type_id, lang, subject, body_html, item_html)
	SELECT app_sid, 27, lang, subject, body_html, item_html
	  FROM alert_template_body atb
	 WHERE alert_type_id = 5
	   AND EXISTS (SELECT 1 FROM customer_alert_type cat2 WHERE atb.app_sid = cat2.app_sid AND alert_type_id BETWEEN 9 AND 18);

INSERT INTO alert_template (app_sid, alert_type_id, alert_frame_id, send_type, reply_to_name, reply_to_email)
	SELECT app_sid, 28, alert_frame_id, send_type, reply_to_name, reply_to_email
	  FROM alert_template at
	 WHERE alert_type_id = 3
	   AND EXISTS (SELECT 1 FROM customer_alert_type cat2 WHERE at.app_sid = cat2.app_sid AND alert_type_id BETWEEN 9 AND 18);
	 
INSERT INTO alert_template_body (app_sid, alert_type_id, lang, subject, body_html, item_html)
	SELECT app_sid, 28, lang, subject, body_html, item_html
	  FROM alert_template_body atb
	 WHERE alert_type_id = 3
	   AND EXISTS (SELECT 1 FROM customer_alert_type cat2 WHERE atb.app_sid = cat2.app_sid AND alert_type_id BETWEEN 9 AND 18);

END;
/

create or replace view sheet_with_last_action as
SELECT SH.APP_SID, SH.SHEET_ID, SH.DELEGATION_SID, SH.START_DTM, SH.END_DTM, SH.REMINDER_DTM, SH.SUBMISSION_DTM, 
	   SHE.SHEET_ACTION_ID LAST_ACTION_ID, SHE.FROM_USER_SID LAST_ACTION_FROM_USER_SID, SHE.ACTION_DTM LAST_ACTION_DTM, 
	   SHE.NOTE LAST_ACTION_NOTE, SHE.TO_DELEGATION_SID LAST_ACTION_TO_DELEGATION_SID, 
	   CASE WHEN SYSDATE >= submission_dtm AND SHE.SHEET_ACTION_ID IN (0,2) THEN 1 --csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_RETURNED
            WHEN SYSDATE >= reminder_dtm AND SHE.SHEET_ACTION_ID IN (0,2) THEN 2 --csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_RETURNED
            ELSE 3
       END STATUS, SH.IS_VISIBLE, SH.LAST_SHEET_HISTORY_ID, SHA.COLOUR LAST_ACTION_COLOUR
 FROM SHEET_HISTORY SHE, SHEET SH, SHEET_ACTION SHA
WHERE SHE.APP_SID = SH.APP_SID
  AND SH.LAST_SHEET_HISTORY_ID = SHE.SHEET_HISTORY_ID
  AND SHE.SHEET_ID = SH.SHEET_ID
  AND SHE.SHEET_ACTION_ID = SHA.SHEET_ACTION_ID;
 
drop table alert;
alter table approval_step_sheet drop column reminder_sent_dtm;
alter table approval_step_sheet drop column overdue_sent_dtm;
alter table sheet drop column last_reminded_dtm;
alter table sheet drop column last_overdue_dtm;

@../csr_data_pkg
@../csr_user_pkg
@../alert_pkg
@../delegation_pkg
@../sheet_pkg
@../pending_pkg.sql

@../alert_body
@../csr_user_body
@../csr_data_body
@../delegation_body
@../sheet_body
@../pending_body

@update_tail
