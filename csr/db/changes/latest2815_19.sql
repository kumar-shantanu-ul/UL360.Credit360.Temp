-- Please update version.sql too -- this keeps clean builds in sync
define version=2815
define minor_version=19
@update_header

-- *** DDL ***
CREATE SEQUENCE chain.filter_page_ind_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;
	

CREATE SEQUENCE chain.filter_page_ind_intrval_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;
	
CREATE SEQUENCE chain.customer_aggregate_type_id_seq
    START WITH 10000
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

-- Create tables
CREATE TABLE chain.filter_page_ind (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	filter_page_ind_id				NUMBER(10) NOT NULL,
	card_group_id					NUMBER(10) NOT NULL,
	ind_sid							NUMBER(10) NOT NULL,
	period_set_id					NUMBER(10) NOT NULL,
	period_interval_id				NUMBER(10) NOT NULL,
	start_dtm						DATE,
	end_dtm							DATE,
	previous_n_intervals			NUMBER(10),
	include_in_list					NUMBER(1) DEFAULT 1 NOT NULL,
	include_in_filter				NUMBER(1) DEFAULT 1 NOT NULL,
	include_in_aggregates			NUMBER(1) DEFAULT 0 NOT NULL,
	include_in_breakdown			NUMBER(1) DEFAULT 0 NOT NULL,
	show_measure_in_description		NUMBER(1) DEFAULT 1 NOT NULL,
	show_interval_in_description	NUMBER(1) DEFAULT 1 NOT NULL,
	description_override			VARCHAR2(1023),
	CONSTRAINT pk_filter_page_ind PRIMARY KEY (app_sid, filter_page_ind_id),	
	CONSTRAINT chk_fltr_pg_ind_dtm_or_intrvl CHECK (
		(start_dtm IS NOT NULL AND end_dtm IS NOT NULL AND previous_n_intervals IS NULL) OR 
		(start_dtm IS NULL AND end_dtm IS NULL AND previous_n_intervals IS NOT NULL)),	
	CONSTRAINT chk_fltr_pg_ind_intrvl_gt_0 CHECK (previous_n_intervals IS NULL OR previous_n_intervals > 0),
	CONSTRAINT chk_fltr_pg_ind_inc_list_1_0 CHECK (include_in_list IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_inc_fltr_1_0 CHECK (include_in_filter IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_inc_agg_1_0 CHECK (include_in_aggregates IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_inc_brkdwn_1_0 CHECK (include_in_breakdown IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_shw_msre_1_0 CHECK (show_measure_in_description IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_shw_intrvl_1_0 CHECK (show_interval_in_description IN (1,0)),
	CONSTRAINT fk_filter_page_ind_card_group FOREIGN KEY (card_group_id)
		REFERENCES chain.card_group (card_group_id),
	CONSTRAINT fk_filter_page_ind_ind FOREIGN KEY (app_sid, ind_sid)
		REFERENCES csr.ind (app_sid, ind_sid),
	CONSTRAINT fk_filter_page_ind_prd_inrtvl FOREIGN KEY (app_sid, period_set_id, period_interval_id)
		REFERENCES csr.period_interval (app_sid, period_set_id, period_interval_id)
);

CREATE INDEX chain.ix_filter_page_ind_card_group ON chain.filter_page_ind (app_sid, card_group_id);

CREATE UNIQUE INDEX chain.uk_filter_page_ind ON chain.filter_page_ind (
		app_sid, card_group_id, ind_sid, period_set_id, period_interval_id, 
		start_dtm, end_dtm, previous_n_intervals);
		
CREATE TABLE chain.filter_page_ind_interval (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	filter_page_ind_interval_id		NUMBER(10) NOT NULL,
	filter_page_ind_id				NUMBER(10) NOT NULL,
	start_dtm						DATE,
	current_interval_offset			NUMBER(10),
	CONSTRAINT pk_filter_page_ind_interval PRIMARY KEY (app_sid, filter_page_ind_interval_id),	
	CONSTRAINT chk_fltr_pg_i_itvl_dtm_or_itvl CHECK (
		(start_dtm IS NOT NULL AND current_interval_offset IS NULL) OR 
		(start_dtm IS NULL AND current_interval_offset IS NOT NULL)),
	CONSTRAINT fk_ftr_pg_ind_intvl_ftr_pg_ind FOREIGN KEY (app_sid, filter_page_ind_id)
		REFERENCES chain.filter_page_ind (app_sid, filter_page_ind_id)
);

CREATE UNIQUE INDEX chain.uk_filter_page_ind_interval ON chain.filter_page_ind_interval (
		app_sid, filter_page_ind_id, start_dtm, current_interval_offset);

CREATE GLOBAL TEMPORARY TABLE chain.tt_filter_ind_val (
	filter_page_ind_interval_id	NUMBER(10,0) NOT NULL,
	region_sid			NUMBER(10,0) NOT NULL,
	ind_sid				NUMBER(10,0) NOT NULL,
	period_start_dtm	DATE NOT NULL,
	period_end_dtm		DATE NOT NULL,
	val_number			NUMBER(24,10),
	error_code			NUMBER(10,0),
	note				CLOB
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE chain.tt_filter_id (
	ID							NUMBER(10) NOT NULL
)
ON COMMIT DELETE ROWS;

CREATE TABLE chain.customer_aggregate_type (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	card_group_id					NUMBER(10) NOT NULL,
	customer_aggregate_type_id		NUMBER(10) NOT NULL,
	cms_aggregate_type_id			NUMBER(10),
	initiative_metric_id			NUMBER(10),
	ind_sid							NUMBER(10),
	filter_page_ind_interval_id		NUMBER(10),
	CONSTRAINT pk_customer_aggregate_type PRIMARY KEY (app_sid, customer_aggregate_type_id),
	CONSTRAINT fk_custom_agg_type_card_group FOREIGN KEY (card_group_id)
		REFERENCES chain.card_group (card_group_id),
	CONSTRAINT fk_custom_agg_type_cms_agg_typ FOREIGN KEY (app_sid, cms_aggregate_type_id)
		REFERENCES cms.cms_aggregate_type(app_sid, cms_aggregate_type_id)
		ON DELETE CASCADE,
	CONSTRAINT  fk_custom_agg_type_init_metric FOREIGN KEY (app_sid, initiative_metric_id)
		REFERENCES csr.initiative_metric(app_sid, initiative_metric_id)
		ON DELETE CASCADE,
	CONSTRAINT fk_custom_agg_type_ind FOREIGN KEY (app_sid, ind_sid)
		REFERENCES csr.ind(app_sid, ind_sid)
		ON DELETE CASCADE,
	CONSTRAINT fk_cstm_agg_typ_fltr_pg_i_itvl FOREIGN KEY (app_sid, filter_page_ind_interval_id)
		REFERENCES chain.filter_page_ind_interval (app_sid, filter_page_ind_interval_id)
		ON DELETE CASCADE,
	CONSTRAINT chk_customer_aggregate_type
	CHECK ((cms_aggregate_type_id IS NOT NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NOT NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NOT NULL AND filter_page_ind_interval_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NOT NULL))
);

CREATE UNIQUE INDEX chain.uk_customer_aggregate_type ON chain.customer_aggregate_type (
		app_sid, card_group_id, cms_aggregate_type_id, initiative_metric_id, ind_sid, filter_page_ind_interval_id);

CREATE TABLE csrimp.chain_filter_page_ind (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	filter_page_ind_id				NUMBER(10) NOT NULL,
	card_group_id					NUMBER(10) NOT NULL,
	ind_sid							NUMBER(10) NOT NULL,
	period_set_id					NUMBER(10) NOT NULL,
	period_interval_id				NUMBER(10) NOT NULL,
	start_dtm						DATE,
	end_dtm							DATE,
	previous_n_intervals			NUMBER(10),
	include_in_list					NUMBER(1) NOT NULL,
	include_in_filter				NUMBER(1) NOT NULL,
	include_in_aggregates			NUMBER(1) NOT NULL,
	include_in_breakdown			NUMBER(1) NOT NULL,
	show_measure_in_description		NUMBER(1) NOT NULL,
	show_interval_in_description	NUMBER(1) NOT NULL,
	description_override			VARCHAR2(1023),
	CONSTRAINT pk_filter_page_ind PRIMARY KEY (csrimp_session_id, filter_page_ind_id),	
	CONSTRAINT chk_fltr_pg_ind_dtm_or_intrvl CHECK (
		(start_dtm IS NOT NULL AND end_dtm IS NOT NULL AND previous_n_intervals IS NULL) OR 
		(start_dtm IS NULL AND end_dtm IS NULL AND previous_n_intervals IS NOT NULL)),	
	CONSTRAINT chk_fltr_pg_ind_intrvl_gt_0 CHECK (previous_n_intervals IS NULL OR previous_n_intervals > 0),
	CONSTRAINT chk_fltr_pg_ind_inc_list_1_0 CHECK (include_in_list IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_inc_fltr_1_0 CHECK (include_in_filter IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_inc_agg_1_0 CHECK (include_in_aggregates IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_inc_brkdwn_1_0 CHECK (include_in_breakdown IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_shw_msre_1_0 CHECK (show_measure_in_description IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_shw_intrvl_1_0 CHECK (show_interval_in_description IN (1,0)),
	CONSTRAINT fk_chain_filter_page_ind_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX csrimp.uk_chain_filter_page_ind ON csrimp.chain_filter_page_ind (
		csrimp_session_id, card_group_id, ind_sid, period_set_id, period_interval_id, 
		start_dtm, end_dtm, previous_n_intervals);
		
CREATE TABLE csrimp.chain_filter_page_ind_interval (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	filter_page_ind_interval_id		NUMBER(10) NOT NULL,
	filter_page_ind_id				NUMBER(10) NOT NULL,
	start_dtm						DATE,
	current_interval_offset			NUMBER(10),
	CONSTRAINT pk_filter_page_ind_interval PRIMARY KEY (csrimp_session_id, filter_page_ind_interval_id),	
	CONSTRAINT chk_fltr_pg_i_itvl_dtm_or_itvl CHECK (
		(start_dtm IS NOT NULL AND current_interval_offset IS NULL) OR 
		(start_dtm IS NULL AND current_interval_offset IS NOT NULL)),
	CONSTRAINT fk_chain_fltr_page_ind_itvl_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX csrimp.uk_chain_filter_page_ind_itvl ON csrimp.chain_filter_page_ind_interval (
		csrimp_session_id, filter_page_ind_id, start_dtm, current_interval_offset);
		
CREATE TABLE csrimp.chain_customer_aggregate_type (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	card_group_id					NUMBER(10) NOT NULL,
	customer_aggregate_type_id		NUMBER(10) NOT NULL,
	cms_aggregate_type_id			NUMBER(10),
	initiative_metric_id			NUMBER(10),
	ind_sid							NUMBER(10),
	filter_page_ind_interval_id		NUMBER(10),
	CONSTRAINT pk_customer_aggregate_type PRIMARY KEY (csrimp_session_id, customer_aggregate_type_id),
	CONSTRAINT chk_customer_aggregate_type
	CHECK ((cms_aggregate_type_id IS NOT NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NOT NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NOT NULL AND filter_page_ind_interval_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NOT NULL))
);

CREATE UNIQUE INDEX csrimp.uk_customer_aggregate_type ON csrimp.chain_customer_aggregate_type (
		csrimp_session_id, card_group_id, cms_aggregate_type_id, initiative_metric_id, ind_sid, filter_page_ind_interval_id);
		
CREATE TABLE CSRIMP.MAP_CHAIN_FILTER_PAGE_IND (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILTER_PAGE_IND_ID NUMBER(10) NOT NULL,
	NEW_FILTER_PAGE_IND_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FILTER_PAGE_IND PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILTER_PAGE_IND_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FILTER_PAGE_IND UNIQUE (CSRIMP_SESSION_ID, NEW_FILTER_PAGE_IND_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_FLTR_PAGE_IND_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_FLTR_PAGE_IND_INTRVL (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILTER_PAGE_IND_INTRVL_ID NUMBER(10) NOT NULL,
	NEW_FILTER_PAGE_IND_INTRVL_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FLTR_PG_IND_INTVL PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILTER_PAGE_IND_INTRVL_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FLTR_PG_IND_INTVL UNIQUE (CSRIMP_SESSION_ID, NEW_FILTER_PAGE_IND_INTRVL_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_FLTR_PG_IND_I_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_CUSTOM_AGG_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CUSTOMER_AGGREGATE_TYPE_ID NUMBER(10) NOT NULL,
	NEW_CUSTOMER_AGGREGATE_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CUSTOM_AGG_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CUSTOMER_AGGREGATE_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CUSTOM_AGG_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_CUSTOMER_AGGREGATE_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CUSTOM_AGG_TYP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


-- Alter tables

-- Restructure this to use the join table, so populate join table, update table to reference those rows, then drop the old columns
ALTER TABLE chain.saved_filter_aggregation_type ADD (
	customer_aggregate_type_id		NUMBER(10),
	CONSTRAINT fk_svd_fil_agg_typ_cus_agg_typ FOREIGN KEY (app_sid, customer_aggregate_type_id)
		REFERENCES chain.customer_aggregate_type (app_sid, customer_aggregate_type_id)
);

-- create entries for all current agg types
BEGIN
	security.user_pkg.LogonAdmin;	
	
	-- cms agg types
	INSERT INTO chain.customer_aggregate_type (app_sid, card_group_id, customer_aggregate_type_id, cms_aggregate_type_id)
		 SELECT app_sid, 43, chain.customer_aggregate_type_id_seq.NEXTVAL, cms_aggregate_type_id
		   FROM cms.cms_aggregate_type;
		   
	-- numeric region metrics
	INSERT INTO chain.customer_aggregate_type (app_sid, card_group_id, customer_aggregate_type_id, ind_sid)
		 SELECT rtm.app_sid, 44, chain.customer_aggregate_type_id_seq.NEXTVAL, rtm.ind_sid
		   FROM csr.region_type_metric rtm
		   JOIN csr.ind i ON rtm.app_sid = i.app_sid AND rtm.ind_sid = i.ind_sid
		   JOIN csr.measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
		  WHERE m.custom_field IS NULL
		    AND rtm.region_type = 3;
		   
	-- initiative metrics
	INSERT INTO chain.customer_aggregate_type (app_sid, card_group_id, customer_aggregate_type_id, initiative_metric_id)
		 SELECT app_sid, 45, chain.customer_aggregate_type_id_seq.NEXTVAL, initiative_metric_id
		   FROM csr.initiative_metric;
		   
	UPDATE chain.saved_filter_aggregation_type sfag
	   SET customer_aggregate_type_id = (
		SELECT customer_aggregate_type_id
		  FROM chain.customer_aggregate_type cat
		 WHERE sfag.app_sid = cat.app_sid
		   AND (sfag.cms_aggregate_type_id = cat.cms_aggregate_type_id
		    OR sfag.initiative_metric_id = cat.initiative_metric_id
			OR sfag.ind_sid = cat.ind_sid)
	  )
	 WHERE aggregation_type IS NULL;
END;
/

BEGIN
	FOR r IN (
		SELECT constraint_name 
		  FROM all_constraints 
		 WHERE owner='CHAIN' 
		   AND constraint_name='CHK_SVD_FIL_AGG_TYPE' 
		   AND table_name='SAVED_FILTER_AGGREGATION_TYPE'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE chain.saved_filter_aggregation_type DROP CONSTRAINT chk_svd_fil_agg_type';
	END LOOP;
END;
/
ALTER TABLE chain.saved_filter_aggregation_type ADD CONSTRAINT chk_svd_fil_agg_type
	CHECK ((aggregation_type IS NOT NULL AND customer_aggregate_type_id IS NULL)
	   OR (aggregation_type IS NULL AND customer_aggregate_type_id IS NOT NULL));
	   

ALTER TABLE chain.saved_filter_aggregation_type DROP CONSTRAINT UK_SAVED_FIL_AGGREGATION_TYP;
ALTER TABLE CHAIN.SAVED_FILTER_AGGREGATION_TYPE ADD CONSTRAINT UK_SAVED_FIL_AGGREGATION_TYP
	UNIQUE (APP_SID, SAVED_FILTER_SID, AGGREGATION_TYPE, CUSTOMER_AGGREGATE_TYPE_ID)
;

ALTER TABLE chain.saved_filter_aggregation_type DROP CONSTRAINT fk_svd_fil_agg_typ_cms_agg_typ;
ALTER TABLE chain.saved_filter_aggregation_type DROP CONSTRAINT fk_svd_fil_agg_typ_ind;
ALTER TABLE chain.saved_filter_aggregation_type DROP CONSTRAINT fk_svd_fil_agg_typ_init_metric;
ALTER TABLE chain.saved_filter_aggregation_type DROP COLUMN cms_aggregate_type_id;
ALTER TABLE chain.saved_filter_aggregation_type DROP COLUMN ind_sid;
ALTER TABLE chain.saved_filter_aggregation_type DROP COLUMN initiative_metric_id;


ALTER TABLE csrimp.chain_saved_filter_agg_type ADD (
	customer_aggregate_type_id		NUMBER(10)
);

ALTER TABLE csrimp.chain_saved_filter_agg_type DROP CONSTRAINT chk_svd_fil_agg_type;
ALTER TABLE csrimp.chain_saved_filter_agg_type ADD CONSTRAINT chk_svd_fil_agg_type
	CHECK ((aggregation_type IS NOT NULL AND customer_aggregate_type_id IS NULL)
	   OR (aggregation_type IS NULL AND customer_aggregate_type_id IS NOT NULL));
	   

ALTER TABLE csrimp.chain_saved_filter_agg_type DROP CONSTRAINT UK_CHAIN_SAVED_FIL_AGG_TYP;
ALTER TABLE csrimp.chain_saved_filter_agg_type ADD CONSTRAINT UK_CHAIN_SAVED_FIL_AGG_TYP
	UNIQUE (CSRIMP_SESSION_ID, SAVED_FILTER_SID, AGGREGATION_TYPE, CUSTOMER_AGGREGATE_TYPE_ID)
;

ALTER TABLE csrimp.chain_saved_filter_agg_type DROP COLUMN cms_aggregate_type_id;
ALTER TABLE csrimp.chain_saved_filter_agg_type DROP COLUMN initiative_metric_id;
ALTER TABLE csrimp.chain_saved_filter_agg_type DROP COLUMN ind_sid;

CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_ROW AS 
	 OBJECT ( 
		CARD_GROUP_ID				NUMBER(10),
		AGGREGATE_TYPE_ID			NUMBER(10),	
		DESCRIPTION 				VARCHAR2(1023),
		FORMAT_MASK					VARCHAR2(255),
		FILTER_PAGE_IND_INTERVAL_ID	NUMBER(10)
	 ); 
/

CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_TABLE AS 
	TABLE OF CHAIN.T_FILTER_AGG_TYPE_ROW;
/

CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_THRES_ROW AS 
	 OBJECT ( 
		AGGREGATE_TYPE_ID				NUMBER(10),
		MAX_VALUE						NUMBER(15, 5),	
		LABEL 							VARCHAR2(255),
		ICON_URL						VARCHAR2(255),
		ICON_DATA						BLOB,
		TEXT_COLOUR						NUMBER(10),
		BACKGROUND_COLOUR				NUMBER(10),
		BAR_COLOUR						NUMBER(10)
	 ); 
/

CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_THRES_TABLE AS 
	TABLE OF CHAIN.T_FILTER_AGG_TYPE_THRES_ROW;
/

-- *** Grants ***
GRANT SELECT ON chain.tt_filter_ind_val TO csr;
GRANT SELECT ON chain.filter_page_ind TO csr;
GRANT SELECT ON chain.filter_page_ind_interval TO csr;
GRANT SELECT ON chain.tt_filter_id TO csr;
GRANT SELECT, REFERENCES ON csr.measure TO chain;
GRANT EXECUTE ON csr.utils_pkg TO chain;
GRANT EXECUTE ON csr.t_split_table TO chain;
grant select, insert, update on chain.filter_page_ind to csrimp;
grant select, insert, update on chain.filter_page_ind_interval to csrimp;
grant select, insert, update on chain.customer_aggregate_type to csrimp;
grant select on chain.filter_page_ind_id_seq to csrimp;
grant select on chain.filter_page_ind_intrval_id_seq to csrimp;
grant select on chain.customer_aggregate_type_id_seq to csrimp;
grant select, insert, update, delete on csrimp.chain_filter_page_ind to web_user;
grant select, insert, update, delete on csrimp.chain_filter_page_ind_interval to web_user;
grant select, insert, update, delete on csrimp.chain_customer_aggregate_type to web_user;
grant select on chain.customer_aggregate_type to cms;
grant select on chain.customer_aggregate_type to csr;

grant execute on chain.t_filter_agg_type_table TO csr;
grant execute on chain.t_filter_agg_type_row TO csr;
grant execute on chain.t_filter_agg_type_thres_table TO csr;
grant execute on chain.t_filter_agg_type_thres_row TO csr;
grant execute on chain.t_filter_agg_type_table TO cms;
grant execute on chain.t_filter_agg_type_row TO cms;
grant execute on chain.t_filter_agg_type_thres_table TO cms;
grant execute on chain.t_filter_agg_type_thres_row TO cms;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
		   AND t.table_name IN ('CHAIN_FILTER_PAGE_IND', 'CHAIN_FILTER_PAGE_IND_INTERVAL', 'MAP_CHAIN_FILTER_PAGE_IND', 
		   'MAP_CHAIN_FLTR_PAGE_IND_INTRVL', 'MAP_CHAIN_CUSTOM_AGG_TYPE', 'CHAIN_CUSTOMER_AGGREGATE_TYPE')
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
		'FILTER_PAGE_IND',
		'FILTER_PAGE_IND_INTERVAL',
		'CUSTOMER_AGGREGATE_TYPE'
    );
    FOR I IN 1 .. v_list.count
 	LOOP
		BEGIN
			dbms_rls.add_policy(
				object_schema   => 'CHAIN',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 23) || '_POLICY', 
				function_schema => 'CHAIN',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.context_sensitive);
		EXCEPTION WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
		END;
	END LOOP;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');	
END;
/

-- Data

-- ** New package grants **

-- *** Packages ***
@../audit_report_pkg
@../chain/company_filter_pkg
@../chain/filter_pkg
@../initiative_report_pkg
@../initiative_metric_pkg
@../issue_report_pkg
@../non_compliance_report_pkg
@../property_report_pkg
@../schema_pkg

@../audit_report_body
@../chain/chain_body
@../chain/company_filter_body
@../chain/filter_body
@../csrimp/imp_body
@../initiative_report_body
@../initiative_metric_body
@../issue_report_body
@../non_compliance_report_body
@../property_report_body
@../region_metric_body
@../schema_body
@../../../aspen2/cms/db/filter_body

@update_tail
