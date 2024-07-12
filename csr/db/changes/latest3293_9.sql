-- Please update version.sql too -- this keeps clean builds in sync
define version=3293
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE cms.form_response_import_options(
	app_sid				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	form_id				VARCHAR2(255) NOT NULL,
	helper_sp			VARCHAR2(400) NOT NULL,
	CONSTRAINT PK_FORM_RESPONSE_IMPORT_OPT PRIMARY KEY (app_sid, form_id, helper_sp),
	CONSTRAINT UK_FORM_RESP_APP UNIQUE (app_sid, form_id)
);

CREATE TABLE cms.form_response(
	app_sid				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	import_id			NUMBER(10) NOT NULL,
	form_id				VARCHAR2(255) NOT NULL,
	form_version		NUMBER NOT NULL,
	response_id			VARCHAR2(255) NOT NULL,
	user_sid			NUMBER(10), --NOT NULL,			-- TODO - make this NOT NULL when API is sending user ID!
	retrieved_dtm		DATE DEFAULT SYSDATE NOT NULL,
	response_json		CLOB NOT NULL,
	processed_dtm		DATE,
	failure_dtm			DATE,
	failure_msg			CLOB,
	CONSTRAINT PK_FORM_RESPONSE PRIMARY KEY (app_sid, form_id, form_version, response_id),
	CONSTRAINT UK_FORM_RESP_IMP_ID UNIQUE (app_sid, import_id),
	CONSTRAINT FK_FORM_RESP_FORM FOREIGN KEY (app_sid, form_id) REFERENCES cms.form_response_import_options(app_sid, form_id)
);

CREATE TABLE cms.form_response_answer(
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	import_id			NUMBER(10) NOT NULL,
	response_id			VARCHAR2(255) NOT NULL,
	data_key			VARCHAR(255) NOT NULL,
	answer_type			VARCHAR(100) NOT NULL,
	answer_text			CLOB,
	answer_num			NUMBER,
	answer_dtm			DATE,
	CONSTRAINT PK_FORM_RESP_ANS PRIMARY KEY (app_sid, import_id, response_id, data_key),
	CONSTRAINT FK_FORM_RESP_ANS_IMP FOREIGN KEY (app_sid, import_id) REFERENCES cms.form_response(app_sid, import_id),
	CONSTRAINT CHK_FORM_RESP_ANS_TYPE CHECK (answer_type IN ('null', 'string', 'number', 'date', 'stringlist'))				-- string-list = multiple (lookup in form_response_answer_option table). null = unanswered question but could have file attachments.
);

CREATE TABLE cms.form_response_answer_option(
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	option_id			NUMBER(10) NOT NULL,
	import_id			NUMBER(10) NOT NULL,
	response_id			VARCHAR2(255) NOT NULL,
	data_key			VARCHAR2(255) NOT NULL,
	option_value		VARCHAR2(2048) NOT NULL,
	CONSTRAINT PK_FORM_RESP_ANS_OPT PRIMARY KEY (app_sid, import_id, response_id, option_id),
	CONSTRAINT FK_FORM_RESP_ANS_OPT_IMP FOREIGN KEY (app_sid, import_id) REFERENCES cms.form_response(app_sid, import_id),
	CONSTRAINT FK_FORM_RESP_ANS_OPT_RESP_ANS FOREIGN KEY (app_sid, import_id, response_id, data_key) REFERENCES cms.form_response_answer(app_sid, import_id, response_id, data_key)
);

CREATE INDEX cms.ix_form_response_opt_imp_id ON cms.form_response_answer_option (app_sid, import_id, response_id, data_key);

CREATE TABLE cms.form_response_answer_file(
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	file_id				NUMBER(10) NOT NULL,
	import_id			NUMBER(10) NOT NULL,
	response_id			VARCHAR2(255) NOT NULL,
	data_key			VARCHAR2(255) NOT NULL,
	file_data			BLOB NOT NULL,
	CONSTRAINT PK_FORM_RESP_ANS_FILE PRIMARY KEY (app_sid, file_id),
	CONSTRAINT UK_FORM_RESP_ANS_FILE_RESP UNIQUE (app_sid, file_id, response_id, data_key),
	CONSTRAINT FK_FORM_RESP_ANSWER FOREIGN KEY (app_sid, import_id, response_id, data_key) REFERENCES cms.form_response_answer(app_sid, import_id, response_id, data_key),
	CONSTRAINT FK_FORM_RESP FOREIGN KEY (app_sid, import_id) REFERENCES cms.form_response(app_sid, import_id)
);

CREATE INDEX cms.ix_form_response_file_imp_id ON cms.form_response_answer_file (app_sid, import_id);
CREATE INDEX cms.ix_form_response_file_id_resp_dk ON cms.form_response_answer_file (app_sid, import_id, response_id, data_key);

CREATE SEQUENCE CMS.FORM_RESP_IMPORT_ID_SEQ;
CREATE SEQUENCE CMS.FORM_RESP_ANS_OPT_ID_SEQ;
CREATE SEQUENCE CMS.FORM_RESP_ANS_FILE_ID_SEQ;

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../csr_user_pkg
@../../../aspen2/cms/db/form_response_import_pkg
@../csr_user_body
@../../../aspen2/cms/db/form_response_import_body

@update_tail
