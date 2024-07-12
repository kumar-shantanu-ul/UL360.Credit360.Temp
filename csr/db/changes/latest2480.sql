-- Please update version.sql too -- this keeps clean builds in sync
define version=2480
@update_header

-- *** DDL ***

CREATE OR REPLACE TYPE CHAIN.T_BUS_REL_COMP_ROW AS
	OBJECT (
		BUSINESS_RELATIONSHIP_ID	NUMBER(10),
		BUSINESS_RELATIONSHIP_TIER_ID	NUMBER(10),
		COMPANY_SID					NUMBER(10),
		MAP MEMBER FUNCTION MAP
			RETURN VARCHAR2
	);
/

CREATE OR REPLACE TYPE BODY CHAIN.T_BUS_REL_COMP_ROW AS
	MAP MEMBER FUNCTION MAP
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN BUSINESS_RELATIONSHIP_ID||'/'||BUSINESS_RELATIONSHIP_TIER_ID;
	END;
END;
/

CREATE OR REPLACE TYPE CHAIN.T_BUS_REL_COMP_TABLE AS
	TABLE OF CHAIN.T_BUS_REL_COMP_ROW;
/

CREATE OR REPLACE TYPE CHAIN.T_BUS_REL_PATH_ROW AS
OBJECT (
		BUSINESS_RELATIONSHIP_ID	NUMBER(10),
		START_TIER					NUMBER(10),
		START_COMPANY_SID			NUMBER(10),
		PATH_SIDS					VARCHAR2(1000),
		END_TIER					NUMBER(10),
		END_COMPANY_SID				NUMBER(10),
		MAP MEMBER FUNCTION MAP
			RETURN VARCHAR2
	);
/

CREATE OR REPLACE TYPE BODY CHAIN.T_BUS_REL_PATH_ROW AS
	MAP MEMBER FUNCTION MAP
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN BUSINESS_RELATIONSHIP_ID||':'||START_TIER||'-'||END_TIER;
	END;
END;
/

CREATE OR REPLACE TYPE CHAIN.T_BUS_REL_PATH_TABLE AS
	TABLE OF CHAIN.T_BUS_REL_PATH_ROW;
/


-- Create tables

CREATE SEQUENCE CHAIN.BUSINESS_REL_TYPE_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE TABLE CHAIN.BUSINESS_RELATIONSHIP_TYPE (
    APP_SID							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BUSINESS_RELATIONSHIP_TYPE_ID	NUMBER(10,0) NOT NULL,
	LABEL							VARCHAR2(255) NOT NULL,
    CONSTRAINT PK_BUSINESS_RELATIONSHIP_TYPE PRIMARY KEY (APP_SID, BUSINESS_RELATIONSHIP_TYPE_ID)
);

CREATE SEQUENCE CHAIN.BUSINESS_REL_TIER_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE TABLE CHAIN.BUSINESS_RELATIONSHIP_TIER (
    APP_SID							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BUSINESS_RELATIONSHIP_TYPE_ID	NUMBER(10,0) NOT NULL,
	BUSINESS_RELATIONSHIP_TIER_ID	NUMBER(10,0) NOT NULL,
	TIER							NUMBER(10,0) NOT NULL,
	LABEL							VARCHAR2(255) NOT NULL,
	DIRECT_FROM_PREVIOUS_TIER		NUMBER(1),
    CONSTRAINT PK_BUSINESS_RELATIONSHIP_TIER PRIMARY KEY (APP_SID, BUSINESS_RELATIONSHIP_TIER_ID),
	CONSTRAINT FK_BUS_REL_TIER_BUS_REL_TYPE FOREIGN KEY (APP_SID, BUSINESS_RELATIONSHIP_TYPE_ID) REFERENCES CHAIN.BUSINESS_RELATIONSHIP_TYPE (APP_SID, BUSINESS_RELATIONSHIP_TYPE_ID),
	CONSTRAINT UK_BUS_REL_TIER_TIER UNIQUE(APP_SID, BUSINESS_RELATIONSHIP_TYPE_ID, TIER),
	CONSTRAINT CK_BUS_REL_TIER_TIER CHECK (TIER > 0),
	CONSTRAINT CK_BUS_REL_TIER_DIRECT CHECK (
		(TIER = 1 AND DIRECT_FROM_PREVIOUS_TIER IS NULL) OR
		(TIER > 1 AND DIRECT_FROM_PREVIOUS_TIER IN (0, 1))
	)
);

