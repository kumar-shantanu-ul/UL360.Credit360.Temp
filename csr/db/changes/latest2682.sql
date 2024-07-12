-- Please update version.sql too -- this keeps clean builds in sync
define version=2682
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE cms.debug_sql_log (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	debug_sql_log_id				NUMBER(10) NOT NULL,
	label							VARCHAR2(255) NOT NULL,
	start_dtm						TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
	end_dtm							TIMESTAMP,
	sql_text						CLOB,
	object_id						NUMBER(10),
	CONSTRAINT pk_debug_sql_log PRIMARY KEY (app_sid, debug_sql_log_id)
);

-- just a table to manually poke rows in/out to enable trace logs for a single act
-- (will be very useful when debugging cms slow queries)
CREATE TABLE cms.debug_act (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	act_id							CHAR(36) NOT NULL,
	CONSTRAINT pk_debug_act PRIMARY KEY (app_sid, act_id)
);

CREATE SEQUENCE cms.debug_sql_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

-- Alter tables
ALTER TABLE cms.tab_column ADD (
	show_in_filter					NUMBER(1) DEFAULT 1 NOT NULL,
	include_in_search				NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_show_in_filter_1_0 CHECK (show_in_filter IN (1, 0)),
	CONSTRAINT chk_include_in_search_1_0 CHECK (include_in_search IN (1, 0))
);

ALTER TABLE csrimp.cms_tab_column ADD (
	show_in_filter					NUMBER(1),
	include_in_search				NUMBER(1),
	CONSTRAINT chk_show_in_filter_1_0 CHECK (show_in_filter IN (1, 0)),
	CONSTRAINT chk_include_in_search_1_0 CHECK (include_in_search IN (1, 0))
);

UPDATE csrimp.cms_tab_column SET show_in_filter = 1;
ALTER TABLE csrimp.cms_tab_column MODIFY show_in_filter NOT NULL;

UPDATE csrimp.cms_tab_column SET include_in_search = 0;
ALTER TABLE csrimp.cms_tab_column MODIFY include_in_search NOT NULL;

ALTER TABLE CMS.CMS_AGGREGATE_TYPE RENAME COLUMN COLUMN_SID TO FIRST_ARG_COLUMN_SID;

ALTER TABLE CMS.CMS_AGGREGATE_TYPE ADD (
	SECOND_ARG_COLUMN_SID NUMBER(10),
	OPERATION CHAR(1)
);

ALTER TABLE CMS.CMS_AGGREGATE_TYPE ADD CONSTRAINT CHK_AGG_TYPE_2ND_COL_NUL 
    CHECK ((OPERATION IS NULL AND SECOND_ARG_COLUMN_SID IS NULL) OR (OPERATION IS NOT NULL AND SECOND_ARG_COLUMN_SID IS NOT NULL));

ALTER TABLE CMS.CMS_AGGREGATE_TYPE ADD CONSTRAINT CHK_AGG_TYPE_OPERATION 
    CHECK (OPERATION IN ('+','-','/','*'));

ALTER TABLE CMS.CMS_AGGREGATE_TYPE ADD CONSTRAINT FK_AGG_TYPE_2ND_COL 
    FOREIGN KEY (APP_SID, SECOND_ARG_COLUMN_SID) REFERENCES CMS.TAB_COLUMN (APP_SID,COLUMN_SID);

ALTER TABLE CSRIMP.CMS_AGGREGATE_TYPE RENAME COLUMN COLUMN_SID TO FIRST_ARG_COLUMN_SID;

ALTER TABLE CSRIMP.CMS_AGGREGATE_TYPE ADD (
	SECOND_ARG_COLUMN_SID NUMBER(10),
	OPERATION CHAR(1)
);

ALTER TABLE CSRIMP.CMS_AGGREGATE_TYPE ADD CONSTRAINT CHK_AGG_TYPE_2ND_COL_NUL 
    CHECK ((OPERATION IS NULL AND SECOND_ARG_COLUMN_SID IS NULL) OR (OPERATION IS NOT NULL AND SECOND_ARG_COLUMN_SID IS NOT NULL));

