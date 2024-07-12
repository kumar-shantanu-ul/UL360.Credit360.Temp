-- Please update version.sql too -- this keeps clean builds in sync
define version=498
@update_header

-- Apply order:
-- grants [or after, you just get compile failures]
-- Mail
-- security
-- aspen2/npsl.translation/db
-- aspen2/cms/db
-- yam/db/
-- this script + csr packages + rls
-- ethics/changes/alerts_changes
-- actions/changes/alerts_changes
-- actions/build
-- supplier/build
-- clients:
-- trs/
-- novonordisk

------------ grants (need to go => dba script for DT)
connect aspen2/aspen2@&_CONNECT_IDENTIFIER
grant select,references on aspen2.translation_set to csr;
grant select on aspen2.lang to csr;
connect security/security@&_CONNECT_IDENTIFIER
grant select on security.application to csr;
grant select on security.application to aspen2;
GRANT SELECT ON security.user_table TO ASPEN2;
connect cms/cms@&_CONNECT_IDENTIFIER
grant select on cms.image to csr;
connect csr/csr@&_CONNECT_IDENTIFIER
-------------

DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM security.version;
	IF v_version < 36 THEN 
		RAISE_APPLICATION_ERROR(-20001, '========= A **security** database of at least version 36 is required =======');
	END IF;
	SELECT db_version INTO v_version FROM mail.version;
	IF v_version < 15 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= A **mail** database of at least version 15 is required =======');
	END IF;
END;
/

-- SECURITY.LATEST36 first

-- xxx check aspen2 + security version
-- make sure npsl.translation/db/tr_pkg + npsl.translation/db/tr_body get recompiled

-- can junk "consolidated alert"
delete from alert_template where alert_type_id=6;
delete from customer_alert_type where alert_type_id=6;
delete from alert_type where alert_type_id=6;

-- we need this later for "upgrades"
create table old_alert_template as 
	select * from alert_template;
drop table alert_template cascade constraints;

-- for testing
-- drop table alert_frame cascade constraints;
-- drop table alert_frame_body cascade constraints;
-- drop table alert_template_body cascade constraints;

create table alert_frame
(
	app_sid	number(10) default sys_context('security','app') not null,
	alert_frame_id number(10) not null,
	name varchar2(1000) not null,
	constraint pk_alert_frame primary key (app_sid, alert_frame_id)
	using index tablespace indx,
	constraint fk_alert_frame foreign key (app_sid) references customer(app_sid)
);

create table alert_frame_body
(
	app_sid	number(10) default sys_context('security','app') not null,
	alert_frame_id number(10) not null,
	lang varchar2(10) not null,
	html clob not null,
	constraint pk_alert_frame_body primary key (app_sid, alert_frame_id, lang)
	using index tablespace indx,
	constraint fk_alert_frm_bdy_alert_frm foreign key (app_sid, alert_frame_id)
	references alert_frame (app_sid, alert_frame_id),
	constraint fk_alert_frm_bdy_tran_set foreign key (app_sid, lang)
	references aspen2.translation_set (application_sid, lang)
);

create table alert_template
(
	app_sid	number(10) default sys_context('security','app') not null,
	alert_type_id number(10) not null,
	alert_frame_id number(10) not null,
	send_type varchar2(10) not null,
	constraint pk_alert_template primary key (app_sid, alert_type_id)
	using index tablespace indx,
	constraint ck_alert_template_send_type check (send_type in ('manual', 'automatic')),
	constraint fk_alert_tpl_cust_alert_type foreign key (app_sid, alert_type_id)
	references customer_alert_type (app_sid, alert_type_id),
	constraint fk_alert_tpl_alert_frame foreign key (app_sid, alert_frame_id)
	references alert_frame (app_sid, alert_frame_id)
);

create table alert_template_body
(
	app_sid	number(10) default sys_context('security','app') not null,
	alert_type_id number(10) not null,
	lang varchar2(10) not null,
	subject clob not null,
	body_html clob not null,
	item_html clob not null,
	constraint pk_alert_template_body primary key (app_sid, alert_type_id, lang)
	using index tablespace indx,
	constraint fk_alt_tpl_bdy_bdy_tran_set foreign key (app_sid, lang)
	references aspen2.translation_set (application_sid, lang),
	constraint fk_alert_tpl_bdy_alert_tpl foreign key (app_sid, alert_type_id)
	references alert_template (app_sid, alert_type_id)
);

create sequence alert_frame_id_seq;

create table alert_type_param
(
	alert_type_id number(10) not null,
	field_name varchar2(100) not null,
	description varchar2(200) not null,
	help_text varchar2(2000) not null,
	repeats number(1) not null,
	display_pos number(10) not null,
	constraint pk_alert_type_param primary key (alert_type_id, field_name)
	using index tablespace indx,
	constraint fk_alrt_type_parm_alrt_type foreign key (alert_type_id)
	references alert_type (alert_type_id)
);

alter table alert_type drop column params_xml;
alter table alert_type drop column get_data_sp;

create index ix_alert_template_frame on ALERT_TEMPLATE(APP_SID, ALERT_FRAME_ID) tablespace indx;
--create index ix_alert_template_lang on ALERT_TEMPLATE(APP_SID, LANG) tablespace indx;
create index ix_alert_tpl_body_lang on ALERT_TEMPLATE_BODY(APP_SID, LANG) tablespace indx;
create index ix_alert_frame_body_lang on ALERT_FRAME_BODY(APP_SID, LANG) tablespace indx;

create global temporary table temp_alert_frame
(
	default_alert_frame_id	number(10),
	alert_frame_id			number(10)
) on commit delete rows;

create table default_alert_frame (
	default_alert_frame_id number(10) not null, 
	name varchar2(1000) not null,
	constraint pk_default_alert_frame primary key (default_alert_frame_id)
	using index tablespace indx
);

create table default_alert_frame_body
(
	default_alert_frame_id number(10) not null,
	lang varchar2(10) not null,
	html clob not null,
	constraint pk_default_alert_frame_body primary key (default_alert_frame_id, lang)
	using index tablespace indx,
	constraint fk_dalrt_frm_bdy_dalrt_frm foreign key (default_alert_frame_id)
	references default_alert_frame (default_alert_frame_id)
);

create table default_alert_template
(
	alert_type_id number(10) not null,
	default_alert_frame_id number(10) not null,
	send_type varchar2(10) not null,
	constraint pk_default_alert_template primary key (alert_type_id)
	using index tablespace indx,
	constraint ck_def_alrt_template_send_type check (send_type in ('manual', 'automatic')),
	constraint fk_def_alrt_tpl_alrt_typ foreign key (alert_type_id)
	references alert_type (alert_type_id),
	constraint fk_def_alrt_tpl_def_alrt_frame foreign key (default_alert_frame_id)
	references default_alert_frame (default_alert_frame_id)
);

