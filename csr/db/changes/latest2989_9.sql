-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables
-- Need this early for the FKs!
GRANT REFERENCES ON mail.mailbox TO CSR;
CREATE TABLE csr.auto_imp_mailbox (
	app_sid								NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	address								VARCHAR2(255) NOT NULL,
	mailbox_sid							NUMBER(10) NOT NULL,
	body_validator_plugin				VARCHAR2(1024),
	use_full_mail_logging				NUMBER(1) DEFAULT 0 NOT NULL,
	matched_imp_class_sid_for_body		NUMBER(10),
	deactivated_dtm						DATE,
	CONSTRAINT pk_auto_imp_mailbox PRIMARY KEY (app_sid, mailbox_sid),
	CONSTRAINT fk_auto_imp_mailbox_box FOREIGN KEY (mailbox_sid) REFERENCES mail.mailbox (mailbox_sid),
	CONSTRAINT fk_auto_imp_mailbox_bdy_cls FOREIGN KEY (app_sid, matched_imp_class_sid_for_body) REFERENCES csr.automated_import_class(app_sid, automated_import_class_sid),
	CONSTRAINT ck_auto_imp_mailbox_logging CHECK (use_full_mail_logging IN (0, 1))
);

CREATE TABLE csr.auto_imp_mail_sender_filter (
	app_sid						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	mailbox_sid					NUMBER(10) NOT NULL,
	filter_string				VARCHAR2(1024) NOT NULL,
	is_wildcard					NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_auto_imp_mail_sndr_filter PRIMARY KEY (app_sid, mailbox_sid, filter_string),
	CONSTRAINT fk_auto_imp_mail_sndr_fltr_bx FOREIGN KEY (mailbox_sid) REFERENCES mail.mailbox (mailbox_sid),
	CONSTRAINT fk_auto_imp_mail_sndr_ftr_sid FOREIGN KEY (app_sid, mailbox_sid) REFERENCES csr.auto_imp_mailbox(app_sid, mailbox_sid),
	CONSTRAINT ck_auto_imp_mail_sndr_fltr_wc CHECK (is_wildcard IN (0, 1))
);

CREATE TABLE csr.auto_imp_mail_subject_filter (
	app_sid						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	mailbox_sid					NUMBER(10) NOT NULL,
	filter_string				VARCHAR2(1024) NOT NULL,
	is_wildcard					NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_auto_imp_mail_sbject_filter PRIMARY KEY (app_sid, mailbox_sid, filter_string),
	CONSTRAINT fk_auto_imp_mail_sbjct_fltr_bx FOREIGN KEY (mailbox_sid) REFERENCES mail.mailbox (mailbox_sid),
	CONSTRAINT fk_auto_imp_mail_sbjt_fltr_sid FOREIGN KEY (app_sid, mailbox_sid) REFERENCES csr.auto_imp_mailbox(app_sid, mailbox_sid),
	CONSTRAINT ck_auto_imp_mail_sbjct_fltr_wc CHECK (is_wildcard IN (0, 1))
);

CREATE TABLE csr.auto_imp_mail_attach_filter (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	mailbox_sid						NUMBER(10) NOT NULL,
	filter_string					VARCHAR2(1024) NOT NULL,
	is_wildcard						NUMBER(1) DEFAULT 0 NOT NULL,
	pos								NUMBER(2) NOT NULL,
	matched_import_class_sid		NUMBER(10) NOT NULL,
	required_mimetype				VARCHAR2(1024),
	CONSTRAINT pk_auto_imp_mail_attach_filter PRIMARY KEY (app_sid, mailbox_sid, pos),
	CONSTRAINT fk_auto_imp_mail_atch_fltr_box FOREIGN KEY (mailbox_sid) REFERENCES mail.mailbox (mailbox_sid),
	CONSTRAINT fk_auto_imp_mail_att_fltr_sid FOREIGN KEY (app_sid, mailbox_sid) REFERENCES csr.auto_imp_mailbox(app_sid, mailbox_sid),
	CONSTRAINT fk_auto_imp_mail_att_fltr_cls FOREIGN KEY (app_sid, matched_import_class_sid) REFERENCES csr.automated_import_class(app_sid, automated_import_class_sid),
	CONSTRAINT ck_auto_imp_mail_att_fltr_wc CHECK (is_wildcard IN (0, 1))
);

