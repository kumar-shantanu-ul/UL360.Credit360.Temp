-- Please update version.sql too -- this keeps clean builds in sync
define version=2453
@update_header

-- Remove duff policy that doesn't exist on live 
DECLARE
	policy_does_not_exists exception;
	pragma exception_init(policy_does_not_exists, -28102);
BEGIN
	BEGIN
		dbms_rls.drop_policy(
				object_schema   => 'CHAIN',
				object_name     => 'SAVED_FILTER',
				policy_name     => 'SAVED_FILTER_POLICY'
			);
	EXCEPTION
		WHEN policy_does_not_exists THEN
			NULL;
	END;
END;
/

-- Add context sensitive policies using new naming convention to have old + new at the same time
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439); 
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 23) || '_POLICY') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner = 'CHAIN' AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'APP_SID'
		 MINUS
		SELECT object_owner, object_name, CASE function WHEN 'NULLABLEAPPSIDCHECK' THEN 'Y' ELSE 'N' END, policy_name
		  FROM all_policies
		 WHERE function IN ('APPSIDCHECK', 'NULLABLEAPPSIDCHECK')
		   AND object_owner = 'CHAIN'
		   AND policy_name LIKE '%_POLICY'
		   AND policy_type = 'CONTEXT_SENSITIVE' -- filter out any context sensitive policies already (from change scripts)
 	)
 	LOOP
		BEGIN
			dbms_output.put_line('Writing policy '||r.policy_name);
			dbms_rls.add_policy(
				object_schema   => r.owner,
				object_name     => r.table_name,
				policy_name     => r.policy_name, 
				function_schema => r.owner,
				policy_function => (CASE WHEN r.nullable ='N' THEN 'appSidCheck' ELSE 'nullableAppSidCheck' END),
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.context_sensitive);
		EXCEPTION WHEN POLICY_ALREADY_EXISTS THEN
			NULL;
		END;
	END LOOP;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');	
END;
/

-- Remove old (static) policies
BEGIN
	FOR r IN (
		SELECT ap.object_name, ap.policy_name 
		  FROM all_policies ap
		  JOIN all_tables at ON ap.object_owner = at.owner AND ap.object_name = at.table_name
		 WHERE ap.function IN ('APPSIDCHECK', 'NULLABLEAPPSIDCHECK')
		   AND ap.object_owner = 'CHAIN'
		   AND ap.policy_name != (SUBSTR(at.table_name, 1, 23) || '_POLICY') -- any policies that don't match new naming convention
	) LOOP
		dbms_rls.drop_policy(
			object_schema   => 'CHAIN',
			object_name     => r.object_name,
			policy_name     => r.policy_name
		);
	END LOOP;
END;
/

-- Update chain's RLS functions to be more like CSR (needed for the alter table statements in 11g and general consistency)
CREATE OR REPLACE FUNCTION chain.appSidCheck (
	in_schema 		IN	varchar2, 
	in_object 		IN	varchar2
)
RETURN VARCHAR2
AS
BEGIN
	-- Not logged on => see everything.
	IF SYS_CONTEXT('SECURITY', 'APP') IS NULL THEN
		RETURN '';
	END IF;
	
	-- This is:
	--
	--    Allow data for superadmins (must exist for joins for names and so on, needs to be fixed);
	-- OR logged on and data is for the current application
	--
	RETURN 'app_sid = 0 or app_sid = sys_context(''SECURITY'', ''APP'')';
END;
/

CREATE OR REPLACE FUNCTION chain.nullableAppSidCheck (
	in_schema 		IN	varchar2, 
	in_object 		IN	varchar2
)
RETURN VARCHAR2
AS
BEGIN
	-- Not logged on => see everything.
	IF SYS_CONTEXT('SECURITY', 'APP') IS NULL THEN
		RETURN '';
	END IF;
	
	-- This is:
	--
	--    Allow data for superadmins (must exist for joins for names and so on, needs to be fixed);
	-- OR logged on and data is for the current application
	-- OR app_sid is null and nullable
	--
	RETURN 'app_sid is null or app_sid = 0 or app_sid = sys_context(''SECURITY'', ''APP'')';