create table default_alert_template_body
(
	app_sid	number(10) default sys_context('security','app') not null,
	alert_type_id number(10) not null,
	lang varchar2(10) not null,
	subject clob not null,
	body_html clob not null,
	item_html clob not null,
	constraint pk_default_alert_template_body primary key (alert_type_id, lang)
	using index tablespace indx,
	constraint fk_dalrt_tpl_bdy_dalrt_tpl foreign key (alert_type_id)
	references default_alert_template (alert_type_id)
);

create global temporary table temp_lang
(
	lang varchar2(10)
) on commit delete rows;

create sequence default_alert_frame_id_seq start with 1 increment by 1;

CREATE OR REPLACE VIEW V$ACTIVE_USER AS
	SELECT cu.csr_user_sid, cu.email, cu.region_mount_point_sid, cu.app_sid, cu.full_name,
	  	   cu.user_name, cu.info_xml, cu.send_alerts, cu.guid, cu.friendly_name, 
	  	   ut.language, ut.culture, ut.timezone
	  FROM csr_user cu, security.user_table ut
	 WHERE cu.csr_user_sid = ut.sid_id
	   AND ut.account_enabled = 1;

-- Well, this gave me a headache.
-- What it does is to first figure out what time it is in the user's timezone.  Then we stick with their timezone and:
-- a. Figure out what time they want the batch to run at, i.e. knock the time part off and set it to the batch run time
-- b. Decide when the next time to fire the trigger is. If the trigger time was in the past we add one day (i.e. do it tomorrow).
-- c. Figure out when the previous time to fire the trigger was (i.e. b - 1 day).
-- Then everything gets converted back to GMT.  Most of the columns in the view aren't necessary, but are left there
-- for ease of figuring out what's going on.
--
-- To run a batch using this, the idea is:
-- a. fill alert_batch_run info out for missing users so we know the next trigger fire time for all users
-- b. join $your_query to alert_batch_run and just do those jobs where systimestamp >= next_fire_time_gmt
-- c. after running a batch for a user update their next fire time from query a).  You have to save this and NOT
-- requery!  (The next fire time computed above accounts for DST changes, i.e. clocks going forward one day by 1 hour
-- means that the next fire time will be 23 hours after the previous fire time instead of 24)
-- 
-- This method accounts for missed ticks, e.g. if you set a batch to run at 23:59 we may end up running a bit late, at 00.01
-- the next day.
--
-- Now the annoying bit is if the user changes timezone, the next fire time will be wrong.  To fix that
-- the last fire time should be converted to the new timezone, then the next tick computed based on that (using the
-- if in the past, that time tomorrow; if in the future at that time method as below).  I haven't actually fixed
-- this as I guess alerts going out at the wrong time once isn't a big deal (and I have a headache).
alter table customer add alert_batch_run_time interval day to second default to_dsinterval('0 20:00:00') not null;

create or replace view v$alert_batch_run_time as
	select app_sid, csr_user_sid, alert_batch_run_time, user_tz,
		   user_run_at, user_run_at at time zone 'Etc/GMT' user_run_at_gmt,
		   user_current_time, user_current_time at time zone 'Etc/GMT' user_current_time_gmt,
		   next_fire_time, next_fire_time at time zone 'Etc/GMT' next_fire_time_gmt,
		   next_fire_time - numtodsinterval(1,'DAY') prev_fire_time,
		   (next_fire_time - numtodsinterval(1,'DAY')) at time zone 'Etc/GMT' prev_fire_time_gmt
	  from (select app_sid, csr_user_sid, alert_batch_run_time, user_run_at, user_current_time,
		   		   case when user_run_at < user_current_time then user_run_at + numtodsinterval(1,'DAY') else user_run_at end next_fire_time,
		   		   user_tz
			  from (select app_sid, csr_user_sid, alert_batch_run_time,
						   from_tz(cast(trunc(user_current_time) as timestamp), user_tz) + alert_batch_run_time user_run_at,
						   user_current_time, user_tz
			  		  from (select cu.app_sid, cu.csr_user_sid, alert_batch_run_time,
								   systimestamp at time zone COALESCE(ut.timezone, a.timezone, 'Etc/GMT') user_current_time,
								   COALESCE(ut.timezone, a.timezone, 'Etc/GMT') user_tz
							  from security.user_table ut, security.application a, csr_user cu, customer c
							 where cu.csr_user_sid = ut.sid_id
							   and c.app_sid = cu.app_sid
							   and a.application_sid_id = c.app_sid)));

drop view v$issue_log_alert_batch;

create table ilab_old as 
	select * from issue_log_alert_batch_run;

drop table issue_log_alert_batch_run cascade constraints;
drop table issue_log_alert_batch cascade constraints;

create table alert_batch_run
(
	app_sid number(10) default sys_context('security','app') not null ,
	csr_user_sid number(10) not null,
	alert_type_id number(10) not null,
	prev_fire_time timestamp,
	next_fire_time timestamp not null,
	constraint pk_alert_batch_run primary key (alert_type_id, app_sid, csr_user_sid)
	using index tablespace indx,
	constraint fk_alert_batch_run_csr_user foreign key (app_sid, csr_user_sid)
	references csr_user (app_sid, csr_user_sid),
	constraint fk_alert_batch_run_alert_type foreign key (alert_type_id)
	references alert_type (alert_type_id)
);
create index ix_alert_batch_run_user on alert_batch_run(app_sid, csr_user_sid);

insert into alert_batch_run (app_sid, csr_user_sid, alert_type_id, prev_fire_time, next_fire_time)
	select distinct cu.app_sid, cu.csr_user_sid, 18 alert_type_id, cast(ilab.last_ran_at as timestamp), abr.next_fire_time_gmt
	  from ilab_old ilab, csr_user cu, v$alert_batch_run_time abr
	 where ilab.app_sid = cu.app_sid and cu.app_sid = abr.app_sid and cu.csr_user_sid = abr.csr_user_sid;

drop table ilab_old;

create global temporary table temp_alert_batch_run
(
	alert_type_id	number(10) not null,
	app_sid			number(10) not null,
	csr_user_sid	number(10) not null,
	prev_fire_time	date,
	this_fire_time	date not null
) on commit preserve rows;
create index ix_temp_alert_batch_run on temp_alert_batch_run (alert_type_id, app_sid, csr_user_sid);

alter table alert_template add (reply_to_name varchar(255), reply_to_email varchar2(255));
update alert_template at
   set (reply_to_name, reply_to_email) = (select reply_to_name, reply_to_email
   											from customer_alert_type cat
   										   where at.app_sid = cat.app_sid
   										     and at.alert_type_id = cat.alert_type_id);
alter table customer_alert_type drop column reply_to_name;
alter table customer_alert_type drop column reply_to_email;