ALTER TABLE CSRIMP.CMS_AGGREGATE_TYPE ADD CONSTRAINT CHK_AGG_TYPE_OPERATION 
    CHECK (OPERATION IN ('+','-','/','*'));

ALTER TABLE chain.saved_filter ADD (
	cms_region_column_sid			NUMBER(10),
	cms_date_column_sid				NUMBER(10),
	CONSTRAINT fk_saved_filter_cms_region_col FOREIGN KEY (app_sid, cms_region_column_sid)
		REFERENCES cms.tab_column (app_sid, column_sid),
	CONSTRAINT fk_saved_filter_cms_date_col FOREIGN KEY (app_sid, cms_date_column_sid)
		REFERENCES cms.tab_column (app_sid, column_sid),
	CONSTRAINT chk_one_region_column CHECK (NOT(region_column_id IS NOT NULL AND cms_region_column_sid IS NOT NULL)),
	CONSTRAINT chk_one_date_column CHECK (NOT(date_column_id IS NOT NULL AND cms_date_column_sid IS NOT NULL))
);	

ALTER TABLE csrimp.chain_saved_filter ADD (
	cms_region_column_sid			NUMBER(10),
	cms_date_column_sid				NUMBER(10),
	CONSTRAINT chk_one_region_column CHECK (NOT(region_column_id IS NOT NULL AND cms_region_column_sid IS NOT NULL)),
	CONSTRAINT chk_one_date_column CHECK (NOT(date_column_id IS NOT NULL AND cms_date_column_sid IS NOT NULL))
);

ALTER TABLE chain.saved_filter ADD (
	cms_id_column_sid				NUMBER(10),
	list_page_url					VARCHAR2(255),
	CONSTRAINT fk_saved_filter_cms_id_col FOREIGN KEY (app_sid, cms_id_column_sid)
		REFERENCES cms.tab_column (app_sid, column_sid)
);

UPDATE chain.saved_filter
   SET cms_id_column_sid = group_key
 WHERE card_group_id = 43;

UPDATE chain.saved_filter
   SET group_key = NULL
 WHERE card_group_id = 43;
 
ALTER TABLE chain.saved_filter ADD (
	CONSTRAINT chk_cms_id_col CHECK ((card_group_id != 43 AND cms_id_column_sid IS NULL) OR (card_group_id = 43 AND cms_id_column_sid IS NOT NULL))
);

ALTER TABLE csrimp.chain_saved_filter ADD (
	cms_id_column_sid				NUMBER(10),
	list_page_url					VARCHAR2(255)
);

UPDATE csrimp.chain_saved_filter
   SET cms_id_column_sid = group_key
 WHERE card_group_id = 43;
 
UPDATE csrimp.chain_saved_filter
   SET group_key = NULL
 WHERE card_group_id = 43;
 
ALTER TABLE csrimp.chain_saved_filter ADD (
	CONSTRAINT chk_cms_id_col CHECK ((card_group_id != 43 AND cms_id_column_sid IS NULL) OR (card_group_id = 43 AND cms_id_column_sid IS NOT NULL))
);

ALTER TABLE chain.filter_field ADD (
	column_sid						NUMBER(10),
	CONSTRAINT fk_filter_field_cms_col_sid FOREIGN KEY (app_sid, column_sid)
		REFERENCES cms.tab_column (app_sid, column_sid)
);

ALTER TABLE csrimp.chain_filter_field ADD (
	column_sid						NUMBER(10)
);

create index cms.ix_cms_agg_type_2nd_column on cms.cms_aggregate_type (app_sid, second_arg_column_sid);
create index chain.ix_saved_filter_cms_id_col on chain.saved_filter (app_sid, cms_id_column_sid);
create index chain.ix_saved_filter_cms_region_col on chain.saved_filter (app_sid, cms_region_column_sid);
create index chain.ix_saved_filter_cms_date_col on chain.saved_filter (app_sid, cms_date_column_sid);
create index chain.ix_filter_field_cms_col_sid on chain.filter_field (app_sid, column_sid);

