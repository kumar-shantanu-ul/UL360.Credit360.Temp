-- Please update version.sql too -- this keeps clean builds in sync
define version=2009
@update_header

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit section docs', 0);

CREATE TABLE CSR.SECTION_CONTENT_DOC (	
	APP_SID 					NUMBER(10,0) 	DEFAULT SYS_CONTEXT('SECURITY','APP') 	NOT NULL, 
	SECTION_SID 				NUMBER(10,0) 											NOT NULL,
	DOC_ID						NUMBER(10,0)											NOT NULL,
	CHECKED_OUT_TO_SID 			NUMBER(10,0), 
	CHECKED_OUT_DTM 			DATE, 
	CHECKED_OUT_VERSION_NUMBER 	NUMBER(10,0), 
	CONSTRAINT PK_SECTION_CONTENT_DOC PRIMARY KEY (APP_SID, SECTION_SID, DOC_ID), 
	CONSTRAINT FK_SECTION_CONTENT_DOC_SECTION FOREIGN KEY (APP_SID, SECTION_SID)
		REFERENCES CSR.SECTION (APP_SID, SECTION_SID),
	CONSTRAINT FK_SECTION_CONTENT_DOC_DOC FOREIGN KEY (APP_SID, DOC_ID)
		REFERENCES CSR.DOC (APP_SID, DOC_ID)
);

CREATE TABLE CSR.SECTION_CONTENT_DOC_WAIT (	
	APP_SID 					NUMBER(10,0) 	DEFAULT SYS_CONTEXT('SECURITY','APP') 	NOT NULL, 
	SECTION_SID 				NUMBER(10,0) 											NOT NULL,
	DOC_ID						NUMBER(10,0)											NOT NULL,
	CSR_USER_SID      			NUMBER(10,0)                      						NOT NULL, 
	CONSTRAINT PK_SECTION_CONTENT_DOC_WAIT PRIMARY KEY (APP_SID, SECTION_SID, DOC_ID, CSR_USER_SID), 
	CONSTRAINT FK_SEC_CON_DOC_DITTO_WAIT FOREIGN KEY (APP_SID, SECTION_SID, DOC_ID)
		REFERENCES CSR.SECTION_CONTENT_DOC (APP_SID, SECTION_SID, DOC_ID),
	CONSTRAINT FK_SECT_CONT_DOC_WAIT_USR FOREIGN KEY (APP_SID, CSR_USER_SID)
		REFERENCES CSR.CSR_USER (APP_SID, CSR_USER_SID)
);  

ALTER TABLE CSR.section_module ADD(
	library_sid			NUMBER(10, 0),
	active				NUMBER(1, 0)  DEFAULT 1 NOT NULL,
	parent_folder_sid 	NUMBER(10, 0)	
);

ALTER TABLE CSR.section_module ADD CONSTRAINT fk_section_mod_doc_fldr
	FOREIGN KEY (app_sid, library_sid) REFERENCES csr.doc_folder(app_sid, doc_folder_sid);


DECLARE
	v_default_alert_frame_id 	NUMBER;