CREATE TABLE CHAIN.BUSINESS_REL_TIER_COMPANY_TYPE (
    APP_SID							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BUSINESS_RELATIONSHIP_TIER_ID	NUMBER(10,0) NOT NULL,
	COMPANY_TYPE_ID					NUMBER(10,0) NOT NULL,
    CONSTRAINT PK_BUS_REL_TIER_COMP_TYPE PRIMARY KEY (APP_SID, BUSINESS_RELATIONSHIP_TIER_ID, COMPANY_TYPE_ID),
	CONSTRAINT FK_BUS_REL_TIER_COMP_TYPE_TIER FOREIGN KEY (APP_SID, BUSINESS_RELATIONSHIP_TIER_ID) REFERENCES CHAIN.BUSINESS_RELATIONSHIP_TIER (APP_SID, BUSINESS_RELATIONSHIP_TIER_ID),
	CONSTRAINT FK_BUS_REL_TIER_COMP_TYPE_COMP FOREIGN KEY (APP_SID, COMPANY_TYPE_ID) REFERENCES CHAIN.COMPANY_TYPE (APP_SID, COMPANY_TYPE_ID)
);

CREATE SEQUENCE CHAIN.BUSINESS_RELATIONSHIP_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE TABLE CHAIN.BUSINESS_RELATIONSHIP (
    APP_SID							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BUSINESS_RELATIONSHIP_ID		NUMBER(10,0) NOT NULL,
	BUSINESS_RELATIONSHIP_TYPE_ID	NUMBER(10,0) NOT NULL,
	START_DTM						DATE NOT NULL,
	END_DTM							DATE,
	END_REASON						CLOB,
    CONSTRAINT PK_BUSINESS_RELATIONSHIP PRIMARY KEY (APP_SID, BUSINESS_RELATIONSHIP_ID),
	CONSTRAINT FK_BUS_REL_BUS_REL_TYPE FOREIGN KEY (APP_SID, BUSINESS_RELATIONSHIP_TYPE_ID) REFERENCES CHAIN.BUSINESS_RELATIONSHIP_TYPE (APP_SID, BUSINESS_RELATIONSHIP_TYPE_ID)
);

CREATE TABLE CHAIN.BUSINESS_RELATIONSHIP_COMPANY (
    APP_SID							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BUSINESS_RELATIONSHIP_ID		NUMBER(10,0) NOT NULL,
	BUSINESS_RELATIONSHIP_TIER_ID	NUMBER(10,0) NOT NULL,
	COMPANY_SID						NUMBER(10,0) NOT NULL,
    CONSTRAINT PK_BUS_REL_COMPANY PRIMARY KEY (APP_SID, BUSINESS_RELATIONSHIP_ID, BUSINESS_RELATIONSHIP_TIER_ID),
    CONSTRAINT UK_BUS_REL_COMPANY_COMPANY UNIQUE (APP_SID, BUSINESS_RELATIONSHIP_ID, COMPANY_SID),
    CONSTRAINT FK_BUS_REL_COMPANY_BUS_REL FOREIGN KEY (APP_SID, BUSINESS_RELATIONSHIP_ID) REFERENCES CHAIN.BUSINESS_RELATIONSHIP (APP_SID, BUSINESS_RELATIONSHIP_ID),
	CONSTRAINT FK_BUS_REL_COMPANY_TIER FOREIGN KEY (APP_SID, BUSINESS_RELATIONSHIP_TIER_ID) REFERENCES CHAIN.BUSINESS_RELATIONSHIP_TIER (APP_SID, BUSINESS_RELATIONSHIP_TIER_ID),
    CONSTRAINT FK_BUS_REL_COMPANY_COMPANY FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CHAIN.COMPANY (APP_SID, COMPANY_SID)
);

