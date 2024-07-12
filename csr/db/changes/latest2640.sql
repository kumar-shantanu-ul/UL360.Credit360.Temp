-- Please update version.sql too -- this keeps clean builds in sync
define version=2640
@update_header

-- *** DDL ***
-- Create tables

CREATE GLOBAL TEMPORARY TABLE CMS.TT_ID
( 
	ID							NUMBER(10) NOT NULL
) 
ON COMMIT DELETE ROWS;

CREATE TABLE CMS.CMS_AGGREGATE_TYPE (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    CMS_AGGREGATE_TYPE_ID NUMBER(10) NOT NULL,
    TAB_SID NUMBER(10) NOT NULL,
    COLUMN_SID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(255) NOT NULL,
    ANALYTIC_FUNCTION NUMBER(10) NOT NULL,
    CONSTRAINT PK_CMS_AGGREGATE_TYPE PRIMARY KEY (APP_SID, CMS_AGGREGATE_TYPE_ID)
);

CREATE TABLE CSRIMP.CMS_AGGREGATE_TYPE (
    CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    CMS_AGGREGATE_TYPE_ID NUMBER(10) NOT NULL,
    TAB_SID NUMBER(10) NOT NULL,
    COLUMN_SID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(255) NOT NULL,
    ANALYTIC_FUNCTION NUMBER(10) NOT NULL,
    CONSTRAINT PK_CMS_AGGREGATE_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, CMS_AGGREGATE_TYPE_ID),
    CONSTRAINT FK_CMS_AGGREGATE_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_aggregate_type (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_cms_aggregate_type_id			NUMBER(10) NOT NULL,
	new_cms_aggregate_type_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_cms_aggregate_type primary key (csrimp_session_id, old_cms_aggregate_type_id) USING INDEX,
	CONSTRAINT uk_map_cms_aggregate_type unique (csrimp_session_id, new_cms_aggregate_type_id) USING INDEX,
    CONSTRAINT fk_map_cms_aggregate_type_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE SEQUENCE CMS.CMS_AGGREGATE_TYPE_ID_SEQ start with 10000 nocache;

-- Alter tables
ALTER TABLE csrimp.chain_busine_relati_type ADD (
	FORM_PATH		VARCHAR2(255),
	TAB_SID			NUMBER(10, 0),
	COLUMN_SID		NUMBER(10, 0)
);

ALTER TABLE CMS.CMS_AGGREGATE_TYPE ADD CONSTRAINT FK_CMS_AGG_TYP_TAB_SID 
    FOREIGN KEY (APP_SID, TAB_SID) REFERENCES CMS.TAB (APP_SID,TAB_SID);

ALTER TABLE CMS.CMS_AGGREGATE_TYPE ADD CONSTRAINT TAB_COLUMN_CMS_AGGREGATE_TYPE 
    FOREIGN KEY (APP_SID, COLUMN_SID) REFERENCES CMS.TAB_COLUMN (APP_SID,COLUMN_SID);

create index csr.ix_issue_region_2 on csr.issue(app_sid,region_2_sid);

ALTER TABLE chain.saved_filter_aggregation_type MODIFY aggregation_type NULL;
ALTER TABLE chain.saved_filter_aggregation_type ADD cms_aggregate_type_id NUMBER(10);
ALTER TABLE chain.saved_filter_aggregation_type ADD CONSTRAINT chk_svd_fil_agg_type
	CHECK ((aggregation_type IS NULL AND cms_aggregate_type_id IS NOT NULL)
	   OR (aggregation_type IS NOT NULL AND cms_aggregate_type_id IS NULL));


ALTER TABLE csrimp.chain_saved_filter_agg_type MODIFY aggregation_type NULL;
ALTER TABLE csrimp.chain_saved_filter_agg_type ADD cms_aggregate_type_id NUMBER(10);
ALTER TABLE csrimp.chain_saved_filter_agg_type ADD CONSTRAINT chk_svd_fil_agg_type
	CHECK ((aggregation_type IS NULL AND cms_aggregate_type_id IS NOT NULL)
	   OR (aggregation_type IS NOT NULL AND cms_aggregate_type_id IS NULL));

create index cms.ix_cms_agg_type_column on cms.cms_aggregate_type (app_sid, column_sid);
create index cms.ix_cms_agg_type_tab on cms.cms_aggregate_type (app_sid, tab_sid);
create index chain.ix_svd_fil_agg_typ_cms_agg_typ on chain.saved_filter_aggregation_type (app_sid, cms_aggregate_type_id);

ALTER TABLE CHAIN.SAVED_FILTER_AGGREGATION_TYPE DROP CONSTRAINT UK_SAVED_FIL_AGGREGATION_TYP;
ALTER TABLE CHAIN.SAVED_FILTER_AGGREGATION_TYPE ADD CONSTRAINT UK_SAVED_FIL_AGGREGATION_TYP
	UNIQUE (APP_SID, SAVED_FILTER_SID, AGGREGATION_TYPE, CMS_AGGREGATE_TYPE_ID)
;



-- *** Grants ***
GRANT EXECUTE ON cms.filter_pkg TO chain;
grant select, references on cms.cms_aggregate_type to chain;
GRANT SELECT, REFERENCES ON chain.filter TO cms;
GRANT SELECT ON chain.v$filter_field TO cms;
grant execute on chain.filter_pkg to cms;
GRANT SELECT, REFERENCES ON chain.compound_filter TO cms;
GRANT SELECT ON chain.filter_type TO cms;

GRANT SELECT, UPDATE, INSERT, DELETE ON chain.tt_filter_object_data TO cms;
grant select,insert,update,delete on csrimp.cms_aggregate_type to web_user;
grant insert on cms.cms_aggregate_type to csrimp;
grant select on cms.cms_aggregate_type_id_seq to csrimp;

-- ** Cross schema constraints ***
ALTER TABLE chain.saved_filter_aggregation_type ADD CONSTRAINT FK_SVD_FIL_AGG_TYP_CMS_AGG_TYP
	FOREIGN KEY (APP_SID, CMS_AGGREGATE_TYPE_ID)
	REFERENCES CMS.CMS_AGGREGATE_TYPE(APP_SID, CMS_AGGREGATE_TYPE_ID);

-- *** Views ***

-- *** Data changes ***
-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'CMS_AGGREGATE_TYPE'
	);
	for i in 1 .. v_list.count loop
		begin
			--dbms_output.put_line('doing '||v_name);
			dbms_rls.add_policy(
				object_schema   => 'CMS',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
				function_schema => 'CMS',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.context_sensitive );
			dbms_output.put_line('done  '||v_list(i));
		exception
			when policy_already_exists then
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policy for '||v_list(i)||' not applied as feature not enabled');
				exit;
		end;
	end loop;
