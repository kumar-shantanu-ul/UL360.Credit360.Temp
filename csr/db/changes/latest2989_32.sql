-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=32
@update_header

-- *** DDL ***
-- Create tables

CREATE GLOBAL TEMPORARY TABLE chain.tt_dedupe_cms_data (
	processed_record_id				NUMBER(10) NOT NULL,
	oracle_schema					VARCHAR2(30) NOT NULL,
	source_table					VARCHAR2(30) NOT NULL,
	source_tab_sid					NUMBER(10) NOT NULL,
	source_column					VARCHAR2(30) NOT NULL,
	source_col_sid					NUMBER(10) NOT NULL,
	source_col_type					NUMBER(10) NOT NULL,
	source_data_type				VARCHAR2(255) NULL,
	destination_table				VARCHAR2(30) NOT NULL,
	destination_tab_sid				NUMBER(10) NOT NULL,
	destination_column				VARCHAR2(30) NOT NULL,
	destination_col_sid				NUMBER(10) NOT NULL,
	destination_col_type			NUMBER(10) NOT NULL,
	destination_data_type			VARCHAR2(255) NULL,
	current_str_value				VARCHAR2(4000) NULL,
	new_str_value					VARCHAR2(4000) NULL,
	current_date_value				DATE NULL,
	new_date_value					DATE NULL,
	current_desc_val				VARCHAR2(4000) NULL,
	new_raw_value					VARCHAR2(4000) NULL,
	new_translated_value			VARCHAR2(4000) NULL
) ON COMMIT DELETE ROWS;

-- Alter tables
ALTER TABLE chain.dedupe_mapping ADD (
	destination_tab_sid				NUMBER(10, 0),
	destination_col_sid				NUMBER(10, 0),
	CONSTRAINT chk_dedupe_field_one_value_set
	CHECK ((CASE WHEN dedupe_field_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN reference_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN tag_group_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN destination_col_sid IS NOT NULL THEN 1 ELSE 0 END
		) = 1)
);
ALTER TABLE chain.dedupe_mapping DROP CONSTRAINT chk_dedupe_field_or_ref_or_tag;

ALTER TABLE chain.dedupe_merge_log ADD DESTINATION_TAB_SID	NUMBER(10, 0);
ALTER TABLE chain.dedupe_merge_log ADD DESTINATION_COL_SID	NUMBER(10, 0);
ALTER TABLE chain.dedupe_merge_log ADD error_message		VARCHAR2(255);
ALTER TABLE chain.dedupe_merge_log ADD current_desc_val		VARCHAR2(4000);
ALTER TABLE chain.dedupe_merge_log ADD new_raw_val			VARCHAR2(4000);
ALTER TABLE chain.dedupe_merge_log ADD new_translated_val	VARCHAR2(4000);

ALTER TABLE chain.dedupe_merge_log ADD CONSTRAINT CHK_DEDUPE_MERGE_ONE_VALUE_SET 
	CHECK ((CASE WHEN dedupe_field_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN reference_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN tag_group_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN destination_col_sid IS NOT NULL THEN 1 ELSE 0 END
		) = 1);
		
ALTER TABLE chain.dedupe_merge_log ADD CONSTRAINT CHK_DEDUPE_MERGE_LOG_VAL
	CHECK (new_val IS NOT NULL OR old_val IS NOT NULL OR error_message IS NOT NULL);

ALTER TABLE chain.dedupe_merge_log DROP CONSTRAINT CHK_DEDUPE_MERGE_FLD_REF_TAG;

DROP INDEX CHAIN.UK_DEDUPE_MERGE_LOG;

CREATE UNIQUE INDEX CHAIN.UK_DEDUPE_MERGE_LOG ON CHAIN.DEDUPE_MERGE_LOG (APP_SID, DEDUPE_PROCESSED_RECORD_ID, COALESCE(DEDUPE_FIELD_ID, REFERENCE_ID, TAG_GROUP_ID, DESTINATION_COL_SID));

ALTER TABLE cms.tab ADD enum_translation_tab_sid NUMBER(10,0);
	
ALTER TABLE cms.tab ADD CONSTRAINT FK_TAB_ENUM_TR_TAB_SID
	FOREIGN KEY (app_sid, enum_translation_tab_sid)
	REFERENCES cms.tab (app_sid, tab_sid);

ALTER TABLE csrimp.chain_dedupe_mapping ADD (
	destination_tab_sid				NUMBER(10, 0),
	destination_col_sid				NUMBER(10, 0)
);

ALTER TABLE csrimp.chain_dedupe_merge_log ADD (
	destination_tab_sid		NUMBER(10, 0),
	destination_col_sid		NUMBER(10, 0),
	error_message			VARCHAR2(255),
	current_desc_val		VARCHAR2(4000),
	new_raw_val				VARCHAR2(4000),
	new_translated_val		VARCHAR2(4000)
);

ALTER TABLE csrimp.cms_tab ADD enum_translation_tab_sid NUMBER(10, 0);

create index chain.ix_dedupe_processed_rec_c_comp on chain.dedupe_processed_record (app_sid, created_company_sid);
create index chain.ix_dedupe_merge_log_col_sid on chain.dedupe_merge_log (app_sid, destination_tab_sid, destination_col_sid);

-- *** Grants ***

-- ** Cross schema constraints ***

ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT FK_DEDUPE_MAPPING_COL_DEST
	FOREIGN KEY (app_sid, destination_col_sid, destination_tab_sid)
	REFERENCES cms.tab_column(app_sid, column_sid, tab_sid);
	
ALTER TABLE chain.dedupe_merge_log ADD CONSTRAINT FK_DEDUPE_MERGE_LOG_DEST
	FOREIGN KEY (app_sid, destination_col_sid, destination_tab_sid)
	REFERENCES cms.tab_column(app_sid, column_sid, tab_sid);


-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/tab_pkg
@../chain/company_dedupe_pkg
@../chain/test_chain_utils_pkg

@../../../aspen2/cms/db/tab_body
@../schema_body
@../chain/company_dedupe_body
@../chain/company_body
@../chain/test_chain_utils_body
@../csrimp/imp_body

@update_tail