-- csrimp data tables
CREATE TABLE CSRIMP.CHAIN_BUSINE_RELATI_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	BUSINESS_RELATIONSHIP_TYPE_ID NUMBER(10,0) NOT NULL,
	LABEL VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_CHAIN_BUSINE_RELATI_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, BUSINESS_RELATIONSHIP_TYPE_ID),
	CONSTRAINT FK_CHAIN_BUSINE_RELATI_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_BUSINE_RELATI_TIER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	BUSINESS_RELATIONSHIP_TYPE_ID NUMBER(10,0) NOT NULL,
	BUSINESS_RELATIONSHIP_TIER_ID NUMBER(10,0) NOT NULL,
	TIER NUMBER(10,0) NOT NULL,
	DIRECT_FROM_PREVIOUS_TIER NUMBER(1,0),
	LABEL VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_CHAIN_BUSINE_RELATI_TIER PRIMARY KEY (CSRIMP_SESSION_ID, BUSINESS_RELATIONSHIP_TIER_ID),
	CONSTRAINT FK_CHAIN_BUSINE_RELATI_TIER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_BU_REL_TIE_COM_TYP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	BUSINESS_RELATIONSHIP_TYPE_ID NUMBER(10,0) NOT NULL,
	BUSINESS_RELATIONSHIP_TIER_ID NUMBER(10,0) NOT NULL,
	COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_BU_REL_TIE_COM_TYP PRIMARY KEY (CSRIMP_SESSION_ID, BUSINESS_RELATIONSHIP_TIER_ID, COMPANY_TYPE_ID),
	CONSTRAINT FK_CHAIN_BU_REL_TIE_COM_TYP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_BUSINESS_RELATIONS (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	BUSINESS_RELATIONSHIP_ID NUMBER(10,0) NOT NULL,
	BUSINESS_RELATIONSHIP_TYPE_ID NUMBER(10,0) NOT NULL,
	END_DTM DATE,
	END_REASON CLOB,
	START_DTM DATE NOT NULL,
	CONSTRAINT PK_CHAIN_BUSINESS_RELATIONS PRIMARY KEY (CSRIMP_SESSION_ID, BUSINESS_RELATIONSHIP_ID),
	CONSTRAINT FK_CHAIN_BUSINESS_RELATIONS_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_BUSIN_RELAT_COMPAN (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	BUSINESS_RELATIONSHIP_ID NUMBER(10,0) NOT NULL,
	BUSINESS_RELATIONSHIP_TIER_ID NUMBER(10,0) NOT NULL,
	COMPANY_SID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_BUSIN_RELAT_COMPAN PRIMARY KEY (CSRIMP_SESSION_ID, BUSINESS_RELATIONSHIP_ID, BUSINESS_RELATIONSHIP_TIER_ID),
	CONSTRAINT FK_CHAIN_BUSIN_RELAT_COMPAN_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- csrimp map tables
CREATE TABLE CSRIMP.MAP_CHAIN_BUSIN_REL_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_BUSINESS_REL_TYPE_ID NUMBER(10) NOT NULL,
	NEW_BUSINESS_REL_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_BUSIN_REL_TYPE PRIMARY KEY (OLD_BUSINESS_REL_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_BUSIN_REL_TYPE UNIQUE (NEW_BUSINESS_REL_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_BUSIN_REL_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_BUSIN_REL_TIER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_BUSINESS_REL_TIER_ID NUMBER(10) NOT NULL,
	NEW_BUSINESS_REL_TIER_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_BUSIN_REL_TIER PRIMARY KEY (OLD_BUSINESS_REL_TIER_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_BUSIN_REL_TIER UNIQUE (NEW_BUSINESS_REL_TIER_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_BUSIN_REL_TIER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_BUSINE_RELATIO (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_BUSINESS_RELATIONSHIP_ID NUMBER(10) NOT NULL,
	NEW_BUSINESS_RELATIONSHIP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_BUSINE_RELATIO PRIMARY KEY (OLD_BUSINESS_RELATIONSHIP_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_BUSINE_RELATIO UNIQUE (NEW_BUSINESS_RELATIONSHIP_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_BUSINE_RELATIO_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.score_type ADD (
	ASK_FOR_COMMENT			VARCHAR2(16)
);
UPDATE csr.score_type SET ASK_FOR_COMMENT = 'none' WHERE ASK_FOR_COMMENT IS NULL;
ALTER TABLE csr.score_type MODIFY (
	ASK_FOR_COMMENT		DEFAULT 'none' NOT NULL
);
ALTER TABLE csr.score_type ADD (
    CHECK (ASK_FOR_COMMENT IN ('none','required','optional'))
);

ALTER TABLE csrimp.score_type ADD (
	ASK_FOR_COMMENT		VARCHAR2(16)
);

ALTER TABLE csr.supplier_score_log ADD (
	CHANGED_BY_USER_SID		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	COMMENT_TEXT			CLOB,
	SCORE_TYPE_ID			NUMBER(10, 0),
	CONSTRAINT fk_sup_score_log_type FOREIGN KEY (APP_SID, SCORE_TYPE_ID) REFERENCES csr.score_type(APP_SID, SCORE_TYPE_ID),
	CONSTRAINT fk_sup_score_log_user FOREIGN KEY (APP_SID, CHANGED_BY_USER_SID) REFERENCES csr.csr_user(APP_SID, CSR_USER_SID)
);

ALTER TABLE csrimp.supplier_score_log ADD (
	CHANGED_BY_USER_SID		NUMBER(10, 0),
	COMMENT_TEXT			CLOB,
	SCORE_TYPE_ID			NUMBER(10, 0)
);

DECLARE
	v_score_type_id	NUMBER(10, 0);
BEGIN
	FOR r IN (
		SELECT app_sid, count(*) score_type_count
		  FROM csr.score_type
		 GROUP BY app_sid
	) LOOP

		IF r.score_type_count = 1 THEN

			SELECT score_type_id INTO v_score_type_id
			  FROM csr.score_type
			 WHERE app_sid = r.app_sid;

			UPDATE csr.supplier_score_log
			   SET score_type_id = v_score_type_id
			 WHERE app_sid = r.app_sid
			   AND score_type_id IS NULL;

		ELSE

			UPDATE csr.supplier_score_log ssl
			   SET score_type_id = (SELECT css.score_type_id
									  FROM csr.current_supplier_score css
									 WHERE css.app_sid = ssl.app_sid AND css.last_supplier_score_id = ssl.supplier_score_id)
			 WHERE score_type_id IS NULL
			   AND EXISTS (SELECT css.score_type_id
							 FROM csr.current_supplier_score css
							WHERE css.app_sid = ssl.app_sid AND css.last_supplier_score_id = ssl.supplier_score_id);
							
			UPDATE csr.supplier_score_log ssl
			   SET score_type_id = (SELECT st.score_type_id
									  FROM csr.score_threshold st
									 WHERE st.app_sid = ssl.app_sid AND st.score_threshold_id = ssl.score_threshold_id)
			 WHERE score_type_id IS NULL
			   AND EXISTS (SELECT st.score_type_id
							 FROM csr.score_threshold st
							WHERE st.app_sid = ssl.app_sid AND st.score_threshold_id = ssl.score_threshold_id);

		END IF;

	END LOOP;
END;
/

PROMPT >> The supplier score log score types have now been filled in
PROMPT >> as much as possible.  At the time of writing, that was all
PROMPT >> log entries.  Here are the sites with log entries that we
PROMPT >> could not fill in this time:

SELECT c.host, a.row_count
FROM csr.customer c
JOIN (
	SELECT app_sid, count(*) row_count
	  FROM csr.supplier_score_log
	 WHERE score_type_id IS NULL
	 GROUP BY app_sid
) a on a.app_sid = c.app_sid;

PROMPT >> Deleting...

DELETE FROM csr.supplier_score_log WHERE score_type_id IS NULL;
ALTER TABLE csr.supplier_score_log MODIFY (
	SCORE_TYPE_ID NOT NULL
);

ALTER TABLE chain.company_type  ADD (
	region_root_sid					NUMBER(10),
	default_region_layout			VARCHAR2(255),
	create_subsids_under_parent		NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT chk_subs_under_parent_1_0 CHECK (create_subsids_under_parent IN (1,0)),
	CONSTRAINT fk_ct_region_root_sid_region FOREIGN KEY (app_sid, region_root_sid) 
		REFERENCES csr.region (app_sid, region_sid)
);

ALTER TABLE csrimp.chain_company_type  ADD (
	region_root_sid					NUMBER(10),
	default_region_layout			VARCHAR2(255),
	create_subsids_under_parent		NUMBER(1),
	CONSTRAINT chk_subs_under_parent_1_0 CHECK (create_subsids_under_parent IN (1,0))
);

UPDATE csrimp.chain_company_type SET create_subsids_under_parent=1;
ALTER TABLE csrimp.chain_company_type MODIFY create_subsids_under_parent NOT NULL;

create index chain.ix_company_type_region_root_s on chain.company_type (app_sid, region_root_sid);
create index chain.ix_company_type_default_regio on chain.company_type (app_sid, default_region_type);

ALTER TABLE csr.issue_involvement DROP CONSTRAINT UK_ISSUE_INVOLVEMENT DROP INDEX;
ALTER TABLE csr.issue_involvement DROP CONSTRAINT CHK_ISSUE_XOR_INVOLVED;

ALTER TABLE csr.issue_involvement ADD (
	company_sid				NUMBER(10, 0),
	CONSTRAINT fk_issue_involvement_company FOREIGN KEY (app_sid, company_sid) REFERENCES csr.supplier (app_sid, company_sid),
	CONSTRAINT CHK_ISSUE_XOR_INVOLVED CHECK ((user_sid IS NOT NULL AND role_sid IS NULL AND company_sid IS NULL) OR (user_sid IS NULL AND role_sid IS NOT NULL AND company_sid IS NULL) OR (user_sid IS NULL AND role_sid IS NULL and company_sid IS NOT NULL)),
	CONSTRAINT UK_ISSUE_INVOLVEMENT  UNIQUE (APP_SID, ISSUE_ID, USER_SID, ROLE_SID, COMPANY_SID)
);

CREATE INDEX csr.ix_issue_involvement_company ON csr.issue_involvement (app_sid, company_sid);

ALTER TABLE csrimp.issue_involvement ADD company_sid NUMBER(10, 0);

-- *** Grants ***
GRANT select, references ON csr.supplier_score_log TO chain;
GRANT select, references ON cms.tab TO chain;
GRANT select, references on cms.tab_column to chain;
grant select on chain.business_unit_supplier to csr;
grant select on chain.business_unit to csr;
GRANT execute ON chain.chain_link_pkg TO csr;
grant execute on chain.type_capability_pkg to csr;
grant select, insert, update, delete on csrimp.chain_busine_relati_type to web_user;
grant select, insert, update, delete on csrimp.chain_busine_relati_tier to web_user;
grant select, insert, update, delete on csrimp.chain_bu_rel_tie_com_typ to web_user;
grant select, insert, update, delete on csrimp.chain_business_relations to web_user;
grant select, insert, update, delete on csrimp.chain_busin_relat_compan to web_user;
grant select, insert, update on chain.business_relationship_type to csrimp;
grant select, insert, update on chain.business_relationship_type to CSR;
grant select, insert, update on chain.business_relationship_tier to csrimp;
grant select, insert, update on chain.business_relationship_tier to CSR;
grant select, insert, update on chain.business_rel_tier_company_type to csrimp;
grant select, insert, update on chain.business_rel_tier_company_type to CSR;
grant select, insert, update on chain.business_relationship to csrimp;
grant select, insert, update on chain.business_relationship to CSR;
grant select, insert, update on chain.business_relationship_company to csrimp;
grant select, insert, update on chain.business_relationship_company to CSR;
grant select on chain.business_rel_type_id_seq to csrimp;
grant select on chain.business_rel_type_id_seq to CSR;
grant select on chain.business_rel_tier_id_seq to csrimp;
grant select on chain.business_rel_tier_id_seq to CSR;
grant select on chain.business_relationship_id_seq to csrimp;
grant select on chain.business_relationship_id_seq to CSR;

-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW csr.v$supplier_score AS
	SELECT css.app_sid, css.company_sid, css.score_type_id, css.last_supplier_score_id,
		   ss.score, ss.set_dtm score_last_changed, ss.score_threshold_id, 
		   ss.changed_by_user_sid, cu.full_name changed_by_user_full_name, ss.comment_text,
		   st.description score_threshold_description, t.label score_type_label, t.pos,
		   t.format_mask
	  FROM csr.current_supplier_score css
	  JOIN csr.supplier_score_log ss ON css.company_sid = css.company_sid AND css.last_supplier_score_id = ss.supplier_score_id
	  LEFT JOIN csr.score_threshold st ON ss.score_threshold_id = st.score_threshold_id
	  JOIN csr.score_type t ON css.score_type_id = t.score_type_id
	  LEFT JOIN csr.csr_user cu ON ss.changed_by_user_sid = cu.csr_user_sid;

-- *** Data changes ***
-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
		'BUSINESS_RELATIONSHIP',
		'BUSINESS_RELATIONSHIP_COMPANY',
		'BUSINESS_RELATIONSHIP_TIER',
		'BUSINESS_RELATIONSHIP_TYPE',
		'BUSINESS_REL_TIER_COMPANY_TYPE'
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
CREATE OR REPLACE FUNCTION csr.Temp_SetCorePlugin(
	in_plugin_type_id				IN 	csr.plugin.plugin_type_id%TYPE,
	in_js_class						IN  csr.plugin.js_class%TYPE,
	in_description					IN  csr.plugin.description%TYPE,
	in_js_include					IN  csr.plugin.js_include%TYPE,
	in_cs_class						IN  csr.plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
	in_details						IN  csr.plugin.details%TYPE DEFAULT NULL,
	in_preview_image_path			IN  csr.plugin.preview_image_path%TYPE DEFAULT NULL,
	in_tab_sid						IN  csr.plugin.tab_sid%TYPE DEFAULT NULL,
	in_form_path					IN  csr.plugin.form_path%TYPE DEFAULT NULL
) RETURN plugin.plugin_id%TYPE
AS
	v_plugin_id		csr.plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
							details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, in_js_class, 
					 in_cs_class, in_details, in_preview_image_path, in_tab_sid, in_form_path)
		  RETURNING plugin_id INTO v_plugin_id;
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE plugin 
		   SET description = in_description,
			   js_include = in_js_include,
			   cs_class = in_cs_class,
			   details = in_details,
			   preview_image_path = in_preview_image_path,
			   form_path = in_form_path
		 WHERE plugin_type_id = in_plugin_type_id
		   AND js_class = in_js_class
		   AND app_sid IS NULL
		   AND ((tab_sid IS NULL AND in_tab_sid IS NULL) OR (tab_sid = in_tab_sid))
			   RETURNING plugin_id INTO v_plugin_id;
	END;

	RETURN v_plugin_id;
END;
/

DECLARE
	v_plugin_id NUMBER;
BEGIN
	v_plugin_id := csr.temp_SetCorePlugin(
		in_plugin_type_id		=> 10, --csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB
		in_description			=> 'Company users',
		in_js_class				=> 'Chain.ManageCompany.CompanyUsers',
		in_js_include			=> '/csr/site/chain/manageCompany/controls/CompanyUsers.js',
		in_cs_class				=> 'Credit360.Chain.Plugins.CompanyUsersDto',
		in_details				=> 'This tab shows the users of the selected company, and given the correct permissions, will allow updateding / adding new users.'
	);
	
	v_plugin_id := csr.temp_SetCorePlugin(
		in_plugin_type_id		=> 10, --csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB
		in_description			=> 'Company details',
		in_js_class				=> 'Chain.ManageCompany.CompanyDetails',
		in_js_include			=> '/csr/site/chain/manageCompany/controls/CompanyDetails.js',
		in_cs_class				=> 'Credit360.Chain.Plugins.CompanyDetailsDto',
		in_details				=> 'This tab allows editing of the core company details such as address.'
	);
	
	v_plugin_id := csr.temp_SetCorePlugin(
		in_plugin_type_id		=> 10, --csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB
		in_description			=> 'Relationships',
		in_js_class				=> 'Chain.ManageCompany.RelationshipsTab',
		in_js_include			=> '/csr/site/chain/manageCompany/controls/RelationshipsTab.js',
		in_cs_class				=> 'Credit360.Chain.Plugins.RelationshipsTabDto',
		in_details				=> 'This tab allows adding/removing relationships to a company.'
	);
	
	v_plugin_id := csr.temp_SetCorePlugin(
		in_plugin_type_id		=> 10, --csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB
		in_description			=> 'Business Relationships',
		in_js_class				=> 'Chain.ManageCompany.BusinessRelationships',
		in_js_include			=> '/csr/site/chain/manageCompany/controls/BusinessRelationships.js',
		in_cs_class				=> 'Credit360.Chain.Plugins.BusinessRelationshipsDto',
		in_details				=> 'This tab shows the business relationships for a company.'
	);
	
	v_plugin_id := csr.temp_SetCorePlugin(
		in_plugin_type_id		=> 10, --csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB
		in_description			=> 'My Details',
		in_js_class				=> 'Chain.ManageCompany.MyDetailsTab',
		in_js_include			=> '/csr/site/chain/manageCompany/controls/MyDetailsTab.js',
		in_cs_class				=> 'Credit360.Chain.Plugins.MyDetailsDto',
		in_details				=> 'This tab allows a user to maintain their personal details. This tab would normally only be used when looking at your own company.'
	);
END;
/

DROP FUNCTION csr.Temp_SetCorePlugin;


CREATE OR REPLACE PROCEDURE chain.temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2,
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER
)
AS
	v_count						NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;

	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND (
				(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 1 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
			 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
		   );

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;

	INSERT INTO capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);

END;
/

-- New chain capabilities
BEGIN
	BEGIN
		chain.temp_RegisterCapability(1 /*chain.chain_pkg.CT_COMPANY*/, 'View company score log', 1, 0);
		chain.temp_RegisterCapability(2 /*chain.chain_pkg.CT_SUPPLIERS*/, 'View company score log', 1, 1);
		-- chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.FILTER_ON_RELATIONSHIPS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
		chain.temp_RegisterCapability(0 /*chain.chain_pkg.CT_COMMON*/, 'Filter on company relationships', 1, 0);
		chain.temp_RegisterCapability(1 /*chain.chain_pkg.CT_COMPANY*/, 'Create business relationships', 1, 0);
		chain.temp_RegisterCapability(1 /*chain.chain_pkg.CT_COMPANY*/, 'Add company to business relationships', 1, 0);
		chain.temp_RegisterCapability(2 /*chain.chain_pkg.CT_SUPPLIERS*/, 'Add company to business relationships', 1, 1);
		chain.temp_RegisterCapability(1 /*chain.chain_pkg.CT_COMPANY*/, 'View company business relationships', 1, 0);
		chain.temp_RegisterCapability(2 /*chain.chain_pkg.CT_SUPPLIERS*/, 'View company business relationships', 1, 1);
		chain.temp_RegisterCapability(2 /*chain.chain_pkg.CT_SUPPLIERS*/, 'Add company to business relationships (supplier => purchaser)', 1, 1);
		chain.temp_RegisterCapability(2 /*chain.chain_pkg.CT_SUPPLIERS*/, 'View company business relationships (supplier => purchaser)', 1, 1);
		chain.temp_RegisterCapability(2 /*chain.chain_pkg.CT_SUPPLIERS*/, 'Query questionnaire answers', 1, 1);
	END;
END;
/

DROP PROCEDURE chain.temp_RegisterCapability;

--Output from chain.card_pkg.DumpCard
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	-- Chain.Cards.Filters.CompanyRelationshipFilter
	v_desc := 'Chain Company Relationship Filter';
	v_class := 'Credit360.Chain.Cards.Filters.CompanyRelationshipFilter';
	v_js_path := '/csr/site/chain/cards/filters/companyRelationshipFilter.js';
	v_js_class := 'Chain.Cards.Filters.CompanyRelationshipFilter';
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
	v_card_id				NUMBER(10);
	v_group_id				NUMBER(10);
	v_capability_id			NUMBER(10);
BEGIN
	/*chain.filter_pkg.CreateFilterType (
		in_description => 'Chain Company Relationship Filter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyRelationshipFilter'
	);*/
	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE LOWER(js_class_type) = LOWER('Chain.Cards.Filters.CompanyRelationshipFilter');
	
	BEGIN
		INSERT INTO chain.filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			chain.filter_type_id_seq.NEXTVAL,
			'Chain Company Relationship Filter',
			'chain.company_filter_pkg',
			v_card_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM chain.card_group
		 WHERE LOWER(name) = LOWER('Basic Company Filter');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card group with name = Basic Company Filter');
	END;
	
	BEGIN
		SELECT capability_id
		  INTO v_capability_id
		  FROM chain.capability
		 WHERE LOWER(capability_name) = LOWER('Filter on company relationships');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a capability with name = Filter on company relationships');
	END;
	
	
	FOR r IN (
		SELECT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = v_group_id
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card(app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
			     VALUES (r.app_sid, v_group_id, v_card_id, r.pos, NULL, v_capability_id);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END LOOP;
END;
/

-- ** New package grants **

-- dummy procs for grant
create or replace package chain.business_relationship_pkg as
procedure dummy;
end;
/
create or replace package body chain.business_relationship_pkg as
procedure dummy
as
begin
	null;
end;
end;
/
grant execute on chain.business_relationship_pkg to web_user;

-- *** Packages ***

@..\chain\audit_request_pkg
@..\chain\chain_pkg
@..\chain\chain_link_pkg
@..\chain\company_pkg
@..\chain\business_relationship_pkg
@..\chain\company_type_pkg
@..\quick_survey_pkg
@..\supplier_pkg
@..\schema_pkg
@..\issue_pkg
@..\csrimp\imp_pkg

@..\chain\audit_request_body
@..\chain\chain_body
@..\chain\chain_link_body
@..\chain\company_body
@..\chain\company_filter_body
@..\chain\type_capability_body
@..\chain\business_relationship_body
@..\chain\plugin_body
@..\chain\company_type_body
@..\chain\setup_body
@..\audit_body
@..\property_body
@..\quick_survey_body
@..\supplier_body
@..\issue_body
@..\issue_report_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
