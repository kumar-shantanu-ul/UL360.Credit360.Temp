define version=3399
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE cms.form_response_section(
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	import_id			NUMBER(10) NOT NULL,
	response_id			VARCHAR2(255) NOT NULL,
	node_id				NUMBER(10) NOT NULL,
	data_key			VARCHAR(255) NOT NULL,
	parent_node_id		NUMBER(10) NULL,
	repeat_index		NUMBER(10) NULL,
	row_key 			VARCHAR2(255) NULL,
	CONSTRAINT PK_FORM_RESP_SEC PRIMARY KEY (app_sid, import_id, response_id, node_id),
	CONSTRAINT FK_FORM_RESP_SEC_IMP FOREIGN KEY (app_sid, import_id) REFERENCES cms.form_response(app_sid, import_id)
);

CREATE TABLE cms.form_response_section_answer(
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	import_id			NUMBER(10) NOT NULL,
	response_id			VARCHAR2(255) NOT NULL,
	node_id				NUMBER(10) NOT NULL,
	data_key			VARCHAR(255) NOT NULL,
	answer_type			VARCHAR(100) NOT NULL,
	answer_text			CLOB,
	answer_num			NUMBER,
	answer_dtm			DATE,
	CONSTRAINT PK_FORM_RESP_SEC_ANS PRIMARY KEY (app_sid, import_id, node_id, response_id, data_key),
	CONSTRAINT FK_FORM_RESP_SEC_ANS_IMP FOREIGN KEY (app_sid, import_id, response_id, node_id) REFERENCES cms.form_response_section(app_sid, import_id, response_id, node_id),
	CONSTRAINT CHK_FORM_RESP_SEC_ANS_TYPE CHECK (answer_type IN ('null', 'string', 'number', 'date', 'stringlist'))
);

CREATE TABLE cms.form_response_section_option(
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	option_id			NUMBER(10) NOT NULL,
	import_id			NUMBER(10) NOT NULL,
	response_id			VARCHAR2(255) NOT NULL,
	node_id				NUMBER(10) NOT NULL,
	data_key			VARCHAR2(255) NOT NULL,
	option_value		VARCHAR2(2048) NOT NULL,
	CONSTRAINT PK_FORM_RESP_SEC_ANS_OPT PRIMARY KEY (app_sid, import_id, node_id, response_id, option_id),
	CONSTRAINT FK_FORM_RESP_SEC_ANS_OPT_IMP FOREIGN KEY (app_sid, import_id, response_id, node_id) REFERENCES cms.form_response_section(app_sid, import_id, response_id, node_id),
	CONSTRAINT FK_FORM_RESP_SEC_ANS_OPT_RESP_ANS FOREIGN KEY (app_sid, import_id, node_id, response_id, data_key) REFERENCES cms.form_response_section_answer(app_sid, import_id, node_id, response_id, data_key)
);

CREATE TABLE cms.form_response_section_file(
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	file_id				NUMBER(10) NOT NULL,
	import_id			NUMBER(10) NOT NULL,
	response_id			VARCHAR2(255) NOT NULL,
	node_id				NUMBER(10) NOT NULL,
	remote_file_id		VARCHAR2(255) NOT NULL,
	data_key			VARCHAR2(255) NOT NULL,
	mime_type			VARCHAR2(255) NOT NULL,
	file_name			VARCHAR2(255) NOT NULL,
	file_data			BLOB NOT NULL,
	CONSTRAINT PK_FORM_RESP_SEC_FILE PRIMARY KEY (app_sid, file_id),
	CONSTRAINT UK_FORM_RESP_SEC_FILE_RESP UNIQUE (app_sid, file_id, node_id, response_id, data_key),
	CONSTRAINT FK_FORM_RESP_SEC_ANSWER FOREIGN KEY (app_sid, import_id, node_id, response_id, data_key) REFERENCES cms.form_response_section_answer(app_sid, import_id, node_id, response_id, data_key),
	CONSTRAINT FK_FORM_SEC_RESP FOREIGN KEY (app_sid, import_id, response_id, node_id) REFERENCES cms.form_response_section(app_sid, import_id, response_id, node_id)
);

CREATE SEQUENCE cms.form_resp_section_id_seq;
CREATE SEQUENCE cms.form_resp_sec_opt_id_seq;
CREATE SEQUENCE cms.form_resp_sec_file_id_seq;

CREATE INDEX cms.ix_form_resp_sect_ans_import_id_res ON cms.form_response_section_answer (app_sid, import_id, response_id, node_id);
CREATE INDEX cms.ix_form_resp_sect_file_import_id_res ON cms.form_response_section_file (app_sid, import_id, response_id, node_id);
CREATE INDEX cms.ix_form_resp_sect_file_data_key_import_id_nod ON cms.form_response_section_file (app_sid, import_id, node_id, response_id, data_key);
CREATE INDEX cms.ix_form_resp_sect_opt_import_id_res ON cms.form_response_section_option (app_sid, import_id, response_id, node_id);
CREATE INDEX cms.ix_form_resp_sect_opt_data_key_import_id_nod ON cms.form_response_section_option (app_sid, import_id, node_id, response_id, data_key);


-- Alter tables
ALTER TABLE cms.form_response_import_options
ADD child_helper_sp VARCHAR2(400) NULL;

-- *** Grants ***

-- *** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.util_script_param(util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES(66, 'Child Helper SP', 'SP called when importing child data for responses', 4, NULL, 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\util_script_pkg
@..\util_script_body
@..\..\..\aspen2\cms\db\form_response_import_pkg
@..\..\..\aspen2\cms\db\form_response_import_body


@update_tail