-- no RI on alert_image to cms.image so you can can old images, this just breaks
-- image links in old alert mails so isn't the end of the world.
-- we could/should probably do this better as the image code can track dependencies
-- and warn -- avoiding the circular bit during build would probably mean something
-- like adding the RI from the CMS build script (ick).
create table alert_image
(
	app_sid		number(10) default sys_context('security','app') not null,
	pass_key	varchar2(22) not null,
	image_id	number(10) not null,
	constraint pk_alert_image primary key (app_sid, pass_key)
	using index tablespace indx,
	constraint fk_alert_image_customer foreign key (app_sid)
	references customer(app_sid)
);

alter table customer add self_reg_approver_sid number(10);
alter table customer add constraint fk_cust_selfreg_appr_csr_user 
foreign key (app_sid, self_reg_approver_sid) references csr_user (app_sid, csr_user_sid);
create index ix_customer_self_reg_apprv_sid on customer(app_sid, self_reg_approver_sid);

/*
This stuff looks a bit rubbish:

select * from (
select host, alert_mail_Address ,
    (select string_value from security.securable_object_attributes where attribute_id=100297 and sid_id in (select sid_id from security.securable_object where parent_sid_id=customer.app_sid and lower(name)='csr')) ae,
    (select string_value from security.securable_object_attributes where attribute_id=100298 and sid_id in (select sid_id from security.securable_object where parent_sid_id=customer.app_sid and lower(name)='csr')) an
from csr.customer
) where an not in ('Credit360 support team','Credit360 support') or ae != 'support@credit360.com' or alert_mail_address != 'support@credit360.com';

so let's just reset to the default.
*/
alter table customer add alert_mail_name varchar2(255) ;
update customer set alert_mail_name = 'Credit360 support team';
alter table customer modify alert_mail_name not null;

-- drop the old attribute
begin
	user_pkg.logonadmin;
	attribute_pkg.deletedefinition(sys_context('security','act'),class_pkg.getclassid('CSRData'),'admin-email-name');
	attribute_pkg.deletedefinition(sys_context('security','act'),class_pkg.getclassid('CSRData'),'admin-email');
end;
/

BEGIN
-- Notify user	
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);

-- New delegation
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'DELEGATOR_FULL_NAME', 'Delegator full name', 'The full name of the user who made the delegation', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'DELEGATOR_EMAIL', 'Delegator e-mail', 'The e-mail address of the user who made the delegation', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'DELEG_ASSIGNED_TO', 'Assigned to', 'The name of the user the delegation is assigned to', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);

-- Delegation data overdue	
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 1, 'DELEG_ASSIGNED_TO', 'Assigned to', 'The name of the user the delegation is assigned to', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 9);
/*XXX: add? INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'DELEGATOR_FULL_NAME', 'Delegator full name', 'The full name of the user who made the delegation', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'DELEGATOR_EMAIL', 'Delegator e-mail', 'The e-mail address of the user who made the delegation', 11);*/

-- Delegation state changed
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 10);

-- Delegation data reminder
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 1, 'DELEG_ASSIGNED_TO', 'Assigned to', 'The name of the user the delegation is assigned to', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 1, 'DESCRIPTION', 'Description', 'A description of the change', 10);

-- Delegation terminated	
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 1, 'TERMINATED_BY_FULL_NAME', 'Sheet link', 'A hyperlink to the sheet', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 1, 'DELEGATOR_FULL_NAME', 'Assigned to', 'The name of the user the delegation is assigned to', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 1, 'DELEGATOR_EMAIL', 'Assigned to', 'The name of the user the delegation is assigned to', 8);

-- Mail sent when new approval step form created
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'LABEL', 'Label', 'The name of the new approval step', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);

-- Mail sent thanking user for submission of data	
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'TO_NAMES', 'To names', 'The names of the users thanking you', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'LABEL', 'Label', 'The name of approval step', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 11);

-- Mail sent to user when their data is rejected
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'LABEL', 'Label', 'The name of the new approval step', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'DUE_DTM', 'Due date', 'The date the data is due', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 11);

-- Mail sent to subdelegee when sub-delegation takes place	
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 1, 'LABEL', 'Label', 'The name of the new approval step', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 1, 'DELEGATOR_FULL_NAME', 'Delegator full name', 'The full name of the user who made the delegation', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 11);

-- Mail sent thanking user for submitting to approval step owner
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'LABEL', 'Label', 'The name of the approval step', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'TO_NAMES', 'To names', 'The names of the users thanking you', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 11);

-- Mail sent when approval step owner rejects
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'LABEL', 'Label', 'The name of the new approval step', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'DUE_DTM', 'Due date', 'The date the data is due', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 11);

-- Mail sent to approver when a new submission is made	
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'TO_USER_NAME', 'User name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'TO_EMAIL', 'E-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'LABEL', 'Label', 'The name of the approval step', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'SHEET_LABEL', 'Sheet label', 'The name of the sheet', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 11);

-- Mail sent to data provider when final approval occurs	
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'TO_USER_NAME', 'User name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'TO_EMAIL', 'E-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'LABEL', 'Label', 'The name of the new approval step', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);

-- Mail sent when a comment is made on an issue
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17, 0, 'COMMENT', 'Comment', 'The comment', 9);

-- Mail sent containing issue summaries
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'SHEET_LABEL', 'Sheet label', 'The name of the sheet that the issue relates to', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'SHEET_URL', 'Sheet url', 'A link to the sheet that the issue relates to', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'ISSUE_DETAIL', 'Issue details', 'The issue details', 11);

-- Mail sent when a document in the document library is updated
-- (Not actually used anywhere)
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'CHANGED_DTM', 'Changed date', 'The date the change was made', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'CHANGED_BY', 'Changed by', 'The user who made the change', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'VERSION', 'Version', 'The version of the document that was created', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'FILE_NAME', 'Document name', 'The name of the document', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'CHANGE_DESCRIPTION', 'Change description', 'A description of the change that was made', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'DOC_LINK', 'Document link', 'A hyperlink to the document', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'DOC_FOLDER_LINK', 'Folder link', 'A hyperlink to the folder in the document library containing the document', 11);

-- Generic mailout
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);