BEGIN
	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (56, 'Section document now available notification',
		'A document for a section has been checked in and is now available for user to change.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
	);  

	-- user cover started
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (56, 0, 'TO_FULLNAME', 'To Full Name', 'The user that requested to be alerted.', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (56, 0, 'FIN_FULLNAME', 'Full Name', 'The user that has finished editing the document.', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (56, 0, 'FILENAME', 'Filename', 'The file that has become available for editing.', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (56, 0, 'QUESTION_LABEL', 'Question Name', 'The questions title.', 4);

	SELECT MAX (default_alert_frame_id) INTO v_default_alert_frame_id FROM CSR.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (56, v_default_alert_frame_id, 'manual');


	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (56, 'en',
		'<template>A document you wanted to edit is now available for editing</template>',
		'<template><p>Dear <mergefield name="TO_FULLNAME"/>,</p>'||
		'<p><mergefield name="FIN_FULLNAME"/> has finished editing the document <mergefield name="FILENAME"/>.</p>'||
		'<p>It is now available for you to edit in the question <mergefield name="QUESTION_LABEL"/> via "Your Questions".</p></template>',
		'<template/>');
		
END;
/

	DECLARE
		v_index_library         	csr.section_module.LIBRARY_SID%TYPE;
		v_doc_id			        csr.doc_version.DOC_ID%TYPE;
		v_attachment_id	        	csr.attachment.ATTACHMENT_ID%TYPE;
		v_indx_lib_folder_sid		security.security_pkg.T_SID_ID;
		v_doclib_sid            	security.security_pkg.T_SID_ID;
	BEGIN
		--Look through every index (or section module root)
		FOR r IN (SELECT c.website_name, sm.app_sid, sm.module_root_sid, sm.label FROM csr.section_module sm JOIN SECURITY.WEBSITE c ON sm.app_sid = c.application_sid_id WHERE label != 'Sections')
		LOOP
			--Need to logon on as some procedures called use sys_context
			security.user_pkg.logonadmin(r.website_name);
			--Create a folder to store all the libs in.
			BEGIN
				v_indx_lib_folder_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('security','act'), r.app_sid, 'IndexLibs');		
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.SecurableObject_pkg.CreateSO(SYS_CONTEXT('security','act'), r.app_sid, security.security_pkg.SO_CONTAINER, 'IndexLibs', v_indx_lib_folder_sid);	
			END;
			
			--Create Library
			--Try finding index lib by index name, tack on index sid to keep unique
			BEGIN
				v_doclib_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('security','act'), v_indx_lib_folder_sid, r.label ||'_'|| r.module_root_sid);		
			EXCEPTION
				--Create if doesn't exist
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN    
					csr.doc_lib_pkg.CreateLibrary(
						v_indx_lib_folder_sid,
						r.label ||'_' || r.module_root_sid,
						'Documents',
						'Recycle bin',
						r.app_sid,
						v_doclib_sid);
			END;
			--Hook up library to index 
			UPDATE csr.section_module 
			   SET library_sid = (SELECT documents_sid FROM csr.doc_library WHERE doc_library_sid = v_doclib_sid) 
			 WHERE app_sid = r.app_sid 
			   AND module_root_sid = r.module_root_sid;
		END LOOP;
	END;
	/


DROP INDEX csr.ix_section_body_search;

grant create table to csr;

/* SECTION HTML INDEX */
create index csr.ix_section_body_search on csr.section_version(body) indextype is ctxsys.context
parameters ('filter CTXSYS.NULL_FILTER section group ctxsys.html_section_group');

/* SECTION TITLE INDEX */
create index csr.ix_section_title_search on csr.section_version(title) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

revoke create table from csr;

DECLARE
	job BINARY_INTEGER;
BEGIN
	-- now and every minute afterwards
	-- 10g w/low_priority_job created
	DBMS_SCHEDULER.CREATE_JOB (
	   job_name             => 'csr.section_title_text',
	   job_type             => 'PLSQL_BLOCK',
	   job_action           => 'ctx_ddl.sync_index(''ix_section_title_search'');',
	   job_class            => 'low_priority_job',
	   start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	   repeat_interval      => 'FREQ=MINUTELY',
	   enabled              => TRUE,
	   auto_drop            => FALSE,
	   comments             => 'Synchronise section title text indexes');
END;
/

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_SECTION_SID_FILTER (
	SECTION_SID			NUMBER(10,0)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSR.temp_doc_id_path
(
	doc_id				NUMBER(10,0),
	path				VARCHAR2(2000)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_SECTION_SEARCH_RESULT (
	MODULE_NAME			VARCHAR2(1024),
	SECTION_SID			NUMBER(10,0),
	DOC_ID				NUMBER(10,0),
	ATTACHMENT_ID		NUMBER(10,0),
	VERSION_NUMBER		NUMBER(10,0),
	TITLE				VARCHAR2(1024),
	PATH				VARCHAR2(1024),
	SNIPPET				VARCHAR2(1024),
	CHANGED_BY_SID		NUMBER(10,0),
	CHANGED_BY_NAME		VARCHAR2(256),
	CHANGED_DTM			DATE,
	RESULT_TYPE			NUMBER(1,0),
	RESULT_SCORE		NUMBER(10,0),
	MIME_TYPE			VARCHAR2(128)
) ON COMMIT DELETE ROWS;

-- this looks f**ked up - why does it join to sal2?
CREATE OR REPLACE VIEW csr.v$section_attach_log_last AS
	SELECT sal.app_sid,
			sal.section_attach_log_id,
			sal.section_sid,
			sal.attachment_id, 
			sal.log_date changed_dtm, 
			sal.csr_user_sid changed_by_sid,
			cu.full_name changed_by_name,
			sal.summary,
			sal.description
	  FROM section_attach_log sal, csr_user cu,
			(
			SELECT app_sid, attachment_id, MAX(log_date) log_date
			FROM section_attach_log
			GROUP BY app_sid, attachment_id
			) sal2
	 WHERE sal.app_sid = sal2.app_sid
	   AND sal.log_date = sal2.log_date  AND sal.attachment_id = sal2.attachment_id
	   AND sal.csr_user_sid = cu.csr_user_sid;


@../section_pkg
@../section_root_pkg

@../section_body
@../section_root_body
@../doc_body
@../doc_lib_body

@update_tail