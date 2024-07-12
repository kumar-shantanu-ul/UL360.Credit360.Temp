-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=44
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE chain.filter_page_column ADD session_prefix VARCHAR2(255);
ALTER TABLE chain.filter_item_config ADD session_prefix VARCHAR2(255);
ALTER TABLE chain.aggregate_type_config ADD session_prefix VARCHAR2(255);

ALTER TABLE csrimp.chain_filter_page_column ADD session_prefix VARCHAR2(255);
ALTER TABLE csrimp.chain_filter_item_config ADD session_prefix VARCHAR2(255);
ALTER TABLE csrimp.chain_aggregate_type_config ADD session_prefix VARCHAR2(255);


UPDATE chain.filter_page_column 
   SET session_prefix = 'csr_site_chain_supplierfilter_' || company_tab_id 
 WHERE company_tab_id IS NOT NULL AND card_group_id = 23;

UPDATE chain.filter_item_config 
   SET session_prefix = 'csr_site_chain_supplierfilter_' || company_tab_id 
 WHERE company_tab_id IS NOT NULL AND card_group_id = 23;

UPDATE chain.aggregate_type_config 
   SET session_prefix = 'csr_site_chain_supplierfilter_' || company_tab_id 
 WHERE company_tab_id IS NOT NULL AND card_group_id = 23;

UPDATE chain.filter_page_column 
   SET session_prefix = 'csr_site_audit_auditlist_' || group_key 
 WHERE group_key IS NOT NULL AND card_group_id = 41;

DROP INDEX chain.uk_filter_table_column ;
CREATE UNIQUE INDEX chain.uk_filter_table_column 
    ON chain.filter_page_column(app_sid, card_group_id, column_name, session_prefix, LOWER(group_key));

DROP INDEX chain.ix_filter_page_c_company_tab_i ;
CREATE INDEX chain.ix_filter_page_c_company_tab_i 
    ON chain.filter_page_column (app_sid, session_prefix);

	
DROP INDEX chain.uk_filter_item_config ;
CREATE UNIQUE INDEX chain.uk_filter_item_config 
    ON chain.filter_item_config(app_sid, card_group_id, card_id, item_name, session_prefix, path);

DROP INDEX chain.uk_aggregate_type_config ;
CREATE UNIQUE INDEX chain.uk_aggregate_type_config 
    ON chain.aggregate_type_config(app_sid, card_group_id, aggregate_type_id, session_prefix, path);

ALTER TABLE chain.filter_page_column DROP CONSTRAINT fk_fltr_pg_col_plugin;
ALTER TABLE chain.filter_page_column DROP COLUMN company_tab_id;

ALTER TABLE chain.filter_item_config DROP COLUMN company_tab_id;
ALTER TABLE chain.aggregate_type_config DROP COLUMN company_tab_id;


ALTER TABLE csrimp.chain_filter_page_column DROP COLUMN company_tab_id;
ALTER TABLE csrimp.chain_filter_item_config DROP COLUMN company_tab_id;
ALTER TABLE csrimp.chain_aggregate_type_config DROP COLUMN company_tab_id;

BEGIN
	security.user_pkg.logonadmin;
END;
/

DECLARE
	v_card_id			chain.card.card_id%TYPE;
	v_desc				chain.card.description%TYPE;
	v_class				chain.card.class_type%TYPE;
	v_js_path			chain.card.js_include%TYPE;
	v_js_class			chain.card.js_class_type%TYPE;
	v_css_path			chain.card.css_include%TYPE;
	v_actions			chain.T_STRING_LIST;
BEGIN
	v_desc := 'Dedupe Processed Record Filter';
	v_class := 'Credit360.Chain.Cards.Filters.DedupeProcessedRecordFilter';
	v_js_path := '/csr/site/chain/dedupe/filters/processedRecordFilter.js';
	v_js_class := 'Chain.dedupe.filters.ProcessedRecordFilter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			   SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			 WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	 WHERE card_id = v_card_id
	   AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/

DECLARE
	v_card_id						NUMBER(10);
	v_audit_filter_card_id			NUMBER(10);
	v_sid							NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(57 /*chain.filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS*/, 'Dedupe Processed Record Filter', 'Allows filtering of processed dedupe records.', 'chain.dedupe_proc_record_report_pkg', '/csr/site/chain/dedupe/processedRecords.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.dedupe.filters.ProcessedRecordFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Dedupe Processed Record Filter', 'chain.dedupe_proc_record_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT app_sid FROM chain.customer_options
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
					VALUES (r.app_sid, 57 /*chain.filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS*/, v_card_id, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/

BEGIN
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (57 /*chain.filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS*/, 1 /*chain.dedupe_proc_record_report_pkg.AGG_TYPE_COUNT*/, 'Number of records');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/

BEGIN
	BEGIN
		INSERT INTO chain.saved_filter_alert_param (card_group_id, field_name, description, translatable, link_text)
		VALUES (57, 'COMPANY_REF', 'Company ID', 0, NULL);
		
		INSERT INTO chain.saved_filter_alert_param (card_group_id, field_name, description, translatable, link_text)
		VALUES (57, 'MATCHED_TO_COMPANY_NAME', 'Matched to company name', 0, NULL);
		
		INSERT INTO chain.saved_filter_alert_param (card_group_id, field_name, description, translatable, link_text)
		VALUES (57, 'IMPORT_SOURCE_NAME', 'Import source name', 0, NULL);
		
		INSERT INTO chain.saved_filter_alert_param (card_group_id, field_name, description, translatable, link_text)
		VALUES (57, 'CREATED_COMPANY_NAME', 'Created company name', 0, NULL);
		
		INSERT INTO chain.saved_filter_alert_param (card_group_id, field_name, description, translatable, link_text)
		VALUES (57, 'BATCH_NUM', 'Batch number', 0, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
CREATE OR REPLACE PACKAGE chain.dedupe_proc_record_report_pkg AS END;
/

GRANT EXECUTE ON chain.dedupe_proc_record_report_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/filter_pkg
@../chain/dedupe_admin_pkg
@../chain/dedupe_proc_record_report_pkg

@../chain/filter_body
@../chain/plugin_body
@../chain/dedupe_admin_body
@../chain/dedupe_proc_record_report_body
@../chain/setup_body
@../schema_body
@../csrimp/imp_body

@update_tail