-- Self register validate e-mail address	
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (21, 0, 'TO_NAME', 'User name', 'The user name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (21, 0, 'TO_EMAIL', 'E-mail', 'The e-mail address of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (21, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (21, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (21, 0, 'URL', 'Validate link', 'The validation link', 5);

-- Self register notify administrator	
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'USER_NAME', 'User name', 'The requested user name', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'USER_FULL_NAME', 'User full name', 'The requested full name', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'USER_EMAIL', 'User e-mail', 'The e-mail address of the requesting user', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'URL', 'Validate link', 'The validation link', 7);

-- Self register account approval
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (23, 0, 'TO_NAME', 'User name', 'The user name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (23, 0, 'TO_EMAIL', 'E-mail', 'The e-mail address of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (23, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (23, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (23, 0, 'URL', 'Login link', 'Link to the site to login with', 5);

-- Self register account rejection
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (24, 0, 'TO_NAME', 'User name', 'The user name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (24, 0, 'TO_EMAIL', 'E-mail', 'The e-mail address of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (24, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (24, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 4);

-- Password reset	
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (25, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (25, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (25, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (25, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (25, 0, 'URL', 'Reset link', 'The password reset link', 5);

-- Account disabled (password reset)
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (26, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (26, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (26, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (26, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (26, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (26, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);

-- Supplier user assigned to product
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1000, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1000, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1000, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1000, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1000, 0, 'PRODUCT_DESC', 'Product description', 'A description of the product', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1000, 0, 'PRODUCT_CODE', 'Product code', 'The product code', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1000, 0, 'PRODUCT_ASSIGNMENT_DATA', 'Product assignment data', 'Assignment data for the product', 7);

-- Supplier product activation state changed	
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1001, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1001, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1001, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1001, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1001, 0, 'PRODUCT_DESC', 'Product description', 'A description of the product', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1001, 0, 'PRODUCT_CODE', 'Product code', 'The product code', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1001, 0, 'PRODUCT_ASSIGNMENT_DATA', 'Product assignment data', 'Assignment data for the product', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1001, 0, 'ACTIVATION_TYPE', 'Activation type', 'The type of activation that occurred', 8);

-- Supplier product approval status changed
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1002, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1002, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1002, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1002, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1002, 0, 'PRODUCT_DESC', 'Product description', 'A description of the product', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1002, 0, 'PRODUCT_CODE', 'Product code', 'The product code', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1002, 0, 'GROUP_STATUS', 'Group status', 'The group status', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1002, 0, 'COMMENT', 'Comment', 'The comment', 8);

-- Supplier work reminder
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1003, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1003, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1003, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1003, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1003, 0, 'PROVIDING_LIST', 'Providing list', 'Providign list', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1003, 0, 'PROVIDING_N', 'Providing N', 'Providing N', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1003, 0, 'PROVIDING_CR_N', 'Providing CR N', 'Providing CR N', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1003, 0, 'APPROVING_LIST', 'Approving list', 'Approving list', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1003, 0, 'APPROVING_N', 'Approving N', 'Approving N', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1003, 0, 'APPROVING_CR_N', 'Approving CR N', 'Approving CR N', 10);

-- Initiative submitted alert
for r in (select 1 from alert_type where alert_type_id = 2000) loop
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'COORDINATOR_FULL_NAME', 'Co-ordinator full name', 'The full name of the co-ordinator', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'COORDINATOR_FRIENDLY_NAME', 'Co-ordinator friendly name', 'The friendly name of the co-ordinator', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'COORDINATOR_USER_NAME', 'Co-ordinator user name', 'The user name of the co-ordinator', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'COORDINATOR_EMAIL', 'Co-ordinator e-mail', 'The e-mail address of the co-ordintor', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'NAME', 'Name', 'The initiative name', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'REFERENCE', 'Reference', 'The initiative reference', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'DESCRIPTION', 'Description', 'The initiative description', 11);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'START_DTM', 'Start date', 'The initiative start date', 12);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'END_DTM', 'End date', 'The initiative end date', 13);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'VIEW_URL', 'View link', 'A link to the initiative', 14);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2000, 0, 'PROPERTY', 'Property', 'The property the initiative relates to', 15);
end loop;

-- Initiative approved alert
for r in (select 1 from alert_type where alert_type_id = 2001) loop
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'COORDINATOR_FULL_NAME', 'Co-ordinator full name', 'The full name of the co-ordinator', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'COORDINATOR_FRIENDLY_NAME', 'Co-ordinator friendly name', 'The friendly name of the co-ordinator', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'COORDINATOR_USER_NAME', 'Co-ordinator user name', 'The user name of the co-ordinator', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'COORDINATOR_EMAIL', 'Co-ordinator e-mail', 'The e-mail address of the co-ordintor', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'NAME', 'Name', 'The initiative name', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'REFERENCE', 'Reference', 'The initiative reference', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'DESCRIPTION', 'Description', 'The initiative description', 11);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'START_DTM', 'Start date', 'The initiative start date', 12);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'END_DTM', 'End date', 'The initiative end date', 13);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'VIEW_URL', 'View link', 'A link to the initiative', 14);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'PROPERTY', 'Property', 'The property the initiative relates to', 15);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2001, 0, 'COMMENT', 'Comment', 'A comment made by the approver', 16);
end loop;

-- Initiative rejected alert
for r in (select 1 from alert_type where alert_type_id = 2002) loop
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'COORDINATOR_FULL_NAME', 'Co-ordinator full name', 'The full name of the co-ordinator', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'COORDINATOR_FRIENDLY_NAME', 'Co-ordinator friendly name', 'The friendly name of the co-ordinator', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'COORDINATOR_USER_NAME', 'Co-ordinator user name', 'The user name of the co-ordinator', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'COORDINATOR_EMAIL', 'Co-ordinator e-mail', 'The e-mail address of the co-ordintor', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'NAME', 'Name', 'The initiative name', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'REFERENCE', 'Reference', 'The initiative reference', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'DESCRIPTION', 'Description', 'The initiative description', 11);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'START_DTM', 'Start date', 'The initiative start date', 12);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'END_DTM', 'End date', 'The initiative end date', 13);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'VIEW_URL', 'View link', 'A link to the initiative', 14);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'PROPERTY', 'Property', 'The property the initiative relates to', 15);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2002, 0, 'COMMENT', 'Comment', 'A comment made by the approver', 16);
end loop;

-- Initiative reminder alert
for r in (select 1 from alert_type where alert_type_id = 2003) loop
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'SUBMITTED_BY_FULL_NAME', 'Submitted by full name', 'The full name of the submitting user', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'SUBMITTED_BY_FRIENDLY_NAME', 'Submitted by friendly name', 'The friendly name of the submitting user', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'SUBMITTED_BY_USER_NAME', 'Submitted user name', 'The user name of the submitting user', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'SUBMITTED_BY_EMAIL', 'Submitted e-Mmail', 'The e-mail address of the submitting user', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'COORDINATOR_FULL_NAME', 'Co-ordinator full name', 'The full name of the co-ordinator', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'COORDINATOR_FRIENDLY_NAME', 'Co-ordinator friendly name', 'The friendly name of the co-ordinator', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'COORDINATOR_USER_NAME', 'Co-ordinator user name', 'The user name of the co-ordinator', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'COORDINATOR_EMAIL', 'Co-ordinator e-mail', 'The e-mail address of the co-ordintor', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'NAME', 'Name', 'The initiative name', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'REFERENCE', 'Reference', 'The initiative reference', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'DESCRIPTION', 'Description', 'The initiative description', 11);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'START_DTM', 'Start date', 'The initiative start date', 12);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'END_DTM', 'End date', 'The initiative end date', 13);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'VIEW_URL', 'View link', 'A link to the initiative', 14);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2003, 0, 'PROPERTY', 'Property', 'The property the initiative relates to', 15);
end loop;