CREATE TABLE csr.auto_imp_mail (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	mailbox_sid				NUMBER(10) NOT NULL,
	mail_message_uid		NUMBER(10) NOT NULL,
	subject					VARCHAR2(4000),
	recieved_dtm			DATE,
	sender_address			VARCHAR2(255) NOT NULL,
	sender_name				VARCHAR2(255),
	number_attachments		NUMBER(10) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_auto_imp_mail PRIMARY KEY (app_sid, mailbox_sid, mail_message_uid),
	CONSTRAINT fk_auto_imp_mail_box FOREIGN KEY (mailbox_sid) REFERENCES mail.mailbox (mailbox_sid),
	CONSTRAINT fk_auto_imp_mail_box_sid FOREIGN KEY (app_sid, mailbox_sid) REFERENCES csr.auto_imp_mailbox(app_sid, mailbox_sid)
);

CREATE TABLE csr.auto_imp_mail_file (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	mailbox_sid						NUMBER(10) NOT NULL,
	mail_message_uid				NUMBER(10) NOT NULL,
	file_blob						BLOB NOT NULL,
	file_name						VARCHAR2(255) NOT NULL,
	made_from_body					NUMBER(1) DEFAULT 0 NOT NULL,
	automated_import_instance_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_auto_imp_mail_file PRIMARY KEY (app_sid, automated_import_instance_id),
	CONSTRAINT fk_auto_imp_mail_file_box FOREIGN KEY (mailbox_sid) REFERENCES mail.mailbox (mailbox_sid),
	CONSTRAINT fk_auto_imp_mail_file_instance FOREIGN KEY (app_sid, automated_import_instance_id) REFERENCES csr.automated_import_instance (app_sid, automated_import_instance_id),
	CONSTRAINT ck_auto_imp_mail_file_frm_body CHECK (made_from_body IN (0, 1))
);

CREATE TABLE csr.auto_imp_mail_msg (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	mailbox_sid						NUMBER(10) NOT NULL,
	mail_message_uid				NUMBER(10) NOT NULL,
	message							VARCHAR2(1024) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	CONSTRAINT pk_auto_imp_mail_msg PRIMARY KEY (app_sid, mailbox_sid, mail_message_uid, pos),
	CONSTRAINT fk_auto_imp_mail_msg_box FOREIGN KEY (mailbox_sid) REFERENCES mail.mailbox (mailbox_sid)
);

-- Alter tables
ALTER TABLE csr.automated_import_instance
ADD mailbox_sid NUMBER(10);

ALTER TABLE csr.automated_import_instance
ADD mail_message_uid NUMBER(10);

ALTER TABLE csr.automated_import_instance
ADD CONSTRAINT fk_auto_imp_inst_mailbox FOREIGN KEY (app_sid, mailbox_sid, mail_message_uid) REFERENCES CSR.auto_imp_mail (app_sid, mailbox_sid, mail_message_uid);

-- Modify the zip filter stuff to match what I'm doing with mail filters for consistency
-- Add the new column
ALTER TABLE csr.auto_imp_zip_filter
  ADD is_wildcard NUMBER(1) DEFAULT 0 NOT NULL;

-- Set the value of it based on current contents. Only need to set for wildcard as the default 0 kicks in otherwise
UPDATE csr.auto_imp_zip_filter
   SET is_wildcard = 1
 WHERE wildcard_match IS NOT NULL;
	 
-- Rename one of the current filter columns
 ALTER TABLE csr.auto_imp_zip_filter
RENAME COLUMN wildcard_match TO filter_string;

-- Copy the others across to the same shared column
UPDATE csr.auto_imp_zip_filter
   SET filter_string = regex_match
 WHERE filter_string IS NULL;
-- Drop the old column
ALTER TABLE csr.auto_imp_zip_filter
 DROP COLUMN regex_match;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_id	NUMBER(10);
BEGIN   
	security.user_pkg.logonadmin;
	security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), security.class_pkg.GetClassId('Mailbox'), 'CSRMailbox', 'csr.mailbox_pkg', null, v_id);
EXCEPTION
	WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		NULL;
END;
/

BEGIN
	INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 300, 'Automated import mailbox change');
END;
/

-- ** New package grants **
-- Create dummy packages for the grant
create or replace package csr.mailbox_pkg as
	procedure dummy;
end;
/
create or replace package body csr.mailbox_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/
grant execute on csr.mailbox_pkg to security;
grant execute on csr.mailbox_pkg to web_user;

-- *** Conditional Packages ***

-- Need to do some changes to the yam mail packages in OSS. 
update mail.version set db_version=33;

@latestUS5469_2_packages


-- *** Packages ***
@../csr_data_pkg
@../mailbox_pkg
@../mailbox_body
@../automated_import_pkg
@../automated_import_body

@update_tail
