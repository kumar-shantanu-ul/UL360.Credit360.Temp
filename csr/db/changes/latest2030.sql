-- Please update version.sql too -- this keeps clean builds in sync
define version=2030
@update_header

PROMPT CHANGES TO EXISTING TABLES

ALTER TABLE CSR.SECTION_CART ADD (
	SECTION_CART_FOLDER_ID		NUMBER(10, 0)
);

PROMPT ADD NEW TABLE

CREATE SEQUENCE CSR.SECTION_CART_FOLDER_ID_SEQ 
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 5
	NOORDER
;

CREATE TABLE CSR.SECTION_CART_FOLDER (
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SECTION_CART_FOLDER_ID	NUMBER(10, 0)	NOT NULL,
	PARENT_ID				NUMBER(10, 0),
	NAME					VARCHAR2(255)	NOT NULL,
	IS_VISIBLE				NUMBER(1, 0)	DEFAULT 1 NOT NULL,
	IS_ROOT					NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	CONSTRAINT PK_SECTION_CART_FOLDER PRIMARY KEY (APP_SID, SECTION_CART_FOLDER_ID),
	CONSTRAINT UK_SECTION_CART_FOLDER UNIQUE (SECTION_CART_FOLDER_ID),
	CONSTRAINT CK_SECTION_CART_FOLDER CHECK ((PARENT_ID IS NULL AND IS_ROOT = 1) OR (PARENT_ID IS NOT NULL))
);

CREATE UNIQUE INDEX CSR.UK_SECTION_FOLDER_ROOT ON CSR.SECTION_CART_FOLDER(
	DECODE(IS_ROOT, 1, APP_SID, SECTION_CART_FOLDER_ID)
)
;

ALTER TABLE CSR.SECTION_CART ADD CONSTRAINT FK_SECTION_CART_FOLDER
	FOREIGN KEY (APP_SID, SECTION_CART_FOLDER_ID)
	REFERENCES CSR.SECTION_CART_FOLDER(APP_SID, SECTION_CART_FOLDER_ID)
;

grant create table to csr;

create index csr.ix_doc_desc_search on csr.doc_version(description) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

revoke create table from csr;

grant execute on ctx_ddl to csr;

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every mintue afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.doclib_desc_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_doc_desc_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2014/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise doclib text indexes');
       COMMIT;
END;
/

@../section_cart_folder_pkg
@../section_cart_folder_body
@../section_pkg
@../section_body

grant execute on csr.section_cart_folder_pkg TO web_user;

PROMPT ADDING RLS to CSR.SECTION_CART_FOLDER

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	dbms_rls.add_policy(
		object_schema	=> 'CSR',
		object_name		=> 'SECTION_CART_FOLDER',
		policy_name		=> 'SECTION_CART_FOLDER_POLICY',
		function_schema	=> 'CSR',
		policy_function	=> 'appSidCheck',
		statement_types	=> 'select, insert, update, delete',
		update_check	=> true,
		policy_type		=> dbms_rls.context_sensitive );
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for SECTION_CART_FOLDER');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for SECTION_CART_FOLDER as feature not enabled');
END;
/

PROMPT Updating existing section carts
DECLARE
	v_root_folder_id	NUMBER(10);
BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT w.website_name, sc.app_sid, COUNT(section_cart_id) section_carts
		  FROM csr.section_cart sc
		  JOIN security.website w ON sc.app_sid = w.application_sid_id
		 WHERE sc.section_cart_folder_id IS NULL
		 GROUP BY w.website_name, sc.app_sid
	)
	LOOP
		security.user_pkg.logonadmin(r.website_name);
		
		BEGIN
			SELECT section_cart_folder_id
			  INTO v_root_folder_id
			  FROM csr.section_cart_folder
			 WHERE is_root = 1;
		EXCEPTION
			WHEN no_data_found THEN
				INSERT INTO csr.section_cart_folder 
				(section_cart_folder_id, parent_id, name, is_visible, is_root)
				VALUES	(csr.section_cart_folder_id_seq.NEXTVAL, null, 'Carts', 1, 1)
				RETURNING section_cart_folder_id INTO v_root_folder_id;
		END;

		DBMS_OUTPUT.PUT_LINE('UPDATING ' || r.website_name || ' SETTING ROOT SECTION CART FOLDER TO ' || TO_CHAR(v_root_folder_id));

		UPDATE csr.section_cart
		   SET section_cart_folder_id = v_root_folder_id
		 WHERE app_sid = SYS_CONTEXT('security','app');
		security.user_pkg.logonadmin;
	END LOOP;

	security.user_pkg.logOff(SYS_CONTEXT('security','act'));
END;
/

ALTER TABLE CSR.SECTION_CART MODIFY SECTION_CART_FOLDER_ID NOT NULL;

@update_tail