-- Initiative Property Manager Alert
for r in (select 1 from alert_type where alert_type_id = 2004) loop
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2004, 0, 'REGION_DESC', 'Region description', 'The region description', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2004, 0, 'INITIATIVE_LIST', 'Initiative list', 'The initiative list', 2);
end loop;

-- Ethics course question distribution
for r in (select 1 from alert_type where alert_type_id = 3000) loop
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3000, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3000, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3000, 0, 'SUBJECT', 'Subject', 'The subject', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3000, 0, 'COURSE_NAME', 'Course name', 'The course name', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3000, 0, 'QUESTION_DESCRIPTION', 'Question description', 'The question description', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3000, 0, 'QUESTION_TEXT', 'Question text', 'The question text', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3000, 0, 'VOTE_CLOSE_DATE', 'Vote close date', 'The vote close date', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3000, 0, 'LINK', 'Link', 'A link to the question', 8);
end loop;

-- Ethics course question followup
for r in (select 1 from alert_type where alert_type_id = 3001) loop
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3001, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3001, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3001, 0, 'SUBJECT', 'Subject', 'The subject', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3001, 0, 'COURSE_NAME', 'Course name', 'The course name', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3001, 0, 'QUESTION_DESCRIPTION', 'Question description', 'The question description', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3001, 0, 'QUESTION_TEXT', 'Question text', 'The question text', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3001, 0, 'ANALYSIS_TEXT', 'Analysis text', 'The analysis text', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3001, 0, 'VOTE_CLOSE_DATE', 'Vote close date', 'The vote close date', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3001, 0, 'LINK', 'Link', 'A link to the question', 9);
end loop;

-- Chain invitation
for r in (select 1 from alert_type where alert_type_id = 5000) loop
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 0, 'TO_COMPANY_NAME', 'To company', 'The company of the user the alert is being sent to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 0, 'FROM_JOB_TITLE', 'From job title', 'The job title of the user the alert is being sent from', 8);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 0, 'FROM_COMPANY_NAME', 'From company', 'The company of the user the alert is being sent from', 9);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 1, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 10);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 1, 'QUESTIONNAIRE_DESCRIPTION', 'Questionnaire description', 'The questionnaire description', 11);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 0, 'PERSONAL_MESSAGE', 'Personal message', 'A personal message from the sending user', 12);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 0, 'LINK', 'Link', 'A hyperlink to the invitation acceptance page', 13);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5000, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 14);
end loop;

-- Stub invitation
for r in (select 1 from alert_type where alert_type_id = 5002) loop
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5002, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5002, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5002, 0, 'LINK', 'Link', 'A hyperlink to the invitationi acceptance page', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5002, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5002, 0, 'SITE_NAME', 'Site name', 'The site name', 5);
end loop;

-- Scheduled alert
for r in (select 1 from alert_type where alert_type_id = 5003) loop
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5003, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5003, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5003, 0, 'SITE_NAME', 'Site name', 'The site name', 3);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5003, 0, 'COMPANY_NAME', 'Company name', 'The company name that the alert is related to', 4);
INSERT INTO alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5003, 0, 'ENTRIES', 'Entries', 'The scheduled alert entries', 5);
end loop;

END;
/

-- turn the tracker off
alter table customer modify use_tracker default 0 ;
update customer set use_tracker = 0;

-- there's a typo in this bit of text
update alert_type set description='Self register validate e-mail address' where alert_type_id=21;

-- this one is being renamed
update alert_type set description='Welcome message' where alert_type_id=1;

-- remove chain's custom reset password mail - we can use the standard one
DELETE FROM CUSTOMER_ALERT_TYPE WHERE ALERT_TYPE_ID = 5001;
DELETE FROM ALERT_TYPE WHERE ALERT_TYPE_ID = 5001;
delete from old_alert_template where alert_type_id = 5001;

-- XXX: this ought to just be done by anonymous mail folders, not real mail addresses

------------------------------
-- DT NOTE:
-- urgh -- remove this for DT
-- and also the NOT IN (random hosts) below
-------------------------------
/*
select a.email_address,m.mailbox_name from mail.mailbox m, mail.account a
  where a.email_address != m.mailbox_name
    and m.mailbox_sid = a.root_mailbox_sid;
*/
begin
	update mail.mailbox
	   set mailbox_name = 'produceworld_tracker@credit360.com'
	 where mailbox_name = 'produceworld-tracker@credit360.com';
	update security.securable_object
	   set name = 'produceworld_tracker@credit360.com'
	 where sid_id = (select mailbox_sid from mail.mailbox where mailbox_name='produceworld_tracker@credit360.com');  
	update mail.mailbox
	   set mailbox_name = 'linde_tracker@credit360.com'
	 where mailbox_name = 'linde-tracker@credit360.com';
	update security.securable_object
	   set name = 'linde_tracker@credit360.com'
	 where sid_id = (select mailbox_sid from mail.mailbox where mailbox_name='linde_tracker@credit360.com');  
	update mail.mailbox
	   set mailbox_name = 'climatesmart-support@credit360.com'
	 where mailbox_name = 'climatesmart-support';
	update security.securable_object
	   set name = 'climatesmart-support@credit360.com'
	 where sid_id = (select mailbox_sid from mail.mailbox where mailbox_name='climatesmart-support@credit360.com');
	update mail.mailbox
	   set mailbox_name = 'itv_tracker@credit360.com'
	 where mailbox_name = 'itv-tracker@credit360.com';
	update security.securable_object
	   set name = 'itv_tracker@credit360.com'
	 where sid_id = (select mailbox_sid from mail.mailbox where mailbox_name='itv_tracker@credit360.com');  
end;
/

-- more renaming mailbox horror
declare
	v_root_mailbox_sid 		number;
	v_account_sid			number;
	v_mailbox_sid			number;
	v_mailbox_name			varchar2(255);