end;
/

-- Data

-- output from chain.card_pkg.dumpcard
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	-- Credit360.Audit.Filters.InternalAuditFilter
	v_desc := 'CMS Filter';
	v_class := 'NPSL.Cms.Cards.CmsFilter';
	v_js_path := '/fp/cms/filters/CmsFilter.js';
	v_js_class := 'NPSL.Cms.Filters.CmsFilter';
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
	v_card_id	NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(43, 'Cms Filter', 'Allows filtering of cms tables', 'cms.filter_pkg', '/fp/cms/list.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		SELECT card_id
		  INTO v_card_id
		  FROM chain.card
		 WHERE js_class_type = 'NPSL.Cms.Filters.CmsFilter';
	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'CMS Filter', 'cms.filter_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/


INSERT INTO chain.aggregate_type (CARD_GROUP_ID, AGGREGATE_TYPE_ID, DESCRIPTION)
     VALUES (43, 1, 'Number of items');

-- ** New package grants **

-- *** Packages ***
@../../../aspen2/cms/db/filter_pkg
@../../../aspen2/cms/db/tab_pkg
@../chain/filter_pkg

@../schema_body
@../supplier_body
@../csrimp/imp_body
@../chain/business_relationship_pkg
@../chain/business_relationship_body
@../chain/filter_body

@../../../aspen2/cms/db/filter_body
@../../../aspen2/cms/db/tab_body

@update_tail
