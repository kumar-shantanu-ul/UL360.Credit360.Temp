-- Please update version.sql too -- this keeps clean builds in sync
define version=2747
define minor_version=1
@update_header

-- Clean
--ALTER TABLE csr.dataview DROP COLUMN version_num;
--ALTER TABLE csrimp.dataview DROP COLUMN version_num;
--DROP TABLE csr.dataview_history;
--DROP TABLE csrimp.dataview_history;
--ALTER TABLE csr.customer DROP COLUMN max_dataview_history;
--ALTER TABLE csrimp.customer DROP COLUMN max_dataview_history;

-- *** DDL ***
-- Create tables
CREATE TABLE csr.dataview_history (
    app_sid NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL, 
    dataview_sid NUMBER(10,0) NOT NULL,    
    version_num NUMBER(10,0) NOT NULL,
    name VARCHAR2(256) NOT NULL,
    start_dtm DATE NOT NULL, 
	end_dtm DATE, 
	group_by VARCHAR2(128) NOT NULL, 
	chart_config_xml CLOB, 
	chart_style_xml CLOB, 
	pos NUMBER(10,0) NOT NULL, 
	description VARCHAR2(2048), 
	dataview_type_id NUMBER(6,0) NOT NULL, 
	use_unmerged NUMBER(1,0) NOT NULL, 
	use_backfill NUMBER(1,0) NOT NULL, 
	use_pending NUMBER(1,0) NOT NULL, 
	show_calc_trace NUMBER(1,0) NOT NULL, 
	show_variance NUMBER(1,0) NOT NULL, 
	sort_by_most_recent NUMBER(1,0) NOT NULL, 
	include_parent_region_names NUMBER(10,0) NOT NULL, 
	last_updated_dtm DATE NOT NULL, 
	last_updated_sid NUMBER(10,0), 
	rank_filter_type NUMBER(10,0) NOT NULL, 
	rank_limit_left NUMBER(10,0) NOT NULL, 
	rank_ind_sid NUMBER(10,0), 
	rank_limit_right NUMBER(10,0) NOT NULL, 
	rank_limit_left_type NUMBER(10,0) NOT NULL, 
	rank_limit_right_type NUMBER(10,0) NOT NULL, 
	rank_reverse NUMBER(1,0) NOT NULL, 
	region_grouping_tag_group NUMBER(10,0), 
	anonymous_region_names NUMBER(1,0) NOT NULL, 
	include_notes_in_table NUMBER(1,0) NOT NULL, 
	show_region_events NUMBER(1,0) NOT NULL, 
	suppress_unmerged_data_message NUMBER(1,0) NOT NULL, 
	period_set_id NUMBER(10,0) NOT NULL, 
	period_interval_id NUMBER(10,0) NOT NULL, 
    CONSTRAINT pk_dataview_history PRIMARY KEY (app_sid, dataview_sid, version_num),
    CONSTRAINT fk_dataview_hst_user FOREIGN KEY (app_sid, last_updated_sid) 
        REFERENCES csr.csr_user (app_sid, csr_user_sid),
    CONSTRAINT fk_dataview_hst_cmr FOREIGN KEY (app_sid) 
        REFERENCES csr.customer (app_sid)
    -- no other constraints (this is just a history table, orphaning is okay)
);

CREATE TABLE csrimp.dataview_history (
	csrimp_session_id NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    dataview_sid NUMBER(10,0) NOT NULL,    
    version_num NUMBER(10,0) NOT NULL,
    name VARCHAR2(256) NOT NULL,
    start_dtm DATE NOT NULL, 
	end_dtm DATE, 
	group_by VARCHAR2(128) NOT NULL, 
	chart_config_xml CLOB, 
	chart_style_xml CLOB, 
	pos NUMBER(10,0) NOT NULL, 
	description VARCHAR2(2048), 
	dataview_type_id NUMBER(6,0) NOT NULL, 
	use_unmerged NUMBER(1,0) NOT NULL, 
	use_backfill NUMBER(1,0) NOT NULL, 
	use_pending NUMBER(1,0) NOT NULL, 
	show_calc_trace NUMBER(1,0) NOT NULL, 
	show_variance NUMBER(1,0) NOT NULL, 
	sort_by_most_recent NUMBER(1,0) NOT NULL, 
	include_parent_region_names NUMBER(10,0) NOT NULL, 
	last_updated_dtm DATE NOT NULL, 
	last_updated_sid NUMBER(10,0), 
	rank_filter_type NUMBER(10,0) NOT NULL, 
	rank_limit_left NUMBER(10,0) NOT NULL, 
	rank_ind_sid NUMBER(10,0), 
	rank_limit_right NUMBER(10,0) NOT NULL, 
	rank_limit_left_type NUMBER(10,0) NOT NULL, 
	rank_limit_right_type NUMBER(10,0) NOT NULL, 
	rank_reverse NUMBER(1,0) NOT NULL, 
	region_grouping_tag_group NUMBER(10,0), 
	anonymous_region_names NUMBER(1,0) NOT NULL, 
	include_notes_in_table NUMBER(1,0) NOT NULL, 
	show_region_events NUMBER(1,0) NOT NULL, 
	suppress_unmerged_data_message NUMBER(1,0) NOT NULL, 
	period_set_id NUMBER(10,0) NOT NULL, 
	period_interval_id NUMBER(10,0) NOT NULL, 
    CONSTRAINT pk_dataview_history PRIMARY KEY (csrimp_session_id, dataview_sid, version_num),
    CONSTRAINT fk_dataview_history_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.dataview ADD version_num NUMBER(10,0) NULL;
ALTER TABLE csrimp.dataview ADD version_num NUMBER(10, 0) NULL;
ALTER TABLE csr.customer ADD max_dataview_history NUMBER(10, 0) DEFAULT 0 NULL;
ALTER TABLE csrimp.customer ADD max_dataview_history NUMBER(10, 0) DEFAULT 0 NULL;

-- *** Grants ***
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.dataview_history TO web_user;
GRANT INSERT ON csr.dataview_history TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../dataview_body
@../templated_report_body
@../csr_app_body
@../schema_pkg
@../schema_body
@../csrimp/imp_body

@update_tail