begin
	dbms_output.enable(null);
	user_pkg.LogonAdmin;
	for r in (select * from mail.account where email_address not in ('kyle@credit360.com','richard@credit360.com','richard.kirby@credit360.com','alistair.blackmore@credit360.com')) loop
		begin
			select mailbox_name
			  into v_mailbox_name
			  from mail.mailbox
			 where mailbox_sid = r.root_mailbox_sid;
			if v_mailbox_name != r.email_address then
				dbms_output.put_line(r.email_address || ' has an incorrectly named root folder ' || v_mailbox_name);
				update mail.mailbox
				   set mailbox_name = r.email_address
				 where mailbox_sid = r.root_mailbox_sid;
			end if;
		exception
			when no_data_found then
				dbms_output.put_line(r.email_address || ' has no root mailbox folder');
		end;
	end loop;
	for r in (select m.mailbox_sid, m.mailbox_name, so.name from mail.mailbox m, security.securable_object so where m.mailbox_sid = so.sid_id and m.mailbox_name != nvl(so.name,'!3$!"L£P$!"P')) loop
		dbms_output.put_line('the mailbox ' ||r.mailbox_sid||' named '||r.mailbox_name||' has mismatched so name '||r.name);
		update security.securable_object
		   set name = r.mailbox_name
		 where sid_id = r.mailbox_sid;
	end loop;
	for r in (select a.account_sid, a.email_address, so.name from mail.account a, security.securable_object so where a.account_sid = so.sid_id and a.email_address != nvl(so.name,'!3$!"L£P$!"P')) loop
		dbms_output.put_line('the account ' ||r.account_sid||' named '||r.email_address||' has mismatched so name '||r.name);
		update security.securable_object
		   set name = r.email_address
		 where sid_id = r.account_sid;
	end loop;
	-- delete accounts / mailboxes with no SOs
	for r in (select account_sid, email_address from mail.account where account_sid not in (select sid_id from security.securable_object)) loop
		dbms_output.put_line('the account ' ||r.account_sid||' named '||r.email_address||' has no backing sos, deleting');
		mail.mail_pkg.deleteAccount(r.account_sid);
	end loop;
	for r in (select mailbox_sid, mailbox_name from mail.mailbox where mailbox_sid not in (select sid_id from security.securable_object)) loop
		dbms_output.put_line('the mailbox ' ||r.mailbox_sid||' named '||r.mailbox_name||' has no backing sos, deleting');
		DELETE
		  FROM mail.message_address_field
		 WHERE mailbox_sid IN (SELECT mailbox_sid
		 						 FROM mail.mailbox
		 						 	  START WITH mailbox_sid = r.mailbox_sid
		 						 	  CONNECT BY PRIOR mailbox_sid = parent_sid);
		 						 	  
		DELETE
		  FROM mail.message_address_field
		 WHERE mailbox_sid IN (SELECT mailbox_sid
		 						 FROM mail.mailbox
		 						 	  START WITH mailbox_sid = r.mailbox_sid
		 						 	  CONNECT BY PRIOR mailbox_sid = parent_sid);
	
		DELETE
		  FROM mail.message_header
		 WHERE mailbox_sid IN (SELECT mailbox_sid
		 						 FROM mail.mailbox
		 						 	  START WITH mailbox_sid = r.mailbox_sid
		 						 	  CONNECT BY PRIOR mailbox_sid = parent_sid);
		DELETE
		  FROM mail.message
		 WHERE mailbox_sid IN (SELECT mailbox_sid
		 						 FROM mail.mailbox
		 						 	  START WITH mailbox_sid = r.mailbox_sid
		 						 	  CONNECT BY PRIOR mailbox_sid = parent_sid);
	
		delete from mail.fulltext_index where mailbox_sid = r.mailbox_sid;
	end loop;
	-- and now the other way around -- delete mailboxes / accounts with SOs but no matching mail objects
	for r in (
		select t.sid_id, max(t.lvl)
		  from (select sid_id,level lvl
	  	  		  from security.securable_object so start with parent_sid_id is null connect by prior sid_id = parent_sid_id) t,
	  	  	   ( (select sid_id from security.securable_object start with parent_sid_id = securableobject_pkg.getsidfrompath(null,0,'/Mail/Accounts') connect by prior sid_id = parent_sid_id
				   minus
				  select account_sid from mail.account)
				 union all 
				 (select sid_id from security.securable_object start with parent_sid_id = securableobject_pkg.getsidfrompath(null,0,'/Mail/Folders') connect by prior sid_id = parent_sid_id
				   minus
				  select mailbox_sid from mail.mailbox)) d
		 where t.sid_id = d.sid_id
		group by t.sid_id
		order by max(t.lvl) desc
	) loop
		dbms_output.put_line('the object with sid '||r.sid_id||' and path '||securableobject_pkg.getpathfromsid(null,r.sid_id)||' has no matching mailbox/account SO, deleting');
		DELETE security.acl
		 WHERE acl_id = Acl_Pkg.GetDACLIDForSID(r.sid_id)
 		    OR sid_id = r.sid_id;
	
	    -- this securable object may be a user, or a group.  If so delete the necessary records
	    DELETE security.user_table
	     WHERE sid_id = r.sid_id;
	     
	    DELETE security.user_password_history
	     WHERE sid_id = r.sid_id;
	
	    DELETE security.user_certificates
	     WHERE sid_id = r.sid_id;
	     	
	    DELETE security.securable_object
	     WHERE sid_id = r.sid_id;
		
	end loop;
end;
/

declare
	v_root_mailbox_sid 		number;
	v_tracker_mailbox_sid	number;
	v_sent_mailbox_sid		number;
	v_users_mailbox_sid		number;
	v_user_mailbox_sid		number;
	v_outbox_mailbox_sid	number;
	v_admins_sid			number;
	v_reg_users_sid			number;
	v_acl_count				number;
	v_email					customer.system_mail_address%TYPE;
	v_tracker_email			customer.tracker_mail_address%TYPE;
	v_account_sid			NUMBER(10);
	v_outbox_sid			NUMBER(10);
	v_user_so_exists		number;
