-- finds tables (or just columns) that are inconsistent between csr and csrimp

PROMPT Hint: Make sure you are running as upd so you can see everything in csrimp
Prompt --

WITH all_csr_columns AS (
	SELECT table_name, column_name
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   -----------------------------------------
	   -- things that don't need to be in csrimp
	   -----------------------------------------
	   AND column_name NOT LIKE 'XX\_%'					ESCAPE '\'
	   AND column_name NOT LIKE 'XXX\_%'				ESCAPE '\'
	   AND column_name NOT IN ('APP_SID', 'OLD_APPROVAL_STEP_ID')
	   AND table_name NOT LIKE 'XX\_%'					ESCAPE '\'
	   AND table_name NOT LIKE '%\_XXX'					ESCAPE '\'
	   AND table_name NOT LIKE '%\_XX'					ESCAPE '\'
	   AND table_name NOT LIKE '%\_X'					ESCAPE '\'
	   AND table_name NOT LIKE 'FB%'
	   AND table_name NOT LIKE '%\_FB%'					ESCAPE '\'
	   AND table_name NOT LIKE 'DR$IX\_%'				ESCAPE '\'
	   AND table_name NOT LIKE 'DUFF\_%'				ESCAPE '\'
	   AND table_name NOT LIKE 'FFS\_%'					ESCAPE '\'
	   AND table_name NOT LIKE 'TEMP\_%'				ESCAPE '\'
	   AND table_name NOT LIKE '%\_TEMP'				ESCAPE '\'
	   AND table_name NOT LIKE 'TMP\_%'					ESCAPE '\'
	   AND table_name NOT LIKE 'SS\_%'					ESCAPE '\'
	   AND table_name NOT LIKE '%\_BACKUP'				ESCAPE '\'
	   AND table_name NOT LIKE '%\_BUG'					ESCAPE '\'
	   AND table_name NOT LIKE 'RESURRECTED\_%'			ESCAPE '\'
	   AND table_name NOT LIKE 'LINDE\_%'				ESCAPE '\'
	   AND table_name NOT LIKE 'LOGICA\_%'				ESCAPE '\'
	   AND table_name NOT LIKE 'LSE\_%'					ESCAPE '\'
	   AND table_name NOT LIKE 'RBS\_%'					ESCAPE '\'
	   AND table_name NOT LIKE 'TIFF\_%'				ESCAPE '\'
	   AND table_name NOT LIKE '%CALC\_JOB%'			ESCAPE '\'
	   AND (table_name NOT LIKE 'BATCH\_JOB%'			ESCAPE '\' OR table_name = 'BATCH_JOB_APPROVAL_DASH_VALS')
	   AND table_name <> 'R_REPORT_JOB'
	   AND table_name NOT IN ('DELEGATION_CHANGE_ALERT', 'DELEGATION_EDITED_ALERT', 'DELEGATION_TERMINATED_ALERT', 'DELEG_DATA_CHANGE_ALERT')
	   AND table_name NOT LIKE 'TPL\_REPORT\_SCHED%'	ESCAPE '\'
	   AND table_name <> 'APP_LOCK' -- filled in by csrimp.imp_pkg
	   -- stuff MDW said to ignore
	   AND table_name <> 'JOB'
	   AND table_name NOT IN ('PVC_REGION_RECALC_JOB', 'PVC_STORED_CALC_JOB')
	   -- stuff XPJ said to ignore
	   AND table_name NOT LIKE 'ENHESA\_%'				ESCAPE '\'
	   AND table_name NOT LIKE 'EST\_%'					ESCAPE '\'
	   AND table_name <> 'IMI_SHEET'
	   -- other things to safely ignore
	   AND table_name NOT IN ('ALERT_MAIL', 'DELEG_PLAN_JOB', 'BRANDING_AVAILABILITY',
	                          'BRANDING_LOCK', 'DELETED_DELEGATION', 'OPTION_ITEM', 'OPTION_SET',
	                          'SESSION_EXTRA', 'SHEET_COMPLETENESS_JOB')
	   AND table_name NOT IN ('PENDING_VAL_CACHE', 'PENDING_VAL_FILE_UPLOAD')
	   AND table_name NOT LIKE 'METER\_%\_OLD'			ESCAPE '\'
	   AND table_name NOT IN ('FEED', 'FEED_REQUEST', 'FTP_PROFILE', 'IMPORT_FEED', 'IMPORT_FEED_REQUEST') -- best resurrected by hand if needed
	   AND table_name NOT LIKE 'HELP\_%'				ESCAPE '\' -- dead old help?
	   AND table_name <> 'DIVISION' -- seems deeply embedded in clients' custom code
	   -- tables holding transient data
	   AND table_name <> 'SHEET_CHANGE_LOG'
	   AND table_name NOT IN ('SHEET_VAL_CHANGE_LOG', 'VAL_CHANGE_LOG')
	   AND table_name <> 'PCT_OWNERSHIP_CHANGE'
	   AND table_name <> 'UPDATED_PLANNED_DELEG_ALERT'
	   -------------------------------------------
	   -- things used by just one or two customers
	   -------------------------------------------
	   AND table_name NOT IN ('UTILITY_INVOICE_FIELD', 'UTILITY_INVOICE_FIELD_VAL')			-- crdemo
	   AND table_name NOT IN ('DELEGATION_AUTOMATIC_APPROVAL', 'SHEET_AUTOMATIC_APPROVAL')	-- otto
	   AND table_name <> 'FLOW_ITEM_SUBSCRIPTION'											-- hsdemo
	   AND table_name <> 'FUND_MGMT_CONTACT'												-- cbre
	   AND table_name <> 'HMAC'																-- teliasonera
	   AND table_name NOT IN ('FUNCTION', 'FUNCTION_COURSE', 'PLACE', 'USER_FUNCTION',
	                          'USER_RELATIONSHIP', 'USER_RELATIONSHIP_TYPE')				-- berkeley
	   AND table_name NOT IN ('GP_LOGIN_CONTEXT', 'GP_TEMP_CONVERTED_VALUES',
	                          'GREENPRINT_CLEANED_BUILDINGS')								-- greenprint
	   AND table_name NOT LIKE 'RULESET%'													-- greenprint
	   AND table_name NOT LIKE 'FLOW\_STATE\_ALERT%'	ESCAPE '\'							-- hsdemo
	   AND table_name NOT LIKE 'DELEG\_REPORT%'			ESCAPE '\'							-- heineken, SocGen
	   AND table_name NOT IN ('INBOUND_FEED_ACCOUNT', 'INBOUND_FEED_ATTACHMENT')			-- hyatt
	   AND table_name <> 'INSTANCE_DATAVIEW'												-- whistler
	   AND table_name NOT IN ('PLUGIN_LOOKUP', 'PLUGIN_LOOKUP_FLOW_STATE')					-- dbs-test3
	   AND table_name <> 'USER_PROFILE_PANEL'												-- nobody?
	   AND table_name NOT LIKE 'LOGISTICS%'													-- with product team, parked
	   AND table_name <> 'MATCHED_GIVING_POLICY'											-- donations = parked
	   --------------------------------------------------------------------
	   -- tables deliberately ignored in US5889 after checking with the TAs
	   --------------------------------------------------------------------
	   AND table_name NOT LIKE 'TEAMROOM%'
	   AND table_name NOT IN (
		'INBOUND_CMS_ACCOUNT', 'INBOUND_ISSUE_ACCOUNT'
	   )
	   AND table_name NOT LIKE 'AUTO\_%'				ESCAPE '\'
	   AND table_name NOT LIKE 'AUTOMATED\_%'			ESCAPE '\'
	   AND table_name <> 'APPROVAL_DASHBOARD_VAL_SRC'
	   AND table_name NOT LIKE '%LIKE\_FOR\_LIKE%'		ESCAPE '\'
	   -------------------------------------------------------------------------
	   -- tables that are currently missing but for which cases have been raised
	   -------------------------------------------------------------------------
	   AND NOT (table_name = 'ALL_METER' AND column_name = 'DEMAND_IND_SID')
	   AND NOT (table_name = 'COMPLIANCE_OPTIONS' AND column_name IN('REGULATION_FLOW_SID', 'REQUIREMENT_FLOW_SID'))
	   AND NOT (table_name = 'CUSTOMER' AND column_name IN('DELEG_DROPDOWN_THRESHOLD', 'TEAR_OFF_DELEG_HEADER'))
	   AND NOT (table_name = 'ISSUE' AND column_name IN('ISSUE_INITIATIVE_ID', 'ISSUE_METER_MISSING_DATA_ID'))
	   AND NOT (table_name = 'QS_ANSWER_FILE' AND column_name IN('DATA', 'UPLOADED_DTM'))
	   AND table_name NOT IN (
		'ACTIVITY', 'ACTIVITY_FOLLOWER', 'ACTIVITY_LIKE', 'ACTIVITY_MEMBER', 'ACTIVITY_MEMBER_TIME', 'ACTIVITY_MONEY',
		'ACTIVITY_POST', 'ACTIVITY_POST_FILE', 'ACTIVITY_POST_LIKE', 'ACTIVITY_SHOWCASE', 'ACTIVITY_SUB_TYPE', 'ACTIVITY_TYPE',
		'ALERT_IMAGE',
		'ALL_PROPERTY', 'ALL_SPACE',
		'APPROVAL_STEP_MODEL', 'APPROVAL_STEP_SHEET_ALERT', 'APPROVAL_STEP_TEMPLATE', 'APPROVAL_STEP_USER_TEMPLATE',
		'AUDIT_ISS_ALL_CLOSED_ALERT',
		'AXIS', 'AXIS_MEMBER',
		'CLIENT_UTIL_SCRIPT', 'CLIENT_UTIL_SCRIPT_PARAM',
		'CMS_FIELD_CHANGE_ALERT',
		'COURSE', 'COURSE_FILE', 'COURSE_FILE_DATA', 'COURSE_SCHEDULE', 'COURSE_TYPE', 'COURSE_TYPE_REGION',
		'CUSTOMER_MAP',
		'CUSTOMER_SAML_SSO', 'CUSTOMER_SAML_SSO_CERT',
		'CUSTOM_DISTANCE', 'CUSTOM_LOCATION',
		'DEFAULT_RSS_FEED',
		'FORECASTING_SCENARIO_ALERT',
		'GEO_MAP_TAB', 'GEO_MAP_TAB_CHART',
		'INCIDENT_TYPE',
		-- Tom added some initiatives tables recently but not these?
		'INITIATIVE_GROUP_FLOW_STATE', 'INITIATIVE_IMPORT_TEMPLATE', 'INITIATIVE_IMPORT_TEMPLATE_MAP', 'INITIATIVE_METRIC_STATE_IND', 'INITIATIVE_METRIC_TAG_IND',
		'INITIATIVE_PROJECT_RAG_STATUS', 'INITIATIVE_PROJECT_TAB_GROUP', 'INITIATIVE_PROJECT_USER_GROUP',
		'MAP_SHPFILE',
		'MEASURE_CONVERSION_SET', 'MEASURE_CONVERSION_SET_ENTRY',
		'METER_READING_PERIOD', 'METER_RECOMPUTE_BATCH_JOB', 'METER_TYPE_CHANGE_BATCH_JOB',
		'MODEL_DELEG_IMPORT',
		'NEW_DELEGATION_ALERT',
		'NEW_PLANNED_DELEG_ALERT',
		'OBJECTIVE', 'OBJECTIVE_STATUS',
		'OUTSTANDING_REQUESTS_JOB',
		'PERIOD_SPAN_PATTERN',
		'PROPERTY_DIVISION', 'PROPERTY_OPTIONS',
		'REGION_POSTIT',
		'RELATED_AXIS', 'RELATED_AXIS_MEMBER',
		'RISKS',
		'RSS_FEED', 'RSS_FEED_ITEM',
		'SAML_ASSERTION_CACHE', 'SAML_ASSERTION_LOG', 'SAML_LOG',
		'SCENARIO_AUTO_RUN_REQUEST',
		'SCENARIO_MAN_RUN_REQUEST',
		'SCENARIO_RUN_SNAPSHOT', 'SCENARIO_RUN_SNAPSHOT_FILE', 'SCENARIO_RUN_SNAPSHOT_IND', 'SCENARIO_RUN_SNAPSHOT_REGION',
		'SCENARIO_RUN_VERSION', 'SCENARIO_RUN_VERSION_FILE',
		'SECTION_ATTACH_LOG', 'SECTION_CONTENT_DOC', 'SECTION_CONTENT_DOC_WAIT', 'SECTION_FACT', 'SECTION_FACT_ATTACH',
		'SECTION_FACT_ENUM', 'SECTION_PLUGIN_LOOKUP', 'SECTION_VAL',
		'SELECTED_AXIS_TASK',
		'SNAPSHOT', 'SNAPSHOT_IND', 'SNAPSHOT_REGION', 'SNAPSHOT_TAG_GROUP',
		'STD_FACTOR_SET_ACTIVE',
		'TRAINER', 'TRAINING_OPTIONS',
		'URJANET_IMPORT_INSTANCE', 'URJANET_SERVICE_TYPE',
		'USER_COURSE', 'USER_COURSE_LOG',
		'USER_FEED',
		'USER_INACTIVE_MAN_ALERT', 'USER_INACTIVE_REM_ALERT', 'USER_INACTIVE_SYS_ALERT',
		'USER_MESSAGE_ALERT',
		'USER_TRAINING',
		'UTIL_SCRIPT_RUN_LOG'
	   )
),
all_csrimp_columns AS (
	SELECT table_name, column_name
	  FROM all_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND column_name <> 'CSRIMP_SESSION_ID'
	   AND NOT (table_name = 'PLUGIN' AND column_name = 'APP_SID')
)
SELECT g.status,
       g.table_name,
	   CASE WHEN allt1.table_name IS NOT NULL AND allt2.table_name IS NOT NULL THEN 'COLUMN' ELSE 'TABLE' END missing,
       g.columns FROM (
	SELECT 'only in csr' status, table_name, csr.stragg(column_name) columns
	  FROM (
		SELECT table_name, column_name FROM all_csr_columns
		MINUS
		SELECT table_name, column_name FROM all_csrimp_columns
	)
	 GROUP BY table_name
	UNION ALL
	SELECT 'only in csrimp' status, table_name, csr.stragg(column_name) columns
	 FROM (
		SELECT table_name, column_name FROM all_csrimp_columns
		MINUS
		SELECT table_name, column_name FROM all_csr_columns
	)
	 GROUP BY table_name
)g
LEFT JOIN all_tables allt1 ON g.table_name = allt1.table_name AND allt1.owner = 'CSR'
LEFT JOIN all_tables allt2 ON g.table_name = allt2.table_name AND allt2.owner = 'CSRIMP'
 WHERE EXISTS (
	-- only interested in tables with an APP_SID column
	SELECT NULL
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND column_name = 'APP_SID'
	   AND table_name = g.table_name
 )
 AND EXISTS (
 	-- ignore temporary tables
	SELECT NULL
	  FROM all_tables
	 WHERE owner = 'CSR'
	   AND table_name = g.table_name
	   AND temporary = 'N'
 )
 AND NOT EXISTS (
	-- ignore views (they don't all start with V$)
	SELECT NULL
	  FROM all_views
	 WHERE owner = 'CSR'
	   AND view_name = g.table_name
 )
 ORDER BY status, table_name;