END;
/

-- *** DDL ***
CREATE OR REPLACE TYPE CHAIN.T_COMPANY_RELATIONSHIP_SIDS AS
	OBJECT (
		PRIMARY_COMPANY_SID			NUMBER(10),
		SECONDARY_COMPANY_SID		NUMBER(10),
		MAP MEMBER FUNCTION MAP
			RETURN VARCHAR2
	);
/

CREATE OR REPLACE TYPE BODY CHAIN.T_COMPANY_RELATIONSHIP_SIDS AS
	MAP MEMBER FUNCTION MAP
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN RPAD(PRIMARY_COMPANY_SID, 10) || '->' || RPAD(SECONDARY_COMPANY_SID, 10);
	END;
END;
/

CREATE OR REPLACE TYPE CHAIN.T_COMPANY_REL_SIDS_TABLE AS
	TABLE OF CHAIN.T_COMPANY_RELATIONSHIP_SIDS;
/

-- Create tables

-- Alter tables
ALTER TABLE chain.company_type ADD (
	default_region_type				NUMBER(2)
);

ALTER TABLE csrimp.chain_company_type ADD (
	default_region_type				NUMBER(2) 
);

ALTER TABLE chain.company_tab ADD (
	viewing_own_company				NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_cmp_tab_view_own_cmp_1_0 CHECK (viewing_own_company IN (1, 0)),
	CONSTRAINT chk_cmp_tab_viewing_own_types CHECK (viewing_own_company = 0 OR (user_company_type_id = page_company_type_id))
);

ALTER TABLE csrimp.chain_company_tab ADD (
	viewing_own_company				NUMBER(1)
);
UPDATE csrimp.chain_company_tab SET viewing_own_company = 0;
ALTER TABLE csrimp.chain_company_tab MODIFY viewing_own_company NOT NULL;

ALTER TABLE chain.company_header ADD (
	viewing_own_company				NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_cmp_head_view_own_cmp_1_0 CHECK (viewing_own_company IN (1, 0)),
	CONSTRAINT chk_cmp_head_viewing_own_types CHECK (viewing_own_company = 0 OR (user_company_type_id = page_company_type_id))
);

ALTER TABLE csrimp.chain_company_header ADD (
	viewing_own_company				NUMBER(1)
);
UPDATE csrimp.chain_company_header SET viewing_own_company = 0;
ALTER TABLE csrimp.chain_company_header MODIFY viewing_own_company NOT NULL;


ALTER TABLE chain.company_type_relationship ADD (
	hidden							NUMBER(1)
);
UPDATE chain.company_type_relationship SET hidden = 0;
ALTER TABLE chain.company_type_relationship MODIFY hidden DEFAULT 0 NOT NULL;
ALTER TABLE chain.company_type_relationship ADD (
	CONSTRAINT chk_cmp_type_rel_hidden CHECK (hidden IN (1, 0))
);

ALTER TABLE csrimp.chain_compan_type_relati ADD (
	hidden							NUMBER(1)
);
UPDATE csrimp.chain_compan_type_relati SET hidden = 0;
ALTER TABLE csrimp.chain_compan_type_relati MODIFY hidden NOT NULL;

-- *** Grants ***
GRANT REFERENCES ON csr.customer_region_type TO chain;
grant execute on chain.plugin_pkg to web_user;

-- ** Cross schema constraints ***
ALTER TABLE chain.company_type ADD CONSTRAINT fk_comp_type_cust_region_type 
	FOREIGN KEY (app_sid, default_region_type)
	REFERENCES csr.customer_region_type (app_sid, region_type);

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- Set the default region type to supplier region for sites 
-- that have it enabled.
UPDATE chain.company_type
   SET default_region_type = 7 -- csr.csr_data_pkg.REGION_TYPE_SUPPLIER
 WHERE (app_sid, 7) IN (
	SELECT app_sid, region_type
	  FROM csr.customer_region_type
	);
	