begin
	dbms_output.enable(null);
	user_pkg.LogonAdmin;
	for r in (select system_mail_address, tracker_mail_address, host, app_sid
				from customer 
			   where host not in ('kyle.credit360.com','richard.credit360.com','alistair.credit360.com')) loop
		security_pkg.SetApp(r.app_sid);

		dbms_output.put_line('doing '||r.host);
		v_reg_users_sid := securableObject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/RegisteredUsers');
		
		begin
			v_admins_sid := securableObject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/Administrators');
		exception
			when security_pkg.object_not_found then
				v_admins_sid := null;
		end;
					
		-- create system mail account and add an Outbox (foo.credit360.com -> foo@credit360.com)
		-- .credit360.com = 14 chars
		IF LOWER(SUBSTR(r.host, LENGTH(r.host)-13,14)) = '.credit360.com' THEN
			-- a standard foo.credit360.com
			v_email := SUBSTR(r.host, 1, LENGTH(r.host)-14)||'@credit360.com';
			v_tracker_email := SUBSTR(r.host, 1, LENGTH(r.host)-14)||'_tracker@credit360.com';
		ELSE
			-- not a standard foo.credit360.com, so... www.foo.com@credit360.com
			v_email := r.host||'@credit360.com';
			v_tracker_email := r.host||'_tracker@credit360.com';
		END IF;
		
		-- if the address is wrong, then just create a new one
		-- this stuff all comes from renaming sites or importing not doing the right thing (it's a mix of renames + imports to test sites)
		begin
			mail.mail_pkg.createAccount(v_email, NULL, 'System mail account for '||r.host, v_account_sid, v_root_mailbox_sid);
		exception
			when security_pkg.DUPLICATE_OBJECT_NAME then
				v_root_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(null, v_email);
		end;
		IF v_email != r.system_mail_address THEN
			dbms_output.put_line('created '||v_email||' (was '||r.system_mail_address||')');
		end if;

		-- if they exist, give administrators full control over the mailboxes
		if v_admins_sid is not null	then
			select count(*)
			  into v_acl_count
			  from security.acl 
			 where acl_id = acl_pkg.GetDACLIDForSID(v_root_mailbox_sid)
			   and ace_type = security_pkg.ACE_TYPE_ALLOW and sid_id = v_admins_sid and permission_set = security_pkg.PERMISSION_STANDARD_ALL;
			if v_acl_count = 0 then
				acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_root_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
					security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security_pkg.PERMISSION_STANDARD_ALL);
				acl_pkg.PropogateAces(SYS_CONTEXT('SECURITY', 'ACT'), v_root_mailbox_sid);
			end if;
		end if;

		begin	
			mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Sent', v_sent_mailbox_sid);
		exception
			when security_pkg.DUPLICATE_OBJECT_NAME then
				v_sent_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(v_root_mailbox_sid, 'Sent');		
		end;
		select count(*)
		  into v_acl_count
		  from security.acl 
		 where acl_id = acl_pkg.GetDACLIDForSID(v_sent_mailbox_sid)
		   and ace_type = security_pkg.ACE_TYPE_ALLOW and sid_id = v_reg_users_sid and permission_set = security_pkg.PERMISSION_ADD_CONTENTS;
		if v_acl_count = 0 then
			acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_sent_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security_pkg.PERMISSION_ADD_CONTENTS);
		end if;
		
		begin
			mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Outbox', v_outbox_mailbox_sid);
		exception
			when security_pkg.DUPLICATE_OBJECT_NAME then
				v_outbox_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(v_root_mailbox_sid, 'Outbox');
		end;
		
		select count(*)
		  into v_acl_count
		  from security.acl 
		 where acl_id = acl_pkg.GetDACLIDForSID(v_outbox_mailbox_sid)
		   and ace_type = security_pkg.ACE_TYPE_ALLOW and sid_id = v_reg_users_sid and permission_set = security_pkg.PERMISSION_ADD_CONTENTS;
		if v_acl_count = 0 then
			acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_outbox_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security_pkg.PERMISSION_ADD_CONTENTS);
		end if;
		
		begin
			mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Users', v_users_mailbox_sid);
		exception
			when security_pkg.DUPLICATE_OBJECT_NAME then
				v_users_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(v_root_mailbox_sid, 'Users');
		end;

		for u in (select csr_user_sid, user_name
					from csr_user) loop
--			dbms_output.put_line('adding mailbox for '||u.user_name||' ('||u.csr_user_sid||')');
			begin
				mail.mail_pkg.createMailbox(v_users_mailbox_sid, u.csr_user_sid, v_user_mailbox_sid);
			exception
				when security_pkg.DUPLICATE_OBJECT_NAME then
					v_user_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(v_users_mailbox_sid, u.csr_user_sid);
			end;
			select count(*) into v_user_so_exists from security.securable_object where sid_id = u.csr_user_sid;
			if v_user_so_exists <> 0 then
				select count(*)
				  into v_acl_count
				  from security.acl 
				 where acl_id = acl_pkg.GetDACLIDForSID(v_user_mailbox_sid)
				   and ace_type = security_pkg.ACE_TYPE_ALLOW and sid_id = v_reg_users_sid and permission_set = security_pkg.PERMISSION_ADD_CONTENTS;
				if v_acl_count = 0 then
					acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
						security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security_pkg.PERMISSION_ADD_CONTENTS);
				end if;
				select count(*)
				  into v_acl_count
				  from security.acl 
				 where acl_id = acl_pkg.GetDACLIDForSID(v_user_mailbox_sid)
				   and ace_type = security_pkg.ACE_TYPE_ALLOW and sid_id = u.csr_user_sid and permission_set = security_pkg.PERMISSION_STANDARD_ALL;
				if v_acl_count = 0 then
					acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
						security_pkg.ACE_FLAG_DEFAULT, u.csr_user_sid, security_pkg.PERMISSION_STANDARD_ALL);
				end if;
			end if;
		end loop;
		
		begin
			mail.mail_pkg.createAccount(v_tracker_email, NULL, 'Tracker mail account for '||r.host, v_account_sid, v_tracker_mailbox_sid);
			dbms_output.put_line('created '||v_tracker_email||' (was '||r.tracker_mail_address||')');
		exception
			when security_pkg.DUPLICATE_OBJECT_NAME then
				v_tracker_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(null, v_tracker_email);
		end;

		-- if they exist, give administrators full control over the mailboxes
		if v_admins_sid is not null	then
			select count(*)
			  into v_acl_count
			  from security.acl 
			 where acl_id = acl_pkg.GetDACLIDForSID(v_tracker_mailbox_sid)
			   and ace_type = security_pkg.ACE_TYPE_ALLOW and sid_id = v_admins_sid and permission_set = security_pkg.PERMISSION_STANDARD_ALL;
			if v_acl_count = 0 then
				acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_tracker_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
					security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security_pkg.PERMISSION_STANDARD_ALL);
				acl_pkg.PropogateAces(SYS_CONTEXT('SECURITY', 'ACT'), v_root_mailbox_sid);
			end if;
		end if;
		
		UPDATE customer
		   SET tracker_mail_address = v_tracker_email, system_mail_address = v_email
		 WHERE app_sid = r.app_sid;
	end loop;
end;
/

-- UserCreatorDaemon needs to be able to add mailboxes
declare
	v_user_creator_sid		number;
	v_root_mailbox_sid 		number;
	v_users_mailbox_sid		number;
	v_reg_users_sid			number;
	v_acl_count				number;
begin
	dbms_output.enable(null);
	user_pkg.LogonAdmin;
	for r in (select host, app_sid, system_mail_address
				from customer
			   where host not in ('kyle.credit360.com','richard.credit360.com','alistair.credit360.com')) loop
		security_pkg.SetApp(r.app_sid);

		dbms_output.put_line('doing '||r.host);
		begin
			v_reg_users_sid := securableObject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/RegisteredUsers');
			v_user_creator_sid := securableObject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Users/UserCreatorDaemon');
			v_root_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(null, r.system_mail_address);
			v_users_mailbox_sid := mail.mail_pkg.GetMailboxSIDFromPath(v_root_mailbox_sid, 'Users');
	
			select count(*)
			  into v_acl_count
			  from security.acl 
			 where acl_id = acl_pkg.GetDACLIDForSID(v_users_mailbox_sid)
			   and ace_type = security_pkg.ACE_TYPE_ALLOW and sid_id = v_user_creator_sid and permission_set = security_pkg.PERMISSION_ADD_CONTENTS;
			if v_acl_count = 0 then
				acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_users_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
					0, v_user_creator_sid, security_pkg.PERMISSION_ADD_CONTENTS);
			end if;

			-- the user creator daemon needs to be a member of registered users to send mails to them
			security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_creator_sid, v_reg_users_sid);
		exception
			when security_pkg.object_not_found then
				dbms_output.put_line('No user creator daemon');
		end;
	end loop;
