-- Please update version.sql too -- this keeps clean builds in sync
define version=3036
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

declare
	v_exists number;
	v_sql varchar2(4000);
begin
	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SCRAGFETCHOPTIONS' and object_type='TYPE';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE TYPE csr.ScragFetchOptions AS OBJECT
(
	app_sid						NUMBER(10),
	scenario_run_sid 			NUMBER(10),
	ind_sids					security.T_SID_TABLE,
	region_sids					security.T_SID_TABLE,
	start_dtm					DATE,
	end_dtm						DATE,
	period_set_id				NUMBER(10),
	period_interval_id			NUMBER(10),
	fetch_source_values			NUMBER(1),
	fetch_file_uploads			NUMBER(1),
	fetch_source_details		NUMBER(1),
	fixed_analysis_server		VARCHAR2(255),
	finder_broadcast_addresses	VARCHAR2(4000),
	CONSTRUCTOR FUNCTION ScragFetchOptions(
		ind_sids					security.T_SID_TABLE,
		region_sids					security.T_SID_TABLE,
		app_sid 					NUMBER DEFAULT SYS_CONTEXT(''SECURITY'', ''APP''),
		scenario_run_sid 			NUMBER DEFAULT NULL,
		start_dtm					DATE DEFAULT NULL,
		end_dtm						DATE DEFAULT NULL,
		period_set_id				NUMBER DEFAULT NULL,
		period_interval_id			NUMBER DEFAULT NULL,
		fetch_source_values			NUMBER DEFAULT 1,
		fetch_file_uploads			NUMBER DEFAULT 0,
		fetch_source_details 		NUMBER DEFAULT 0,
		fixed_analysis_server		VARCHAR2 DEFAULT NULL,
		finder_broadcast_addresses	VARCHAR2 DEFAULT NULL
	) RETURN SELF AS RESULT 
)';
		execute immediate v_sql;
	end if;

	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SCRAGFETCHOPTIONS' and object_type='TYPE BODY';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE TYPE BODY csr.ScragFetchOptions AS
	CONSTRUCTOR FUNCTION ScragFetchOptions(
		ind_sids					security.T_SID_TABLE,
		region_sids					security.T_SID_TABLE,
		app_sid 					NUMBER DEFAULT SYS_CONTEXT(''SECURITY'', ''APP''),
		scenario_run_sid 			NUMBER DEFAULT NULL,
		start_dtm					DATE DEFAULT NULL,
		end_dtm						DATE DEFAULT NULL,
		period_set_id				NUMBER DEFAULT NULL,
		period_interval_id			NUMBER DEFAULT NULL,
		fetch_source_values			NUMBER DEFAULT 1,
		fetch_file_uploads			NUMBER DEFAULT 0,
		fetch_source_details 		NUMBER DEFAULT 0,
		fixed_analysis_server		VARCHAR2 DEFAULT NULL,
		finder_broadcast_addresses	VARCHAR2 DEFAULT NULL
	) RETURN SELF AS RESULT AS
	BEGIN
		self.app_sid := app_sid;
		self.scenario_run_sid := scenario_run_sid;
		self.ind_sids := ind_sids;
		self.region_sids := region_sids;
		self.start_dtm := start_dtm;
		self.end_dtm := end_dtm;
		self.period_set_id := period_set_id;
		self.period_interval_id := period_interval_id;
		self.fetch_source_values := fetch_source_values;
		self.fetch_file_uploads	:= fetch_file_uploads;
		self.fetch_source_details := fetch_source_details;
		self.fixed_analysis_server := fixed_analysis_server;
		self.finder_broadcast_addresses := finder_broadcast_addresses;
		RETURN;
	END;
END;';
		execute immediate v_sql;
	end if;

	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SOURCEVALROW' and object_type='TYPE';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE TYPE csr.SourceValRow AS OBJECT
(
	ind_sid							NUMBER(10),
	region_sid						NUMBER(10),
	period_start_dtm				DATE,
	period_end_dtm					DATE,
	val_number						NUMBER(24, 10),
	error_code						NUMBER(10),
	source_type_id					NUMBER(10),
	source_id						NUMBER(10),
	val_id							NUMBER(20),
	entry_measure_conversion_id		NUMBER(10),
	entry_val_number				NUMBER(24, 10),
	is_merged						NUMBER(1),
	note							CLOB,
	var_expl_note					CLOB,
	changed_dtm						DATE,
	changed_by_sid					NUMBER(10)
)';
		execute immediate v_sql;
	end if;

	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SOURCEVALTABLE' and object_type='TYPE';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE TYPE csr.SourceValTable AS TABLE OF SourceValRow;
';
		execute immediate v_sql;
	end if;

	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SCRAGQUERY' and object_type='TYPE';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE TYPE csr.ScragQuery AS OBJECT
(
	key INTEGER,

	STATIC FUNCTION ODCITableStart(
		sctx 					OUT ScragQuery,
		options					IN	ScragFetchOptions
	)
		RETURN NUMBER
		AS LANGUAGE JAVA
		NAME ''ScragQuery.ODCITableStart(java.sql.Struct[], java.sql.Struct) return java.math.BigDecimal'',

	MEMBER FUNCTION ODCITableFetch(self IN OUT ScragQuery, nrows IN NUMBER,
																 outSet OUT SourceValTable) RETURN NUMBER
		AS LANGUAGE JAVA
		NAME ''ScragQuery.ODCITableFetch(java.math.BigDecimal, java.sql.Array[]) return java.math.BigDecimal'',

	MEMBER FUNCTION ODCITableClose(self IN ScragQuery) RETURN NUMBER
		AS LANGUAGE JAVA
		NAME ''ScragQuery.ODCITableClose() return java.math.BigDecimal''

)';
		execute immediate v_sql;
	end if;

	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SCRAG' and object_type='FUNCTION';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE FUNCTION csr.Scrag(
	options		ScragFetchOptions
)
RETURN csr.SourceValTable
PIPELINED USING csr.ScragQuery;
';
		execute immediate v_sql;
	end if;

	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SCRAG2' and object_type='FUNCTION';
	if v_exists = 0 then
		v_sql := '
CREATE OR REPLACE FUNCTION csr.Scrag2(
	options		csr.ScragFetchOptions
)
RETURN csr.SourceValTable
AS LANGUAGE JAVA NAME ''ScragQuery.Query(java.sql.Struct) return java.sql.Array'';
';
		execute immediate v_sql;
	end if;

	select count(*) into v_exists from all_objects where owner='CSR' and object_name='SCRAG_CONFIG' and object_type='TABLE';
	if v_exists = 0 then
		v_sql := '
CREATE TABLE CSR.SCRAG_CONFIG
(
	FIXED_ANALYSIS_SERVER			VARCHAR2(255),
	FINDER_BROADCAST_ADDRESSES 		VARCHAR2(4000),
	ONLY_ONE_ROW NUMBER(1) CHECK (ONLY_ONE_ROW = 0),
	CONSTRAINT PK_SCRAG_CONFIG PRIMARY KEY (ONLY_ONE_ROW)
)';
		execute immediate v_sql;
	end if;

	dbms_java.grant_permission( 'CSR', 'SYS:java.net.SocketPermission', '*', 'accept,connect,listen,resolve' );
end;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