-- Clone the company plugins for 'my company' version
INSERT INTO chain.company_tab (app_sid, company_tab_id, plugin_id, plugin_type_id, pos, label, page_company_type_id, user_company_type_id, viewing_own_company)
	 SELECT app_sid, chain.company_tab_id_seq.NEXTVAL, plugin_id, plugin_type_id, pos, label, page_company_type_id, user_company_type_id, 1
	   FROM chain.company_tab
	  WHERE page_company_type_id = user_company_type_id
	    AND viewing_own_company = 0
		AND (app_sid, plugin_id, page_company_type_id, user_company_type_id) NOT IN (
			SELECT app_sid, plugin_id, page_company_type_id, user_company_type_id
			  FROM chain.company_tab
			 WHERE viewing_own_company = 1
		);
		
INSERT INTO chain.company_header (app_sid, company_header_id, plugin_id, plugin_type_id, pos, page_company_type_id, user_company_type_id, viewing_own_company)
	 SELECT app_sid, chain.company_header_id_seq.NEXTVAL, plugin_id, plugin_type_id, pos, page_company_type_id, user_company_type_id, 1
	   FROM chain.company_header
	  WHERE page_company_type_id = user_company_type_id
	    AND viewing_own_company = 0
		AND (app_sid, plugin_id, page_company_type_id, user_company_type_id) NOT IN (
			SELECT app_sid, plugin_id, page_company_type_id, user_company_type_id
			  FROM chain.company_header
			 WHERE viewing_own_company = 1
		);
		
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
		-- chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.CREATE_COMPANY_AS_SUBSIDIARY, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
		chain.temp_RegisterCapability(0 /*chain.chain_pkg.CT_COMMON*/, 'Create company as subsidiary', 1, 1);
		-- chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.CREATE_SUBSIDIARY_ON_BEHLF_OF, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
		chain.temp_RegisterCapability(3 /*chain.chain_pkg.CT_ON_BEHALF_OF*/, 'Create subsidiary on behalf of', 1, 1);
		-- chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_ON_BEHALF_OF, chain.chain_pkg.VIEW_SUBSIDIARIES_ON_BEHLF_OF, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
		chain.temp_RegisterCapability(3 /*chain.chain_pkg.CT_ON_BEHALF_OF*/, 'View subsidiaries on behalf of', 1, 1);
	END;
END;
/

DROP PROCEDURE chain.temp_RegisterCapability;

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
		in_description			=> 'Subsidiaries',
		in_js_class				=> 'Chain.ManageCompany.SubsidiaryTab',
		in_js_include			=> '/csr/site/chain/manageCompany/controls/SubsidiaryTab.js',
		in_cs_class				=> 'Credit360.Chain.Plugins.SubsidiaryDto',
		in_details				=> 'This tab shows the subsidiaries of the selected company, and given the correct permissions, will allow adding new subsidiaries.'
	);

	v_plugin_id := csr.temp_SetCorePlugin(
		in_plugin_type_id		=> 10, --csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB
		in_description			=> 'Supply Chain Graph',
		in_js_class				=> 'Chain.ManageCompany.CompaniesGraph',
		in_js_include			=> '/csr/site/chain/manageCompany/controls/CompaniesGraph.js',
		in_cs_class				=> 'Credit360.Chain.Plugins.CompaniesGraphDto',
		in_details				=> 'This tab shows a graph of the supply chain for the selected company.'
	);
END;
/

DROP FUNCTION csr.Temp_SetCorePlugin;

-- ** New package grants **

-- *** Packages ***
@..\chain\company_type_pkg
@..\chain\company_filter_pkg
@..\chain\company_pkg
@..\chain\plugin_pkg
@..\chain\capability_pkg
@..\chain\chain_pkg
@..\chain\type_capability_pkg

@..\chain\company_type_body
@..\chain\company_filter_body
@..\chain\type_capability_body
@..\chain\capability_body
@..\chain\company_body
@..\chain\plugin_body
@..\chain\setup_body
@..\chain\report_body
@..\schema_body
@..\csrimp\imp_body
@..\supplier_body

@update_tail