end;
/

-- RegisteredUsers need read permission on /fp/yam and /fp/cms
declare
	v_reg_users_sid			number;
	v_wwwroot_sid			number;
	v_fp_sid				number;
	v_yam_sid				number;
	v_cms_sid				number;
	v_acl_count				number;
begin
	dbms_output.enable(null);
	user_pkg.LogonAdmin;
	for r in (select host, app_sid, system_mail_address
				from customer
			   where host not in ('kyle.credit360.com','richard.credit360.com','alistair.credit360.com')) loop
		security_pkg.SetApp(r.app_sid);

		dbms_output.put_line('doing '||r.host);
		begin
			v_reg_users_sid := securableObject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Groups/RegisteredUsers');
			v_wwwroot_sid := securableObject_pkg.getsidfrompath(null, r.app_sid, 'wwwroot');
			v_fp_sid := securableObject_pkg.getsidfrompath(null, v_wwwroot_sid, 'fp');
			
			begin
				v_yam_sid := securableObject_pkg.getsidfrompath(null, v_fp_sid, 'yam');
			exception
				when security_pkg.object_not_found then
					web_pkg.createResource(sys_context('security', 'act'), v_wwwroot_sid, v_fp_sid, 'yam', v_yam_sid);
			end;
	
			select count(*)
			  into v_acl_count
			  from security.acl 
			 where acl_id = acl_pkg.GetDACLIDForSID(v_yam_sid)
			   and ace_type = security_pkg.ACE_TYPE_ALLOW and sid_id = v_reg_users_sid and permission_set = security_pkg.PERMISSION_STANDARD_READ;
			if v_acl_count = 0 then
				acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_yam_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
					security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);
			end if;

			begin
				v_cms_sid := securableObject_pkg.getsidfrompath(null, v_fp_sid, 'cms');
			exception
				when security_pkg.object_not_found then
					web_pkg.createResource(sys_context('security', 'act'), v_wwwroot_sid, v_fp_sid, 'cms', v_cms_sid);
			end;

			select count(*)
			  into v_acl_count
			  from security.acl 
			 where acl_id = acl_pkg.GetDACLIDForSID(v_cms_sid)
			   and ace_type = security_pkg.ACE_TYPE_ALLOW and sid_id = v_reg_users_sid and permission_set = security_pkg.PERMISSION_STANDARD_READ;
			if v_acl_count = 0 then
				acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_cms_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
					security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);
			end if;
		exception
			when security_pkg.object_not_found then
				dbms_output.put_line('No registered users group');
		end;
	end loop;
end;
/

-- menu changes
declare
	v_setup_sid security_pkg.t_sid_id;
	v_setup_pos number;
	v_setup_parent_sid security_pkg.t_sid_id;
	v_frames_sid security_pkg.t_sid_id;
	v_missing boolean;
	v_messages_cnt number;
begin
	user_pkg.logonadmin;
	update security.menu
	   set action = '/csr/site/mail/mailbox.acds?mailbox=Inbox'
	 where lower(action) = '/csr/site/mail/Mailbox.acds';
	for r in (select host,app_sid from customer) loop
		security_pkg.setApp(r.app_sid);

		dbms_output.put_line('Processing '||r.host||' ('||r.app_sid||')');
		v_missing := true;
		for s in (select sid_id
					from security.securable_object 
					where name='csr_alerts_setup'
					start with sid_id=securableobject_pkg.getsidfrompath(sys_context('security','act'),sys_context('security','app'),'Menu') 
					connect by prior sid_id=parent_sid_id) loop
			securableObject_pkg.renameSO(sys_context('security','act'),s.sid_id,'csr_alerts_template');							
			update security.menu
			   set action='/csr/site/alerts/template.acds'
			 where sid_id = s.sid_id;
			select m.sid_id, so.parent_sid_id, m.pos
			  into v_setup_sid, v_setup_parent_sid, v_setup_pos
			  from security.menu m, security.securable_object so
			 where m.sid_id = s.sid_id and m.sid_id = so.sid_id;
			v_missing := false;
		end loop;

		if not v_missing then
			update security.menu
			   set pos = pos + 1
			 where sid_id in (select sid_id from security.securable_object where parent_sid_id = v_setup_parent_sid)
			   and pos >= v_setup_pos;
			   
			security.menu_pkg.createMenu(sys_context('security','act'),
					v_setup_parent_sid, 'csr_alerts_frame', 'E-mail templates', '/csr/site/alerts/frame.acds', v_setup_pos, null, v_frames_sid);
	
			v_messages_cnt := 0;
			for s in (
					select so.sid_id, so.parent_sid_id, m.pos
					  from security.menu m, security.securable_object so
					 where m.sid_id = so.sid_id
					   and so.name='csr_alerts_messages'
					   and so.sid_id in (select sid_id from security.securable_object start with sid_id=securableobject_pkg.getsidfrompath(sys_context('security','act'),r.app_sid,'Menu') connect by prior sid_id=parent_sid_id)) loop
				update security.menu
				   set pos = pos + 1
				 where sid_id in (select sid_id from security.securable_object where parent_sid_id = s.parent_sid_id)
				   and pos > s.pos;
				security.menu_pkg.createMenu(sys_context('security','act'),
						s.parent_sid_id, 'csr_alerts_sent', 'Sent alerts', '/csr/site/mail/mailbox.acds?mailbox=Sent', s.pos+1, null, v_frames_sid);
				v_messages_cnt := v_messages_cnt + 1;
			end loop;
			if v_messages_cnt > 1 then
				dbms_output.put_line('**** Duplicate csr_alerts_messages menu for '||r.host||' ('||r.app_sid||')');
			end if;
			dbms_output.put_line('Added menu items for '||r.host||' ('||r.app_sid||')');
		else
			dbms_output.put_line('**** No csr_alerts_setup menu for '||r.host||' ('||r.app_sid||')');
		end if;
	end loop;
end;
/

INSERT INTO PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'My messages', 'Credit360.Portlets.MyMessages', '/csr/site/portal/Portlets/MyMessages.js');

-- Can the old job that raised reminder alerts as we now run this when needed
exec dbms_scheduler.drop_job( job_name => 'csr.RaiseReminders' );

create global temporary table temp_approval_step_sheet
(
	approval_step_id	number(10),
	sheet_key			varchar2(255)
) on commit delete rows;

grant insert, select, update, delete on temp_approval_step_sheet to web_user;

-- enable missing standard alerts
begin
	-- clear app_sid
	user_pkg.logonadmin;
	INSERT INTO customer_alert_type (app_sid, alert_type_id)
		SELECT c.app_sid, at.alert_type_id
		  FROM customer c, alert_type at
		 WHERE at.alert_type_id IN (1, 2, 3, 4, 5, 7, 20, 21, 22, 23, 24, 25, 26)
		 MINUS
		SELECT app_sid, alert_type_id
		  FROM customer_alert_type;
end;
/

@update_tail