-- *** Grants ***
grant execute on csr.csr_data_pkg to cms;
grant execute on csr.issue_report_pkg to cms;

-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW chain.v$filter_value AS
       SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
		   fv.num_value, fv.min_num_val, fv.max_num_val, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
		   fv.compound_filter_id_value, fv.saved_filter_sid_value,
		   NVL(NVL(fv.description, CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' ELSE
		   NVL(NVL(r.description, cu.full_name), cr.name) END), fv.str_value) description, ff.group_by_index,
		   f.compound_filter_id, ff.show_all
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid;

CREATE OR REPLACE VIEW CHAIN.v$filter_field AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, ff.show_all, ff.group_by_index,
		   f.compound_filter_id, ff.top_n, ff.bottom_n, ff.column_sid
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id;
	  
-- *** Data changes ***
-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
BEGIN
	BEGIN
		--dbms_output.put_line('doing '||v_name);
		dbms_rls.add_policy(
			object_schema   => 'CMS',
			object_name     => 'DEBUG_SQL_LOG',
			policy_name     => 'DEBUG_SQL_LOG_POLICY',
			function_schema => 'CMS',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive );
		-- dbms_output.put_line('done  '||v_name);
	EXCEPTION
		WHEN policy_already_exists THEN
			NULL;
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policy DEBUG_SQL_LOG_POLICY not applied as feature not enabled');
	END;
	BEGIN
		--dbms_output.put_line('doing '||v_name);
		dbms_rls.add_policy(
			object_schema   => 'CMS',
			object_name     => 'DEBUG_ACT',
			policy_name     => 'DEBUG_ACT_POLICY',
			function_schema => 'CMS',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive );
		-- dbms_output.put_line('done  '||v_name);
	EXCEPTION
		WHEN policy_already_exists THEN
			NULL;
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policy DEBUG_ACT_POLICY not applied as feature not enabled');
	END;
END;
/

-- Data
insert into cms.col_type values (37, 'Business relationship');

-- This updates the 4 PVH columns that have already been created
-- TODO: double-checl before release that there are still just those four
update cms.tab_column set col_type = 37 where col_type = 0 AND oracle_column = 'BUSINESS_RELATIONSHIP_ID';

-- convert loosely referenced column sids to proper referenced columns
DECLARE
	v_count NUMBER;
BEGIN
	FOR r IN (
		SELECT app_sid, filter_field_id, CAST(regexp_substr(name,'[0-9]+') AS NUMBER) column_sid
		FROM chain.filter_field
		WHERE column_sid IS NULL
		 AND (name LIKE 'EnumField.%' 
		  OR name LIKE 'UserField.%' 
		OR name LIKE 'RegionField.%' 
		OR name LIKE 'TextField.%' 
		OR name LIKE 'DateField.%' 
		OR name LIKE 'BooleanField.%' 
		OR name LIKE 'ChildCmsFilter.%')
	) LOOP
		SELECT COUNT(*)
		INTO v_count
		FROM cms.tab_column
		WHERE app_sid = r.app_sid
		 AND column_sid = r.column_sid;

		IF v_count > 0 THEN		
			UPDATE chain.filter_field
			  SET column_sid = r.column_sid
			WHERE app_sid = r.app_sid
			  AND filter_field_id = r.filter_field_id;
			ELSE
			DELETE FROM chain.filter_field
				  WHERE filter_field_id = r.filter_field_id;
			END IF;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Packages ***
@../issue_pkg
@../issue_report_pkg
@../csrimp/imp_pkg
@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/filter_pkg
@../chain/filter_pkg

@../issue_body
@../schema_body
@../issue_report_body
@../csrimp/imp_body
@../../../aspen2/cms/db/tab_body
@../../../aspen2/cms/db/filter_body
@../chain/filter_body
@../chain/company_filter_body

@update_tail
