-- Please update version.sql too -- this keeps clean builds in sync
define version=2441
@update_header

ALTER TABLE csr.section_module ADD (
	  start_dtm DATE NULL, end_dtm DATE NULL
);

CREATE TABLE csr.section_ind(
	app_sid						NUMBER(10)		DEFAULT sys_context('security','app') NOT NULL,
	section_sid					NUMBER(10)		NOT NULL,
	fact_id						VARCHAR2(255)	NOT NULL,
	map_to_ind_sid				NUMBER(10)		NULL,
	data_type					VARCHAR2(30)	NULL,
	CONSTRAINT pk_section_ind PRIMARY KEY (app_sid, section_sid, fact_id)
);

CREATE TABLE csr.section_val(
	app_sid						NUMBER(10)		DEFAULT sys_context('security','app') NOT NULL,
	section_val_id				NUMBER(20)		NOT NULL,
	section_sid					NUMBER(10)		NOT NULL,
	fact_id						VARCHAR2(255)	NOT NULL,
	region_sid					NUMBER(10)		NULL,
	start_dtm					DATE			NULL,
	end_dtm						DATE			NULL,
	idx							NUMBER(10)		NOT NULL,
	val_number					NUMBER(24,10)	NULL,
	std_measure_conversion_id	NUMBER(10)		NULL,
	note						CLOB			NULL,
	CONSTRAINT pk_section_val PRIMARY KEY (app_sid, section_val_id)
);

ALTER TABLE csr.section_val ADD CONSTRAINT fk_section_val_section_ind 
    FOREIGN KEY (app_sid, section_sid, fact_id)
    REFERENCES csr.section_ind(app_sid, section_sid, fact_id);
	
CREATE SEQUENCE csr.section_val_id_seq MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE;

CREATE UNIQUE INDEX csr.uk_section_val ON csr.section_val (app_sid, section_sid, fact_id, region_sid, start_dtm, end_dtm, idx);

-- Add to RLS
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	DBMS_RLS.ADD_POLICY(
		object_schema   => 'CSR',
		object_name     => 'SECTION_IND',
		policy_name     => 'SECTION_IND_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check    => true,
		policy_type     => dbms_rls.context_sensitive );
	DBMS_OUTPUT.PUT_LINE('Policy added to SECTION_IND');
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists for SECTION_IND');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied for SECTION_IND as feature not enabled');
END;
/

-- Add to RLS
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	DBMS_RLS.ADD_POLICY(
		object_schema   => 'CSR',
		object_name     => 'SECTION_VAL',
		policy_name     => 'SECTION_VAL_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check    => true,
		policy_type     => dbms_rls.context_sensitive );
	DBMS_OUTPUT.PUT_LINE('Policy added to SECTION_VAL');
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists for SECTION_VAL');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied for SECTION_VAL as feature not enabled');
END;
/

@../section_pkg
@../section_root_pkg

@../section_body
@../section_root_body

@update_tail
