
CREATE OR REPLACE PACKAGE CMS.temp_tab_pkg AS

-- Errors.  We don't use normal error codes since it's impossible
-- to add detail to them.  Instead, the Oracle Workspace Manager
-- approach is taken whereby we have specific error codes for what
-- would be normal Oracle errors.  The error codes are the same
-- as for Workspace manager on the offchance that it becomes
-- possible to use it as a basis for this stuff.
TYPE t_error_array IS VARRAY(300) OF VARCHAR2(500);

-- Oracle errors with no predefined exceptions that we want to catch
FGA_ALREADY_EXISTS		EXCEPTION;
PRAGMA EXCEPTION_INIT(FGA_ALREADY_EXISTS, -28101);

FEATURE_NOT_ENABLED EXCEPTION;
PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);

FGA_NOT_FOUND			EXCEPTION;
PRAGMA EXCEPTION_INIT(FGA_NOT_FOUND, -28102);

TABLE_DOES_NOT_EXIST	EXCEPTION;
PRAGMA EXCEPTION_INIT(TABLE_DOES_NOT_EXIST, -04043);

PACKAGE_DOES_NOT_EXIST	EXCEPTION;
PRAGMA EXCEPTION_INIT(PACKAGE_DOES_NOT_EXIST, -00942);
	
USER_DOES_NOT_EXIST	EXCEPTION;
PRAGMA EXCEPTION_INIT(USER_DOES_NOT_EXIST, -01435);

-- WM_ERROR_3
ERR_PK_MODIFIED					CONSTANT NUMBER := -20003;
PK_MODIFIED						EXCEPTION;
PRAGMA EXCEPTION_INIT(PK_MODIFIED, -20003);

-- WM_ERROR_5
ERR_RI_CONS_CHILD_FOUND			CONSTANT NUMBER := -20005;
RI_CONS_CHILD_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(RI_CONS_CHILD_FOUND, -20005);

-- WM_ERROR_6
ERR_RI_CONS_NO_PARENT			CONSTANT NUMBER := -20006;
RI_CONS_NO_PARENT				EXCEPTION;
PRAGMA EXCEPTION_INIT(RI_CONS_NO_PARENT, -20006);
	
-- WM_ERROR_10
ERR_UK_VIOLATION				CONSTANT NUMBER := -20010;
UK_VIOLATION					EXCEPTION;
PRAGMA EXCEPTION_INIT(UK_VIOLATION, -20010);

-- TODO: probably ought to be WM_ERROR_170
ERR_ROW_LOCKED					CONSTANT NUMBER := -20011;
ROW_LOCKED						EXCEPTION;
PRAGMA EXCEPTION_INIT(ROW_LOCKED, -20011);

--No cms.tab record found for flow sid
ERR_FLOW_TAB_NOT_FOUND			CONSTANT NUMBER := -20012;
FLOW_TAB_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(FLOW_TAB_NOT_FOUND, -20012);

--No cms.tab record found for flow sid
ERR_FLOW_ITEM_COL_NOT_FOUND			CONSTANT NUMBER := -20013;
FLOW_ITEM_COL_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(FLOW_ITEM_COL_NOT_FOUND, -20013);

-- Column types
SUBTYPE T_COL_TYPE				IS tab_column.col_type%TYPE;
CT_NORMAL						CONSTANT T_COL_TYPE := 0;
CT_FILE_DATA					CONSTANT T_COL_TYPE := 1;
CT_FILE_MIME					CONSTANT T_COL_TYPE := 2;
CT_FILE_NAME					CONSTANT T_COL_TYPE := 3;
CT_HTML							CONSTANT T_COL_TYPE := 4;
CT_IMAGE						CONSTANT T_COL_TYPE := 5;
CT_LINK							CONSTANT T_COL_TYPE := 6;
CT_ENUMERATED					CONSTANT T_COL_TYPE := 7;
CT_USER							CONSTANT T_COL_TYPE := 8;
CT_REGION						CONSTANT T_COL_TYPE := 9;
CT_INDICATOR					CONSTANT T_COL_TYPE := 10;
CT_TIME							CONSTANT T_COL_TYPE := 11;
CT_MEASURE_CONVERSION			CONSTANT T_COL_TYPE := 12;
CT_SEARCH_ENUM					CONSTANT T_COL_TYPE := 14;	
CT_VIDEO_CODE					CONSTANT T_COL_TYPE := 15;	
CT_AUTO_INCREMENT				CONSTANT T_COL_TYPE := 16;
CT_POSITION						CONSTANT T_COL_TYPE := 17;
CT_CHART						CONSTANT T_COL_TYPE := 18;
CT_DOCUMENT						CONSTANT T_COL_TYPE := 19;
CT_BOOLEAN						CONSTANT T_COL_TYPE := 20;
CT_APP_SID						CONSTANT T_COL_TYPE := 21;
CT_CASCADE_ENUM					CONSTANT T_COL_TYPE := 22;
CT_FLOW_ITEM					CONSTANT T_COL_TYPE := 23;
CT_FLOW_REGION					CONSTANT T_COL_TYPE := 24;
CT_CALC							CONSTANT T_COL_TYPE := 25;
CT_ENFORCE_NULLABILITY			CONSTANT T_COL_TYPE := 26;
CT_FLOW_STATE					CONSTANT T_COL_TYPE := 27;
CT_COMPANY						CONSTANT T_COL_TYPE := 28;
CT_TREE							CONSTANT T_COL_TYPE := 29;
CT_CHANGED_BY					CONSTANT T_COL_TYPE := 30;
CT_CONSTRAINED_ENUM				CONSTANT T_COL_TYPE := 31;
CT_OWNER_USER					CONSTANT T_COL_TYPE := 32;
CT_ROLE							CONSTANT T_COL_TYPE := 33;
CT_SURVEY_RESPONSE				CONSTANT T_COL_TYPE := 34;
CT_INTERNAL_AUDIT				CONSTANT T_COL_TYPE := 35;
CT_SUBSTANCE					CONSTANT T_COL_TYPE := 36;
CT_BUSINESS_RELATIONSHIP		CONSTANT T_COL_TYPE := 37;
CT_FORM_SELECTION				CONSTANT T_COL_TYPE := 38;
CT_PRODUCT						CONSTANT T_COL_TYPE := 39;
CT_PERMIT						CONSTANT T_COL_TYPE := 40;

SUBTYPE T_TAB_COLUMN_PERMISSION	IS tab_column_role_permission.permission%TYPE;
TAB_COL_PERM_NONE				CONSTANT T_TAB_COLUMN_PERMISSION := 0;
TAB_COL_PERM_READ_POLICY		CONSTANT T_TAB_COLUMN_PERMISSION := 1;
TAB_COL_PERM_READ				CONSTANT T_TAB_COLUMN_PERMISSION := 2;
TAB_COL_PERM_READ_WRITE			CONSTANT T_TAB_COLUMN_PERMISSION := 3;


FLOW_REGIONS_ALL				CONSTANT NUMBER(10) := 0;
FLOW_REGIONS_PROPERTIES			CONSTANT NUMBER(10) := 1;
FLOW_REGIONS_ROOTS				CONSTANT NUMBER(10) := 2;

-- PERMISSION SETS FOR CmsContainer AND CmsTable
PERMISSION_EXPORT				CONSTANT  security.security_pkg.T_PERMISSION := 65536;
PERMISSION_BULK_EXPORT			CONSTANT  security.security_pkg.T_PERMISSION := 131072;

PERMISSION_STD_READ_EXPORT		CONSTANT security.security_pkg.T_PERMISSION := 196833; -- STANDARD READ (SECURITY_PKG) + Export + Bulk export
PERMISSION_STD_ALL_EXPORT		CONSTANT security.security_pkg.T_PERMISSION := 197631; -- STANDARD ALL (SECURITY_PKG) + Export + Bulk export

PROCEDURE CreateObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id	 				IN	security_pkg.T_SID_ID,
	in_class_id 				IN	security_pkg.T_CLASS_ID,
	in_name 					IN	security_pkg.T_SO_NAME,
	in_parent_sid_id 			IN	security_pkg.T_SID_ID);

PROCEDURE RenameObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id 					IN	security_pkg.T_SID_ID,
	in_new_name 				IN	security_pkg.T_SO_NAME);

PROCEDURE DeleteObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id 					IN	security_pkg.T_SID_ID);

PROCEDURE MoveObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id 					IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id 		IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN	security_pkg.T_SID_ID
	);

-- Raises the given error
PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_args		IN	t_error_array
);

-- Variants with different numbers of arguments
PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER
);

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_arg1		IN	VARCHAR2
);

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_arg1		IN	VARCHAR2,
	in_arg2		IN	VARCHAR2
);

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_arg1		IN	VARCHAR2,
	in_arg2		IN	VARCHAR2,
	in_arg3		IN	VARCHAR2
);

FUNCTION sq(
	s							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC;

-- Internal: dequote a quoted identifier, converting to upper case
-- if it wasn't quoted.  For passing in a table/column/schema name
-- and identifying the correct thing in the metadata tables.
FUNCTION dq(
	s							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC;
PRAGMA RESTRICT_REFERENCES(dq, RNPS, RNDS, WNDS, WNPS);

FUNCTION q( 
	s 							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC;


FUNCTION GetAppSidForTable(
	in_tab_sid					IN	tab.tab_sid%TYPE
)
RETURN security_pkg.T_SID_ID;
PRAGMA RESTRICT_REFERENCES(GetAppSidForTable, RNPS, WNDS, WNPS);


-- Escapes a primary key value as '\' -> '\\', ',' -> '\,'
-- This is used in the item description view for tables that
-- have non-numeric primary key columns.
FUNCTION PkEscape(
	in_s						IN	VARCHAR2
) 
RETURN VARCHAR2
DETERMINISTIC;
PRAGMA RESTRICT_REFERENCES(PkEscape, RNDS, RNPS, WNDS, WNPS);

FUNCTION GetTableSid(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE
) 
RETURN security_pkg.T_SID_ID;
-- TODO: Deterministic? pragma?
--PRAGMA RESTRICT_REFERENCES(GetTableSid,  RNPS, WNDS, WNPS);

FUNCTION GetColumnSid(
	in_tab_sid					IN	security_pkg.T_SID_ID,
	in_oracle_column			IN	tab_column.oracle_column%TYPE
) 
RETURN security_pkg.T_SID_ID;
-- TODO: Deterministic? pragma?
--PRAGMA RESTRICT_REFERENCES(GetTableSid,  RNPS, WNDS, WNPS);



-- Enable tracing of DDL to dbms_output (defaults to OFF)
PROCEDURE EnableTrace;

-- Disable tracing of DDL to dbms_output
PROCEDURE DisableTrace;

-- Enable tracing of DDL to dbms_output WITHOUT running it (defaults to OFF)
PROCEDURE EnableTraceOnly;

-- Disable tracing of DDL to dbms_output WITHOUT running it
PROCEDURE DisableTraceOnly;

-- For upgrading/recreating views for all CMS tables/packages/triggers
-- Useful for testing (or when bugs are found!)
PROCEDURE RecreateViews;

PROCEDURE RecreateView(
	in_tab_sid					IN	tab.tab_sid%TYPE
);

PROCEDURE RecreateView(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE
);

PROCEDURE ReParseComments(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table		        IN	tab.oracle_table%TYPE
);

PROCEDURE RefreshUnmanaged(
	in_app_sid					IN	tab.app_sid%TYPE DEFAULT NULL
);

PROCEDURE RegisterTable(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	VARCHAR2,
	in_managed					IN	BOOLEAN DEFAULT TRUE,
	in_allow_entire_schema		IN	BOOLEAN DEFAULT TRUE	
);

PROCEDURE UnregisterTable(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE
);

PROCEDURE AllowTable(
	in_oracle_schema			IN	app_schema_table.oracle_schema%TYPE,
	in_oracle_table				IN	app_schema_table.oracle_table%TYPE
);

-- Totally unsafe -- drops all tables for the current application
PROCEDURE DropAllTables;

-- Totally unsafe -- drop a single table by name (registered, will not clean up orphaned table SOs)
PROCEDURE DropTable(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_cascade_constraints		IN	BOOLEAN DEFAULT FALSE,
	in_drop_physical			IN	BOOLEAN DEFAULT TRUE
);

PROCEDURE SetColumnDescription(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_description				IN	tab_column.description%TYPE
);

PROCEDURE SetColumnHelp(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	out_help					OUT	tab_column.help%TYPE
);

PROCEDURE SetColumnHelp(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_helptext					IN	VARCHAR2
);

PROCEDURE SetColumnIncludeInSearch(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_include_in_search		IN	tab_column.include_in_search%TYPE
);

PROCEDURE SetColumnShowInFilter(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_show_in_filter			IN	tab_column.show_in_filter%TYPE
);

PROCEDURE SetColumnShowInBreakdown(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_show_in_breakdown		IN	tab_column.show_in_breakdown%TYPE
);

PROCEDURE SetColumnRestrictedByPolicy(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_restricted_by_policy		IN	tab_column.restricted_by_policy%TYPE
);

PROCEDURE SetEnumeratedColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_enumerated_desc_field	IN	tab_column.enumerated_desc_field%TYPE DEFAULT NULL,
	in_enumerated_pos_field		IN	tab_column.enumerated_pos_field%TYPE DEFAULT NULL,
	in_enumerated_colpos_field	IN	tab_column.enumerated_colpos_field%TYPE DEFAULT NULL,
	in_enumerated_colour_field	IN	tab_column.enumerated_colour_field%TYPE DEFAULT NULL,
	in_enumerated_extra_fields	IN	tab_column.enumerated_extra_fields%TYPE DEFAULT NULL
);

PROCEDURE SetSearchEnumColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_enumerated_desc_field	IN	tab_column.enumerated_desc_field%TYPE DEFAULT NULL,
	in_enumerated_pos_field		IN	tab_column.enumerated_pos_field%TYPE DEFAULT NULL
);

PROCEDURE SetConstrainedEnumColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_enumerated_desc_field	IN	tab_column.enumerated_desc_field%TYPE DEFAULT NULL,
	in_enumerated_pos_field		IN	tab_column.enumerated_pos_field%TYPE DEFAULT NULL,
	in_enumerated_colpos_field	IN	tab_column.enumerated_colpos_field%TYPE DEFAULT NULL,
	in_enumerated_colour_field	IN	tab_column.enumerated_colour_field%TYPE DEFAULT NULL,
	in_enumerated_extra_fields	IN	tab_column.enumerated_extra_fields%TYPE DEFAULT NULL
);

PROCEDURE SetVideoColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_video_code				IN	NUMBER DEFAULT 1
);

PROCEDURE SetChartColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_chart					IN	NUMBER DEFAULT 1
);

PROCEDURE SetHtmlColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_html						IN	NUMBER DEFAULT 1
);

PROCEDURE SetFileColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_file_column				IN	tab_column.oracle_column%TYPE,
	in_mime_column				IN	tab_column.oracle_column%TYPE,
	in_name_column				IN	tab_column.oracle_column%TYPE
);

PROCEDURE RenameColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_old_name					IN	tab_column.oracle_column%TYPE,
	in_new_name					IN	tab_column.oracle_column%TYPE
);

PROCEDURE DropColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE
);

/**
 * Adds a new column to a registered table
 *
 * @param		in_oracle_schema			The name of the Oracle schema containing the table to which the new column should be added.
 * @param		in_oracle_table				The name of the Oracle table to which the new column should be added.
 * @param		in_oracle_column			The name of the column to be added.
 * @param		in_type						The type of the column to be added.
 * @param		in_comment					The comment to attach to the new column
 * @param		in_pos						The position of the column (optional, defaults to 0)
 * @param		in_calc_xml					The calculation XML
 */
PROCEDURE AddColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_type						IN	VARCHAR2,
	in_comment					IN	VARCHAR2 DEFAULT NULL,
	in_pos						IN	tab_column.pos%TYPE DEFAULT 0,
	in_calc_xml					IN	tab_column.calc_xml%TYPE DEFAULT NULL
);

PROCEDURE UpdateColumn(
	in_column_sid				IN  tab_column.column_sid%TYPE,
	in_include_in_search		IN  tab_column.include_in_search%TYPE,
	in_show_in_filter			IN  tab_column.show_in_filter%TYPE,
	in_show_in_breakdown		IN  tab_column.show_in_breakdown%TYPE
);

PROCEDURE AddForeignKey(
	in_from_schema				IN	tab.oracle_schema%TYPE,
	in_from_table				IN	tab.oracle_table%TYPE,
	in_from_columns				IN	VARCHAR2,
	in_to_schema				IN	tab.oracle_schema%TYPE,
	in_to_table					IN	tab.oracle_table%TYPE,
	in_to_columns				IN	VARCHAR2,
	in_constraint_name			IN	VARCHAR2,
	in_delete_rule				IN 	VARCHAR2 DEFAULT 'RESTRICT'
);

/**
 * Drops a foreign key
 *
 * @param		in_oracle_schema			The name of the Oracle schema containing the table from which to drop the foreign key
 * @param		in_table_name				The name of the Oracle table from which to drop the foreign key
 * @param		in_column_names				The names of the columns in the parent table, in the order they appeared when the constraint was created, of the foreign key to be dropped
 * @param		in_ref_table_name			The name of the Oracle table that is referenced by the foreign key to be dropped
 * @param		in_ref_column_names			The names of the columns in the referenced table, in the order they appeared when the constraint was created, of the foreign key to be dropped
 */
PROCEDURE DropForeignKey(
	in_oracle_schema 			IN 	tab.oracle_schema%TYPE,
	in_table_name 				IN 	tab.oracle_table%TYPE,
	in_column_names 			IN 	VARCHAR2,
	in_ref_table_name 			IN 	tab.oracle_table%TYPE,
	in_ref_column_names 		IN 	VARCHAR2
);

/**
 * Drops a foreign key, by name
 *
 * @param		in_oracle_schema			The name of the Oracle schema containing the table from which to drop the foreign key
 * @param		in_foreign_key_name			The name of the foreign key to be dropped
 */
PROCEDURE DropForeignKeyByName(
	in_oracle_schema 			IN 	tab.oracle_schema%TYPE,
	in_foreign_key_name 		IN 	fk_cons.constraint_name%TYPE
);

PROCEDURE AddUniqueKey(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_constraint_name			IN	uk_cons.constraint_name%TYPE,
	in_oracle_columns			IN	VARCHAR2
);

PROCEDURE INTERNAL_AddIssueFK(
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_oracle_schema				IN	tab.oracle_schema%TYPE,
	in_i$_table_name				IN	VARCHAR2
);

PROCEDURE GetDetails(
	in_tab_sid					IN	tab.tab_sid%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetTableDefinition(
	in_tab_sid						IN	security_pkg.T_SID_ID,
	out_tab_cur						OUT	SYS_REFCURSOR,
	out_col_cur						OUT	SYS_REFCURSOR,
	out_ck_cur						OUT	SYS_REFCURSOR,
	out_ck_col_cur					OUT	SYS_REFCURSOR,
	out_uk_cur						OUT	SYS_REFCURSOR,
	out_fk_cur						OUT	SYS_REFCURSOR,
	out_flow_tab_col_cons_cur		OUT	SYS_REFCURSOR,
	out_flow_state_user_col_cur		OUT	SYS_REFCURSOR,
	out_measure_cur 				OUT	SYS_REFCURSOR,
	out_measure_conv_cur 			OUT	SYS_REFCURSOR,
	out_measure_conv_period_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetTableDefinitions(
	out_tab_cur						OUT	SYS_REFCURSOR,
	out_col_cur						OUT	SYS_REFCURSOR,
	out_ck_cur						OUT	SYS_REFCURSOR,
	out_ck_col_cur					OUT	SYS_REFCURSOR,
	out_uk_cur						OUT	SYS_REFCURSOR,
	out_fk_cur						OUT	SYS_REFCURSOR,
	out_flow_tab_col_cons_cur		OUT	SYS_REFCURSOR,
	out_flow_state_user_col_cur		OUT	SYS_REFCURSOR,
	out_measure_cur 				OUT	SYS_REFCURSOR,
	out_measure_conv_cur 			OUT	SYS_REFCURSOR,
	out_measure_conv_period_cur		OUT SYS_REFCURSOR
);

PROCEDURE GoToContextIfExists(
	in_context_id				IN	security_pkg.T_SID_ID
);

PROCEDURE GoToContext(
	in_context_id				IN	security_pkg.T_SID_ID
);

PROCEDURE PublishItem(
	in_from_context				IN	context.context_id%TYPE,
	in_to_context				IN	context.context_id%TYPE,
	in_tab_sid					IN	tab.tab_sid%TYPE,
	in_item_id					IN	security_pkg.T_SID_ID
);

PROCEDURE SearchContent(
	in_tab_sids					IN	security_pkg.T_SID_IDS,
	in_part_description			IN  varchar2,
	in_item_ids					IN  security_pkg.T_SID_IDS,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetAppDisplayTemplates(
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE EnsureContextExists(
	in_context					IN	context.context_id%TYPE
);

PROCEDURE GetItemsBeingTracked(
	in_path						IN  link_track.path%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetUserContent(
	out_cur						OUT	SYS_REFCURSOR
); 

PROCEDURE GetFlowRegions(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_flow_region_selector			IN	NUMBER,
	in_phrase						IN  VARCHAR2,
	in_root_lookup_key				IN  VARCHAR2,
	in_tag_lookup_keys				IN  VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowItemRegions(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetCurrentFlowState(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetDefaultFlowState(
	in_tab_sid						IN	tab.tab_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowTransitions(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowTransitions(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowItemTransitions(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	in_is_owner						IN 	csr.flow_state_transition.owner_can_set%TYPE DEFAULT 0,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowItemTransitions(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_is_owner						IN 	csr.flow_state_transition.owner_can_set%TYPE DEFAULT 0,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE EnterFlow(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	out_flow_item_id				OUT	csr.flow_item.flow_item_id%TYPE
);

PROCEDURE EnterFlow(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_flow_item_id				OUT	csr.flow_item.flow_item_id%TYPE
);

PROCEDURE CheckFlowEntry(
	in_tab_sid				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE CheckFlowEntry(
	in_tab_sid				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sids			IN	security_pkg.T_SID_IDS
);

PROCEDURE CheckFlowStateEntry(
	in_tab_sid				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	in_to_flow_state_id		IN  csr.flow_state.flow_state_id%TYPE
);

FUNCTION CloneFlowItem(
	in_flow_item_id				IN  csr.flow_item.flow_item_id%TYPE
) RETURN csr.flow_item.flow_item_id%TYPE;

FUNCTION GetFlowItemEditable(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	in_tab_sid 						IN  security_pkg.T_SID_ID DEFAULT NULL
) RETURN csr.flow_state_role.is_editable%TYPE;

PROCEDURE GetFlowItemEditable(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	in_tab_sid 						IN  security_pkg.T_SID_ID DEFAULT NULL,
	out_editable					OUT	csr.flow_state_role.is_editable%TYPE
);

PROCEDURE GetFlowItemEditable(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_tab_sid 						IN  security_pkg.T_SID_ID DEFAULT NULL,
	out_editable					OUT	csr.flow_state_role.is_editable%TYPE
);

PROCEDURE GetFlowSidFromLabel(
	in_flow_label					IN	csr.flow.label%TYPE,
	out_flow_sid					OUT	csr.flow.flow_sid%TYPE
);

FUNCTION CanSetDefaultStateTrans(
	in_flow_sid						IN	csr.flow.flow_sid%TYPE
)RETURN NUMBER;

PROCEDURE GetDefaultFlowStateEditable(
	in_flow_sid						IN	csr.flow.flow_sid%TYPE,
	out_editable					OUT	csr.flow_state_role.is_editable%TYPE
);

PROCEDURE UpdateUnmanagedFlowStateLabel(
    in_tab_sid                      security_pkg.T_SID_ID,
    in_flow_state_id                csr.flow_state.flow_state_id%TYPE,
    in_where_clause                 VARCHAR2
);

PROCEDURE GetFlowStatesForTables(
	in_table_sids					IN	security.security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE SyncFullTextIndexes;

PROCEDURE GetFlowItemSubscribed(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	out_subscribed					OUT	NUMBER
);

PROCEDURE SubscribeToFlowItem(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE
);

PROCEDURE UnsubscribeFromFlowItem(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE
);

PROCEDURE GetPrimaryKeys(
	in_tab_sid					IN   security_pkg.T_SID_ID,
	out_pk_columns				OUT  SYS_REFCURSOR
);

FUNCTION IsOwner(
	in_tab_sid 				IN   security_pkg.T_SID_ID,
	in_flow_item_id			IN   csr.flow_item.flow_item_id%TYPE
) RETURN NUMBER;

FUNCTION GetAccessLevelForState(
	in_tab_sid 				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	in_flow_state_id		IN	csr.flow_state.flow_state_id%TYPE,
	in_region_sids			IN  security.security_pkg.T_SID_IDS
) RETURN NUMBER;

PROCEDURE GetSchemaForExport(
	out_app_schema_cur				OUT	SYS_REFCURSOR,
	out_app_schema_table_cur		OUT	SYS_REFCURSOR,
	out_tab_cur						OUT	SYS_REFCURSOR,
	out_tab_column_cur				OUT	SYS_REFCURSOR,
	out_tab_column_measure_cur		OUT	SYS_REFCURSOR,
	out_tab_column_role_perm_cur	OUT	SYS_REFCURSOR,
	out_flow_tab_column_cons_cur	OUT	SYS_REFCURSOR,
	out_uk_cons_cur					OUT	SYS_REFCURSOR,
	out_uk_cons_col_cur				OUT	SYS_REFCURSOR,
	out_fk_cons_cur					OUT	SYS_REFCURSOR,
	out_fk_cons_col_cur				OUT	SYS_REFCURSOR,
	out_ck_cons_cur					OUT	SYS_REFCURSOR,
	out_ck_cons_col_cur				OUT	SYS_REFCURSOR,
	out_form_cur					OUT	SYS_REFCURSOR,
	out_form_version_cur			OUT	SYS_REFCURSOR,
	out_filter_cur					OUT	SYS_REFCURSOR,
	out_display_template			OUT	SYS_REFCURSOR,
	out_web_publication				OUT	SYS_REFCURSOR,
	out_link_track					OUT	SYS_REFCURSOR,
	out_image						OUT	SYS_REFCURSOR,
	out_image_tag					OUT	SYS_REFCURSOR,
	out_tag							OUT	SYS_REFCURSOR,
	out_tab_column_link				OUT	SYS_REFCURSOR,
	out_tab_column_link_type		OUT	SYS_REFCURSOR,
	out_tab_aggregate_ind			OUT	SYS_REFCURSOR,
	out_tab_issue_aggregate_ind		OUT	SYS_REFCURSOR,
	out_cms_aggregate_type			OUT	SYS_REFCURSOR,
	out_doc_template				OUT	SYS_REFCURSOR,
	out_doc_template_file			OUT SYS_REFCURSOR,
	out_doc_template_version		OUT SYS_REFCURSOR,
	out_cms_data_helper				OUT	SYS_REFCURSOR,
	out_enum_tabs_cur				OUT	SYS_REFCURSOR,
	out_enum_groups_cur				OUT	SYS_REFCURSOR,
	out_enum_groups_members_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetDDLForExport(
	out_tables_cur					OUT	SYS_REFCURSOR,
	out_tab_column_cur				OUT	SYS_REFCURSOR,
	out_cons_cur					OUT	SYS_REFCURSOR,
	out_cons_column_cur				OUT	SYS_REFCURSOR,
	out_indexes_cur					OUT	SYS_REFCURSOR,
	out_ind_column_cur				OUT	SYS_REFCURSOR,
	out_ind_expr_cur				OUT	SYS_REFCURSOR,
	out_tab_privs_cur				OUT	SYS_REFCURSOR,
	out_tab_comments_cur			OUT	SYS_REFCURSOR,
	out_col_comments_cur			OUT	SYS_REFCURSOR
);

PROCEDURE CreateImportedSchema;

PROCEDURE PostCreateImportedSchema;

PROCEDURE TestDDLImport(
	in_owner						IN	tab.oracle_schema%TYPE,
	in_new_owner					IN	tab.oracle_schema%TYPE
);

PROCEDURE GetTablesForExport(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTableDataForExport(
	in_owner						IN	VARCHAR2,
	in_table_name					IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE SetCmsSchemaMappings(
	in_old_schemas					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_new_schemas					IN	security_pkg.T_VARCHAR2_ARRAY
);

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE;

FUNCTION FlowItemRecordExists(
	in_flow_item_id				IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER;

FUNCTION GetFlowRoleSid(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE, 
	in_col_sid			IN	tab_column.column_sid%TYPE
)RETURN security_pkg.T_SID_ID;

FUNCTION GetFlowCompanySid(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE, 
	in_col_sid			IN	tab_column.column_sid%TYPE
)RETURN security_pkg.T_SID_ID;

PROCEDURE GenerateUserColumnAlerts(
	in_flow_item_id				IN	csr.flow_item.flow_item_id%TYPE,
	in_set_by_user_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id		IN	csr.flow_state_log.flow_state_log_id%TYPE,
	in_flow_state_transition_id	IN  csr.flow_state_transition.flow_state_transition_id%TYPE
);

PROCEDURE GenerateRoleColumnAlerts(
	in_flow_item_id				IN	csr.flow_item.flow_item_id%TYPE,
	in_set_by_user_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id		IN	csr.flow_state_log.flow_state_log_id%TYPE,
	in_flow_state_transition_id	IN	csr.flow_state_transition.flow_state_transition_id%TYPE,
	in_region_sids_t			IN	security.T_SID_TABLE
);

PROCEDURE GenerateCompanyColumnAlerts(
	in_flow_item_id				IN	csr.flow_item.flow_item_id%TYPE,
	in_set_by_user_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id		IN	csr.flow_state_log.flow_state_log_id%TYPE,
	in_flow_state_transition_id	IN	csr.flow_state_transition.flow_state_transition_id%TYPE
);

PROCEDURE MarkGenAlertsRefDeletedCms(
	in_flow_transition_alert_id IN csr.flow_transition_alert.flow_transition_alert_id %TYPE
);

FUNCTION TryGetCompanyColTypeName(
	in_tab_sid		IN tab_column.tab_sid%TYPE,
	out_col_name	OUT tab_column.oracle_column%TYPE
)RETURN BOOLEAN;

FUNCTION GetParentTabSid(
	in_col_sid		IN tab_column.column_sid%TYPE
)RETURN tab.tab_sid%TYPE;

FUNCTION TryGetEnumDescription(
	in_enum_tab_sid		IN tab_column.tab_sid%TYPE,
	in_fk_col_sid		IN tab_column.column_sid%TYPE,
	in_enum_id			IN NUMBER,
	out_description		OUT VARCHAR2
)RETURN BOOLEAN;

FUNCTION TryGetEnumValFromMapTable(
	in_enum_tab_sid		IN tab_column.tab_sid%TYPE,
	in_fk_col_sid		IN tab_column.column_sid%TYPE,
	in_original_text	IN VARCHAR2,
	out_enum_id			OUT NUMBER,
	out_translated_val	OUT VARCHAR2
)RETURN BOOLEAN;

FUNCTION TryGetEnumVal(
	in_tab_sid			IN tab_column.tab_sid%TYPE,
	in_fk_col_sid		IN tab_column.column_sid%TYPE,
	in_original_text	IN VARCHAR2,
	out_enum_id			OUT NUMBER
)RETURN BOOLEAN;

FUNCTION GetUCColsInclColType(
	in_tab_sid			cms.tab.tab_sid%TYPE,
	in_col_type_incl	cms.tab_column.col_type%TYPE
) RETURN security.T_VARCHAR2_TABLE;

PROCEDURE GatherStats;

PROCEDURE GetEnumGroups(
	out_enum_tabs_cur				OUT	SYS_REFCURSOR,
	out_enum_groups_cur				OUT	SYS_REFCURSOR,
	out_enum_groups_members_cur		OUT SYS_REFCURSOR
);

PROCEDURE SaveEnumGroup(
	in_enum_group_id				IN  enum_group.enum_group_id%TYPE,
	in_tab_sid     					IN  enum_group.tab_sid%TYPE,	
	in_group_label					IN  enum_group.group_label%TYPE,
	in_member_ids     				IN  security.security_pkg.T_SID_IDS,
	out_enum_group_id				OUT enum_group.enum_group_id%TYPE
);

PROCEDURE SaveEnumTab(
	in_tab_sid						IN  enum_group_tab.tab_sid%TYPE,
	in_label						IN  enum_group_tab.label%TYPE,
	in_replace_existing_filters		IN  enum_group_tab.replace_existing_filters%TYPE
);

PROCEDURE DeleteRemainingEnumGroups (
	in_tab_sid						IN  enum_group_tab.tab_sid%TYPE,
	in_group_ids_to_keep			IN  security.security_pkg.T_SID_IDS
);

PROCEDURE DeleteEnumTab(
	in_tab_sid						IN  enum_group.tab_sid%TYPE
);

/*
 * Get CMS workflow statistics for aggregate ind job. Standard interface.
 *
 * @param in_aggregate_ind_group_id		Aggregate Ind Group ID
 * @param in_start_dtm					Start of reporting periods range (month start)
 * @param in_end_dtm					End of reporting periods range (month start of proceeding month)
 */
PROCEDURE GetCmsTableFlowValues(
	in_aggregate_ind_group_id	IN	csr.aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security.security_pkg.T_OUTPUT_CUR
);

END;
/


CREATE OR REPLACE PACKAGE BODY CMS.temp_tab_pkg AS

TYPE t_ddl IS TABLE OF CLOB;
TYPE t_tab_set IS TABLE OF NUMBER(1) INDEX BY PLS_INTEGER;
TYPE t_string_list IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;

TYPE CommentParseState IS RECORD
(
	text	VARCHAR2(4000),
	name	VARCHAR2(1000),
	value	VARCHAR2(4000),
	sep		VARCHAR2(1),
	pos		BINARY_INTEGER DEFAULT 1,
	quoted	BOOLEAN
);

m_trace BOOLEAN DEFAULT FALSE;
m_trace_only BOOLEAN DEFAULT FALSE;

PROCEDURE ParseQuotedList(
	in_quoted_list				IN	VARCHAR2,
	out_string_list				OUT	t_string_list
);

PROCEDURE GetTableForWrite(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	out_tab_sid					OUT	tab_column.column_sid%TYPE
);

PROCEDURE GetTableForDDL(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_check_managed			IN	BOOLEAN DEFAULT TRUE,
	out_tab_sid					OUT	tab_column.column_sid%TYPE
);

PROCEDURE GetColumnForWrite(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	out_tab_sid					OUT	tab.tab_sid%TYPE,
	out_col_sid					OUT	tab_column.column_sid%TYPE
);

PROCEDURE GetColumnForDDL(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	out_tab_sid					OUT	tab.tab_sid%TYPE,
	out_col_sid					OUT	tab_column.column_sid%TYPE
);

PROCEDURE RegisterTable_(
	in_tables_sid				IN				security_pkg.T_SID_ID,
	in_owner					IN				tab.oracle_schema%TYPE,
	in_table_name				IN				tab.oracle_table%TYPE,
	in_managed					IN				BOOLEAN,
	in_is_view					IN				BOOLEAN,
	in_auto_registered			IN				BOOLEAN,
	in_refresh					IN				BOOLEAN,
	io_ddl						IN OUT NOCOPY	t_ddl,
	io_tab_set					IN OUT NOCOPY	t_tab_set
);

FUNCTION GetUserFlowItemTransitions(
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sids			IN  security.security_pkg.T_SID_IDS
) RETURN security.T_SID_TABLE;

-- Errors we generate
m_errors t_error_array := t_error_array(
'',
'',
'cannot modify primary key values for version-enabled table (constraint id %1)',
'',
'integrity constraint (%1) violated - child record found',
'integrity constraint (%1) violated - parent key not found',
'',
'',
'',
'unique constraint (%1) violated',
'the row is locked for editing in context %1'
);

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_args		IN	t_error_array
)
AS
	v_msg		VARCHAR2(4000);
	v_start		BINARY_INTEGER;
	v_pos		BINARY_INTEGER := 1;
	v_n			BINARY_INTEGER;
	v_error		VARCHAR2(500);
BEGIN
	v_error := m_errors(-in_num-20000);
	LOOP
		v_start := v_pos;
		v_pos := INSTR(v_error, '%', v_pos);
		IF v_pos > 0 THEN
			v_n := TO_NUMBER(SUBSTR(v_error, v_pos + 1, 1));
			v_msg := v_msg || SUBSTR(v_error, v_start, v_pos - v_start) ||
					 in_args(v_n);
			v_pos := v_pos + 2;
		ELSE
			v_msg := v_msg || SUBSTR(v_error, v_start, LENGTH(v_error) - v_start + 1);
			RAISE_APPLICATION_ERROR(in_num, v_msg);
		END IF;
	END LOOP;
END;

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER
)
AS
BEGIN
	RaiseError(in_num, t_error_array());
END;

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_arg1		IN	VARCHAR2
)
AS
BEGIN
	RaiseError(in_num, t_error_array(in_arg1));
END;

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_arg1		IN	VARCHAR2,
	in_arg2		IN	VARCHAR2
)
AS
BEGIN
	RaiseError(in_num, t_error_array(in_arg1, in_arg2));
END;

PROCEDURE RaiseError(
	in_num		IN	BINARY_INTEGER,
	in_arg1		IN	VARCHAR2,
	in_arg2		IN	VARCHAR2,
	in_arg3		IN	VARCHAR2
)
AS
BEGIN
	RaiseError(in_num, t_error_array(in_arg1, in_arg2, in_arg3));
END;

PROCEDURE WriteAppend(
	in_clob						IN OUT NOCOPY	CLOB,
	in_str						IN				VARCHAR2
)
AS
BEGIN
	dbms_lob.writeappend(in_clob, LENGTH(in_str), in_str);
END;

-- security interface procs
PROCEDURE CreateObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id	 				IN	security_pkg.T_SID_ID,
	in_class_id 				IN	security_pkg.T_CLASS_ID,
	in_name 					IN	security_pkg.T_SO_NAME,
	in_parent_sid_id 			IN	security_pkg.T_SID_ID)
IS
BEGIN
	NULL;
END CreateObject;


PROCEDURE RenameObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id 					IN	security_pkg.T_SID_ID,
	in_new_name 				IN	security_pkg.T_SO_NAME)
IS
BEGIN
	NULL;
END RenameObject;

PROCEDURE DeleteObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id 					IN	security_pkg.T_SID_ID)
IS
	v_oracle_schema				tab.oracle_schema%TYPE;
	v_oracle_table				tab.oracle_table%TYPE;
	-- standard constraint violated exception
	CHILD_RECORD_FOUND EXCEPTION;
	PRAGMA EXCEPTION_INIT(CHILD_RECORD_FOUND, -02292);	
BEGIN
	-- Delete any filters saved in chain
	chain.filter_pkg.DeleteFiltersForTabSid(in_act, in_sid_id);
	
	-- Delete all FKs
	DELETE FROM fk_cons_col
	 WHERE fk_cons_id IN (SELECT fk_cons_id
	 						FROM fk_cons
	 					   WHERE tab_sid = in_sid_id);
						   
	UPDATE tab
	   SET securable_fk_cons_id = NULL
	 WHERE securable_fk_cons_id IN (
			SELECT fk_cons_id
	 		  FROM fk_cons
			 WHERE tab_sid = in_sid_id);
						
	DELETE FROM fk_cons
	 WHERE tab_sid = in_sid_id;
	 
	 
	DELETE FROM fk_cons_col
	 WHERE fk_cons_id IN (
        SELECT fk_cons_id 
          FROM fk_cons f, uk_cons u
         WHERE f.r_cons_id = u.uk_cons_id  
           AND u.tab_sid = in_sid_id
    );
	
	UPDATE tab
	   SET securable_fk_cons_id = NULL
	 WHERE securable_fk_cons_id IN (
		SELECT fk_cons_id 
          FROM fk_cons f, uk_cons u
         WHERE f.r_cons_id = u.uk_cons_id  
           AND u.tab_sid = in_sid_id);
    
	DELETE FROM fk_cons
	 WHERE fk_cons_id IN (
        SELECT fk_cons_id 
          FROM fk_cons f, uk_cons u
         WHERE f.r_cons_id = u.uk_cons_id  
           AND u.tab_sid = in_sid_id
    );

	UPDATE tab
	   SET enum_translation_tab_sid = NULL
	 WHERE enum_translation_tab_sid = in_sid_id;

	-- Clean the PK off for RI
	UPDATE tab
	   SET pk_cons_id = NULL
	 WHERE tab_sid = in_sid_id;
	 
	-- Clean up constraints
	DELETE FROM uk_cons_col
	 WHERE uk_cons_id IN (SELECT uk_cons_id
	 						FROM uk_cons
	 					   WHERE tab_sid = in_sid_id);
	DELETE FROM uk_cons
	 WHERE tab_sid = in_sid_id;

	-- clean up web publications
	FOR r IN (SELECT wp.web_publication_id
				FROM web_publication wp, display_template dt
			   WHERE wp.display_template_id = dt.display_template_id AND dt.tab_sid = in_sid_id) LOOP
		SecurableObject_pkg.DeleteSO(in_act, r.web_publication_id);
	END LOOP;

	-- clean up templates
	-- some web_publication_ids weren't sids in the past
	DELETE FROM web_publication
	 WHERE display_template_id IN (
			SELECT display_template_id
			  FROM display_template 
			 WHERE tab_sid = in_sid_id);

	DELETE FROM display_template
	 WHERE tab_sid = in_sid_id;
	 
	-- clean up link tracking
	DELETE FROM link_track
	 WHERE column_sid IN (
	 	SELECT column_sid
	 	  FROM tab_column
	 	 WHERE tab_sid = in_sid_id
	 );
	 
	-- clean up saved search filters
	DELETE FROM active_session_filter
	 WHERE tab_sid = in_sid_id;
	
	FOR r IN (SELECT filter_sid
				FROM filter
			   WHERE tab_sid = in_sid_id) LOOP
		SecurableObject_pkg.DeleteSO(in_act, r.filter_sid);
	END LOOP;
	
	-- clean up saved reports
	FOR r IN (SELECT saved_filter_sid
				FROM chain.saved_filter
			   WHERE card_group_id = chain.filter_pkg.FILTER_TYPE_CMS
				 AND cms_id_column_sid IN (SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id)) LOOP
		SecurableObject_pkg.DeleteSO(in_act, r.saved_filter_sid);
	END LOOP;
	
	-- clean up filter CMS tables
	DELETE FROM chain.filter_page_cms_table
	 WHERE column_sid IN (SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id);
	
	-- clean up forms
	DELETE FROM form_version
	 WHERE form_sid IN (
		SELECT form_sid
		  FROM form
		 WHERE parent_tab_sid = in_sid_id
	);
	
	DELETE FROM form
	 WHERE parent_tab_sid = in_sid_id;
	 
	-- clean up table info
    DELETE FROM ck_cons_col
     WHERE column_sid IN (
        SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id
     );

	DELETE FROM flow_tab_column_cons 
	 WHERE column_sid IN (
		SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id
	 );
	 
	DELETE FROM csr.flow_transition_alert_cms_col
	 WHERE column_sid IN (
		SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id
	 );
	
	DELETE FROM csr.flow_state_cms_col
	 WHERE column_sid IN (
		SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id
	 );
	
	DELETE FROM csr.flow_state_transition_cms_col
	 WHERE column_sid IN (
		SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id
	 );
	
	UPDATE tab
	   SET region_col_sid = NULL
	 WHERE tab_sid = in_sid_id;

	DELETE FROM tab_column_role_permission
	 WHERE column_sid IN (
		SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id
	 );
	 
	DELETE FROM tab_column_link
	 WHERE column_sid_1 IN (
		SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id
	 )
	    OR column_sid_2 IN (
		SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id
	 );   

	DELETE FROM tab_column_link_type
	 WHERE column_sid IN (
		SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id
	 )
	    OR link_column_sid IN (
		SELECT column_sid FROM tab_column WHERE tab_sid = in_sid_id
	 );  
	 
	DELETE FROM tab_aggregate_ind
	 WHERE tab_sid = in_sid_id;
	 
	DELETE FROM tab_issue_aggregate_ind
	 WHERE tab_sid = in_sid_id;
	
	DELETE FROM cms_aggregate_type
	 WHERE tab_sid = in_sid_id;

	DELETE FROM ck_cons
	 WHERE tab_sid = in_sid_id;

	DELETE FROM enum_group_member
	 WHERE enum_group_id IN (
		SELECT enum_group_id
		  FROM enum_group
		 WHERE tab_sid = in_sid_id
	 );

	DELETE FROM enum_group
	 WHERE tab_sid = in_sid_id;

	DELETE FROM enum_group_tab
	 WHERE tab_sid = in_sid_id;

	DELETE FROM csr.flow_item_generated_alert
	 WHERE (app_sid, flow_transition_alert_id) IN (
        SELECT app_sid, flow_transition_alert_id 
          FROM csr.flow_transition_alert 
         WHERE (app_sid, helper_sp) IN (
            SELECT app_sid, helper_sp FROM csr.cms_alert_helper WHERE tab_sid = in_sid_id
         )
	 );
    
	DELETE FROM csr.flow_transition_alert
	 WHERE (app_sid, helper_sp) IN (
		SELECT app_sid, helper_sp FROM csr.cms_alert_helper WHERE tab_sid = in_sid_id
	 );

	DELETE FROM csr.approval_dashboard_tpl_tag
	 WHERE (app_sid, tpl_report_sid, tag) IN (
		SELECT trt.app_sid, trt.tpl_report_sid, trt.tag
		  FROM csr.tpl_report_tag trt, csr.tpl_report_tag_logging_form trtlf
		 WHERE trt.app_sid = trtlf.app_sid AND trt.tpl_report_tag_logging_form_id = trtlf.tpl_report_tag_logging_form_id
		   AND trtlf.tab_sid = in_sid_id);
		   
	DELETE FROM csr.tpl_report_tag
	 WHERE (app_sid, tpl_report_tag_logging_form_id) IN (
		SELECT app_sid, tpl_report_tag_logging_form_id
		  FROM csr.tpl_report_tag_logging_form 
		 WHERE tab_sid = in_sid_id);
	 
	DELETE FROM csr.tpl_report_tag_logging_form
	 WHERE tab_sid = in_sid_id;
	 
    DELETE FROM csr.cms_alert_helper
	 WHERE tab_sid = in_sid_id;
	 
	DELETE FROM pivot
	 WHERE tab_sid = in_sid_id;
    
	DELETE FROM csr.cms_alert_type
	 WHERE tab_sid = in_sid_id;	
	
	DELETE FROM csr.logistics_error_log
	 WHERE tab_sid = in_sid_id;
	 
	DELETE FROM csr.logistics_tab_mode
	 WHERE tab_sid = in_sid_id;
	 
	UPDATE csr.internal_audit_type
	   SET tab_sid = null,
	       form_path = null
	 WHERE tab_sid = in_sid_id;
	 
	UPDATE csr.auto_imp_importer_cms
	   SET tab_sid = null
	 WHERE tab_sid = in_sid_id;
	 
	csr.plugin_pkg.DeleteCmsPlugins(in_sid_id);

	DELETE FROM chain.dedupe_merge_log
	 WHERE destination_tab_sid = in_sid_id;

	DELETE FROM chain.dedupe_mapping
	 WHERE tab_sid = in_sid_id
	    OR destination_tab_sid = in_sid_id;

	DELETE FROM chain.dedupe_match
	 WHERE dedupe_rule_set_id IN (
		SELECT dedupe_rule_set_id
		  FROM chain.dedupe_rule_set
		 WHERE dedupe_staging_link_id IN (
			SELECT dedupe_staging_link_id
			  FROM chain.dedupe_staging_link
			 WHERE staging_tab_sid = in_sid_id
				OR destination_tab_sid = in_sid_id));

	DELETE FROM chain.dedupe_rule_set
	 WHERE dedupe_staging_link_id IN (
		SELECT dedupe_staging_link_id
		  FROM chain.dedupe_staging_link
		 WHERE staging_tab_sid = in_sid_id
			OR destination_tab_sid = in_sid_id);

	DELETE FROM chain.dedupe_merge_log
	 WHERE dedupe_processed_record_id IN (
		SELECT dedupe_processed_record_id
		  FROM chain.dedupe_processed_record
		 WHERE dedupe_staging_link_id IN (
			SELECT dedupe_staging_link_id
			  FROM chain.dedupe_staging_link
			 WHERE staging_tab_sid = in_sid_id
				OR destination_tab_sid = in_sid_id));

	DELETE FROM chain.dedupe_processed_record
	 WHERE dedupe_staging_link_id IN (
		SELECT dedupe_staging_link_id
		  FROM chain.dedupe_staging_link
		 WHERE staging_tab_sid = in_sid_id
			OR destination_tab_sid = in_sid_id);

	DELETE FROM chain.dedupe_staging_link
	 WHERE staging_tab_sid = in_sid_id
	    OR destination_tab_sid = in_sid_id;
	
	DELETE FROM tab_column
	 WHERE tab_sid = in_sid_id;

	BEGIN
		SELECT oracle_schema, oracle_table
		  INTO v_oracle_schema, v_oracle_table
		  FROM tab
		 WHERE tab_sid = in_sid_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	DELETE FROM tab
	 WHERE tab_sid = in_sid_id;
	
	-- clean up the shared table reference (this will fail if this
	-- is not the last reference to the table -- we can't check that
	-- in advance of running the statement due to RLS)
	IF v_oracle_schema IS NOT NULL AND v_oracle_table IS NOT NULL THEN
		BEGIN
			DELETE FROM oracle_tab
			 WHERE oracle_schema = v_oracle_schema
			   AND oracle_table = v_oracle_table;
		EXCEPTION
			WHEN CHILD_RECORD_FOUND THEN
				NULL;
		END;
	END IF;
END DeleteObject;

PROCEDURE MoveObject(
	in_act 						IN	security_pkg.T_ACT_ID,
	in_sid_id 					IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id 		IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN	security_pkg.T_SID_ID
	)
IS
BEGIN
	NULL;
END MoveObject;

FUNCTION comma(
	s							IN	VARCHAR2,
	sep							IN	VARCHAR2 default ', '
)
RETURN VARCHAR2
DETERMINISTIC
AS
BEGIN
	IF s IS NULL THEN
		RETURN s;
	END IF;
	RETURN s || sep;
END;

FUNCTION q( 
	s 							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC
IS
BEGIN
    RETURN '"'||s||'"';
END;
	
FUNCTION qs(
	s 							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC
IS
BEGIN
    RETURN '"'||REPLACE(s,'''','''''')||'"';
END;

FUNCTION sq(
	s							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC
IS
BEGIN
    RETURN ''''||REPLACE(s,'''','''''')||'''';
END;

FUNCTION dq(
	s							IN	VARCHAR2
)
RETURN VARCHAR2
DETERMINISTIC
IS
	v_r		VARCHAR2(30);
BEGIN
	IF SUBSTR(s, 1, 1) = '"' THEN
		IF SUBSTR(s, -1, 1) <> '"' THEN
			RAISE_APPLICATION_ERROR(-20001, 'Missing quote in identifier '||s);
		END IF;
		v_r := SUBSTR(s, 2, LENGTH(s) - 2);
		IF INSTR(v_r, '"') <> 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Embedded quote in quoted identifier '||s);
		END IF;
		RETURN v_r;
	END IF;
	RETURN UPPER(s);
END;

FUNCTION QuotedList(
	in_string_list					IN	t_string_list
)
RETURN VARCHAR
DETERMINISTIC
AS
	v_result	VARCHAR2(32767);
BEGIN
	FOR i IN 1 .. in_string_list.COUNT LOOP
		IF v_result IS NOT NULL THEN
			v_result := v_result || ',';
		END IF;
		v_result := v_result || q(in_string_list(i));
	END LOOP;
	RETURN v_result;
END;

PROCEDURE GetPkCols(
	in_tab_sid					IN	tab.tab_sid%TYPE,
	out_cols					OUT	t_string_list
)
AS
BEGIN
    SELECT tc.oracle_column
      BULK COLLECT INTO out_cols
      FROM tab_column tc, tab t, uk_cons uk, uk_cons_col ukc
     WHERE t.pk_cons_id = uk.uk_cons_id AND uk.uk_cons_id = ukc.uk_cons_id AND
           ukc.column_sid = tc.column_sid AND t.tab_sid = in_tab_sid
     ORDER BY ukc.pos;
END;

FUNCTION BoolToNum(
	in_bool						IN BOOLEAN
) RETURN NUMBER
DETERMINISTIC
AS
BEGIN
	IF in_bool THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

FUNCTION SanitiseDataDefault (
	in_data_default				IN  VARCHAR2
) RETURN VARCHAR2
DETERMINISTIC
AS
	v_data_default				VARCHAR2(255) := SUBSTR(TRIM(in_data_default), 1, 255);
BEGIN
	-- if default has brackets around them, strip them off as the JS + app don't support that
	IF SUBSTR(v_data_default, 1, 1) = '(' AND SUBSTR(v_data_default, LENGTH(v_data_default), 1) = ')' THEN
		v_data_default := SUBSTR(v_data_default, 2, LENGTH(v_data_default) - 2);
	END IF;
	
	RETURN v_data_default;
END;

PROCEDURE WriteHelperPackageCalls(
	in_tab_sid						IN				tab.tab_sid%TYPE,
	io_lob							IN OUT NOCOPY	CLOB,
	in_pk_columns					IN				t_string_list,
	in_fn							IN				VARCHAR2,
	in_pk_from						IN				VARCHAR2,
	in_old_values					IN				BOOLEAN,
	in_new_values					IN				BOOLEAN
)
AS
	v_last_helper_pkg								tab_column.helper_pkg%TYPE;
BEGIN
	v_last_helper_pkg := NULL;
	FOR r IN (SELECT helper_pkg, oracle_column
				FROM tab_column
			   WHERE tab_sid = in_tab_sid
			     AND helper_pkg IS NOT NULL
			   ORDER BY LOWER(helper_pkg), pos) LOOP
		IF v_last_helper_pkg IS NULL OR LOWER(v_last_helper_pkg) != LOWER(r.helper_pkg) THEN
			IF v_last_helper_pkg IS NOT NULL THEN
				WriteAppend(io_lob, ');'||chr(10));
			END IF;
			
			WriteAppend(io_lob, 
				'    '||r.helper_pkg||'.'||in_fn||'(');
			FOR i IN 1 .. in_pk_columns.COUNT LOOP
				IF i != 1 THEN
					WriteAppend(io_lob, ', ');
				END IF;
				WriteAppend(io_lob, in_pk_from||'.'||q(in_pk_columns(i)));
			END LOOP;
			
			v_last_helper_pkg := r.helper_pkg;
		END IF;
		
		IF in_old_values THEN
			WriteAppend(io_lob, ', :OLD.'||q(r.oracle_column));
		END IF;
		IF in_new_values THEN
			WriteAppend(io_lob, ', :NEW.'||q(r.oracle_column));
		END IF;		
	END LOOP;
	IF v_last_helper_pkg IS NOT NULL THEN
		WriteAppend(io_lob, ');'||chr(10));
	END IF;
END;

FUNCTION GetTableSid(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE
) 
RETURN security_pkg.T_SID_ID
AS
	v_tab_sid 		security_pkg.T_SID_ID;
BEGIN
	SELECT tab_sid INTO v_tab_sid FROM tab WHERE oracle_schema = in_oracle_schema AND oracle_table = in_oracle_table;
	RETURN v_tab_sid;
END;

FUNCTION GetColumnSid(
	in_tab_sid					IN	security_pkg.T_SID_ID,
	in_oracle_column			IN	tab_column.oracle_column%TYPE
) 
RETURN security_pkg.T_SID_ID
AS
	v_col_sid 		security_pkg.T_SID_ID;
BEGIN
	SELECT column_sid
	  INTO v_col_sid
	  FROM tab_column
	 WHERE tab_sid = in_tab_sid
	   AND oracle_column = in_oracle_column;
	RETURN v_col_sid;
END;

PROCEDURE WriteContextClause(
	io_lob						IN OUT NOCOPY	CLOB,
	in_indent					IN VARCHAR2
)
AS
BEGIN
	WriteAppend(io_lob, 
		           '((i.context_id in ('||chr(10)||
		in_indent||'     select parent_context_id '||chr(10)||
		in_indent||'       from cms.fast_context '||chr(10)||
		in_indent||'      where context_id = nvl(sys_context(''SECURITY'',''CONTEXT_ID''),0))'||chr(10)||
		in_indent||'  and'||chr(10)||
		in_indent||'  (i.locked_by is null or '||chr(10)||
		in_indent||'   (i.locked_by <> nvl(sys_context(''SECURITY'',''CONTEXT_ID''),0)'||chr(10)||
		in_indent||'    and i.locked_by not in (select parent_context_id'||chr(10)||
		in_indent||'                              from cms.fast_context'||chr(10)||
		in_indent||'                             where context_id = nvl(sys_context(''SECURITY'',''CONTEXT_ID''),0))'||chr(10)||
		in_indent||' )))'||chr(10)||
		in_indent||' or'||chr(10)||
		in_indent||' i.context_id = nvl(sys_context(''SECURITY'',''CONTEXT_ID''),0)'||chr(10)||
		in_indent||')');
END;

PROCEDURE WriteCurrentClause(
	io_lob						IN OUT NOCOPY	CLOB,
	in_indent					IN VARCHAR2
)
AS
BEGIN
	WriteAppend(io_lob, 
		           'systimestamp >= i.created_dtm'||chr(10)||
		in_indent||'and ( systimestamp < i.retired_dtm or i.retired_dtm is null )'||chr(10)||
		in_indent||'and i.vers > 0');
END;

PROCEDURE CreateTriggers(
	in_tab_sid					IN			  tab.tab_sid%TYPE,
	io_ddl						IN OUT NOCOPY t_ddl
)
AS
	v_s					CLOB;
	v_d					CLOB;
	v_u					CLOB;
	v_i					CLOB;
	v_p					CLOB;
	v_c					VARCHAR2(200);
	v_c_tab				VARCHAR2(100);
	v_l_tab				VARCHAR2(100);
	v_tab				VARCHAR2(100);
	v_cols				VARCHAR2(8000);			-- cols for view
	v_u_vals			VARCHAR2(8000);			-- vals for updates ("N$COL")
	v_i_vals			VARCHAR2(8000);			-- vals for inserts (NVL("N$COL", column_default))
	v_i_args			VARCHAR2(8000);			-- args for i calls in package
	v_u_args			VARCHAR2(8000);			-- args for u calls in package
	v_d_args			VARCHAR2(8000);			-- args for d calls in package
	v_owner				tab.oracle_schema%TYPE;
	v_table_name		tab.oracle_table%TYPE;	
	v_pk_columns		t_string_list;
	v_uk_columns		t_string_list;
	v_parent_lock		VARCHAR2(32767);
	v_t					VARCHAR2(32767);
	v_t2				VARCHAR2(32767);
	v_t3				VARCHAR2(32767);
	v_t4				VARCHAR2(32767);
	v_first				BOOLEAN;
	v_pk_cons_id		tab.pk_cons_id%TYPE;
	v_base_tab			VARCHAR2(30);
BEGIN
	SELECT oracle_schema, oracle_table, pk_cons_id
	  INTO v_owner, v_table_name, v_pk_cons_id
	  FROM tab 
	 WHERE tab_sid = in_tab_sid;
	GetPkCols(in_tab_sid, v_pk_columns);

	-- Figure out the current base table name (it's either C$TABLE, if already registered
	-- and we are recreating the triggers, or just TABLE if it's not)
	BEGIN
		SELECT table_name
		  INTO v_base_tab
		  FROM all_tables
		 WHERE table_name = 'C$'||v_table_name
		   AND owner = v_owner;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_base_tab := v_table_name;
	END;
	
	-- Get all UK key columns -- the trigger has to pass these on to the package
    SELECT tc.oracle_column
      BULK COLLECT INTO v_uk_columns
      FROM tab_column tc, uk_cons uk, uk_cons_col ukc
     WHERE uk.tab_sid = in_tab_sid AND uk.uk_cons_id = ukc.uk_cons_id AND
           ukc.column_sid = tc.column_sid
     GROUP BY tc.oracle_column;
	
	v_c_tab := q(v_owner) || '.' || q('C$' || v_table_name);
 	v_l_tab := q(v_owner) || '.' || q('L$' || v_table_name);
	v_tab   := q(v_owner) || '.' || q(v_table_name);
	
	v_s :=
		'create or replace package '||q(v_owner)||'.'||q('T$'||v_table_name)||chr(10)||
		'as'||chr(10);
	v_i :=
		'    procedure i'||chr(10)||
		'    ('||chr(10);
	v_u :=
		'    procedure u'||chr(10)||
		'    ('||chr(10);
	v_d :=
		'    procedure d'||chr(10)||
		'    ('||chr(10);
	v_p :=
		'    procedure p'||chr(10)||
		'    ('||chr(10)||
		'        '||rpad(q('FROM_CONTEXT'), 32)||' in  '||v_c_tab||'."CONTEXT_ID"%TYPE,'||chr(10)||
		'        '||rpad(q('TO_CONTEXT'), 32)||' in  '||v_c_tab||'."CONTEXT_ID"%TYPE,'||chr(10);
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_p,
		'        '||rpad(q('N$'||v_pk_columns(i)), 32)||' in  '||v_c_tab||'.'||q(v_pk_columns(i))||'%TYPE');
		IF i <> v_pk_columns.COUNT THEN
			WriteAppend(v_p, ',');
		END IF;
		WriteAppend(v_p, chr(10));
	END LOOP;
	WriteAppend(v_p,
		'    )');
	v_first := TRUE;
	v_t := NULL;
	FOR r IN (SELECT tc.oracle_column c, atc.data_default
		  		FROM tab_column tc, all_tab_columns atc
		 	   WHERE tc.tab_sid = in_tab_sid AND atc.owner = v_owner AND
		 	   		 atc.table_name = v_base_tab AND atc.column_name = tc.oracle_column
	  	    ORDER BY tc.pos) LOOP
		IF NOT v_first THEN
			WriteAppend(v_i, ',' || chr(10));
			WriteAppend(v_u, ',' || chr(10));
		END IF;
		v_first := FALSE;
		FOR i IN 1 .. v_uk_columns.COUNT LOOP
			IF r.c = v_uk_columns(i) THEN
				v_c := 
					'        '||rpad(q('O$'||r.c), 32)||' in  ' || v_c_tab || '.' || q(r.c) ||
					'%TYPE';
				v_u_args := comma(v_u_args) || ':OLD.' || q(r.c);
				v_d_args := comma(v_d_args) || ':OLD.' || q(r.c);
				v_t := comma(v_t, ','||chr(10)) || v_c;
				WriteAppend(v_u, v_c || ',' || chr(10));
				EXIT;
			END IF;
		END LOOP;
		v_c := '        '||rpad(q('N$'||r.c), 32)||' in  ';
		v_c := v_c || v_c_tab || '.' || q(r.c);			
		v_cols := comma(v_cols) || q(r.c);
		v_u_vals := comma(v_u_vals) || q('N$'||r.c);
		IF r.data_default IS NOT NULL THEN
			v_i_vals := comma(v_i_vals) || 'nvl(' || q('N$'||r.c) || ',' || r.data_default || ')';
		ELSE
			v_i_vals := comma(v_i_vals) || q('N$'||r.c);
		END IF;		
		v_i_args := comma(v_i_args) || ':NEW.' || q(r.c);
		v_u_args := comma(v_u_args) || ':NEW.' || q(r.c);
		v_c := v_c || '%TYPE';
		WriteAppend(v_i, v_c);
		WriteAppend(v_u, v_c);				
	END LOOP;
	v_d := v_d || v_t;
	
	v_i_args := comma(v_i_args) || ':NEW.' || q('CHANGE_DESCRIPTION');
	v_u_args := comma(v_u_args) || ':NEW.' || q('CHANGE_DESCRIPTION');
	WriteAppend(v_i,
		 ',' || chr(10)||'        '||rpad(q('N$CHANGE_DESCRIPTION'), 32)||' in  ' || v_c_tab || '.' || q('CHANGE_DESCRIPTION') || '%TYPE');
	WriteAppend(v_u,
		 ',' || chr(10)||'        '||rpad(q('N$CHANGE_DESCRIPTION'), 32)||' in  ' || v_c_tab || '.' || q('CHANGE_DESCRIPTION') || '%TYPE');
		
	v_s := v_s || v_i;
	WriteAppend(v_s, chr(10) ||
		'    );'||chr(10)||
		chr(10));
	v_s := v_s || v_u;
	WriteAppend(v_s, chr(10) ||
		'    );'||chr(10)||
		chr(10));
	v_s := v_s || v_d;
	WriteAppend(v_s, chr(10) ||
		'    );'||chr(10)||
		chr(10));
	v_s := v_s || v_p;
	WriteAppend(v_s, ';' || chr(10) ||
		chr(10)||
		'    procedure sx'||chr(10)||
		'    ('||chr(10)||
		'        in_object_schema                 in  varchar2,'||chr(10)||
		'        in_object_name                   in  varchar2,'||chr(10)||
		'        in_policy_name                   in  varchar2'||chr(10)||
		'    );'||chr(10)||
		chr(10)||
		'    procedure ux;'||chr(10)||
		'    procedure ix;'||chr(10)||
		'    procedure dx;'||chr(10)||
		'end;');

	io_ddl.extend(1);
	io_ddl(io_ddl.count) := v_s;
	
	v_s := 
		'create or replace package body '||q(v_owner)||'.'||q('T$'||v_table_name)||chr(10)||
		'as'||chr(10)||
		chr(10)||
		'    g_tab_sid CONSTANT NUMBER(10) := '||in_tab_sid||';'||chr(10);
		
	---------------------------------
	-- INSERT PROCEDURE GENERATION --
	---------------------------------
	WriteAppend(v_s, chr(10));
	v_s := v_s || v_i;
	WriteAppend(v_s, chr(10) ||
		'    )' || chr(10) ||
		'    as' || chr(10) ||
  		'        v_vers         number(10);'||chr(10)||
  		'        v_child        number(10);'||chr(10)||
  		'        v_locked_by    number(10);'||chr(10)||
  		'        v_context_id   number(10);'||chr(10)||
  		'        v_uk_cons_id   number(10);'||chr(10)||
		'    begin' || chr(10) ||
		'        v_context_id := NVL(SYS_CONTEXT(''SECURITY'',''CONTEXT_ID''), 0);' || chr(10));
 
	-- Check + lock parent records
	-- Basically if all parts of the FK are non-null then we need to select the parent
	-- rows FOR UPDATE to prevent them being removed / updated half way through this transaction
	-- Also don't check parent records for unmanaged tables (as we have real RI there!)
	FOR r IN (SELECT fkc.fk_cons_id, fkc.r_cons_id
				FROM fk_cons fkc, uk_cons ukc, tab ukt
			   WHERE fkc.tab_sid = in_tab_sid AND fkc.r_cons_id = ukc.uk_cons_id AND
			   	     ukc.tab_sid = ukt.tab_sid AND ukt.managed = 1) LOOP
		v_t := NULL;
		v_t2 := NULL;
	
		FOR s IN (SELECT pt.oracle_schema owner, pt.oracle_table table_name, ptc.oracle_column column_name, 
						 rtc.oracle_column r_column_name
					FROM fk_cons_col fkcc, uk_cons_col ukcc, tab_column ptc, tab_column rtc, tab pt
				   WHERE fkcc.fk_cons_id = r.fk_cons_id AND fkcc.column_sid = rtc.column_sid AND 
				   		 ptc.tab_sid = pt.tab_sid AND ukcc.uk_cons_id = r.r_cons_id AND 
				   		 ukcc.pos = fkcc.pos AND ukcc.column_sid = ptc.column_sid) LOOP
				   		 
			IF v_t IS NULL THEN
				v_t :=
				'                select 1'||chr(10)||
				'                  into v_child'||chr(10)||
				'                  from '||q(s.owner)||'.'||q('C$'||s.table_name)||' i'||chr(10)||
				'                 where ';				
				WriteContextClause(v_t, '                       ');
				WriteAppend(v_t, chr(10)||
					'                       and ');
				WriteCurrentClause(v_t, '                       ');
				WriteAppend(v_t, chr(10)||
					'                       and ');
			ELSE
				v_t := v_t || ' and'||chr(10)||
				'                       ';
			END IF;
			v_t := v_t || q(s.column_name)||' = '||q('N$'||s.r_column_name);

			IF v_t2 IS NULL THEN
				v_t2 :=
				'        if ';
			ELSE
				v_t2 := v_t2 || ' and'||chr(10)||
				'           ';
			END IF;
			
			v_t2 := v_t2 ||
				q('N$'||s.r_column_name)||' is not null ';
		END LOOP;
		
		v_parent_lock := v_parent_lock || v_t2 || 'then'||chr(10)||
			'            begin'||chr(10)||
			v_t||chr(10)||
			'                       for update;'||chr(10)||
			'            exception'||chr(10)||
			'                when no_data_found then'||chr(10)||
			'                    cms.tab_pkg.RaiseError(cms.tab_pkg.err_ri_cons_no_parent, '||r.fk_cons_id||');'||chr(10)||
	 		'            end;'||chr(10)||
			'        end if;'||chr(10);
	END LOOP;

	WriteAppend(v_s, 
		v_parent_lock ||
		'        begin'||chr(10)||
    	'            select 1, locked_by'||chr(10)||
		'              into v_child, v_locked_by'||chr(10)||
		'              from '||v_l_tab||chr(10)||
     	'             where ');
     	
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			WriteAppend(v_s, ' and '||chr(10) ||
				'                    ');
		END IF; 
		WriteAppend(v_s, q(v_pk_columns(i)) || ' = ' || q('N$'||v_pk_columns(i)));
	END LOOP;

	WriteAppend(v_s, chr(10) ||
		'                   for update;'||chr(10)||
  		'        exception'||chr(10)||
    	'            when no_data_found then'||chr(10)||
		'                v_child := null;'||chr(10)||
  		'        end;'||chr(10)||
  		'        if nvl(v_locked_by, v_context_id) <> v_context_id then'||chr(10)||
    	'            select count(*)'||chr(10)||
      	'              into v_child'||chr(10)||
      	'              from cms.fast_context'||chr(10)||
     	'             where parent_context_id = v_locked_by and context_id = v_context_id;'||chr(10)||
      	'            if v_child = 0 then'||chr(10)||
		'                cms.tab_pkg.RaiseError(cms.tab_pkg.err_row_locked, v_locked_by);'||chr(10)||      	
      	'            end if;'||chr(10)||
      	'        end if;'||chr(10)||
  		'        if v_child is not null then'||chr(10)||
  		'            cms.tab_pkg.RaiseError(cms.tab_pkg.err_uk_violation, '||v_pk_cons_id||');'||chr(10)||
  		'        end if;'||chr(10));
  		
	-- Now check any unique keys defined on the table.  There's nothing good
	-- to lock on here, so we have to lock the constraint definition row.
	-- This is overkill, but otherwise we need a separate table for enforcing the unique constraint.
	FOR r IN (SELECT ukc.uk_cons_id
				FROM uk_cons ukc, tab t
			   WHERE ukc.tab_sid = in_tab_sid AND t.tab_sid = ukc.tab_sid AND t.tab_sid = in_tab_sid AND
			   		 t.pk_cons_id <> ukc.uk_cons_id) LOOP

		-- UKs seem to do "if any part of the key is non-null then check the row is unique 
		-- (with null=null => true) otherwise if all nulls don't check
		-- seems a bit crazy
		v_t := NULL;
		v_t2 := NULL;
		FOR s IN (SELECT tc.oracle_column
		            FROM tab_column tc, uk_cons_col ukcc
		           WHERE ukcc.uk_cons_id = r.uk_cons_id AND ukcc.column_sid = tc.column_sid) LOOP
			IF v_t IS NULL THEN
				v_t := 
					'        if ';
			ELSE
				v_t := v_t || ' or'||chr(10) ||
					'           ';
			END IF;
			v_t := v_t || q('N$'||s.oracle_column) || ' is not null';
			IF v_t2 IS NOT NULL THEN
				v_t2 := v_t2 ||' and'||chr(10) ||
					'                                  ';
			END IF;	
			v_t2 := v_t2 || '(' || q(s.oracle_column) || '=' || q('N$'||s.oracle_column) || ' or ('||
							q(s.oracle_column) || ' is null and ' || q('N$'||s.oracle_column) || ' is null))';
		END LOOP;
		
		WriteAppend(v_s,
		v_t||' then'||chr(10)||
		'            select uk_cons_id'||chr(10)||
		'              into v_uk_cons_id'||chr(10)||
		'              from cms.uk_cons'||chr(10)||
		'             where uk_cons_id = '||r.uk_cons_id||chr(10)||
		'                   for update;'||chr(10)||
		'            select min(1)'||chr(10)||
		'              into v_child'||chr(10)||
		'              from dual'||chr(10)||
		'             where exists (select 1'||chr(10)||
		'                             from '||v_c_tab||chr(10)||
		'                            where retired_dtm is null and vers > 0 and '||v_t2||');'||chr(10)||
		'            if v_child is not null then'||chr(10)||
		'                cms.tab_pkg.RaiseError(cms.tab_pkg.ERR_UK_VIOLATION, '||r.uk_cons_id||');'||chr(10)||
		'            end if;'||chr(10)||
		'        end if;'||chr(10));
	END LOOP;
	
	WriteAppend(v_s,
    	'        select NVL(max(vers), 0)'||chr(10)||
      	'          into v_vers'||chr(10)||
      	'          from '||v_c_tab||chr(10)||
     	'         where context_id = v_context_id and'||chr(10)||
     	'               ');
    FOR i IN 1 .. v_pk_columns.COUNT LOOP
    	IF i <> 1 THEN
    		WriteAppend(v_s,' and' || chr(10) || '               ');
    	END IF;
    	WriteAppend(v_s, q(v_pk_columns(i)) || ' = ' || q('N$'||v_pk_columns(i)));
    END LOOP;
    WriteAppend(v_s, ';' || chr(10) ||
		'        insert into '||v_l_tab||' (locked_by');
		
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_s, ', ' || q(v_pk_columns(i)));
	END LOOP;
	WriteAppend(v_s, ')' || chr(10) ||
		'        values (v_context_id');

	FOR r IN (SELECT tc.oracle_column c, atc.data_default
      			FROM tab_column tc, tab t, uk_cons uk, uk_cons_col ukc, all_tab_columns atc
     		   WHERE t.pk_cons_id = uk.uk_cons_id AND uk.uk_cons_id = ukc.uk_cons_id AND
           		     ukc.column_sid = tc.column_sid AND t.tab_sid = in_tab_sid AND
           		     atc.owner = v_owner AND atc.table_name = v_base_tab AND
           		     atc.column_name = tc.oracle_column
     		ORDER BY ukc.pos) LOOP
		IF r.data_default IS NOT NULL THEN
			WriteAppend(v_s, ', nvl(' || q('N$'||r.c) || ',' || r.data_default || ')');
		ELSE
			WriteAppend(v_s, ', ' || q('N$'||r.c));
		END IF;
	END LOOP;	

	WriteAppend(v_s, ');' || chr(10) ||
		'        insert into '||v_c_tab||' ('||comma(v_cols)||'context_id, locked_by, vers, changed_by, change_description)'||chr(10)||
		'        values ('||comma(v_i_vals)||'v_context_id, null, v_vers + 1, NVL(SYS_CONTEXT(''SECURITY'', ''RECEIVED_FROM_SID''), security.security_pkg.GetSID()), "N$CHANGE_DESCRIPTION");'||chr(10)||
		'    end;'||chr(10));
		
	---------------------------------
	-- UPDATE PROCEDURE GENERATION --
	---------------------------------
	WriteAppend(v_s, chr(10));
	v_s := v_s || v_u;
	WriteAppend(v_s, chr(10) ||
		'    )' || chr(10) ||
		'    as' || chr(10) || 
  		'        v_vers         number(10);'||chr(10)||
  		'        v_child        number(10);'||chr(10)||
  		'        v_locked_by    number(10);'||chr(10)||
  		'        v_context_id   number(10);'||chr(10)||
  		'        v_uk_cons_id   number(10);'||chr(10)||
		'    begin' || chr(10) ||
		'        v_context_id := NVL(SYS_CONTEXT(''SECURITY'',''CONTEXT_ID''), 0);' || chr(10));
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_s,
		'        if '||q('N$'||v_pk_columns(i))||' <> '||q('O$'||v_pk_columns(i))||' then'||chr(10)||
		'            cms.tab_pkg.RaiseError(cms.tab_pkg.ERR_PK_MODIFIED, '||v_pk_cons_id||');'||chr(10)||
		'        end if;'||chr(10));
	END LOOP;
		WriteAppend(v_s,
		v_parent_lock ||
		'        begin'||chr(10)||
		'            select locked_by'||chr(10)||
		'              into v_locked_by'||chr(10)||
		'              from '||v_l_tab||chr(10)||
		'             where ');
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			WriteAppend(v_s, ' and' || chr(10) || '              	    ');
		END IF;
		WriteAppend(v_s, q(v_pk_columns(i)) || '=' || q('N$'||v_pk_columns(i)));
	END LOOP;
	WriteAppend(v_s, chr(10) ||	
		'                   for update;'||chr(10)||
		'            if nvl(v_locked_by, v_context_id) <> v_context_id then'||chr(10)||
		'                select count(*)'||chr(10)||
		'                  into v_child'||chr(10)||
		'                  from cms.fast_context'||chr(10)||
		'                 where parent_context_id = v_locked_by and context_id = v_context_id;'||chr(10)||
		'                if v_child = 0 then'||chr(10)||
		'                    cms.tab_pkg.RaiseError(cms.tab_pkg.err_row_locked, v_locked_by);'||chr(10)||		
		'                end if;'||chr(10)||
		'            end if;'||chr(10)||
		'        exception'||chr(10)||
		'            when no_data_found then'||chr(10)||
		'                raise_application_error(-20001, ''row is missing (this should not happen!)'');'||chr(10)||
		'        end;'||chr(10)||
		'        update '||v_c_tab||chr(10)||
		'           set locked_by = v_context_id'||chr(10)||
		'         where context_id in (select parent_context_id'||chr(10)||
		'                                from cms.fast_context'||chr(10)|| 
		'                               where context_id = v_context_id) and'||chr(10));
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_s, '               ' || q(v_pk_columns(i))||' = '||q('N$'||v_pk_columns(i))||' and'||chr(10));
	END LOOP;
	WriteAppend(v_s,
		'				retired_dtm is null and vers > 0 and (locked_by = v_context_id or locked_by is null);'||chr(10)||
		'        if sql%rowcount = 0 then'||chr(10)||
		'            raise_application_error(-20001, ''row went missing!'');'||chr(10)||
		'        end if;'||chr(10)||		
		'        update '||v_l_tab||chr(10)||
		'           set locked_by = v_context_id'||chr(10)||
		'         where ');
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			WriteAppend(v_s, ' and' || chr(10) || '               ');
		END IF;
		WriteAppend(v_s, q(v_pk_columns(i)) || '=' || q('N$'||v_pk_columns(i)));
	END LOOP;
	WriteAppend(v_s, ';' || chr(10));

	-- Now check any unique keys defined on the table.  There's nothing good
	-- to lock on here, so we have to lock the constraint definition row.
	-- This is overkill, but otherwise we need a separate table for enforcing the unique constraint.
	FOR r IN (SELECT ukc.uk_cons_id
				FROM uk_cons ukc, tab t
			   WHERE ukc.tab_sid = in_tab_sid AND t.tab_sid = ukc.tab_sid AND t.tab_sid = in_tab_sid AND
			   		 t.pk_cons_id <> ukc.uk_cons_id) LOOP

		-- UKs seem to do "if any part of the key is non-null then check the row is unique 
		-- (with null=null => true) otherwise if all nulls don't check
		-- seems a bit crazy
		v_t := NULL;
		v_t2 := NULL;
		v_t3 := NULL;
		v_t4 := NULL;
		FOR s IN (SELECT tc.oracle_column
		            FROM tab_column tc, uk_cons_col ukcc
		           WHERE ukcc.uk_cons_id = r.uk_cons_id AND ukcc.column_sid = tc.column_sid) LOOP			
			IF v_t IS NULL THEN
				v_t := 
					'        if ';
			ELSE
				v_t := v_t || ' or'||chr(10) ||
					'           ';
			END IF;
			v_t := v_t || q('N$'||s.oracle_column) || ' is not null';
			IF v_t2 IS NOT NULL THEN
				v_t2 := v_t2 ||' and'||chr(10) ||
					'                   ';
			END IF;	
			v_t2 := v_t2 || '(' || q(s.oracle_column) || '=' || q('N$'||s.oracle_column) || ' or ('||
							q(s.oracle_column) || ' is null and ' || q('N$'||s.oracle_column) || ' is null))';
							
			IF v_t3 IS NOT NULL THEN
				v_t3 := v_t3 || ' or'||chr(10)||
					'                     ';
				v_t4 := v_t4 || ' and'||chr(10)||
					'                     ';				
			END IF;

			-- If old was all nulls then it's fine, otherwise we have to run the child check
			v_t3 := v_t3 || q('O$' || s.oracle_column) || ' != ' || q('N$' || s.oracle_column);
			v_t4 := v_t4 || q('O$' || s.oracle_column) || ' is null';
		END LOOP;
		
		WriteAppend(v_s,
		v_t||' then'||chr(10)||
		'            select uk_cons_id'||chr(10)||
		'              into v_uk_cons_id'||chr(10)||
		'              from cms.uk_cons'||chr(10)||
		'             where uk_cons_id = '||r.uk_cons_id||chr(10)||
		'                   for update;'||chr(10)||		
		'            select min(1)'||chr(10)||
		'              into v_child'||chr(10)||
		'              from dual'||chr(10)||
		'             where exists (select 1'||chr(10)||
		'                             from '||v_c_tab||chr(10)||
		'                            where retired_dtm is null and vers > 0 and '||v_t2);
		
		FOR i IN 1 .. v_pk_columns.COUNT LOOP
			WriteAppend(v_s, ' and' || chr(10) ||
				'                                  ' || q(v_pk_columns(i)) || ' <> ' || q('N$' || v_pk_columns(i)));
		END LOOP;
		
		WriteAppend(v_s, ');' || chr(10) ||
		'            if v_child is not null then'||chr(10)||
  		'                cms.tab_pkg.RaiseError(cms.tab_pkg.ERR_UK_VIOLATION, '||r.uk_cons_id||');'||chr(10)||
		'            end if;'||chr(10));
		
		-- See if we are changing any UKs.  If so, check to see if there was a child
		-- record of the old UK and if that's true then complain about it.		
		v_t := NULL;
		FOR s IN (SELECT fkc.fk_cons_id, t.oracle_schema, t.oracle_table
					FROM fk_cons fkc, tab t
				   WHERE r_cons_id = r.uk_cons_id AND fkc.tab_sid = t.tab_sid) LOOP
			v_t := v_t ||
			'                select min(1)'||chr(10)||
			'                  into v_child'||chr(10)||
			'                  from dual'||chr(10)||
			'                 where exists (select *'||chr(10)||
			'                                 from '||q(s.oracle_schema)||'.'||q('C$'||s.oracle_table)||chr(10)||
			'                                where ';
		
			v_first := TRUE;
			FOR t IN (SELECT ptc.oracle_column column_name, rtc.oracle_column r_column_name
					    FROM fk_cons_col fkcc, tab_column rtc, uk_cons_col ukcc, tab_column ptc
				       WHERE fkcc.fk_cons_id = s.fk_cons_id AND fkcc.column_sid = rtc.column_sid AND
				       		 ukcc.uk_cons_id = r.uk_cons_id AND ukcc.column_sid = ptc.column_sid AND
				       		 fkcc.pos = ukcc.pos) LOOP
				IF NOT v_first THEN
					v_t := v_t || ' and' || chr(10) ||
					'                                          ';
				END IF;
				v_first := FALSE;
				v_t := v_t || '(' || q(t.r_column_name) || ' = ' || q('O$' || t.column_name) || ' or ('||
								q(t.r_column_name) || ' is null and ' || q('O$' || t.column_name) || ' is null))';
			END LOOP;
			
			v_t := v_t || ');' || chr(10) ||
			'                if v_child is not null then'||chr(10)||
			'                    cms.tab_pkg.RaiseError(cms.tab_pkg.ERR_RI_CONS_CHILD_FOUND, '||s.fk_cons_id||');'||chr(10)||
			'                end if;'||chr(10);
		END LOOP;
		
		IF v_t IS NOT NULL THEN
			WriteAppend(v_s,
			'            if not ('||v_t4||') and ('||v_t3||') then'||chr(10)||
			v_t||
			'            end if;'||chr(10));
		END IF;		
		WriteAppend(v_s,
		'        end if;'||chr(10));
	END LOOP;

	WriteAppend(v_s,
		'        select NVL(max(vers), 0)'||chr(10)||
		'          into v_vers'||chr(10)||
      	'          from '||v_c_tab||chr(10)||
     	'         where context_id = v_context_id and'||chr(10)||
     	'               ');
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			WriteAppend(v_s, ' and' || chr(10) || '               ');
		END IF;
		WriteAppend(v_s, q(v_pk_columns(i))||' = '||q('N$'||v_pk_columns(i)));
	END LOOP;
	WriteAppend(v_s, ';' || chr(10) ||
		'        update '||v_c_tab||chr(10)||
		'           set retired_dtm = sys_extract_utc(systimestamp)'||chr(10)||
		'         where context_id = v_context_id and'||chr(10));
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_s, '               '||q(v_pk_columns(i))||' = '||q('O$'||v_pk_columns(i))||' and'||chr(10));
	END LOOP;
	WriteAppend(v_s,
		'               retired_dtm is null;'||chr(10)||
		'        insert into '||v_c_tab||' ('||comma(v_cols)||'context_id, locked_by, vers, changed_by, change_description)'||chr(10)||
		'        values ('||comma(v_u_vals)||'v_context_id, null, v_vers + 1, NVL(SYS_CONTEXT(''SECURITY'', ''RECEIVED_FROM_SID''), security.security_pkg.GetSID()), "N$CHANGE_DESCRIPTION");'||chr(10)||		
		'    end;'||chr(10));
		
	---------------------------------
	-- DELETE PROCEDURE GENERATION --
	---------------------------------
	WriteAppend(v_s, chr(10));
	v_s := v_s || v_d;
	WriteAppend(v_s, chr(10) ||
		'    )' || chr(10) ||
		'    as' || chr(10) ||
  		'        v_vers         number(10);'||chr(10)||
  		'        v_child        number(10);'||chr(10)||
  		'        v_locked_by    number(10);'||chr(10)||
  		'        v_context_id   number(10);'||chr(10)||
  		'        v_locks        number(10);'||chr(10)||
		'    begin' || chr(10) ||
		'        v_context_id := NVL(SYS_CONTEXT(''SECURITY'',''CONTEXT_ID''), 0);' || chr(10)||
		'        -- ok, now check if we can lock'||chr(10)||
		'        select locked_by'||chr(10)||
		'          into v_locked_by'||chr(10)||
		'          from '||v_l_tab||chr(10)||
		'         where ');
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			WriteAppend(v_s, ' and' || chr(10) || '              	    ');
		END IF;		
		WriteAppend(v_s, q(v_pk_columns(i)) || ' = ' || q('O$'||v_pk_columns(i)));
	END LOOP;
	WriteAppend(v_s, chr(10) ||
		'               for update;'||chr(10)||
		'        if nvl(v_locked_by, v_context_id) <> v_context_id then'||chr(10)||
		'            select count(*)'||chr(10)||
		'              into v_child'||chr(10)||
		'              from cms.fast_context'||chr(10)||
		'             where parent_context_id = v_locked_by and context_id = v_context_id;'||chr(10)||
		'            if v_child = 0 then'||chr(10)||
		'                cms.tab_pkg.RaiseError(cms.tab_pkg.err_row_locked, v_locked_by);'||chr(10)||		
		'            end if;'||chr(10)||
		'        end if;'||chr(10)||
		'        -- lock the row in all parent contexts for MVCC'||chr(10)||
		'        update '||v_c_tab||chr(10)||
		'           set locked_by = v_context_id'||chr(10)||
		'         where context_id in (select parent_context_id from cms.fast_context where context_id = v_context_id) and'||chr(10));
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_s, '               '||q(v_pk_columns(i))||' = '||q('O$'||v_pk_columns(i))||' and'||chr(10));
	END LOOP;
	WriteAppend(v_s,
		'               retired_dtm is null and vers > 0;'||chr(10)||
		'        v_locks := sql%rowcount;'||chr(10)|| -- yeah, this is no good
		'        -- history it in the current context'||chr(10)||
		'        -- if it doesn''t exist, that''s ok -- the lock is good enough'||chr(10)||
		'        update '||v_c_tab||chr(10)||
		'           set vers = -(vers + 1)'||chr(10)||
		'         where context_id = v_context_id and '||chr(10));
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		WriteAppend(v_s, '               '||q(v_pk_columns(i))||' = '||q('O$'||v_pk_columns(i))||' and'||chr(10));
	END LOOP;
	WriteAppend(v_s,
		'               retired_dtm is null and vers > 0;'||chr(10)||
		'        if v_locks + sql%rowcount = 0 then'||chr(10)||
		'            -- this is the best we can do, there is no way to have 0 rows deleted'||chr(10)||
		'            raise_application_error(-20001, ''row was deleted by another session'');'||chr(10)||
		'        end if;'||chr(10)||

		'        update '||v_l_tab||chr(10)||
		'           set locked_by = v_context_id'||chr(10)||
		'         where ');
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			WriteAppend(v_s, ' and' || chr(10) || '              	    ');
		END IF;
		WriteAppend(v_s, q(v_pk_columns(i)) || '=' || q('O$'||v_pk_columns(i)));
	END LOOP;
	WriteAppend(v_s,
		';' || chr(10));
		
	-- Enforce delete rules.
	-- We have already locked the row we are trying to delete
	-- and insert/update statements try to lock all parent rows, therefore
	-- any concurrent insert/updates will have to wait, so it's safe to 
	-- check/delete/set null child records without locking them (I hope!).
	FOR r IN (SELECT fkc.fk_cons_id, fkc.r_cons_id, fkc.delete_rule, t.oracle_schema, t.oracle_table
  				FROM fk_cons fkc, uk_cons ukc, tab t
			   WHERE ukc.tab_sid = in_tab_sid AND fkc.r_cons_id = ukc.uk_cons_id AND
			   		 fkc.tab_sid = t.tab_sid AND t.is_view = 0) LOOP

		IF r.delete_rule = 'R' THEN
			v_t := NULL;
			FOR s IN (SELECT ptc.oracle_column column_name, 
							 rtc.oracle_column r_column_name
						FROM fk_cons_col fkcc, uk_cons_col ukcc, tab_column ptc, tab_column rtc
					   WHERE fkcc.fk_cons_id = r.fk_cons_id AND fkcc.column_sid = rtc.column_sid AND 
					   		 ukcc.uk_cons_id = r.r_cons_id AND ukcc.pos = fkcc.pos AND 
					   		 ukcc.column_sid = ptc.column_sid) LOOP
				IF v_t IS NOT NULL THEN
					v_t := v_t || ' and' || chr(10) || '                              ';
				END IF;
				v_t := v_t || q(s.r_column_name) || ' = ' || q('O$'||s.column_name);
			END LOOP;

/*
DECLARE
	v_q VARCHAR2(32767);
BEGIN
	v_q :=
			'        select min(1)'||chr(10)||
			'          into v_child'||chr(10)||
			'          from dual'||chr(10)||
			'         where exists (select *'||chr(10)||
			'                         from'||q(r.oracle_schema)||'.'||q(r.oracle_table)||chr(10)||
			'                        where '||v_t||');'||chr(10)||
			'        if v_child is not null then'||chr(10)||
			'            cms.tab_pkg.RaiseError(cms.tab_pkg.ERR_RI_CONS_CHILD_FOUND, '||r.fk_cons_id||');'||chr(10)||
			'        end if;'||chr(10);
	security_pkg.debugmsg(v_q);
	security_pkg.debugmsg('len (v_t) ='||length(v_t));
	v_s := v_s||v_q;
END;*/
			WriteAppend(v_s,
			'        select min(1)'||chr(10)||
			'          into v_child'||chr(10)||
			'          from dual'||chr(10)||
			'         where exists (select *'||chr(10)||
			'                         from'||q(r.oracle_schema)||'.'||q(r.oracle_table)||chr(10)||
			'                        where '||v_t||');'||chr(10)||
			'        if v_child is not null then'||chr(10)||
			'            cms.tab_pkg.RaiseError(cms.tab_pkg.ERR_RI_CONS_CHILD_FOUND, '||r.fk_cons_id||');'||chr(10)||
			'        end if;'||chr(10));
		ELSIF r.delete_rule = 'C' THEN
			-- Note when cascading the cascaded delete will double lock the parent
			-- row, but that's not much of an issue (it could be more efficient)
			v_t := NULL;
			FOR s IN (SELECT ptc.oracle_column column_name, 
							 rtc.oracle_column r_column_name
						FROM fk_cons_col fkcc, uk_cons_col ukcc, tab_column ptc, tab_column rtc
					   WHERE fkcc.fk_cons_id = r.fk_cons_id AND fkcc.column_sid = rtc.column_sid AND 
					   		 ukcc.uk_cons_id = r.r_cons_id AND ukcc.pos = fkcc.pos AND 
					   		 ukcc.column_sid = ptc.column_sid) LOOP
				IF v_t IS NOT NULL THEN
					v_t := v_t || ' and' || chr(10) || '               ';
				END IF;
				v_t := v_t || q(s.r_column_name) || ' = ' || q('O$'||s.column_name);
			END LOOP;

			WriteAppend(v_s,
			'        delete'||chr(10)||
			'          from '||q(r.oracle_schema)||'.'||q(r.oracle_table)||chr(10)||			
			'         where '||v_t||';'||chr(10));
		ELSIF r.delete_rule = 'N' THEN
			v_t := NULL;
			v_t2 := NULL;
			FOR s IN (SELECT ptc.oracle_column column_name, 
							 rtc.oracle_column r_column_name
						FROM fk_cons_col fkcc, uk_cons_col ukcc, tab_column ptc, tab_column rtc
					   WHERE fkcc.fk_cons_id = r.fk_cons_id AND fkcc.column_sid = rtc.column_sid AND 
					   		 ukcc.uk_cons_id = r.r_cons_id AND ukcc.pos = fkcc.pos AND 
					   		 ukcc.column_sid = ptc.column_sid) LOOP
				IF v_t IS NOT NULL THEN
					v_t := v_t || ' and' || chr(10) || '               ';
					v_t2 := v_t2 || ',' || chr(10) || '               ';
				END IF;
				v_t := v_t || q(s.r_column_name) || ' = ' || q('O$'||s.column_name);
				v_t2 := v_t2 || q(s.r_column_name) || ' = null';
			END LOOP;

			WriteAppend(v_s,
			'        update '||q(r.oracle_schema)||'.'||q(r.oracle_table)||chr(10)||
			'           set '||v_t2||chr(10)||
			'         where '||v_t||';'||chr(10));
		ELSE
			-- The check constraint should ensure this is never reached
			RAISE_APPLICATION_ERROR(-20001,
				'Unknown delete_rule '||r.delete_rule||': should be R, C or N');
		END IF;
	END LOOP;

	WriteAppend(v_s,
		'    end;'||chr(10));
		
		
	----------------------------------
	-- PUBLISH PROCEDURE GENERATION --
	----------------------------------
	WriteAppend(v_s, chr(10));
	v_s := v_s || v_p;
	WriteAppend(v_s, chr(10) ||
		'    as' || chr(10) ||
  		'        v_locked_by    number(10);'||chr(10)||
		'    begin' || chr(10) ||
		'        select locked_by'||chr(10)||
        '          into v_locked_by'||chr(10)||
      	'          from '||v_l_tab||chr(10)||
		'         where ');
	v_t := NULL;
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		IF i <> 1 THEN
			v_t := v_t || ' and' || chr(10) ||
			'               ';
		END IF;
		v_t := v_t || q(v_pk_columns(i)) || ' = ' || q('N$' || v_pk_columns(i));
	END LOOP;
	WriteAppend(v_s, v_t || chr(10)||
		'               for update;'||chr(10)||
        '        if nvl(v_locked_by, -1) <> "FROM_CONTEXT" then'||chr(10)||
		'           cms.tab_pkg.RaiseError(cms.tab_pkg.err_row_locked, v_locked_by);'||chr(10)||		
		'        end if;'||chr(10)||
		chr(10)||
		'        -- move a row from context A to context B'||chr(10)||
		'        update '||v_l_tab||chr(10)||
		'           set locked_by = "TO_CONTEXT"'||chr(10)||
		'         where '||v_t||';'||chr(10)||
		'        update '||v_c_tab||chr(10)||
		'           set retired_dtm = sys_extract_utc(systimestamp)'||chr(10)||
		'         where context_id in ('||chr(10)||
		'                 select context_id'||chr(10)||
		'                   from (select context_id, parent_context_id'||chr(10)||
		'                           from cms.context'||chr(10)||
		'                                start with context_id = "FROM_CONTEXT"'||chr(10)||
		'                                connect by prior parent_context_id = context_id'||chr(10)||
		'                      intersect'||chr(10)||
		'                         select context_id, parent_context_id'||chr(10)||
		'                           from cms.context'||chr(10)||
		'                                start with context_id = "TO_CONTEXT"'||chr(10)||
		'                                connect by prior context_id = parent_context_id'||chr(10)||
		'                         )'||chr(10)||
		'                  minus'||chr(10)||
		'                  select "FROM_CONTEXT"'||chr(10)||
		'                    from dual) and'||chr(10)||
		'               '||v_t||' and'||chr(10)||
		'               retired_dtm is null;'||chr(10)||
		'         update '||v_c_tab||chr(10)||
		'           set locked_by = "TO_CONTEXT"'||chr(10)||
		'         where context_id in (select parent_context_id'||chr(10)||
		'                                from cms.context'||chr(10)||
		'                               where context_id = "TO_CONTEXT") and'||chr(10)||
		'               '||v_t||' and'||chr(10)||		
		'                retired_dtm is null and vers > 0;'||chr(10)||
		'        update '||v_c_tab||' c'||chr(10)||
		'           set vers = (select case when c.vers < 0 then -1 else 1 end * (nvl(max(vers), 0) + 1)'||chr(10)||
		'                         from '||v_c_tab||chr(10)||
		'                        where context_id = "TO_CONTEXT" and'||chr(10)||
		'                              '||REPLACE(v_t, '               ', '                              ')||'),'||chr(10)||
		'               context_id = "TO_CONTEXT", locked_by = null'||chr(10)||
		'         where context_id = "FROM_CONTEXT" and'||chr(10)||
		'               '||v_t||' and'||chr(10)||
		'               retired_dtm is null;'||chr(10)||
		'        if sql%rowcount = 0 then'||chr(10)||
		'            raise_application_error(-20001, ''row went missing!'');'||chr(10)||
		'        end if;'||chr(10)||
		'    end;'||chr(10));
		
	----------------------------------
	-- STATEMENT HANDLER GENERATION --
	----------------------------------
	-- Note that it's generating multiple handlers that could be merged, however
	-- we might want some more specific permission types in the future (and it 
	-- doesn't hurt anything if things stay like that)
	WriteAppend(v_s, chr(10)||
		'    procedure checkSecurity'||chr(10)||
		'    ('||chr(10)||
		'        in_permission                    in  security.security_pkg.t_permission'||chr(10)||
		'    )'||chr(10)||
		'    as'||chr(10)||
		'    begin'||chr(10)||
		'        if not security.security_pkg.IsAccessAllowedSid(sys_context(''SECURITY'', ''ACT''),'||chr(10)||
		'                                               g_tab_sid, in_permission) then'||chr(10)||
		'            raise_application_error(security.security_pkg.err_access_denied,'||chr(10)||
		'                ''Access was denied on the table with sid ''||g_tab_sid);'||chr(10)||
		'        end if;'||chr(10)||
		'    end;'||chr(10)||
		chr(10)||
		'    procedure sx'||chr(10)||
		'    ('||chr(10)||
		'        in_object_schema                 in  varchar2,'||chr(10)||
		'        in_object_name                   in  varchar2,'||chr(10)||
		'        in_policy_name                   in  varchar2'||chr(10)||
		'    )'||chr(10)||
		'    as'||chr(10)||
		'    begin'||chr(10)||
		'        checkSecurity(security.security_pkg.permission_read);'||chr(10)||
		'    end;'||chr(10)||
		chr(10)||
		'    procedure ix'||chr(10)||
		'    as'||chr(10)||
		'    begin'||chr(10)||
		'        checkSecurity(security.security_pkg.permission_write);'||chr(10)||
		'    end;'||chr(10)||
		chr(10)||
		'    procedure ux'||chr(10)||
		'    as'||chr(10)||
		'    begin'||chr(10)||
		'        checkSecurity(security.security_pkg.permission_write);'||chr(10)||
		'    end;'||chr(10)||
		chr(10)||
		'    procedure dx'||chr(10)||
		'    as'||chr(10)||
		'    begin'||chr(10)||
		'        checkSecurity(security.security_pkg.permission_write);'||chr(10)||
		'    end;'||chr(10)||
		'end;');
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := v_s;
					
	io_ddl.extend(1);
	io_ddl(io_ddl.count) :=
		'create or replace trigger '||q(v_owner)||'.'||q('I$'||v_table_name)||chr(10)||
		'    instead of insert on '||v_tab||chr(10)||
		'    for each row'||chr(10)||
		'begin'||chr(10)||
		'    '||q(v_owner)||'.'||q('T$'||v_table_name)||'.i(' || v_i_args || ');' || chr(10);	
	WriteHelperPackageCalls(in_tab_sid, io_ddl(io_ddl.count), v_pk_columns, 'i', ':NEW', FALSE, TRUE);
	WriteAppend(io_ddl(io_ddl.count), 
		'end;');

	io_ddl.extend(1);
	io_ddl(io_ddl.count) :=
		'create or replace trigger '||q(v_owner)||'.'||q('U$'||v_table_name)||chr(10)||
		'    instead of update on '||v_tab||chr(10)||
		'    for each row'||chr(10)||
		'begin'||chr(10)||
		'    '||q(v_owner)||'.'||q('T$'||v_table_name)||'.u('||
												  v_u_args||');' || chr(10);
	WriteHelperPackageCalls(in_tab_sid, io_ddl(io_ddl.count), v_pk_columns, 'u', ':OLD', TRUE, TRUE);
	WriteAppend(io_ddl(io_ddl.count), 
		'end;');
		
	io_ddl.extend(1);
	io_ddl(io_ddl.count) :=
		'create or replace trigger '||q(v_owner)||'.'||q('D$'||v_table_name)||chr(10)||
		'    instead of delete on '||v_tab||chr(10)||
		'    for each row'||chr(10)||
		'begin'||chr(10)||
		'    '||q(v_owner)||'.'||q('T$'||v_table_name)||'.d('||
												  v_d_args||');' || chr(10);
	WriteHelperPackageCalls(in_tab_sid, io_ddl(io_ddl.count), v_pk_columns, 'd', ':OLD', TRUE, FALSE);
	WriteAppend(io_ddl(io_ddl.count), 
		'end;');

	io_ddl.extend(1);
	io_ddl(io_ddl.count) :=
		'create or replace trigger '||q(v_owner)||'.'||q('J$'||v_table_name)||chr(10)||
		'    before insert on '||v_c_tab||chr(10)||
		'begin'||chr(10)||
		'    '||q(v_owner)||'.'||q('T$'||v_table_name)||'.IX;'||chr(10)||
		'end;';
		
	io_ddl.extend(1);
	io_ddl(io_ddl.count) :=
		'create or replace trigger '||q(v_owner)||'.'||q('V$'||v_table_name)||chr(10)||
		'    before update on '||v_c_tab||chr(10)||
		'begin'||chr(10)||
		'    '||q(v_owner)||'.'||q('T$'||v_table_name)||'.UX;'||chr(10)||
		'end;';
		
	io_ddl.extend(1);
	io_ddl(io_ddl.count) :=
		'create or replace trigger '||q(v_owner)||'.'||q('E$'||v_table_name)||chr(10)||
		'    before delete on '||v_c_tab||chr(10)||
		'begin'||chr(10)||
		'    '||q(v_owner)||'.'||q('T$'||v_table_name)||'.DX;'||chr(10)||
		'end;';
END;

PROCEDURE CreateView(
	in_tab_sid					IN				tab.tab_sid%TYPE,
	io_ddl						IN OUT NOCOPY	t_ddl
)
AS	
	v_c_tab							VARCHAR2(100);
	v_tab							VARCHAR2(100);
	v_owner							tab.oracle_schema%TYPE;
	v_table_name					tab.oracle_table%TYPE;	
	v_pk_columns					t_string_list;
	v_first							BOOLEAN;
	v_state							calc_xml_pkg.SQLGenerationState;
	v_has_rid_column				tab.has_rid_column%TYPE;
BEGIN
	SELECT oracle_schema, oracle_table
	  INTO v_owner, v_table_name
	  FROM tab 
	 WHERE tab_sid = in_tab_sid;
	GetPkCols(in_tab_sid, v_pk_columns);
	
	v_c_tab := q(v_owner) || '.' || q('C$' || v_table_name);
	v_tab   := q(v_owner) || '.' || q(v_table_name);

	v_state.tab_sid := in_tab_sid;
	v_state.tab_num := 1;
	v_state.needs_rid := FALSE;
	dbms_lob.createtemporary(v_state.col_sql, TRUE, dbms_lob.call);
	dbms_lob.createtemporary(v_state.from_sql, TRUE, dbms_lob.call);
	dbms_lob.createtemporary(v_state.where_sql, TRUE, dbms_lob.call);
	
	WriteAppend(v_state.from_sql, v_c_tab ||' i');
	v_first := TRUE;
	FOR r IN (SELECT oracle_column c, col_type, calc_xml
		  		FROM tab_column
		 	   WHERE tab_sid = in_tab_sid
	  	    ORDER BY pos) LOOP
		IF NOT v_first THEN
			WriteAppend(v_state.col_sql, ', ');
		END IF;
		v_first := FALSE;
		IF r.col_type = CT_CALC THEN
			WriteAppend(v_state.col_sql, '(');			
			calc_xml_pkg.GenerateCalc(v_state, dbms_xmldom.makenode(dbms_xmldom.getdocumentelement(dbms_xmldom.newdomdocument(r.calc_xml))));
			WriteAppend(v_state.col_sql, ') ');
			WriteAppend(v_state.col_sql, q(r.c));
		ELSE
			WriteAppend(v_state.col_sql, 'i.' || q(r.c));
		END IF;
	END LOOP;
	
	-- add a fake rowid (r$rid) column if the calc xml needs it
	IF v_state.needs_rid THEN
		IF NOT v_first THEN
			WriteAppend(v_state.col_sql, ', ');
		END IF;
		v_first := FALSE;
		WriteAppend(v_state.col_sql, 'i.ROWID R$RID');
		v_has_rid_column := 1;
	ELSE
		v_has_rid_column := 0;
	END IF;
	
	-- record the presence or absence of a RID column for query generation
	UPDATE tab
	   SET has_rid_column = v_has_rid_column
	 WHERE tab_sid = in_tab_sid;

	IF NOT v_first THEN
		WriteAppend(v_state.col_sql, ', ');
	END IF;
	v_first := FALSE;
	WriteAppend(v_state.col_sql, 'i.changed_by, i.change_description, NVL(i.locked_by, i.context_id) locked_by ');

	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 
		'create or replace view '||v_tab||' as'||chr(10)||
		'    select ';
	dbms_lob.append(io_ddl(io_ddl.count), v_state.col_sql);
	WriteAppend(io_ddl(io_ddl.count), chr(10)||
		'      from ');
	dbms_lob.append(io_ddl(io_ddl.count), v_state.from_sql);
	WriteAppend(io_ddl(io_ddl.count), chr(10)||
		'     where ');
	WriteContextClause(io_ddl(io_ddl.count), '           ');
	WriteAppend(io_ddl(io_ddl.count), chr(10)||
		'           and ');
	WriteCurrentClause(io_ddl(io_ddl.count), '           ');
	IF dbms_lob.getlength(v_state.where_sql) > 0 THEN
		WriteAppend(io_ddl(io_ddl.count), chr(10)||
		'           and ');
		dbms_lob.append(io_ddl(io_ddl.count), v_state.where_sql);
	END IF;

	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 
		'create or replace view '||q(v_owner)||'.'||q('H$' || v_table_name)||' as'||chr(10)||
		'    select i.created_dtm, i.retired_dtm, i.vers, ';
	dbms_lob.append(io_ddl(io_ddl.count), v_state.col_sql);
	WriteAppend(io_ddl(io_ddl.count), chr(10)||
		'      from ');
	dbms_lob.append(io_ddl(io_ddl.count), v_state.from_sql);
	dbms_lob.append(io_ddl(io_ddl.count), chr(10)||
		'     where ');
	WriteContextClause(io_ddl(io_ddl.count), '           ');
	IF dbms_lob.getlength(v_state.where_sql) > 0 THEN
		WriteAppend(io_ddl(io_ddl.count), chr(10)||
		'           and ');
		dbms_lob.append(io_ddl(io_ddl.count), v_state.where_sql);
	END IF;
END;


FUNCTION GetAppSidForTable(
	in_tab_sid					IN	tab.tab_sid%TYPE
)
RETURN security_pkg.T_SID_ID
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid
	  INTO v_app_sid
	  FROM tab
	 WHERE tab_sid = in_tab_sid;
	RETURN v_app_sid;
END;

FUNCTION PkEscape(
	in_s						IN	VARCHAR2
) 
RETURN VARCHAR2
DETERMINISTIC
AS
BEGIN
	RETURN REPLACE(REPLACE(in_s, '\', '\\'), ',', '\,');  --'
END;

PROCEDURE CreateItemDescriptionView(
	in_app_sid					IN				security_pkg.T_SID_ID,
	io_ddl						IN OUT NOCOPY	t_ddl
)
AS
	v_union         VARCHAR2(100);
	v_s				CLOB;
	v_ctable_count	NUMBER;
BEGIN
	FOR r IN (
		SELECT tab_sid, format_sql, pk_cons_id, oracle_schema, oracle_table
		  FROM tab
		 WHERE app_sid = in_app_sid AND format_sql IS NOT NULL AND 
		 	   pk_cons_id IS NOT NULL AND managed = 1
	) LOOP
		IF v_union IS NULL THEN
			io_ddl.extend(1);
			io_ddl(io_ddl.count) := 'create or replace view cms.item_description_'||in_app_sid||' as '||chr(10);
		END IF;

		-- This function is sometimes called before the C$ table exists (we know it's managed from
		-- the select above) -- this occurs during initial registration
		-- It's also sometimes called after the C$ table exists but before the view exists --
		-- this occurs during csrimp
		-- Therefore cast around for the relevant table
		SELECT COUNT(*)
		  INTO v_ctable_count
		  FROM all_tables
		 WHERE owner = r.oracle_schema 
		   AND table_name = 'C$' || r.oracle_table;

		v_s := '';		   
		FOR s IN (
			SELECT tc.oracle_column, atc.data_type
			  FROM uk_cons_col ukcc, tab_column tc, tab t, all_tab_columns atc
			 WHERE ukcc.uk_cons_id = r.pk_cons_id AND ukcc.column_sid = tc.column_sid AND
			 	   tc.tab_sid = t.tab_sid AND t.oracle_schema = atc.owner AND 
			 	   atc.table_name = (CASE WHEN v_ctable_count = 1 THEN 'C$' ELSE '' END) || t.oracle_table AND
			 	   tc.oracle_column = atc.column_name
		  ORDER BY ukcc.pos) LOOP
		  	
		  	v_s := comma(v_s, ' || ');
		  	IF s.data_type = 'NUMBER' THEN
		  		v_s := v_s || 'to_char(' || q(s.oracle_column) || ')';
		  	ELSE 
		  		v_s := v_s || 'cms.tab_pkg.pkEscape(' || q(s.oracle_column) || ')';
		  	END IF;
		END LOOP;

		io_ddl(io_ddl.count) := io_ddl(io_ddl.count) || v_union || 
			'    select '||r.tab_sid||' tab_sid,'||chr(10)||
			'           '||v_s||' item_id, '||chr(10)||
			'           to_char('||q(r.format_sql)||') description,'||chr(10)||
			'           locked_by'||chr(10)||
			'      from '||q(r.oracle_schema)||'.'||q(r.oracle_table);

		v_union := chr(10)||'    union all'||chr(10);
	END LOOP;
END;

PROCEDURE MarkDDLAsProcessed(
	in_id	NUMBER
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	UPDATE debug_ddl_log
	   SET processed_dtm = SYSDATE
	 WHERE csrimp_session_id = SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID')
	   AND id = in_id;
	COMMIT;
END;

PROCEDURE ExecuteClob(
	in_sql			CLOB,
	in_id			NUMBER DEFAULT NULL
)
AS
	v_sql			DBMS_SQL.VARCHAR2A;
	v_chunk			VARCHAR2(32767);
	v_upperbound	NUMBER;
	v_cur			INTEGER;
	v_ret			NUMBER;
BEGIN
	-- VARCHAR2S deprecated, using VARCHAR2A (VARCHAR2A is table of VARCHAR2(32767))
	v_upperbound := ceil(dbms_lob.getlength(in_sql) / 8190);
	FOR i IN 1..v_upperbound
	LOOP
		v_sql(i) := dbms_lob.substr(in_sql, 8190, ((i - 1) * 8190) + 1);	
	END LOOP;
	
	-- Now parse and execute the SQL statement
	v_cur := dbms_sql.open_cursor;
	BEGIN
		dbms_sql.parse(v_cur, v_sql, 1, v_upperbound, false, dbms_sql.native);
	EXCEPTION
		WHEN OTHERS THEN
			dbms_sql.close_cursor(v_cur);
			RAISE;
	END;

	BEGIN
		v_ret := dbms_sql.execute(v_cur);
	EXCEPTION
		WHEN OTHERS THEN
			dbms_sql.close_cursor(v_cur);
			RAISE;
	END;
	dbms_sql.close_cursor(v_cur);
	
	IF SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') IS NOT NULL THEN
		IF in_id IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'DDL id cannot be passed empty when we run a csrimp');
		END IF;
		MarkDDLAsProcessed(in_id);
	END IF;
END;

PROCEDURE TraceClob_NoCommit(
	in_sql			CLOB
)
AS
	v_sql			DBMS_SQL.VARCHAR2S;
	v_chunk			VARCHAR2(32767);
	v_upperbound	NUMBER;
	v_cur			INTEGER;
	v_ret			NUMBER;
BEGIN

	v_upperbound := ceil(dbms_lob.getlength(in_sql) / 32767);
	FOR i IN 1..v_upperbound
	LOOP
		v_chunk := dbms_lob.substr(in_sql, 32767, ((i - 1) * 32767) + 1);
		dbms_output.put_line(v_chunk);
	END LOOP;
	dbms_output.put_line('');
	IF SUBSTR(v_chunk, -1) = ';' THEN
		dbms_output.put_line('/');
	ELSE
		dbms_output.put_line(';');
	END IF;
	
	-- I can't find a way of getting the DDL out using sql*plus -- all variants
	-- of spool settings and dbms_output seem to be broken (wrapping where it shouldn't, 
	-- loosing chunks of text), so stuff the DDL into a table for later retrieval
	-- by a less broken tool
	INSERT INTO debug_ddl_log (id, ddl)
	VALUES (debug_ddl_log_id_seq.nextval, in_sql);
	
END;

PROCEDURE TraceClob(
	in_sql			CLOB
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	TraceClob_NoCommit(in_sql);
	COMMIT;
END;

FUNCTION HasUnprocessedDDL
RETURN BOOLEAN
AS
	v_count NUMBER;
BEGIN
	IF SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') IS NULL THEN
		RETURN FALSE;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM debug_ddl_log
	 WHERE csrimp_session_id =  SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID')
	   AND processed_dtm IS NULL;
	   
	RETURN v_count > 0;
END;

PROCEDURE ExecDDLFromLog
AS
	v_processing_ids	security_pkg.T_SID_IDS;
	v_ddl				CLOB;
BEGIN
	IF SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'ExecDDLFromLog is only available for CsrImp');
	END IF;
	
	SELECT id
	  BULK COLLECT INTO v_processing_ids
	  FROM debug_ddl_log
	 WHERE csrimp_session_id = SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID')
	   AND processed_dtm IS NULL
	 ORDER BY id;

	FOR i IN 1 .. v_processing_ids.COUNT LOOP
		--overkill??
		SELECT ddl
		  INTO v_ddl
		  FROM debug_ddl_log
		 WHERE id = v_processing_ids(i);
		ExecuteClob(v_ddl, v_processing_ids(i));
	END LOOP;
END;

PROCEDURE LogDDL(
	in_ddl	t_ddl
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	FOR i in in_ddl.first .. in_ddl.last LOOP
		TraceClob_NoCommit(in_ddl(i));
	END LOOP;
	COMMIT;
END;

PROCEDURE ExecuteDDL(
	in_ddl			t_ddl
)
AS
BEGIN
	IF in_ddl.count = 0 THEN
		RETURN;
	END IF;
	
	--if we are running a csrimp log everything in advance and then exec
	IF SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') IS NOT NULL THEN 
		IF m_trace THEN
			LogDDL(in_ddl);
		END IF;	
		ExecDDLFromLog;
	ELSE
		FOR i in in_ddl.first .. in_ddl.last LOOP
			IF m_trace THEN
				TraceClob(in_ddl(i));
			END IF;
			IF NOT m_trace_only THEN
				ExecuteClob(in_ddl(i));
			END IF;
		END LOOP;
	END IF;
END;

PROCEDURE EnableTrace
AS
BEGIN
	m_trace := TRUE;
END;

PROCEDURE DisableTrace
AS
BEGIN
	m_trace := FALSE;
END;

PROCEDURE EnableTraceOnly
AS
BEGIN
	m_trace := TRUE;
	m_trace_only := TRUE;
END;

PROCEDURE DisableTraceOnly
AS
BEGIN
	m_trace := FALSE;
	m_trace_only := FALSE;
END;

PROCEDURE RecreateViews
AS
	v_ddl t_ddl default t_ddl();
BEGIN
	FOR r IN (SELECT tab_sid
				FROM tab
			   WHERE managed = 1
			     AND app_sid = security_pkg.GetApp) LOOP
		CreateView(r.tab_sid, v_ddl);
	END LOOP;
	
	FOR r IN (SELECT DISTINCT app_sid
	            FROM tab
			   WHERE app_sid = security_pkg.GetApp) loop
	    CreateItemDescriptionView(r.app_sid, v_ddl);
	END LOOP;
	
	FOR r IN (SELECT tab_sid
				FROM tab
			   WHERE managed = 1
			     AND app_sid = security_pkg.GetApp) LOOP
		CreateTriggers(r.tab_sid, v_ddl);
	END LOOP;
	IF v_ddl.count = 0 THEN
		RETURN;
	END IF;

	ExecuteDDL(v_ddl);
END;

PROCEDURE RecreateViewInternal(
	in_tab_sid			IN				tab.tab_sid%TYPE,
	io_ddl				IN OUT NOCOPY	t_ddl
)
AS
	v_managed					tab.managed%TYPE;
BEGIN
	-- Recreate the view + triggers if the table is managed
	SELECT managed
	  INTO v_managed
	  FROM tab
	 WHERE tab_sid = in_tab_sid;
	IF v_managed = 1 THEN
		CreateView(in_tab_sid, io_ddl);
		CreateItemDescriptionView(GetAppSidForTable(in_tab_sid), io_ddl);
		CreateTriggers(in_tab_sid, io_ddl);
		ExecuteDDL(io_ddl);
	END IF;
END;

PROCEDURE RecreateViewInternal(
	in_tab_sid					IN	tab.tab_sid%TYPE
)
AS
	v_ddl		t_ddl DEFAULT t_ddl();
BEGIN
	RecreateViewInternal(in_tab_sid, v_ddl);
END;

PROCEDURE RecreateView(
	in_tab_sid					IN	tab.tab_sid%TYPE
)
AS
BEGIN
	-- XXX: need some separate permission type?
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), in_tab_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Access denied writing to table with sid '||in_tab_sid);
	END IF;
	
	RecreateViewInternal(in_tab_sid);
END;

PROCEDURE RecreateView(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE
)
AS
	v_tab_sid					tab.tab_sid%TYPE;
BEGIN
	
	BEGIN
		SELECT tab_sid
		  INTO v_tab_sid
		  FROM tab
		 WHERE oracle_schema = dq(in_oracle_schema)
		   AND oracle_table = dq(in_oracle_table)
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 
				'Could not find table '||in_oracle_schema||'.'||in_oracle_table);
	END;
	RecreateView(v_tab_sid);
END;

PROCEDURE Normalise(
	in_owner					IN	VARCHAR2,
	in_table_name				IN	VARCHAR2,
	out_owner					OUT	VARCHAR2,
	out_table_name				OUT	VARCHAR2,
	out_is_view					OUT	NUMBER
)
AS
BEGIN
	BEGIN
		SELECT owner, table_name, 0
		  INTO out_owner, out_table_name, out_is_view
		  FROM all_tables
		 WHERE owner = dq(in_owner) AND table_name = dq(in_table_name)
		 UNION
		SELECT owner, view_name, 1
		  FROM all_views
		 WHERE owner = dq(in_owner) AND view_name = dq(in_table_name);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Could not find the table '||in_owner||'.'||in_table_name);
	END;
END;

/*
Comments are:

attribute_list: attribute | attribute "," att_list
attribute: name | name "=" value
name: [A-Za-z][A-Za-z0-9-_]*
value: quoted | unquoted
unquoted: [A-Za-z0-9]
quoted: "[^"]*"
[ \t]+: chomped

e.g.

description="This is a column description", file, file_mime=doc_mime, file_name=doc_name

Note: this doesn't allow quotes in descriptions, that's probably ok to be going on with...
*/
FUNCTION ParseComments(
	io_state		IN OUT NOCOPY	CommentParseState
)
RETURN BOOLEAN
AS
BEGIN
	IF io_state.text IS NULL OR io_state.pos > LENGTH(io_state.text) THEN
		RETURN FALSE;
	END IF;

	io_state.name := REGEXP_SUBSTR(io_state.text, '[ \t]*[A-Za-z][A-Za-z0-9-_]*[ \t]*', io_state.pos);
	IF io_state.name IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 
			'Expected "name" at offset '||io_state.pos||' in the comment '||io_state.text);
	END IF;
	io_state.pos := io_state.pos + LENGTH(io_state.name);
	io_state.name := LOWER(TRIM(io_state.name));
	
	io_state.sep := SUBSTR(io_state.text, io_state.pos, 1);
	IF io_state.sep IS NOT NULL AND io_state.sep NOT IN ('=', ',') THEN
		RAISE_APPLICATION_ERROR(-20001, 
			'Expected "=" at offset '||io_state.pos||' in the comment '||io_state.text);
	END IF;		
	io_state.pos := io_state.pos + 1;
	
	IF io_state.sep = '=' THEN
		io_state.value := REGEXP_SUBSTR(io_state.text, '[ \t]*(("[^"]*")|([A-Za-z0-9-_]+))[ \t]*', io_state.pos);
		io_state.pos := io_state.pos + LENGTH(io_state.value);
		io_state.value := TRIM(io_state.value);
		IF io_state.value IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 
				'Expected "quoted_value" or "unquoted_value" at offset '||io_state.pos||
				' in the comment '||io_state.text);
		END IF;
		IF SUBSTR(io_state.value, 1, 1) = '"' THEN
			io_state.quoted := TRUE;
			io_state.value := SUBSTR(io_state.value, 2, LENGTH(io_state.value) - 2);
		ELSE
			io_state.quoted := FALSE;
		END IF;
    
		io_state.sep := SUBSTR(io_state.text, io_state.pos, 1);
		IF io_state.sep IS NOT NULL AND io_state.sep <> ',' THEN
			RAISE_APPLICATION_ERROR(-20001, 
				'Expected "," at offset '||io_state.pos||' in the comment '||io_state.text);
		END IF;
		io_state.pos := io_state.pos + 1;
	ELSE
		io_state.value := NULL;
		io_state.quoted := FALSE;
	END IF;

	RETURN TRUE;
END;


PROCEDURE DropUnusedFullTextIndexes(
	in_tab_sid					IN tab_column.tab_sid%TYPE,
	io_ddl						IN OUT NOCOPY	t_ddl
)
AS
	v_s						VARCHAR2(4000);
BEGIN
	-- find all full text indexes for tables we manage and drop them where no longer used on this table
	FOR r IN (
		SELECT owner, index_name, table_owner, table_name 
		  FROM all_indexes 
		 WHERE ityp_owner = 'CTXSYS'
		   AND index_name LIKE 'FTI$%'
		   AND (table_owner, table_name) IN (
			SELECT oracle_schema, CASE WHEN managed = 1 THEN 'C$'||oracle_table ELSE oracle_table END
			  FROM tab 
			 WHERE tab_sid = in_tab_sid
		 )
		  AND (owner, index_name) NOT IN (
			SELECT t.oracle_schema, 'FTI$'||tc.full_text_index_name
			  FROM tab_column tc
			  JOIN tab t ON tc.tab_sid = t.tab_sid
			 WHERE t.tab_sid = in_tab_sid
			   AND tc.full_text_index_name IS NOT NULL        
		  )
	)
	LOOP	
		v_s := 'drop index '||q(r.owner)||'.'||q(r.index_name);			
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := v_s;
	END LOOP;
END;

PROCEDURE CreateFullTextIndex(
	in_tab_sid					IN tab_column.tab_sid%TYPE,
	in_column_sid				IN tab_column.column_sid%TYPE,
	in_index_name				IN VARCHAR2,
	io_ddl						IN OUT NOCOPY	t_ddl
)
AS
	v_owner					tab.oracle_schema%TYPE;
	v_table_name			tab.oracle_table%TYPE;
	v_managed				tab.managed%TYPE;
	v_column_name			tab_column.oracle_column%TYPE;
	v_s						VARCHAR2(4000);
	v_cnt					NUMBER;
BEGIN
	SELECT oracle_schema, CASE WHEN managed = 1 THEN 'C$'||oracle_table ELSE oracle_table END, managed
	  INTO v_owner, v_table_name, v_managed
	  FROM tab 
	 WHERE tab_sid = in_tab_sid;
	 
	UPDATE tab_column 
	   SET full_text_index_name = in_index_name
	 WHERE column_sid = in_column_sid
	 RETURNING oracle_column INTO v_column_name;
	
	-- if this exists already then just exit
	-- XXX: this will fail if we do:
	--    comment on a is 'fti=foo';
	--    reparse
	--    comment on a is '';
	--    comment on b is 'fti=foo';
	--    reparse
	-- Since the index will be left on a and not moved to b
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_indexes
	 WHERE owner = v_owner
	   AND index_name = 'FTI$'||in_index_name; 
	
	IF v_cnt = 1 THEN
		RETURN;
	END IF;
	
	v_s := 'create index '||q(v_owner)||'.'||q('FTI$'||in_index_name)||' on '||
		q(v_owner)||'.'||q(v_table_name)||'('||q(v_column_name)||') indextype is ctxsys.context'||CHR(10)||
		'parameters(''datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist'')';
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := v_s;
END;

PROCEDURE SyncFullTextIndexes
AS
BEGIN
	FOR r IN (
		SELECT t.oracle_schema, tc.full_text_index_name
		  FROM tab t
			JOIN tab_column tc ON t.tab_sid = tc.tab_sid AND full_text_index_name IS NOT NULL		  
	)	
	LOOP
		ctx_ddl.sync_index(q(r.oracle_schema)||'.'||q('FTI$'||r.full_text_index_name));
	END LOOP;
END;

PROCEDURE AddTable(
	in_oracle_schema				IN	tab.oracle_schema%TYPE,
	in_oracle_table					IN	tab.oracle_table%TYPE,
	in_managed						IN	tab.managed%TYPE,
	in_auto_registered				IN	tab.auto_registered%TYPE,
	in_parent_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_description					IN	tab.description%TYPE DEFAULT NULL,
	in_is_view						IN	tab.is_view%TYPE DEFAULT 0,
	out_tab_sid						OUT	tab.tab_sid%TYPE
)
AS
	v_parent_sid					security_pkg.T_SID_ID := in_parent_sid;
BEGIN
	IF v_parent_sid IS NULL THEN
		v_parent_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(),
			SYS_CONTEXT('SECURITY', 'APP'), 'cms');
	END IF;

	SecurableObject_pkg.CreateSO(
		security_pkg.GetACT(),
		v_parent_sid,
		class_pkg.GetClassID('CMSTable'), 
		q(in_oracle_schema)||'.'||q(in_oracle_table),
		out_tab_sid);

	BEGIN
		INSERT INTO oracle_tab (oracle_schema, oracle_table)
		VALUES (in_oracle_schema, in_oracle_table);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	INSERT INTO tab
		(tab_sid, oracle_schema, oracle_table, description, managed, auto_registered, is_view)
	VALUES
		(out_tab_sid, in_oracle_schema, in_oracle_table, in_description, in_managed, in_auto_registered, in_is_view);
END;

PROCEDURE CreateIssueTable(
	in_tab_sid						IN				tab_column.tab_sid%TYPE,
	io_ddl							IN OUT NOCOPY	t_ddl
)
AS
	v_owner							tab.oracle_schema%TYPE;
	v_table_name					tab.oracle_table%TYPE;
	v_table_desc					tab.description%TYPE;
	v_managed						tab.managed%TYPE;
	v_pk_columns					t_string_list;
	v_s								VARCHAR2(4000);
	v_cols							VARCHAR2(4000);
	v_cnt							NUMBER;
	v_col_type						tab_column.col_type%TYPE;
	v_app_col_name					tab_column.oracle_column%TYPE;
	v_pk_cons_id					tab.pk_cons_id%TYPE;
	v_parent_pk_cons_id				tab.pk_cons_id%TYPE;
	v_j								NUMBER;
	v_itab_sid						tab.tab_sid%TYPE;
	v_l_tab							VARCHAR2(100);
	v_issue_pk_cons_id				tab.pk_cons_id%TYPE;
	v_app_sid_column_sid			tab_column.column_sid%TYPE;
	v_issue_id_column_sid			tab_column.column_sid%TYPE;	
	v_i$_table_name					VARCHAR2(30);
BEGIN
	UPDATE tab
	   SET issues = 1
	 WHERE tab_sid = in_tab_sid;

	SELECT oracle_schema, oracle_table, description, managed, pk_cons_id
	  INTO v_owner, v_table_name, v_table_desc, v_managed, v_parent_pk_cons_id
	  FROM tab
	 WHERE tab_sid = in_tab_sid;
	 
	v_i$_table_name := 'I$' || v_table_name;
	
	-- check for an existing issue join table 
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_tables
	 WHERE owner = v_owner AND (
		(table_name = v_i$_table_name AND v_managed = 0)
		OR (table_name = 'C$' || v_i$_table_name AND v_managed = 1));
		
	IF v_cnt > 0 THEN
		RETURN;
	END IF;

	-- get the pk columns
	GetPkCols(in_tab_sid, v_pk_columns);
	IF v_pk_columns.COUNT = 0 THEN
		-- the table is partially registered, so read the table definition			
	    SELECT acc.column_name
	      BULK COLLECT INTO v_pk_columns
	      FROM all_cons_columns acc, all_constraints ac
	     WHERE ac.constraint_type = 'P' AND ac.owner = v_owner AND ac.table_name = v_table_name
	       AND ac.owner = acc.owner AND ac.constraint_name = acc.constraint_name
	     ORDER BY acc.position; 
	     
		IF v_pk_columns.COUNT = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'The table '||v_owner||'.'||v_table_name||' marked issue must have a primary key');
		END IF;
	END IF;

	-- get a comma separated list of the primary key columns (we'll use this later when
	-- adding a primary key constraint to our new table, but we do it here as it applies
	-- to both managed and unmanaged tables	
	FOR i IN 1 .. v_pk_columns.COUNT LOOP
		-- skip the column if it's in the PK and marked app as we are going to add one
		IF v_app_col_name IS NULL OR v_pk_columns(i) != v_app_col_name THEN
			v_cols := comma(v_cols)||q(v_pk_columns(i));
		END IF;
	END LOOP;
	v_cols := v_cols||',app_sid,issue_id';

	-- if the parent table is managed, then we need to manage the issues table too -- add the extra
	-- required columns to do this, and also insert relevant column data in tab / tab_column
	IF v_managed = 1 THEN
		AddTable(		
			in_oracle_schema	=> v_owner,
			in_oracle_table		=> v_i$_table_name,
			in_managed			=> 1,
			in_auto_registered	=> 0,
			in_description		=> v_table_desc || ' Action',
			out_tab_sid			=> v_itab_sid
		);

		INSERT INTO uk_cons
			(uk_cons_id, tab_sid, constraint_owner, constraint_name)
		VALUES
			(uk_cons_id_seq.NEXTVAL, v_itab_sid, v_owner, 'UK_'||uk_cons_id_seq.CURRVAL)
		RETURNING
			uk_cons_id INTO v_pk_cons_id;
			
		UPDATE tab
		   SET pk_cons_id = v_pk_cons_id
		 WHERE tab_sid = v_itab_sid;

		v_s :=
			'create table '||q(v_owner)||'.'||q('C$I$' || v_table_name)||' as'||chr(10)||
			'    select ';
		v_j := 1;
		FOR i IN 1 .. v_pk_columns.COUNT LOOP
			IF v_pk_columns(i) = 'ISSUE_ID' THEN
				RAISE_APPLICATION_ERROR(-20001, 'The table '||v_owner||'.'||v_table_name||' marked issue has a column named ISSUE_ID which is not supported');
			END IF;			
	
			-- skip the column if it's in the PK and marked app as we are going to add one
			-- XXX: ought to check for two app columns in the PK (but that's nuts)
			SELECT col_type
			  INTO v_col_type
			  FROM tab_column
			 WHERE tab_sid = in_tab_sid and oracle_column = v_pk_columns(i);
			IF v_col_type = CT_APP_SID THEN
				IF v_app_col_name IS NOT NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 'The table '||v_owner||'.'||v_table_name||' marked issue has two app columns in the primary key, which is not supported');
				END IF;
				v_app_col_name := v_pk_columns(i);
			ELSE
				v_s := v_s||'t.'||q(v_pk_columns(i))||', ';
				
				INSERT INTO tab_column (column_sid, tab_sid, oracle_column, pos, data_type, data_length,
					   data_precision, data_scale, nullable, char_length, default_length, data_default)
				SELECT column_id_seq.NEXTVAL, v_itab_sid, v_pk_columns(i), v_j, data_type, data_length, 
					   data_precision, data_scale, nullable, char_length, default_length, data_default
				  FROM tab_column
				 WHERE tab_sid = in_tab_sid
				   AND oracle_column = v_pk_columns(i);
				
				INSERT INTO uk_cons_col
					(uk_cons_id, column_sid, pos)
				VALUES
					(v_pk_cons_id, column_id_seq.CURRVAL, v_j);
				v_j := v_j + 1;
			END IF;
		END LOOP;
		v_s := v_s||'i.app_sid, i.issue_id'||chr(10)||
			'      from '||q(v_owner)||'.'||q('C$'||v_table_name)||' t, csr.issue i'||chr(10)||
			'     where 1 = 0';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := v_s;
		
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 'alter table '||q(v_owner)||'.'||q('C$I$'||v_table_name)||' modify app_sid default sys_context(''security'',''app'')';
		
		INSERT INTO tab_column
			(column_sid, tab_sid, oracle_column, pos, data_type, data_length, data_precision, data_scale, nullable, char_length, default_length, data_default, show_in_filter, show_in_breakdown)
		VALUES
			(column_id_seq.NEXTVAL, v_itab_sid, 'APP_SID', v_j, 'NUMBER', 22, 10, 0, 'N', 0, 30, 'sys_context(''security'',''app'')', 0, 0)
		RETURNING
			column_sid INTO v_app_sid_column_sid;
		INSERT INTO uk_cons_col
			(uk_cons_id, column_sid, pos)
		VALUES
			(v_pk_cons_id, column_id_seq.CURRVAL, v_j);
		INSERT INTO tab_column
			(column_sid, tab_sid, oracle_column, pos, data_type, data_length, data_precision, data_scale, nullable, char_length, default_length, data_default, show_in_filter, show_in_breakdown)
		VALUES
			(column_id_seq.NEXTVAL, v_itab_sid, 'ISSUE_ID', v_j + 1, 'NUMBER', 22, 10, 0, 'N', 0, 0, NULL, 0, 0)
		RETURNING
			column_sid INTO v_issue_id_column_sid;
		INSERT INTO uk_cons_col
			(uk_cons_id, column_sid, pos)
		VALUES
			(v_pk_cons_id, column_id_seq.CURRVAL, v_j + 1);

		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||q(v_owner)||'.'||q('C$I$'||v_table_name)||' add'||chr(10)||
			'('||chr(10)||
			'    context_id number(10) default 0 not null,'||chr(10)||
			'    created_dtm timestamp default sys_extract_utc(systimestamp) not null,'||chr(10)||
			'    retired_dtm timestamp,'||chr(10)||
			'    locked_by number(10),'||chr(10)||
			'    vers number(10) default 1 not null,'||chr(10)||
			'    changed_by number(10) not null,'||chr(10)||
			'    change_description varchar2(2000)'||chr(10)||
			')';

		-- Add a PK constraint on context,pk columns,vers
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 'alter table '||q(v_owner)||'.'||q('C$I$'||v_table_name)||' add primary key (context_id,'||v_cols||',vers)';

		-- Create and populate the lock table
		v_l_tab := q(v_owner)||'.'||q('L$I$'||v_table_name);
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 
			'create table '||v_l_tab||' as'||chr(10)||
			'    select '||v_cols||chr(10)||
			'      from '||q(v_owner)||'.'||q('C$I$'||v_table_name);
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 
			'alter table '||v_l_tab||' add primary key ('||v_cols||')';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_l_tab||' add locked_by number(10)';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'update '||v_l_tab||' set locked_by = 0';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_l_tab||' modify locked_by not null';
			
		-- fk to issue 
		-- REMOVED TO STOP CAUSING LOCKS/TABLE WAITS ON LIVE
		
		-- fk to the parent table
		INSERT INTO fk_cons
			(fk_cons_id, tab_sid, r_cons_id, delete_rule, constraint_owner, constraint_name)
		VALUES
			(fk_cons_id_seq.NEXTVAL, v_itab_sid, v_parent_pk_cons_id, 'C', v_owner, 'FK_'||fk_cons_id_seq.CURRVAL);
		v_j := 1;
		FOR i IN 1 .. v_pk_columns.COUNT LOOP
			IF v_app_col_name IS NULL OR v_pk_columns(i) != v_app_col_name THEN -- skip app_sid as this always goes last
				INSERT INTO fk_cons_col (fk_cons_id, column_sid, pos)
					SELECT fk_cons_id_seq.CURRVAL, tc.column_sid, v_j
					  FROM tab_column tc
					 WHERE tc.tab_sid = v_itab_sid
					   AND oracle_column = v_pk_columns(i);
				v_j := v_j + 1;
			END IF;
		END LOOP;
		IF v_app_col_name IS NOT NULL THEN
			INSERT INTO fk_cons_col (fk_cons_id, column_sid, pos)
				SELECT fk_cons_id_seq.CURRVAL, ukcc.column_sid, v_j
				  FROM uk_cons_col ukcc, tab_column tc
				 WHERE ukcc.uk_cons_id = v_pk_cons_id
				   AND ukcc.app_sid = tc.app_sid AND ukcc.column_sid = tc.column_sid
				   AND tc.oracle_column = v_app_col_name;
		END IF;
	
		-- We need to run CreateView/CreateTriggers after the table is created
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'begin'||chr(10)||
			'    cms.tab_pkg.RecreateView('||v_itab_sid||');'||chr(10)||
			'end;';
	ELSE
		v_s :=
			'create table '||q(v_owner)||'.'||q('I$' || v_table_name)||' as'||chr(10)||
			'    select ';
		FOR i IN 1 .. v_pk_columns.COUNT LOOP
			IF v_pk_columns(i) = 'ISSUE_ID' THEN
				RAISE_APPLICATION_ERROR(-20001, 'The table '||v_owner||'.'||v_table_name||' marked issue has a column named ISSUE_ID which is not supported');
			END IF;			
	
			-- skip the column if it's in the PK and marked app as we are going to add one
			-- XXX: ought to check for two app columns in the PK (but that's nuts)
			SELECT col_type
			  INTO v_col_type
			  FROM tab_column
			 WHERE tab_sid = in_tab_sid and oracle_column = v_pk_columns(i);
			IF v_col_type = CT_APP_SID THEN
				IF v_app_col_name IS NOT NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 'The table '||v_owner||'.'||v_table_name||' marked issue has two app columns in the primary key, which is not supported');
				END IF;
				v_app_col_name := v_pk_columns(i);
			ELSE
				v_s := v_s||'t.'||q(v_pk_columns(i))||', ';
			END IF;
		END LOOP;

		v_s := v_s||'i.app_sid, i.issue_id'||chr(10)||
			'      from '||q(v_owner)||'.'||q(v_table_name)||' t, csr.issue i'||chr(10)||
			'     where 1 = 0';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := v_s;
		
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 'alter table '||q(v_owner)||'.'||q('I$'||v_table_name)||' modify app_sid default sys_context(''security'',''app'')';

		-- we now need to add a primary key constraint since we created it using
		-- create table select....
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 
			'alter table '||q(v_owner)||'.'||q('I$'||v_table_name)||' add primary key ('||v_cols||')';
			
		-- fk to issue
		-- REMOVED TO STOP CAUSING LOCKS/TABLE WAITS ON LIVE
		
		-- fk to the parent table
		v_s := 'alter table '||q(v_owner)||'.'||q('I$'||v_table_name)||' add foreign key (';
		FOR i IN 1 .. v_pk_columns.COUNT LOOP
			IF i != 1 THEN 
				v_s := v_s||', ';
			END IF;
			IF v_col_type = CT_APP_SID THEN
				v_s := v_s||'APP_SID';
			ELSE
				v_s := v_s||q(v_pk_columns(i));
			END IF;
		END LOOP;
		v_s := v_s||') references '||q(v_owner)||'.'||q(v_table_name)||' (';
		FOR i IN 1 .. v_pk_columns.COUNT LOOP
			IF i != 1 THEN 
				v_s := v_s||', ';
			END IF;
			v_s := v_s||q(v_pk_columns(i));
		END LOOP;
		v_s := v_s||') on delete cascade';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := v_s;
		
		-- ensure i$xxx is marked as NOT autoregistered
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 
			'begin'||chr(10)||
			'    cms.tab_pkg.RegisterTable('''||v_owner||''', ''I$'||v_table_name||''', FALSE, FALSE);'||chr(10)||
			'end;';
	END IF;

	-- add the issue type for the app (not sure if this is used though?)
	-- this is done via the generated DDL to avoid this package depending on csr
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 
		'begin'||chr(10)||
		'    begin'||chr(10)||
		'        insert into csr.issue_type'||chr(10)||
		'            (issue_type_id, label)'||chr(10)||
		'        values'||chr(10)||
		'            (csr.csr_data_pkg.ISSUE_CMS, ''CMS issue'');'||chr(10)||
		'    exception'||chr(10)||
		'        when dup_val_on_index then'||chr(10)||
		'            null;'||chr(10)||
		'    end;'||chr(10)||
		'end;';

	-- ensure csr.issue is registered unmanaged
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 
		'begin'||chr(10)||
		'    cms.tab_pkg.RegisterTable(''CSR'', ''ISSUE'', FALSE, FALSE);'||chr(10)||
		'end;';
		
	io_ddl.extend(1);
	io_ddl(io_ddl.count) :=
		'begin'||chr(10)||
		'	cms.tab_pkg.INTERNAL_AddIssueFK('||SYS_CONTEXT('SECURITY','APP')||', '''||v_owner||''', '''||v_i$_table_name||''');'||chr(10)||
		'end;';
END;

PROCEDURE INTERNAL_AddIssueFK(
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_oracle_schema				IN	tab.oracle_schema%TYPE,
	in_i$_table_name				IN	VARCHAR2
)
AS
	v_i$_tab_sid					security_pkg.T_SID_ID;
	v_issue_pk_cons_id				NUMBER;
	v_app_sid_column_sid			security_pkg.T_SID_ID;
	v_issue_id_column_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT tab_sid
	  INTO v_i$_tab_sid
	  FROM tab
	 WHERE oracle_schema = in_oracle_schema
	   AND oracle_table = in_i$_table_name
	   AND app_sid = in_app_sid;
	   
	FOR r IN (
		SELECT *
		  FROM fk
		 WHERE fk.app_sid = in_app_sid
		   AND fk.fk_tab_sid = v_i$_tab_sid
		   AND r_owner = 'CSR'
		   AND r_table_name = 'ISSUE'
	) LOOP
		-- fk already exists
		RETURN;
	END LOOP;

	BEGIN
		SELECT pk_cons_id
		  INTO v_issue_pk_cons_id
		  FROM tab
		 WHERE app_sid = in_app_sid
		   AND oracle_schema = 'CSR' AND oracle_table = 'ISSUE';

		SELECT column_sid
		  INTO v_app_sid_column_sid
		  FROM tab_column
		 WHERE app_sid = in_app_sid
		   AND tab_sid = v_i$_tab_sid
		   AND oracle_column = 'APP_SID';

		SELECT column_sid
		  INTO v_issue_id_column_sid
		  FROM tab_column
		 WHERE app_sid = in_app_sid
		   AND tab_sid = v_i$_tab_sid
		   AND oracle_column = 'ISSUE_ID';
		  
		INSERT INTO fk_cons (app_sid, fk_cons_id, tab_sid, r_cons_id, delete_rule, constraint_owner, constraint_name)
		VALUES (in_app_sid, fk_cons_id_seq.NEXTVAL, v_i$_tab_sid, v_issue_pk_cons_id, 'C', in_oracle_schema,'FK_'||fk_cons_id_seq.CURRVAL);
		
		INSERT INTO fk_cons_col (app_sid, fk_cons_id, column_sid, pos)
		VALUES (in_app_sid, fk_cons_id_seq.CURRVAL, v_app_sid_column_sid, 1);
		
		INSERT INTO fk_cons_col (app_sid, fk_cons_id, column_sid, pos)
		VALUES (in_app_sid, fk_cons_id_seq.CURRVAL, v_issue_id_column_sid, 2);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- issue doesn't exist, this constraint will be created when it is registered
	END;
END;

PROCEDURE RequireValue(
	io_state		IN OUT NOCOPY	CommentParseState
)
AS
BEGIN
	IF io_state.value IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 
			'"' || io_state.name || '" without a value in the column comment '||io_state.text);
	END IF;
END;

FUNCTION UpperQuoted(
	io_state		IN OUT NOCOPY	CommentParseState
)
RETURN VARCHAR2
AS
BEGIN
	RequireValue(io_state);
	
	IF NOT io_state.quoted THEN
		io_state.value := UPPER(io_state.value);
	END IF;
	RETURN io_state.value;
END;

PROCEDURE ParseEnumMappingComment(
	in_tab_sid					IN  tab_column.tab_sid%TYPE,
	in_comment_value			IN  VARCHAR2	
)
AS
	v_schema					tab.oracle_schema%TYPE;
	v_oracle_table				tab.oracle_table%TYPE;
	v_map_tab_sid				security_pkg.T_SID_ID;
	v_count						NUMBER;
BEGIN
	SELECT oracle_schema, oracle_table
	  INTO v_schema, v_oracle_table
	  FROM tab
	 WHERE tab_sid = in_tab_sid;
	
	BEGIN
		SELECT tab_sid
		  INTO v_map_tab_sid
		  FROM tab
		 WHERE oracle_schema = v_schema
		   AND oracle_table = in_comment_value;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			--todo: maybe we can automate table creation if it doesn't exist
			RAISE_APPLICATION_ERROR(-20001, 'There is no registered table with the name:'||in_comment_value);
	END;
	
	--check that translation mapping tab has the right structure
	SELECT COUNT(*)
	  INTO v_count
	  FROM fk_cons fc
	 WHERE fc.tab_sid = v_map_tab_sid
	   AND fc.r_cons_id IN (
			SELECT uc.uk_cons_id
			  FROM uk_cons uc
			 WHERE uc.tab_sid = in_tab_sid
	   );
	IF v_count <> 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Expected 1 fk constraint from table:'||in_comment_value||' to table:'||v_oracle_table);
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM tab_column tc
	 WHERE tc.tab_sid = v_map_tab_sid
	   AND data_type = 'VARCHAR2';
	   
	IF v_count <> 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Expected 1 varchar field in tab_sid:'||v_map_tab_sid);
	END IF;
	
	UPDATE tab
	   SET enum_translation_tab_sid = v_map_tab_sid
	 WHERE tab_sid = in_tab_sid;
END;

PROCEDURE ParseSecurableFkComment(
	in_tab_sid					IN  tab_column.tab_sid%TYPE,
	in_comment_value			IN  VARCHAR2	
)
AS
	v_parent_schema				tab.oracle_table%TYPE;
	v_parent_table				tab.oracle_table%TYPE;
	v_app_sid					security_pkg.T_SID_ID;
	v_fk_cons_id				fk_cons.fk_cons_id%TYPE;
	v_column_list				VARCHAR2(255);
	v_table_name				VARCHAR2(255);
BEGIN

	SELECT app_sid, oracle_schema
	  INTO v_app_sid, v_parent_schema
	  FROM tab
	 WHERE tab_sid = in_tab_sid;
					
	IF INSTR(in_comment_value,'(') != 0 AND INSTR(in_comment_value,')') != 0 THEN
		v_column_list := UPPER(SUBSTR(in_comment_value,INSTR(in_comment_value,'(')+1,INSTR(in_comment_value,')')-INSTR(in_comment_value,'(')-1));
		v_table_name := UPPER(SUBSTR(in_comment_value,1,INSTR(in_comment_value,'(')-1));
	ELSE
		v_column_list := NULL;
		v_table_name := UPPER(in_comment_value);
	END IF;
	
	IF INSTR(v_table_name,'.') != 0 THEN
		v_parent_schema := UPPER(SUBSTR(v_table_name,1,INSTR(in_comment_value,'.')-1));
		v_parent_table := UPPER(SUBSTR(v_table_name,INSTR(in_comment_value,'.')+1));
	ELSE
		v_parent_table := UPPER(v_table_name);
	END IF;
	
	BEGIN
		IF v_column_list IS NOT NULL THEN
			-- check columns against the child tables columns, not the parent table's columns, since the
			-- combination of parent table name / child table columns should be uniquely identifiable 
			-- for an fk (would be easier if we just kept the name!)
			SELECT gfk.fk_cons_id
			  INTO v_fk_cons_id
			  FROM (
				SELECT fk.fk_cons_id, aspen2.ordered_stragg(fk.column_name) columns
				  FROM (
					SELECT fk_cons_id, column_name	
					  FROM fk
					 WHERE r_owner = v_parent_schema
					   AND r_table_name = v_parent_table
					   AND fk_tab_sid = in_tab_sid
					 ORDER BY fk_cons_id, pos
				 ) fk
				 GROUP BY fk.fk_cons_id
			  ) gfk
			 WHERE gfk.columns = v_column_list;
			
		ELSE
			SELECT fk.fk_cons_id
			  INTO v_fk_cons_id
			  FROM fk fk
			 WHERE fk.r_owner = v_parent_schema
			   AND fk.r_table_name = v_parent_table
			   AND fk.fk_tab_sid = in_tab_sid
			 GROUP BY fk.fk_cons_id;
		END IF;
	EXCEPTION
		WHEN no_data_found THEN
			-- when auto registering childs, the fk might not be present yet
			NULL;
		WHEN too_many_rows THEN
			RAISE_APPLICATION_ERROR(-20001, 'Too many securable fks found for tab sid = '||in_tab_sid||
				', to parent table = '||v_parent_schema||'.'||v_parent_table||
				'. Try specifiying the columns to narrow down the search, in the format "SCHEMA.PARENT_TABLE(CHILD_COL1,CHILD_COL2)"');
	END;
	
	UPDATE tab
	   SET securable_fk_cons_id = v_fk_cons_id
	 WHERE tab_sid = in_tab_sid;
	 
END;

PROCEDURE ParseTableComments(
	in_tab_sid					IN				tab_column.tab_sid%TYPE,
	in_comments					IN				all_tab_comments.comments%TYPE,
	io_ddl						IN OUT NOCOPY	t_ddl
)
AS
	v_state						CommentParseState;
	v_is_view					tab.is_view%TYPE;
	v_schema					tab.oracle_schema%TYPE;
	v_parent_schema				tab.oracle_schema%TYPE;
	v_parent_table				tab.oracle_table%TYPE;
	v_app_sid					security_pkg.T_SID_ID;
	v_fk_cons_id				fk_cons.fk_cons_id%TYPE;
	v_pk_cons_id				uk_cons.uk_cons_id%TYPE;
	v_col						VARCHAR2(30);
	v_view_uk_col_sid			security_pkg.T_SID_ID;
	v_parent_tab_sid			security_pkg.T_SID_ID;
	v_column_list				VARCHAR2(255);
	v_table_name				VARCHAR2(255);
BEGIN
	-- Clear existing fields
	UPDATE tab
	   SET format_sql = null,
	   	   description = null,
		   securable_fk_cons_id = null
	 WHERE tab_sid = in_tab_sid;
	
	SELECT app_sid, is_view, oracle_schema
	  INTO v_app_sid, v_is_view, v_schema
	 FROM tab
	WHERE tab_sid = in_tab_sid;
	
	IF v_is_view = 1 THEN
		DELETE FROM fk_cons_col
		 WHERE fk_cons_id IN (
			SELECT fk_cons_id
			  FROM fk_cons
			 WHERE tab_sid = in_tab_sid
		);

		DELETE FROM fk_cons
		 WHERE tab_sid = in_tab_sid;
	END IF;
	
	v_state.text := in_comments;
	WHILE ParseComments(v_state) LOOP
		CASE
			WHEN v_state.name IN ('description', 'desc') THEN
				UPDATE tab
				   SET description = v_state.value
				 WHERE tab_sid = in_tab_sid;
				 
			WHEN v_state.name IN ('description_column', 'description_col', 'desc_col') THEN				
				-- Check the column exists in the table
				v_col := UpperQuoted(v_state);
				DECLARE
					v_dummy NUMBER(1);
				BEGIN
					SELECT 1
					  INTO v_dummy
					  FROM tab_column
					 WHERE tab_sid = in_tab_sid
					   AND oracle_column = v_col;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The table with sid '||
							in_tab_sid||' does not have the description column named '||v_state.value);
				END;
				
				UPDATE tab
				   SET format_sql = v_state.value
				 WHERE tab_sid = in_tab_sid;
			
			WHEN v_state.name IN ('cmseditor') THEN	 
				UPDATE tab
				   SET cms_editor = 1
				 WHERE tab_sid = in_tab_sid;
				
			WHEN v_state.name IN ('issues') THEN
				CreateIssueTable(in_tab_sid, io_ddl);
				
			WHEN v_state.name IN ('helper_pkg') THEN
				RequireValue(v_state);
				UPDATE tab
				   SET helper_pkg = v_state.value
				 WHERE tab_sid = in_tab_sid;
				
			WHEN v_state.name IN ('region_col') THEN
				v_col := UpperQuoted(v_state);
				-- Check the column exists in the table
				-- and update the region_col_sid col in tab.
				DECLARE
					v_col_sid	NUMBER(10);
				BEGIN
					SELECT column_sid
					  INTO v_col_sid
					  FROM tab_column
					 WHERE tab_sid = in_tab_sid
					   AND oracle_column = v_col;
					
					-- Update region_col_sid.
					UPDATE tab
					   SET region_col_sid = v_col_sid
					 WHERE tab_sid = in_tab_sid;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The table with sid '||
							in_tab_sid||' does not have the region column named '||v_state.value);
				END;
				
			WHEN v_state.name IN ('parent') THEN
				IF v_is_view != 1 THEN
					RAISE_APPLICATION_ERROR(-20001, 'The attribute parent is only valid for views: tab_sid = '||in_tab_sid);
				END IF;

				IF INSTR(v_state.value,'.') != 0 THEN
					v_parent_schema := UPPER(SUBSTR(v_state.value,1,INSTR(v_state.value,'.')-1));
					v_parent_table := UPPER(SUBSTR(v_state.value,INSTR(v_state.value,'.')+1));
				ELSE
					v_parent_schema := v_schema;
					v_parent_table := UPPER(v_state.value);
				END IF;
				
				BEGIN
					SELECT pk_cons_id, tab_sid
					  INTO v_pk_cons_id, v_parent_tab_sid
					  FROM tab
					 WHERE app_sid = v_app_sid
					   AND oracle_schema = v_parent_schema
					   AND oracle_table = v_parent_table;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(-20001, 'Parent of view not found: view sid = '||in_tab_sid||', parent = '||v_parent_schema||'.'||v_parent_table);
				END;
				
				IF v_pk_cons_id IS NULL THEN 
					RAISE_APPLICATION_ERROR(-20001, 'Parent of view must have a PK: view sid = '||in_tab_sid||', parent = '||v_parent_schema||'.'||v_parent_table);
				END IF;
				
				FOR chk IN (
					SELECT utc.oracle_column
					  FROM tab_column utc
					  JOIN uk_cons_col ucc ON utc.column_sid = ucc.column_sid
					  LEFT JOIN tab_column tc ON utc.oracle_column = tc.oracle_column AND tc.tab_sid = in_tab_sid
					 WHERE ucc.uk_cons_id = v_pk_cons_id
					   AND tc.column_sid IS NULL
				) LOOP
					RAISE_APPLICATION_ERROR(-20001, 'View must contain all columns of the parent PK. Column missing: '||chk.oracle_column);
				END LOOP;
				 
				-- Insert FK making the view a child of the parent
				INSERT INTO fk_cons (fk_cons_id, tab_sid, r_cons_id, delete_rule, constraint_owner, constraint_name)
				VALUES (fk_cons_id_seq.NEXTVAL, in_tab_sid, v_pk_cons_id, 'R', v_schema, 'FK_'||fk_cons_id_seq.CURRVAL)
				RETURNING fk_cons_id INTO v_fk_cons_id;
				
				INSERT INTO fk_cons_col (app_sid, fk_cons_id, column_sid, pos)
				SELECT tc.app_sid, v_fk_cons_id, tc.column_sid, uk.pos
				  FROM uk_cons_col uk
				  JOIN tab_column utc ON uk.column_sid = utc.column_sid AND uk.app_sid = utc.app_sid
				  JOIN tab_column tc ON utc.oracle_column = tc.oracle_column
				 WHERE tc.tab_sid = in_tab_sid
				   AND uk_cons_id = v_pk_cons_id;
				
				UPDATE tab
				   SET parent_tab_sid = v_parent_tab_sid
				 WHERE tab_sid = in_tab_sid;
			WHEN v_state.name IN ('view_unique_col') THEN
				IF v_is_view != 1 THEN
					RAISE_APPLICATION_ERROR(-20001, 'The attribute view_unique_col is only valid for views: tab_sid = '||in_tab_sid);
				END IF;
				
				BEGIN
					SELECT column_sid
					  INTO v_view_uk_col_sid
					  FROM tab_column
					 WHERE tab_sid = in_tab_sid
					   AND UPPER(oracle_column) = UPPER(v_state.value);
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							RAISE_APPLICATION_ERROR(-20001, 'No column with the name:"'||v_state.value||'" found for tab with sid:'||in_tab_sid);
				END;   
				
				INSERT INTO uk_cons(uk_cons_id, tab_sid, constraint_owner, constraint_name) 
					VALUES(uk_cons_id_seq.NEXTVAL, in_tab_sid, v_schema, 'UK_'||uk_cons_id_seq.CURRVAL);
					
				INSERT INTO uk_cons_col(uk_cons_id, column_sid, pos)
					VALUES(cms.uk_cons_id_seq.CURRVAL, v_view_uk_col_sid, 1);
					
				UPDATE cms.tab 
				   SET pk_cons_id=cms.uk_cons_id_seq.CURRVAL
				 WHERE tab_sid = in_tab_sid;
				 
				UPDATE cms.tab_column
				   SET nullable = 'N'
				 WHERE column_sid = v_view_uk_col_sid;
				 
			WHEN v_state.name = 'securable_fk' THEN
				ParseSecurableFkComment(in_tab_sid, v_state.value);
			WHEN v_state.name = 'enum_translation_tab' THEN
				ParseEnumMappingComment(in_tab_sid, v_state.value);
			WHEN v_state.name = 'basedata' THEN
				UPDATE tab
				   SET is_basedata = 1
				 WHERE tab_sid = in_tab_sid;
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'The attribute '||v_state.name||
					' is not known in the table comment '||in_comments);
		END CASE;
	END LOOP;
END;

PROCEDURE ParseColumnComments(
	in_tab_sid					IN		tab_column.tab_sid%TYPE,
	in_column_sid				IN		tab_column.column_sid%TYPE,
	in_comments					IN		all_col_comments.comments%TYPE,
	io_ddl						IN OUT NOCOPY	t_ddl
)
AS
	v_state							CommentParseState;
	v_flow_item_id_name				VARCHAR2(30);
	v_is_view						tab.is_view%TYPE;
	v_schema						tab.oracle_schema%TYPE;
	v_parent_schema					tab.oracle_schema%TYPE;
	v_parent_table					tab.oracle_table%TYPE;
	v_app_sid						security_pkg.T_SID_ID;
	v_fk_cons_id					fk_cons.fk_cons_id%TYPE;
	v_pk_cons_id					uk_cons.uk_cons_id%TYPE;
	v_measure_sid					csr.measure.measure_sid%TYPE;
	v_column_sid					tab_column.column_sid%TYPE;
	v_col							VARCHAR2(30);
    v_extra_cols					t_string_list;
    v_list							VARCHAR2(4000);
BEGIN
	-- Clear existing fields
	UPDATE tab_column
	   SET help = null,
	   	   description = null,
	   	   check_msg = null,
	   	   enumerated_desc_field = null,
	   	   enumerated_pos_field = null,
	   	   enumerated_colpos_field = null,
	   	   enumerated_hidden_field = null,
	   	   enumerated_colour_field = null,
		   enumerated_extra_fields = null,
	   	   tree_desc_field = null,
	   	   tree_id_field = null,
	   	   tree_parent_id_field = null,
	   	   full_text_index_name = null,
		   incl_in_active_user_filter = 0,
		   measure_sid = null,
		   measure_conv_column_sid = null,
		   measure_conv_date_column_sid = null,
		   form_selection_desc_field = null,
		   form_selection_pos_field = null,
		   form_selection_form_field = null,
		   form_selection_hidden_field = null,
		   restricted_by_policy = 0
	 WHERE tab_sid = in_tab_sid AND column_sid = in_column_sid;
	UPDATE tab_column
	   SET master_column_sid = NULL
	 WHERE master_column_sid = in_column_sid;
	 
	v_state.text := in_comments;
	WHILE ParseComments(v_state) LOOP
		CASE
			WHEN v_state.name = 'html' THEN
				UPDATE tab_column 
				   SET col_type = tab_pkg.CT_HTML
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'fti' THEN
				CreateFullTextIndex(in_tab_sid, in_column_sid, UpperQuoted(v_state), io_ddl);
				 
			WHEN v_state.name IN ('desc', 'description') THEN
				RequireValue(v_state);
				UPDATE tab_column
				   SET description = v_state.value
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name = 'help' THEN
				RequireValue(v_state);
				UPDATE tab_column
				   SET help = v_state.value
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'check' THEN
				RequireValue(v_state);
				UPDATE tab_column
				   SET check_msg = v_state.value
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'file' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_FILE_DATA, master_column_sid = in_column_sid
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'link' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_LINK
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'image' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_IMAGE
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'time' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_TIME
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'user' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_USER
				 WHERE column_sid = in_column_sid;
				
			WHEN v_state.name = 'owner_user' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_OWNER_USER
				 WHERE column_sid = in_column_sid;
				
			WHEN v_state.name = 'region' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_REGION
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'indicator' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_INDICATOR
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'measure' THEN
				RequireValue(v_state);
				BEGIN
					SELECT measure_sid
					  INTO v_measure_sid
					  FROM csr.measure
					 WHERE UPPER(lookup_key) = UPPER(v_state.value);
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(-20001, 'The measure with lookup key '||v_state.value||
							' does not exist in the column comment '||in_comments);
				END;
				UPDATE tab_column
				   SET measure_sid = v_measure_sid,
				   	   col_type = tab_pkg.CT_MEASURE_CONVERSION
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'measure_conversion' THEN
				v_col := UpperQuoted(v_state);
				BEGIN
					SELECT column_sid
					  INTO v_column_sid
					  FROM tab_column
					 WHERE tab_sid = in_tab_sid
					   AND oracle_column = v_col;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(-20001, 'The measure conversion column '||v_state.value||
							' does not exist in the column comment '||in_comments);
				END;				
				UPDATE tab_column
				   SET measure_conv_column_sid = v_column_sid
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'measure_conversion_date' THEN
				v_col := UpperQuoted(v_state);
				BEGIN
					SELECT column_sid
					  INTO v_column_sid
					  FROM tab_column
					 WHERE oracle_column = v_col
					   AND tab_sid = in_tab_sid;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(-20001, 'The measure conversion column '||v_state.value||
							' does not exist in the column comment '||in_comments);
				END;
				UPDATE tab_column
				   SET measure_conv_date_column_sid = v_column_sid
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'file_mime' THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_FILE_MIME, master_column_sid = in_column_sid
				 WHERE oracle_column = v_col
				   AND tab_sid = in_tab_sid;
				IF SQL%ROWCOUNT = 0 THEN
					RAISE_APPLICATION_ERROR(-20001, 'The column '||v_state.value||
						' specified as "file_mime" does not exist in the column comment '||in_comments);
				END IF;

			WHEN v_state.name = 'file_name' THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_FILE_NAME, master_column_sid = in_column_sid
				 WHERE oracle_column = v_col
				   AND tab_sid = in_tab_sid;
				IF SQL%ROWCOUNT = 0 THEN
					RAISE_APPLICATION_ERROR(-20001, 'The column '||v_state.value||
						' specified as "file_name" does not exist in the column comment '||in_comments);
				END IF;
				
			WHEN v_state.name IN ('enumerated', 'enum') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_ENUMERATED,
				       calc_xml = null
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'search_enum' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_SEARCH_ENUM
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'cascade_enum' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_CASCADE_ENUM
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name = 'constrained_enum' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_CONSTRAINED_ENUM
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'video' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_VIDEO_CODE
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name = 'chart' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_CHART
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name IN ('document','doc') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_DOCUMENT
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name IN ('enumerated_pos_field', 'enum_pos_field', 'enum_pos_col') THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET enumerated_pos_field = v_col
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name IN ('enumerated_colpos_field', 'enum_colpos_field', 'enum_column_colpos') THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET enumerated_colpos_field = v_col
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name IN ('enumerated_hidden_field', 'enum_hidden_field', 'enum_hidden_col') THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET enumerated_hidden_field = v_col
				 WHERE column_sid = in_column_sid;
				 				 
			WHEN v_state.name IN ('enumerated_desc_field', 'enum_desc_field', 'enum_desc_col') THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET enumerated_desc_field = v_col
				 WHERE column_sid = in_column_sid;
				
			WHEN v_state.name IN ('enumerated_colour_field', 'enum_colour_field', 'enum_colour_col') THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET enumerated_colour_field = v_col
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name IN ('enumerated_extra_fields', 'enum_extra_fields', 'enum_extra_cols') THEN
    			ParseQuotedList(v_state.value, v_extra_cols);
				FOR i IN 1 .. v_extra_cols.COUNT LOOP
					v_list := comma(v_list) || q(dq(v_extra_cols(i)));
    			END LOOP;	
				UPDATE tab_column
				   SET enumerated_extra_fields = v_list
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name IN ('autoincrement', 'auto') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_AUTO_INCREMENT,
				       show_in_breakdown = 0	-- default to not chart off auto inc column
				 WHERE column_sid = in_column_sid;
				
			WHEN v_state.name IN ('sequence', 'seq') THEN
				UPDATE tab_column
				   SET auto_sequence = v_state.value
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name IN ('app', 'app_sid') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_APP_SID
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name IN ('pos', 'position') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_POSITION
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name IN ('bool', 'boolean') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_BOOLEAN
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'flow_item' THEN
				SELECT oracle_column
				  INTO v_flow_item_id_name
				  FROM tab_column
				 WHERE column_sid = in_column_sid;
				   
				IF LOWER(v_flow_item_id_name) != 'flow_item_id' THEN
					RAISE_APPLICATION_ERROR(-20001, 'Flow item column '||v_flow_item_id_name||' must be called flow_item_id since there is code in tab_pkg that assumes this is the case.');
				END IF;
			
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_FLOW_ITEM
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'flow_region' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_FLOW_REGION
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'calc' THEN
				RequireValue(v_state);
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_CALC, calc_xml = v_state.value
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'helper_pkg' THEN
				RequireValue(v_state);
				UPDATE tab_column
				   SET helper_pkg = v_state.value
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name = 'value_placeholder' THEN
				UPDATE tab_column
				   SET value_placeholder = 1
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name = 'enforce_nullability' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_ENFORCE_NULLABILITY
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'company' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_COMPANY
				 WHERE column_sid = in_column_sid;
				
			WHEN v_state.name = 'tree' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_TREE
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name IN ('tree_desc_field', 'tree_desc_col') THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET tree_desc_field = v_col
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name IN ('tree_id_field', 'tree_id_col') THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET tree_id_field = v_col
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name IN ('tree_parent_id_field', 'tree_parent_id_col') THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET tree_parent_id_field = v_col
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name = 'include_in_active_user_filter' THEN
				UPDATE tab_column
				   SET incl_in_active_user_filter = 1
				 WHERE column_sid = in_column_sid;
			
			WHEN v_state.name = 'coverable' THEN
				UPDATE tab_column
				   SET coverable = 1
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'fk_id' THEN
				SELECT app_sid, is_view, oracle_schema
				  INTO v_app_sid, v_is_view, v_schema
				  FROM tab
				 WHERE tab_sid = in_tab_sid;
			
				IF v_is_view != 1 THEN
					RAISE_APPLICATION_ERROR(-20001, 'The attribute pk_id is only valid for views: tab_sid = '||in_tab_sid);
				END IF;
				
				IF INSTR(v_state.value,'.') != 0 THEN
					v_parent_schema := UPPER(SUBSTR(v_state.value,1,INSTR(v_state.value,'.')-1));
					v_parent_table := UPPER(SUBSTR(v_state.value,INSTR(v_state.value,'.')+1));
				ELSE
					v_parent_schema := v_schema;
					v_parent_table := UPPER(v_state.value);
				END IF;
				
				BEGIN
					SELECT pk_cons_id
					  INTO v_pk_cons_id
					  FROM tab
					 WHERE app_sid = v_app_sid
					   AND oracle_schema = v_parent_schema
					   AND oracle_table = v_parent_table;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(-20001, 'Enum not found: view sid = '||in_tab_sid||', enum = '||v_parent_schema||'.'||v_parent_table);
				END;
				
				IF v_pk_cons_id IS NULL THEN 
					RAISE_APPLICATION_ERROR(-20001, 'Enum must have a PK: view sid = '||in_tab_sid||', enum = '||v_parent_schema||'.'||v_parent_table);
				END IF;
				
				FOR chk IN (
					SELECT NULL FROM (
						SELECT rownum r
						  FROM cms.uk_cons_col
						 WHERE uk_cons_id = v_pk_cons_id) x
					WHERE x.r > 1
				) LOOP
					RAISE_APPLICATION_ERROR(-20001, 'Enum PK must contain only one column. view sid = '||in_tab_sid||', enum = '||v_parent_schema||'.'||v_parent_table);
				END LOOP;
				 
				-- Insert FK making the view a child of the parent
				INSERT INTO fk_cons (fk_cons_id, tab_sid, r_cons_id, delete_rule, constraint_owner, constraint_name)
				VALUES (fk_cons_id_seq.NEXTVAL, in_tab_sid, v_pk_cons_id, 'R', v_schema, 'FK_'||fk_cons_id_seq.CURRVAL)
				RETURNING fk_cons_id INTO v_fk_cons_id;
				
				INSERT INTO fk_cons_col (app_sid, fk_cons_id, column_sid, pos)
				VALUES (v_app_sid, v_fk_cons_id, in_column_sid, 1);

			WHEN v_state.name = 'role' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_ROLE
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'survey_response' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_SURVEY_RESPONSE
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'internal_audit' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_INTERNAL_AUDIT
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name in ('substance','chemical') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_SUBSTANCE
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name in ('business_relationship') THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_BUSINESS_RELATIONSHIP
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'include_in_search' THEN
				UPDATE tab_column
				   SET include_in_search = 1
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'hide_from_filter' THEN
				UPDATE tab_column
				   SET show_in_filter = 0
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'form_selection' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_FORM_SELECTION
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name IN ('form_selection_description_field', 'form_selection_desc_field') THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET form_selection_desc_field = v_col
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'form_selection_pos_field' THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET form_selection_pos_field = v_col
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'form_selection_form_field' THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET form_selection_form_field = v_col
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'form_selection_hidden_field' THEN
				v_col := UpperQuoted(v_state);
				UPDATE tab_column
				   SET form_selection_hidden_field = v_col
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'hide_from_breakdown' THEN
				UPDATE tab_column
				   SET show_in_breakdown = 0
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'restricted_by_policy' THEN
				UPDATE tab_column
				   SET restricted_by_policy = 1
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'format_mask' THEN
				RequireValue(v_state);
				UPDATE tab_column
				   SET format_mask = v_state.value
				 WHERE column_sid = in_column_sid;

			WHEN v_state.name = 'product' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_PRODUCT
				 WHERE column_sid = in_column_sid;
				 
			WHEN v_state.name = 'permit' THEN
				UPDATE tab_column
				   SET col_type = tab_pkg.CT_PERMIT
				 WHERE column_sid = in_column_sid;
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'The attribute '||v_state.name||
					' is not known in the column comment '||in_comments);
		END CASE;
	END LOOP;
END;

PROCEDURE ReParseComments(
	in_oracle_schema			IN		tab.oracle_schema%TYPE,
	in_oracle_table		        IN		tab.oracle_table%TYPE
)
AS
	v_tab_sid						tab.tab_sid%TYPE;
	v_managed						tab.managed%TYPE;
	v_ddl 							t_ddl DEFAULT t_ddl();
	v_table_name					VARCHAR2(30);
	v_owner							VARCHAR2(30);
	v_flow_item_count				NUMBER;
	v_flow_region_count				NUMBER;
	v_flow_item_id_name				VARCHAR2(30);
	v_s								VARCHAR2(4000);
BEGIN
	BEGIN
		SELECT tab_sid, managed, oracle_schema, oracle_table
		  INTO v_tab_sid, v_managed, v_owner, v_table_name
		  FROM tab
		 WHERE oracle_schema = dq(in_oracle_schema)
		   AND oracle_table = dq(in_oracle_table)
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 
				'Could not find table '||in_oracle_schema||'.'||in_oracle_table);
	END;
	IF v_managed = 1 THEN
		v_table_name := 'C$'||v_table_name;
	END IF;

	FOR r IN (SELECT atc.comments
			   FROM all_tab_comments atc
			  WHERE atc.owner = v_owner AND atc.table_name = v_table_name) LOOP
		ParseTableComments(v_tab_sid, r.comments, v_ddl);
	END LOOP;

	FOR r IN (SELECT tc.column_sid, acc.comments
			   FROM tab_column tc, all_col_comments acc
			  WHERE tc.tab_sid = v_tab_sid AND 
				   acc.owner = v_owner AND acc.table_name = v_table_name AND 
				   acc.column_name = tc.oracle_column AND acc.comments IS NOT NULL
	) LOOP
		ParseColumnComments(v_tab_sid, r.column_sid, r.comments, v_ddl);
    END LOOP;
    
	-- clean up
	DropUnusedFullTextIndexes(v_tab_sid, v_ddl);
    
	-- Check the workflow configuration is correct (1 flow item column, 1 flow region column)
	SELECT COUNT(*)
	  INTO v_flow_item_count
	  FROM tab_column
	 WHERE tab_sid = v_tab_sid
	   AND col_type = tab_pkg.CT_FLOW_ITEM;

	IF v_flow_item_count > 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'At most one column can be marked flow_item');
	END IF;
	 
	SELECT COUNT(*)
	  INTO v_flow_region_count
	  FROM tab_column
	 WHERE tab_sid = v_tab_sid
	   AND col_type = tab_pkg.CT_FLOW_REGION;
	   
	IF v_flow_item_count = 1 THEN
		SELECT oracle_column
		  INTO v_flow_item_id_name
		  FROM tab_column
		 WHERE tab_sid = v_tab_sid
		   AND col_type = tab_pkg.CT_FLOW_ITEM;
		   
		IF LOWER(v_flow_item_id_name) != 'flow_item_id' THEN
			RAISE_APPLICATION_ERROR(-20001, 'Flow item column '||v_flow_item_id_name||' must be called flow_item_id since there is code in tab_pkg that assumes this is the case.');
		END IF;
	END IF;

	SELECT MIN(LTRIM(SYS_CONNECT_BY_PATH(full_text_index_name, ', '),', '))
	  INTO v_s
      FROM (
        SELECT full_text_index_name, rownum rn
          FROM (
            SELECT full_text_index_name
              FROM tab_column
             WHERE full_text_index_name IS NOT NULL
               AND tab_sid = v_tab_sid
             GROUP BY full_text_index_name
             HAVING COUNT(*) > 1
         )
      )
      WHERE connect_by_isleaf = 1
      START WITH rn = 1
     CONNECT BY PRIOR rn = rn - 1;

	IF v_s IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Index name is used on more than one column: '||v_s);
	END IF;
    
	ExecuteDDL(v_ddl);    
END;

/* Steps for refreshing:

   1. Drop any shadow foreign key constraints that involve unmanaged tables
   2. Drop any check constraints for either managed or unmanaged tables
   3. Drop all structure information for unmanaged tables: that's all
      foreign / unique keys, the columns, the check constraints, but leaving
      the table object. This is so that security on the table SO, filters, 
      publications etc that hang off the table SOs are not destroyed.
   4. Re-register all the unmanaged tables.
   5. Register all the parent tables of the managed tables again (to 
      account for any new REFERENCES PARENT(PARENT_COLUMN) that may
      have appeared)
   6. Clean up any dropped tables
   7. Reshadow the check constraints on the managed tables
   8. Reshadow column details on the managed tables
 */
PROCEDURE RefreshUnmanaged(
	in_app_sid				IN	tab.app_sid%TYPE DEFAULT NULL
)
AS
	v_tables_sid			security_pkg.T_SID_ID;
	v_ddl 					t_ddl DEFAULT t_ddl();
	v_tab_set				t_tab_set;
    v_col_name 				VARCHAR(30);
    v_cnt      				NUMBER;
    v_all_apps				BOOLEAN DEFAULT FALSE;
    v_last_app				security_pkg.T_SID_ID;
    v_nullable				VARCHAR2(1);
	v_data_default			VARCHAR2(255);
	v_default_length		NUMBER;
BEGIN
	IF SYS_CONTEXT('SECURITY', 'ACT') IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001,
			'You need to be logged on to refresh tables');
	END IF;
	IF NOT NVL(SYS_CONTEXT('SECURITY', 'APP'), -1) = NVL(in_app_sid, -1) THEN
		RAISE_APPLICATION_ERROR(-20001,
			'You can only refresh tables for the application set in your security context');
	END IF;	
	IF SYS_CONTEXT('SECURITY', 'APP') IS NULL THEN
		v_all_apps := TRUE;
	END IF;
	
	-- We need to delete all FKs on unmanaged tables, and also all FKs on
	-- managed tables that reference unmanaged tables.
	DELETE FROM fk_cons_col
	 WHERE fk_cons_id IN (
	 		SELECT fkc.fk_cons_id
	 		  FROM fk_cons fkc, uk_cons ukc, tab ukt, tab fkt
	 		 WHERE fkc.r_cons_id = ukc.uk_cons_id AND fkc.tab_sid = fkt.tab_sid AND
	 		 	   ukc.tab_sid = ukt.tab_sid AND (ukt.managed = 0 OR fkt.managed = 0) AND
	 		 	   (in_app_sid IS NULL OR (ukt.app_sid = fkt.app_sid AND
	 		 	   						   ukt.app_sid = in_app_sid AND 
	 		 	   						   fkt.app_sid = in_app_sid)));
	UPDATE tab
	   SET securable_fk_cons_id = NULL
	 WHERE securable_fk_cons_id IN (
	 		SELECT fkc.fk_cons_id
	 		  FROM fk_cons fkc, uk_cons ukc, tab ukt, tab fkt
	 		 WHERE fkc.r_cons_id = ukc.uk_cons_id AND fkc.tab_sid = fkt.tab_sid AND
	 		 	   ukc.tab_sid = ukt.tab_sid AND (ukt.managed = 0 OR fkt.managed = 0) AND
	 		 	   (in_app_sid IS NULL OR (ukt.app_sid = fkt.app_sid AND
	 		 	   						   ukt.app_sid = in_app_sid AND 
	 		 	   						   fkt.app_sid = in_app_sid)));
	DELETE FROM fk_cons
	 WHERE fk_cons_id IN (
	 		SELECT fkc.fk_cons_id
	 		  FROM fk_cons fkc, uk_cons ukc, tab ukt, tab fkt
	 		 WHERE fkc.r_cons_id = ukc.uk_cons_id AND fkc.tab_sid = fkt.tab_sid AND
	 		 	   ukc.tab_sid = ukt.tab_sid AND (ukt.managed = 0 OR fkt.managed = 0) AND
	 		 	   (in_app_sid IS NULL OR (ukt.app_sid = fkt.app_sid AND
	 		 	   						   ukt.app_sid = in_app_sid AND 
	 		 	   						   fkt.app_sid = in_app_sid)));
	 		 	   								  
	-- Delete all uks on unmanaged tables
	UPDATE tab
	   SET pk_cons_id = NULL
	 WHERE managed = 0 AND
	 	   (in_app_sid IS NULL OR app_sid = in_app_sid);
	DELETE FROM uk_cons_col
	 WHERE uk_cons_id IN (
	 		SELECT uk_cons_id
	 		  FROM uk_cons ukc, tab ukt
	 		 WHERE ukc.tab_sid = ukt.tab_sid AND ukt.managed = 0 AND 
	 		 	   (in_app_sid IS NULL OR ukt.app_sid = in_app_sid));
	DELETE FROM uk_cons
	 WHERE uk_cons_id IN (
	 		SELECT uk_cons_id
	 		  FROM uk_cons ukc, tab ukt
	 		 WHERE ukc.tab_sid = ukt.tab_sid AND ukt.managed = 0 AND
	 		 	   (in_app_sid IS NULL OR ukt.app_sid = in_app_sid));

	-- Delete all check constraints
	DELETE FROM ck_cons_col
	 WHERE ck_cons_id IN (
	 		SELECT ck_cons_id
	 		  FROM ck_cons ck, tab ckt
		 		 WHERE ck.tab_sid = ckt.tab_sid AND
		 		 	   (in_app_sid IS NULL OR ckt.app_sid = in_app_sid));
	DELETE FROM ck_cons
	 WHERE ck_cons_id IN (
	 		SELECT ck_cons_id
	 		  FROM ck_cons ck, tab ckt
	 		 WHERE ck.tab_sid = ckt.tab_sid AND
	 		 	   (in_app_sid IS NULL OR ckt.app_sid = in_app_sid));

	-- Save the tab sids of the tables we want to reregister
	DELETE FROM temp_refresh_table;
	INSERT INTO temp_refresh_table (tab_sid, app_sid, oracle_schema, oracle_table)
		SELECT tab_sid, app_sid, oracle_schema, oracle_table
		  FROM tab
		 WHERE managed = 0 AND (in_app_sid IS NULL OR app_sid = in_app_sid);

	 
	--delete/update columns
	FOR r IN (
		SELECT tc.column_sid, atc.column_name,atc.column_id pos, atc.data_type, atc.data_length,
			atc.data_precision, atc.data_scale, atc.nullable, atc.char_length, atc.default_length,
			atc.data_default, tai.column_sid aggr_col_sid
		  FROM tab_column tc
		  JOIN tab t ON tc.tab_sid = t.tab_sid AND tc.app_sid = t.app_sid
		  LEFT JOIN all_tab_columns atc ON t.oracle_schema = atc.owner AND t.oracle_table = atc.table_name AND tc.oracle_column = atc.column_name
		  LEFT JOIN tab_aggregate_ind tai ON tc.column_sid = tai.column_sid
		 WHERE t.managed = 0
		   AND (in_app_sid IS NULL OR t.app_sid = in_app_sid)
	) 
	LOOP
		IF r.column_name IS NULL THEN 
			IF r.aggr_col_sid IS NULL THEN --Keep old behaviour
				DELETE FROM tab_column tc
				 WHERE column_sid = r.column_sid
				   AND (in_app_sid IS NULL OR app_sid = in_app_sid);
			END IF;
		ELSE 
			v_data_default := SanitiseDataDefault(r.data_default);			
			v_default_length := r.default_length;
			
			-- removing a default in oracle doesn't null it out, it comes through as 'null'
			IF v_data_default = 'null' THEN
				v_data_default := NULL;
				v_default_length := NULL;
			END IF;
				
			UPDATE tab_column 
			   SET pos = r.pos,
				   data_type = r.data_type, 
				   data_length = r.data_length, 
				   data_precision = r.data_precision, 
				   data_scale = r.data_scale, 
				   nullable = r.nullable, 
				   char_length = r.char_length,
				   default_length = v_default_length, 
				   data_default = v_data_default
			 WHERE column_sid = r.column_sid
			   AND (in_app_sid IS NULL OR app_sid = in_app_sid);
		END IF;
	
	END LOOP;
	
	FOR r IN (
		SELECT tc.oracle_column, t.oracle_table, t.oracle_schema
		  FROM tab_column tc
		  JOIN tab t ON tc.tab_sid = t.tab_sid AND tc.app_sid = t.app_sid
		  LEFT JOIN all_tab_columns atc ON t.oracle_schema = atc.owner
		   AND t.oracle_table = atc.table_name
		   AND tc.oracle_column = atc.column_name
		 WHERE t.managed = 0
		   AND (in_app_sid IS NULL OR t.app_sid = in_app_sid)
		   AND atc.column_name IS NULL
	) LOOP
		RAISE_APPLICATION_ERROR(-20001, 'RefreshUnmanaged is removing a column that is referenced by CMS.TAB_AGGREGATE_IND: '||
			r.oracle_schema||'.'||r.oracle_table||'.'||r.oracle_column);
	END LOOP;
	
	-- We have to leave the rows in tab hanging around to keep associated 
	-- filters, publications, etc alive

	-- Run over the temporary list and reregister the tables
	FOR r IN (SELECT tt.app_sid, tt.oracle_schema, tt.oracle_table,
					 CASE WHEN atc.table_name IS NULL THEN 1 ELSE 0 END is_view
				FROM temp_refresh_table tt
				LEFT JOIN all_tables atc ON tt.oracle_schema = atc.owner AND tt.oracle_table = atc.table_name
				LEFT JOIN all_views av ON tt.oracle_schema = av.owner AND tt.oracle_table = av.view_name
			   WHERE atc.table_name IS NOT NULL OR av.view_name IS NOT NULL
			ORDER BY tt.app_sid, CASE WHEN atc.table_name IS NULL THEN 1 ELSE 0 END) LOOP
		
		-- Ensure we create new objects with the correct application sid
		IF NVL(v_last_app, 0) <> r.app_sid AND v_all_apps THEN
			security_pkg.SetApp(r.app_sid);
			v_last_app := r.app_sid;
		END IF;
		
		-- Get the cms container, if nothing found we assume the table is
		-- hanging around from a deleted application and leave it in the 'munched' state
		BEGIN
			v_tables_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), r.app_sid, 'cms');
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				v_tables_sid := NULL;
		END;
		
		IF v_tables_sid IS NOT NULL THEN
			RegisterTable_(v_tables_sid, r.oracle_schema, r.oracle_table, FALSE, r.is_view = 1, TRUE, TRUE, v_ddl, v_tab_set);
		END IF;
	END LOOP;
	
	-- now we want to refresh RI + check constraints on all of the managed tables
	-- to do that, all we need to do is register any new parents -- reregistering
	-- old parents has already added the appropriate fks
	-- note all of the parents are unmanaged (otherwise the RI wouldn't be in the
	-- data dictionary)
	-- exclude mapping tables created by MakeFormIndicators.exe (prefixed R$)
	v_last_app := NULL;
	FOR r IN (SELECT t.app_sid, pap.owner, pap.table_name
				FROM tab t, all_constraints pap, all_constraints cac
			   WHERE cac.owner = t.oracle_schema AND cac.table_name = 'C$'||t.oracle_table AND
			   		 cac.constraint_type = 'R' AND cac.r_owner = pap.owner AND
			   		 cac.r_constraint_name = pap.constraint_name AND			   		 
			   		 (pap.owner IN (SELECT oracle_schema FROM app_schema WHERE app_sid = t.app_sid) OR
			   		  (pap.owner, pap.table_name) IN (SELECT oracle_schema, oracle_table FROM app_schema_table WHERE app_sid = t.app_sid)) AND
			   		 (in_app_sid IS NULL OR t.app_sid = in_app_sid) AND
			   		 t.managed = 1 AND pap.table_name <> 'R$'
			GROUP BY t.app_sid, pap.owner, pap.table_name) LOOP
		
		-- Ensure we create new objects with the correct application sid
		IF NVL(v_last_app, 0) <> r.app_sid AND v_all_apps THEN
			security_pkg.SetApp(r.app_sid);
			v_last_app := r.app_sid;
		END IF;

		-- Get the cms container.  If it's not found assume this is a hangover
		-- from a deleted application.
		-- XXX: should we should munch it?
		BEGIN
			v_tables_sid := SecurableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'APP'), r.app_sid, 'cms');
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_tables_sid := NULL;
		END;
		
		IF v_tables_sid IS NOT NULL THEN
			RegisterTable_(v_tables_sid, r.owner, r.table_name, FALSE, FALSE, TRUE, TRUE, v_ddl, v_tab_set);		
		END IF;
	END LOOP;
	
	-- reshadow fk's to issues table where they are missing, regardless of whether
	-- physical fk exists (a lot have been removed to reduce locking on live)
	FOR r IN (
		SELECT t.app_sid, t.oracle_schema, t.oracle_table
		  FROM tab t
		 WHERE (in_app_sid IS NULL OR t.app_sid = in_app_sid)
		   AND t.oracle_table LIKE 'I$%'
		   AND NOT EXISTS (
			SELECT *
			  FROM fk
			 WHERE fk.app_sid = t.app_sid
			   AND fk.fk_tab_sid = t.tab_sid
			   AND r_owner = 'CSR'
			   AND r_table_name = 'ISSUE'
		  )
	) LOOP
		INTERNAL_AddIssueFK(r.app_sid, r.oracle_schema, r.oracle_table);
	END LOOP;

	-- Clean up any dropped tables
	IF v_all_apps THEN
		security_pkg.SetApp(NULL);
	END IF;
	FOR r IN (SELECT tab_sid
				FROM temp_refresh_table
			   WHERE done = 0) LOOP	
		BEGIN
			SecurableObject_pkg.DeleteSO(security_pkg.GetACT(), r.tab_sid);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				-- clean up metadata for missing SOs
				DeleteObject(security_pkg.GetACT(), r.tab_sid);
		END;		
	END LOOP;

	-- shadow check constraints on managed tables
    FOR r IN (SELECT t.tab_sid, ac.owner, ac.constraint_name, ac.search_condition
                FROM all_constraints ac, tab t
               WHERE ac.constraint_type = 'C' AND t.oracle_schema = ac.owner AND 
               		 t.managed = 1 AND 'C$'||t.oracle_table = ac.table_name AND
               		 (in_app_sid IS NULL OR t.app_sid = in_app_sid))  LOOP
        
        SELECT COUNT(*), MIN(acc.column_name), MIN(atc.nullable)
          INTO v_cnt, v_col_name, v_nullable
          FROM all_cons_columns acc, all_tab_columns atc
         WHERE acc.owner = r.owner AND acc.constraint_name = r.constraint_name AND
         	   acc.owner = atc.owner AND acc.table_name = atc.table_name AND
         	   acc.column_name = atc.column_name;

        IF NOT (v_cnt = 1 AND r.search_condition = '"'||v_col_name||'" IS NOT NULL' AND v_nullable = 'N') THEN
            INSERT INTO ck_cons (ck_cons_id, tab_sid, search_condition, constraint_owner, constraint_name)
            VALUES (ck_cons_id_seq.nextval, r.tab_sid, r.search_condition, r.owner, r.constraint_name);
            
            INSERT INTO ck_cons_col (ck_cons_id, column_sid)
                SELECT ck_cons_id_seq.currval, tc.column_sid
                  FROM tab_column tc, all_cons_columns acc
                 WHERE acc.column_name = tc.oracle_column AND tc.tab_sid = r.tab_sid AND
                       acc.owner = r.owner AND acc.constraint_name = r.constraint_name;
        END IF;
    END LOOP;
    
   	-- Reshadow column details on the managed tables
   	-- XXX: Using a loop as can't see a good correlated update statement involving all_tab_columns
   	-- and merge into doesn't work with the some security policy on tab_column
   	FOR r IN (
   		SELECT tc.tab_sid, tc.column_sid, atc.nullable, atc.data_type, atc.data_length,
		       atc.data_precision, atc.data_scale, atc.char_length, atc.default_length,
		       atc.data_default
	   	  FROM tab t, tab_column tc, all_tab_columns atc
	   	 WHERE (in_app_sid IS NULL OR t.app_sid = in_app_sid)
	   	   AND t.managed = 1 
	   	   AND tc.tab_sid = t.tab_sid
	   	   AND atc.owner = t.oracle_schema
	   	   AND atc.table_name = 'C$'||t.oracle_table
	   	   AND atc.column_name = tc.oracle_column
	) LOOP
		v_data_default := SanitiseDataDefault(r.data_default);
		v_default_length := r.default_length;
		
		-- removing a default in oracle doesn't null it out, it comes through as 'null'
		IF v_data_default = 'null' THEN
			v_data_default := NULL;
			v_default_length := NULL;
		END IF;
	
		UPDATE tab_column
		   SET nullable = r.nullable,
			   data_type = r.data_type, 
 			   data_length = r.data_length, 
 			   data_precision = r.data_precision, 
 			   data_scale = r.data_scale, 
 			   char_length = r.char_length,
 			   default_length = v_default_length, 
 			   data_default = v_data_default
		 WHERE tab_sid = r.tab_sid
		   AND column_sid = r.column_sid;
   	END LOOP;
   
	-- Clear any CMS caches
	chain.filter_pkg.ClearCacheForAllUsers (
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_CMS
	);
   
END;

FUNCTION IndexColumnsExist (
	in_oracle_schema				IN  VARCHAR2,
	in_oracle_table					IN  VARCHAR2,
	in_index_columns				IN  VARCHAR2,
	in_managed						IN  NUMBER
) RETURN BOOLEAN
AS
	v_count							NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM (
		SELECT LISTAGG(aic.column_name, ', ') WITHIN GROUP (ORDER BY aic.column_position) index_columns
		  FROM all_ind_columns aic
		  LEFT JOIN all_constraints ac ON aic.index_owner = ac.owner AND aic.index_name = ac.index_name
		 WHERE aic.table_name = in_oracle_table
		   AND aic.table_owner = in_oracle_schema 
		   AND (ac.index_name IS NULL OR in_managed = 0) -- managed tables drop generated constraints, so don't check them
		 GROUP BY aic.index_owner, aic.index_name
	  ) ic
	 WHERE ic.index_columns = in_index_columns;
	 
	RETURN v_count > 0;
END;

PROCEDURE TryCreateIndex (
	in_oracle_schema				IN  VARCHAR2,
	in_table_name					IN  VARCHAR2,
	in_current_table_name			IN  VARCHAR2,
	in_actual_table_name			IN  VARCHAR2,
	in_managed						IN  NUMBER,
	in_index_columns				IN  VARCHAR2,
	in_index_suffix					IN  VARCHAR2,
	io_ddl							IN OUT NOCOPY	t_ddl
)
AS
	v_index_name					VARCHAR2(61);
BEGIN
	IF in_index_columns IS NOT NULL AND NOT IndexColumnsExist(in_oracle_schema, in_current_table_name, in_index_columns, in_managed) THEN
		v_index_name := in_oracle_schema||'.IX_'||UPPER(SUBSTR(in_table_name, 1, 26-LENGTH(in_index_suffix)))||'_'||in_index_suffix;
		
		-- index could exist in the ddl log, and could be incorrect if it was created against an unmanaged table first
		-- so drop the index if it already exists by 
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 'BEGIN EXECUTE IMMEDIATE ''DROP INDEX '||v_index_name||'''; EXCEPTION '||
			'WHEN OTHERS THEN NULL; END;';

		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 
			'CREATE INDEX '||v_index_name||
			' ON '||in_oracle_schema||'.'||in_actual_table_name||' ('||in_index_columns||')';
	END IF;
END;

PROCEDURE CreateDefaultIndexes (
	in_tab_sid						IN				security_pkg.T_SID_ID,
	io_ddl							IN OUT NOCOPY	t_ddl
)
AS
	v_oracle_schema					VARCHAR2(30);
	v_table_name					VARCHAR2(30);
	v_current_table_name			VARCHAR2(30);
	v_actual_table_name				VARCHAR2(30);
	v_reg_pk_col					VARCHAR2(35);
	v_flow_column_sid				security_pkg.T_SID_ID;
	v_pk_column						VARCHAR2(30);
	v_region_columns				VARCHAR2(2000);
	v_securable_fk_columns			VARCHAR2(2000);
	v_flow_index_columns			VARCHAR2(2000);
	v_region_index_columns			VARCHAR2(2000);
	v_managed						NUMBER(1);
BEGIN
	SELECT t.oracle_schema, t.oracle_table, tc.column_sid, t.managed,
		   CASE WHEN t.managed = 1 THEN 'C$'||t.oracle_table ELSE t.oracle_table END 
	  INTO v_oracle_schema, v_table_name, v_flow_column_sid, v_managed, v_actual_table_name
	  FROM tab t
	  LEFT JOIN tab_column tc ON t.app_sid = tc.app_sid AND t.tab_sid = tc.tab_sid AND tc.col_type = CT_FLOW_ITEM AND tc.oracle_column = 'FLOW_ITEM_ID'
	 WHERE t.is_view = 0
	   AND t.tab_sid = in_tab_sid;
	   
	-- Figure out the current table name. The C$ table might not have been created
	-- yet so we need to check existing indexes against whatever table exists.
	BEGIN
		SELECT table_name
		  INTO v_current_table_name
		  FROM all_tables
		 WHERE table_name = 'C$'||v_table_name
		   AND owner = v_oracle_schema;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_current_table_name := v_table_name;
	END;
	
	BEGIN
		SELECT LISTAGG(oracle_column, ', ') WITHIN GROUP (ORDER BY oracle_column) region_columns
		  INTO v_region_columns
		  FROM tab_column tc
		 WHERE col_type = CT_FLOW_REGION
		   AND tab_sid = in_tab_sid
		 GROUP BY tab_sid;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;
	
	BEGIN
		SELECT MIN(tc.oracle_column) pk_column
		  INTO v_pk_column
		  FROM tab t
		  JOIN uk_cons_col ucc ON t.app_sid = ucc.app_sid AND t.pk_cons_id = uk_cons_id
		  JOIN tab_column tc ON ucc.app_sid = tc.app_sid AND ucc.column_sid = tc.column_sid
		 WHERE t.tab_sid = in_tab_sid
		   AND t.managed = 1
		 GROUP BY ucc.uk_cons_id
		HAVING COUNT(*) = 1;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;
	
	BEGIN
		SELECT LISTAGG(tc.oracle_column) WITHIN GROUP (ORDER BY fcc.pos) securable_fk_columns
		  INTO v_securable_fk_columns
		  FROM tab t
		  JOIN fk_cons_col fcc ON t.app_sid = fcc.app_sid AND t.securable_fk_cons_id = fcc.fk_cons_id
		  JOIN tab_column tc ON fcc.app_sid = tc.app_sid AND fcc.column_sid = tc.column_sid
		 WHERE t.tab_sid = in_tab_sid
		   AND t.securable_fk_cons_id IS NOT NULL
		 GROUP BY fcc.fk_cons_id;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;
	
	IF v_flow_column_sid IS NOT NULL THEN
		-- flow index for all cms tables with flow columns
		IF v_pk_column IS NOT NULL AND INSTR(v_region_columns, v_pk_column) = 0 THEN
			v_reg_pk_col := ', '||v_pk_column;
		END IF;
		
		SELECT NVL2(v_region_columns, v_region_columns||v_reg_pk_col, NULL),
		       CASE WHEN v_managed = 1 
					THEN 'FLOW_ITEM_ID'||NVL2(v_region_columns, ', ', '')||v_region_columns||', RETIRED_DTM, VERS, CONTEXT_ID' 
					ELSE 'FLOW_ITEM_ID'||NVL2(v_region_columns, ', ', '')||v_region_columns 
			   END
		  INTO v_region_index_columns, v_flow_index_columns
		  FROM dual;

		TryCreateIndex(v_oracle_schema, v_table_name, v_current_table_name, v_actual_table_name, v_managed, v_flow_index_columns, 'FLOW', io_ddl);
		TryCreateIndex(v_oracle_schema, v_table_name, v_current_table_name, v_actual_table_name, v_managed, v_region_index_columns, 'REG', io_ddl);
	END IF;
	
	IF NOT(v_pk_column = v_region_index_columns) OR v_region_index_columns IS NULL THEN
		TryCreateIndex(v_oracle_schema, v_table_name, v_current_table_name, v_actual_table_name, v_managed, v_pk_column, 'PK', io_ddl);
	END IF;
	
	IF (NOT(v_securable_fk_columns = v_region_index_columns) OR v_region_index_columns IS NULL) AND
	   (NOT(v_securable_fk_columns = v_pk_column) OR v_pk_column IS NULL) THEN
		TryCreateIndex(v_oracle_schema, v_table_name, v_current_table_name, v_actual_table_name, v_managed, v_securable_fk_columns, 'SFK', io_ddl);
	END IF;
END;

PROCEDURE RegisterTable_(
	in_tables_sid				IN				security_pkg.T_SID_ID,
	in_owner					IN				tab.oracle_schema%TYPE,
	in_table_name				IN				tab.oracle_table%TYPE,
	in_managed					IN				BOOLEAN,
	in_is_view					IN				BOOLEAN,
	in_auto_registered			IN				BOOLEAN,
	in_refresh					IN				BOOLEAN,
	io_ddl						IN OUT NOCOPY	t_ddl,
	io_tab_set					IN OUT NOCOPY	t_tab_set
)
AS
	v_sid_id			security_pkg.T_SID_ID;
	v_pk_name			VARCHAR2(30);
	v_c_tab				VARCHAR2(100);
	v_l_tab				VARCHAR2(100);
	v_table_name		VARCHAR2(30) DEFAULT in_table_name;
	v_ctable_name		VARCHAR2(30);
	v_s					CLOB;
	v_cols				CLOB;
    v_col_name 			VARCHAR2(30);
    v_nullable			VARCHAR2(1);
    v_cnt      			NUMBER;	
    v_cnt2				NUMBER;
    v_problem_col_names	VARCHAR2(2000);
	v_managed			tab.managed%TYPE DEFAULT 0;
	v_is_view			tab.is_view%TYPE DEFAULT 0;
	v_registered		BOOLEAN DEFAULT FALSE;
	v_auto_registered	tab.auto_registered%TYPE;
	v_actual_table_name	VARCHAR2(30);
	v_upgrade			BOOLEAN DEFAULT FALSE;
	v_parse_comments	BOOLEAN DEFAULT FALSE;
	v_uk_cons_id		uk_cons.uk_cons_id%TYPE;
	v_fk_cons_id		fk_cons.fk_cons_id%TYPE;
	v_data_default		VARCHAR2(255);
	v_state				CommentParseState;
BEGIN
	--security_pkg.debugmsg('register '||in_owner||'.'||in_table_name);
	-- Catch dodgy calls
	IF in_managed AND in_refresh THEN
		RAISE_APPLICATION_ERROR(-20001, 
			'Cannot refresh the managed table '||in_owner||'.'||in_table_name);
	END IF;
	
	IF in_managed AND in_is_view THEN
		RAISE_APPLICATION_ERROR(-20001, 
			'Cannot register a view as managed: '||in_owner||'.'||in_table_name);
	END IF;
	
	-- XXX: this is an assumption, probably good enough though
	-- it happens when managing a table that a managed table already
	-- has a reference on
	IF SUBSTR(in_table_name, 1, 2) = 'C$' THEN
		v_table_name := SUBSTR(in_table_name, 3);
	END IF;

	-- Check if this table has been versioned already
	IF NOT in_refresh THEN
		BEGIN
			SELECT tab_sid, managed, auto_registered
			  INTO v_sid_id, v_managed, v_auto_registered
			  FROM tab
			 WHERE oracle_schema = in_owner AND oracle_table = v_table_name AND
			 	   app_sid = SYS_CONTEXT('SECURITY', 'APP');

			-- see if this is an upgrade to managed
			v_upgrade := v_managed = 0 AND in_managed;
			
			-- If we are manually registering a previously automatically registered table,
			-- then just flip the flag
			IF NOT v_upgrade THEN
				IF v_auto_registered = 1 AND NOT in_auto_registered THEN
					UPDATE tab
					   SET auto_registered = 0
					 WHERE tab_sid = v_sid_id;
				END IF;
			
				RETURN;
			END IF;
	
			v_registered := TRUE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	
	-- If we are refreshing, then check if this one has already been refreshed,
	-- or if it's managed.
	ELSE
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM temp_refresh_table
		 WHERE oracle_schema = in_owner AND oracle_table = v_table_name AND done = 1;
		IF v_cnt = 1 THEN
			RETURN;
		END IF;
		
		SELECT NVL(SUM(managed), 0)
		  INTO v_cnt
		  FROM tab
		 WHERE oracle_schema = in_owner AND oracle_table = v_table_name AND
		 	   app_sid = SYS_CONTEXT('SECURITY', 'APP');
		IF v_cnt = 1 THEN
			RETURN;
		END IF;
		
		-- mark it as done
		UPDATE temp_refresh_table
		   SET done = 1
		 WHERE oracle_schema = in_owner AND oracle_table = v_table_name;
		IF SQL%ROWCOUNT = 0 THEN
			INSERT INTO temp_refresh_table
				(oracle_schema, oracle_table, done)
			VALUES
				(in_owner, v_table_name, 1);
		END IF;
	END IF;
		
	-- Set the base table name (v_managed = 1 => the table is _currently_ managed)
	IF v_managed = 1 THEN
		v_actual_table_name := 'C$'||v_table_name;
	ELSE
		v_actual_table_name := v_table_name;
	END IF;

	-- Check that we have a primary key (only required for managed tables)
	IF in_managed THEN
		BEGIN
			SELECT constraint_name
			  INTO v_pk_name
			  FROM all_constraints
			 WHERE owner = in_owner AND table_name = v_actual_table_name AND constraint_type = 'P';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The table '||
					in_owner||'.'||v_table_name||' does not have a primary key');
		END;

		-- check that the columns we'll add don't already exist (not as silly as it sounds since CREATED_DTM
		-- is a perfectly likely column to exist!)		
		BEGIN
			SELECT LTRIM(SYS_CONNECT_BY_PATH(column_name, ', '),', ')
			  INTO v_problem_col_names
			  FROM (
				SELECT column_name, rownum rn
				  FROM all_tab_columns
				 WHERE owner = in_owner AND table_name = v_actual_table_name
				   AND column_name IN ('CREATED_DTM','RETIRED_DTM','LOCKED_BY','VERS','CHANGED_BY','CHANGE_DESCRIPTION')
			  )
			  WHERE connect_by_isleaf = 1
			  START WITH rn = 1
			 CONNECT BY PRIOR rn = rn - 1;
			 
			IF v_problem_col_names IS NOT NULL THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The table '||
					in_owner||'.'||v_table_name||' contains one or more reserved column names: '||v_problem_col_names);
			END IF;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL; -- no problems...
		END;
	END IF;

	-- Create the SO and table metadata if it's not already present
	IF NOT v_registered THEN
		v_managed := BoolToNum(in_managed);

		-- If refreshing check if there is already an SO / tab entry
		IF in_refresh THEN
			BEGIN
				SELECT tab_sid
				  INTO v_sid_id
				  FROM temp_refresh_table
				 WHERE oracle_schema = in_owner AND oracle_table = v_table_name;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL; -- ok, it's new
			END;
		END IF;
		
		IF in_is_view THEN
			SELECT COUNT(*)
			  INTO v_cnt
			  FROM all_tab_columns
			 WHERE owner = in_owner
			   AND table_name = v_table_name
			   AND column_name = 'R$RID';
			IF v_cnt = 0 THEN
				RAISE_APPLICATION_ERROR(-20001, 'View does not have a R$RID column: '||in_owner||'.'||v_table_name);
			END IF;
			v_is_view := 1;
		END IF;

		IF v_sid_id IS NULL THEN
			-- Managed tables are always considered to be manually registered (even those that
			-- were grabbed via a cascade to register the children).
			--
			-- This seems to be sensible since they are protected by triggers hooked up to
			-- the table SO, and by default only admins will be able to do anything to the table.
			--
			IF v_managed = 1 THEN
				v_auto_registered := 0;
			ELSE
				v_auto_registered := BoolToNum(in_auto_registered);
			END IF;

			AddTable(
				in_oracle_schema	=> in_owner, 
				in_oracle_table		=> v_table_name,
				in_managed			=> v_managed,
				in_auto_registered	=> v_auto_registered,
				in_parent_sid		=> in_tables_sid,
				in_is_view			=> v_is_view,
				out_tab_sid			=> v_sid_id
			);
		END IF;
		
		-- umm -- stragg belongs in another schema so use this approach instead to avoid an unneeded dependency
		IF v_managed = 1 THEN
			BEGIN
				SELECT LTRIM(SYS_CONNECT_BY_PATH(column_name, ', '),', ')
				  INTO v_problem_col_names
				  FROM (
					SELECT column_name, rownum rn
					  FROM all_tab_columns
					 WHERE owner = in_owner AND table_name = v_actual_table_name
					   AND LENGTH(column_name) > 28 -- to allow for N$ prefixes etc
				  )
				  WHERE connect_by_isleaf = 1
				  START WITH rn = 1
				 CONNECT BY PRIOR rn = rn - 1;
				IF v_problem_col_names IS NOT NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 'The table '||in_owner||'.'||v_table_name||' has column names longer than the maximum size of 28 characters: '||v_problem_col_names);			
				END IF;
	
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL; -- jolly good -- no problems.
			END;
		END IF;

		-- Stuff in columns - do in loop as data_default is a LONG
		FOR r IN (
			SELECT column_name oracle_column, column_id pos, data_type, data_length,
				   data_precision, data_scale, nullable, char_length, default_length, data_default
			  FROM all_tab_columns
			 WHERE owner = in_owner AND table_name = v_actual_table_name
			   AND column_name NOT IN ('R$RID') -- Filter out special columns
			   -- don't re-add columns that we decided not to remove on refresh
			   AND column_name NOT IN (SELECT oracle_column FROM tab_column WHERE tab_sid = v_sid_id)
		) LOOP
			v_data_default := SanitiseDataDefault(r.data_default);
			
			INSERT INTO tab_column (column_sid, tab_sid, oracle_column, pos,
				   data_type, data_length, data_precision, data_scale, nullable, char_length,
				   default_length, data_default)
			VALUES (column_id_seq.NEXTVAL, v_sid_id, r.oracle_column, r.pos,
				   r.data_type, r.data_length, r.data_precision, r.data_scale, r.nullable, r.char_length,
				   r.default_length, v_data_default);
		END LOOP;
		 
		-- Parse table comments -- we do this later so that the keys have been shadowed which is
		-- necessary for handling the issues join table		
		v_parse_comments := TRUE;

	-- If it's an upgrade to managed then note we've done this
	ELSE
		IF in_managed THEN
			UPDATE tab
			   SET managed = 1, auto_registered = 0
			 WHERE tab_sid = v_sid_id;
		END IF;
	END IF;

	IF in_managed THEN
		-- Remember this for view generation
		io_tab_set(v_sid_id) := 1;

		-- Rename the underlying table to the C$ variant
		v_c_tab := q(in_owner) || '.' || q('C$' || v_table_name);
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||q(in_owner)||'.'||q(v_table_name)||' rename to '||q('C$'||v_table_name);
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add context_id number(10) default 0 not null';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add created_dtm timestamp default sys_extract_utc(systimestamp) not null';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add retired_dtm timestamp';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add locked_by number(10)';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add vers number(10) default 1 not null';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add changed_by number(10)';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' add change_description varchar2(2000)';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'update '||v_c_tab||' set changed_by = '||security_pkg.GetSID();
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_c_tab||' modify changed_by not null';
			
		-- Create and populate the lock table
		v_l_tab := q(in_owner)||'.'||q('L$'||v_table_name);
		v_s :=
			'create table '||v_l_tab||' as'||chr(10)||
			'    select ';
		FOR r IN (SELECT column_name
					FROM all_cons_columns
				   WHERE owner = in_owner AND constraint_name = v_pk_name) LOOP
			v_cols := comma(v_cols) || q(r.column_name);
		END LOOP;
		v_s := v_s || v_cols || chr(10) ||
			'      from '||v_c_tab;		
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 
			v_s;
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 
			'alter table '||v_l_tab||' add primary key ('||v_cols||')';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_l_tab||' add locked_by number(10)';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'update '||v_l_tab||' set locked_by = 0';
		io_ddl.extend(1);
		io_ddl(io_ddl.count) :=
			'alter table '||v_l_tab||' modify locked_by not null';		
	END IF;	

	-- Shadow or manage the UKs/PKs on this table
	-- If we are upgrading to managed, they are already shadowed, so we just drop the original keys
	IF NOT v_registered OR v_upgrade THEN
		
		security_pkg.debugmsg('shadowing uks/pks for '||in_owner||'.'||v_actual_table_name);
		if not v_upgrade then
			security_pkg.debugmsg('!upgrade');
		else
			security_pkg.debugmsg('upgrade');
		end if;

		-- Shadow UK/PKs
		FOR r IN (SELECT /*+all_rows*/ constraint_name, constraint_type
					FROM all_constraints
				   WHERE owner = in_owner AND table_name = v_actual_table_name and constraint_type in ('U','P')) LOOP
			security_pkg.debugmsg('shadowing '||r.constraint_name||' ('||r.constraint_type||')');

			IF NOT v_upgrade THEN
				INSERT INTO uk_cons (uk_cons_id, tab_sid, constraint_owner, constraint_name)
				VALUES (uk_cons_id_seq.NEXTVAL, v_sid_id, in_owner, r.constraint_name);
				for rrr in (select uk_cons_id_seq.currval v from dual) loop
 					security_pkg.debugmsg('flibble '||rrr.v);
 				end loop;
		
				INSERT INTO uk_cons_col (uk_cons_id, column_sid, pos)
					SELECT uk_cons_id_seq.CURRVAL, tc.column_sid, acc.position
					  FROM tab_column tc, all_cons_columns acc
					 WHERE acc.owner = in_owner AND acc.constraint_name = r.constraint_name AND
					 	   tc.oracle_column = acc.column_name AND tc.tab_sid = v_sid_id;

				IF r.constraint_type = 'P' THEN
					UPDATE tab
					   SET pk_cons_id = uk_cons_id_seq.CURRVAL
					 WHERE oracle_schema = in_owner AND oracle_table = v_table_name;
				END IF;
			END IF;
			
			IF in_managed THEN
				-- Drop the UK/PK constraint
				io_ddl.extend(1);
				io_ddl(io_ddl.count) :=
					'alter table '||q(in_owner)||'.'||q('C$'||v_table_name)||
					' drop constraint '||q(r.constraint_name)||' cascade';
					
				-- Add a PK constraint on context,pk columns,vers
				-- (We don't do this for UKs as there's nothing to key on)
				IF r.constraint_type = 'P' THEN
					v_s := 'alter table '||v_c_tab||' add primary key (context_id';
					FOR s IN (SELECT /*+all_rows*/ column_name
								FROM all_cons_columns acc
							   WHERE acc.owner = in_owner AND acc.constraint_name = r.constraint_name) LOOP
						v_s := v_s || ',' || q(s.column_name);
					END LOOP;
					v_s := v_s || ',vers)';
					
					io_ddl.extend(1);
					io_ddl(io_ddl.count) := v_s;
				END IF;
			END IF;			
		END LOOP;
			
		-- shadow check constraints
		IF NOT v_upgrade THEN
		    FOR r IN (SELECT ac.owner, ac.constraint_name, ac.search_condition
		                FROM all_constraints ac
		               WHERE ac.constraint_type = 'C' AND ac.owner = in_owner AND
		               		 ac.table_name = v_actual_table_name) LOOP
		        
		        SELECT COUNT(*), MIN(acc.column_name), MIN(atc.nullable)
		          INTO v_cnt, v_col_name, v_nullable
		          FROM all_cons_columns acc, all_tab_columns atc
		         WHERE acc.owner = r.owner AND acc.constraint_name = r.constraint_name AND
		         	   acc.owner = atc.owner AND acc.table_name = atc.table_name AND
		         	   acc.column_name = atc.column_name;
	
		        IF NOT (v_cnt = 1 AND r.search_condition = '"'||v_col_name||'" IS NOT NULL' AND v_nullable = 'N') THEN
		            INSERT INTO ck_cons (ck_cons_id, tab_sid, search_condition, constraint_owner, constraint_name)
		            VALUES (ck_cons_id_seq.nextval, v_sid_id, r.search_condition, r.owner, r.constraint_name);
		            
		            INSERT INTO ck_cons_col (ck_cons_id, column_sid)
		                SELECT ck_cons_id_seq.currval, tc.column_sid
		                  FROM tab_column tc, all_cons_columns acc
		                 WHERE acc.column_name = tc.oracle_column AND tc.tab_sid = v_sid_id AND
		                       acc.owner = r.owner AND acc.constraint_name = r.constraint_name;
		        END IF;
		    END LOOP;
		END IF;
	END IF;

	-- Register child tables
	FOR r IN (SELECT cac.owner, cac.table_name
			    FROM all_constraints cac, all_constraints pap
			   WHERE pap.owner = in_owner AND pap.table_name = v_actual_table_name AND
			   		 cac.constraint_type = 'R' AND cac.r_owner = in_owner AND 
			   		 cac.r_owner = pap.owner AND cac.r_constraint_name = pap.constraint_name AND
			   		 (cac.owner IN (SELECT oracle_schema FROM app_schema WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')) OR
			   		  (cac.owner, cac.table_name) IN (SELECT oracle_schema, oracle_table FROM app_schema_table WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')))
			GROUP BY cac.owner, cac.table_name) LOOP
		--security_pkg.debugmsg('from: '||in_owner||'.'||v_actual_table_name||', registering child table '||r.owner||'.'||r.table_name);
		RegisterTable_(in_tables_sid, r.owner, r.table_name, in_managed, FALSE, TRUE, in_refresh, io_ddl, io_tab_set);
	END LOOP;

	-- Shadow FKs from child tables
	-- If we are upgrading to managed, they are already shadowed, so we just drop the original keys
	IF NOT v_registered OR v_upgrade THEN
		
		--security_pkg.debugmsg('shadowing fks for '||in_owner||'.'||v_actual_table_name);

		-- Shadow UK/PKs
		FOR r IN (SELECT /*+all_rows*/ owner, constraint_name, constraint_type
					FROM all_constraints
				   WHERE owner = in_owner AND table_name = v_actual_table_name and constraint_type in ('U','P')) LOOP

			-- # of columns in actual constraint				   	
			SELECT COUNT(*)
			  INTO v_cnt
	   	      FROM all_cons_columns acc
	   	     WHERE acc.owner = r.owner AND acc.constraint_name = r.constraint_name;

			-- find the UK constraint that matches	   
			BEGIN
				SELECT uk_cons_id
				  INTO v_uk_cons_id
				  FROM (SELECT suk.uk_cons_id, COUNT(*) cnt
						  FROM cms.uk suk, all_cons_columns uk, all_constraints u
						 WHERE suk.owner = uk.owner AND suk.table_name = uk.table_name
						   AND suk.column_name = uk.column_name AND suk.pos = uk.position
						   AND u.owner = uk.owner AND u.constraint_name = uk.constraint_name
						   AND u.owner = r.owner AND u.constraint_name = r.constraint_name
						   AND (SELECT COUNT(*) 
						   		  FROM uk_cons_col sukcc
						   		 WHERE sukcc.app_sid = suk.app_sid AND sukcc.uk_cons_id = suk.uk_cons_id) = v_cnt				   
						 GROUP BY suk.uk_cons_id)
				  WHERE cnt = v_cnt;
			EXCEPTION
				WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
					-- (this is just for debugging, it can go eventually)					
					security_pkg.debugmsg('owner: '||r.owner||', constraint name: '||r.constraint_name||', constraint type:'||r.constraint_type);
					FOR qr IN (SELECT * FROM cms.uk WHERE owner = r.owner AND table_name = v_actual_table_name order by uk_cons_id, pos) LOOP
						security_pkg.debugmsg(qr.uk_cons_id||','||qr.uk_tab_sid||','||qr.owner||','||qr.table_name||','||qr.column_name||','||qr.pos);
					END LOOP;
					RAISE;
			END;
			
	
			-- Shadow FKs for child tables
			FOR s IN (SELECT /*+all_rows*/ ac.owner, ac.constraint_name, ac.table_name, ac.delete_rule
		  			    FROM all_constraints ac
		 			   WHERE ac.r_owner = in_owner AND ac.r_constraint_name = r.constraint_name AND
		       				 ac.constraint_type = 'R' AND 
					   		 (ac.owner IN (SELECT oracle_schema FROM app_schema WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')) OR
					   		  (ac.owner, ac.table_name) IN (SELECT oracle_schema, oracle_table FROM app_schema_table WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')))) LOOP
				--security_pkg.debugmsg('shadowing '||s.owner||'.'||s.constraint_name||', '||s.table_name);

				-- TODO: check this assumption?
				IF SUBSTR(s.table_name, 1, 2) = 'C$' THEN
					v_ctable_name := SUBSTR(s.table_name, 3);
				ELSE
					v_ctable_name := s.table_name;
				END IF;
		
				IF NOT v_upgrade THEN
					-- check that the constraint doesn't already exist
					--security_pkg.debugmsg('matching up on '||s.owner||'.'||v_ctable_name||'.'||s.constraint_name);
					
					SELECT MIN(fk_cons_id)
					  INTO v_fk_cons_id
					  FROM (SELECT COUNT(*) ora_cnt, COUNT(fuk.fk_cons_id) fk_cnt, MIN(fuk.fk_cons_id) fk_cons_id
							  FROM all_constraints u 
							  JOIN all_cons_columns uk ON u.owner = uk.owner AND u.constraint_name = uk.constraint_name
							  LEFT JOIN cms.fk fuk ON fuk.owner = uk.owner AND fuk.table_name = v_ctable_name AND fuk.column_name = uk.column_name AND fuk.pos = uk.position
							  WHERE u.owner = s.owner
								AND u.constraint_name = s.constraint_name			   
							  GROUP BY u.owner, u.constraint_name)
					 WHERE fk_cnt = ora_cnt;
					
					   
					IF v_fk_cons_id IS NULL THEN
						INSERT INTO fk_cons (fk_cons_id, tab_sid, r_cons_id, delete_rule, constraint_owner, constraint_name)
							SELECT fk_cons_id_seq.NEXTVAL, tab_sid, v_uk_cons_id,
								   DECODE(s.delete_rule, 'CASCADE', 'C', 'SET NULL', 'N', 'R'), s.owner, s.constraint_name
							  FROM tab
							 WHERE oracle_schema = s.owner AND oracle_table = v_ctable_name AND
							 	   app_sid = SYS_CONTEXT('SECURITY', 'APP');
							 
						INSERT INTO fk_cons_col (fk_cons_id, column_sid, pos)
							SELECT fk_cons_id_seq.CURRVAL, tc.column_sid, acc.position
							  FROM tab_column tc, tab t, all_cons_columns acc
							 WHERE acc.owner = s.owner AND t.oracle_schema = s.owner AND t.oracle_schema = acc.owner AND
							 	   t.oracle_table = v_ctable_name AND acc.constraint_name = s.constraint_name AND 
							 	   t.tab_sid = tc.tab_sid AND acc.column_name = tc.oracle_column AND
							 	   t.app_sid = SYS_CONTEXT('SECURITY', 'APP');
						select fk_cons_id_seq.CURRVAL into v_cnt from dual;
						--security_pkg.debugmsg('didn''t match so added fk with id '||v_cnt);
							 	   
					/*ELSE
						security_pkg.debugmsg(' constraint already exists with id ' || v_fk_cons_id);*/
					END IF;
				END IF;
					
				IF in_managed THEN
					-- Drop the FK constraint
					io_ddl.extend(1);
					io_ddl(io_ddl.count) :=
						'begin'||chr(10)||
						'    for r in (select constraint_name from all_constraints where owner = '||sq(in_owner)||' and constraint_name = '||sq(v_table_name)||') loop'||chr(10)||
						'        execute immediate ''alter table '||replace(q(in_owner),'''','''''')||'.'||replace(q('C$'||v_table_name),'''','''''')||' drop constraint ''||r.constraint_name;'||chr(10)||
						'    end loop;'||chr(10)||
						'end;';
				END IF;
			END LOOP;
			
		END LOOP;
		
	END IF;

	-- Register parent tables unmanaged.  This is done to simplify
	-- the handling of e.g. foreign key pickers on user tables or similar things.
	-- Exclude tables created by MakeFormIndicators (prefixed with R$)
	FOR r IN (SELECT pap.owner, pap.table_name
				FROM all_constraints pap, all_constraints cac
			   WHERE cac.owner = in_owner AND cac.table_name = v_actual_table_name AND
			   		 cac.constraint_type = 'R' AND cac.r_owner = pap.owner AND
			   		 cac.r_constraint_name = pap.constraint_name AND
			   		 pap.table_name NOT LIKE 'R$%' AND
			   		 (pap.owner IN (SELECT oracle_schema FROM app_schema WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')) OR
			   		  (pap.owner, pap.table_name) IN (SELECT oracle_schema, oracle_table FROM app_schema_table WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')))
			GROUP BY pap.owner, pap.table_name) LOOP
		--security_pkg.debugmsg('from: '||in_owner||'.'||v_actual_table_name||', registering parent table '||r.owner||'.'||r.table_name);		
		RegisterTable_(in_tables_sid, r.owner, r.table_name, FALSE, FALSE, TRUE, in_refresh, io_ddl, io_tab_set);
	END LOOP;

	-- Add FKs to parent tables that are unmanaged and already registered
	FOR r IN (SELECT pap.owner, pap.table_name, t.tab_sid, t.managed
				FROM all_constraints pap, all_constraints cac, tab t
			   WHERE t.oracle_schema = pap.owner AND t.oracle_table = pap.table_name AND t.managed = 0 AND
			   	     cac.owner = in_owner AND cac.table_name = v_actual_table_name AND
			   		 cac.constraint_type = 'R' AND cac.r_owner = pap.owner AND
			   		 cac.r_constraint_name = pap.constraint_name AND
			   		 (pap.owner IN (SELECT oracle_schema FROM app_schema WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')) OR
			   		  (pap.owner, pap.table_name) IN (SELECT oracle_schema, oracle_table FROM app_schema_table WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')))
			GROUP BY pap.owner, pap.table_name, t.tab_sid, t.managed) LOOP
		--security_pkg.debugmsg('from: '||in_owner||'.'||v_actual_table_name||', finding RI for parent table '||r.owner||'.'||r.table_name);
		
		FOR s IN (SELECT pap.owner, pap.table_name, pap.constraint_name, 
				 		 cac.owner child_owner, cac.delete_rule child_delete_rule, cac.constraint_name child_constraint_name
					FROM all_constraints pap, all_constraints cac
				   WHERE cac.owner = in_owner AND cac.table_name = v_actual_table_name AND
				   		 cac.constraint_type = 'R' AND cac.r_owner = pap.owner AND
				   		 cac.r_constraint_name = pap.constraint_name AND
				   		 pap.owner = r.owner AND pap.table_name = r.table_name) LOOP
			
			--security_pkg.debugmsg('adding R constraint from '||in_owner||'.'||v_actual_table_name||'.'||s.child_constraint_name||
			--	' to existing unmanaged table constraint '||s.owner||'.'||s.table_name||'.'||s.constraint_name);

			-- # of columns in actual constraint				   	
			SELECT COUNT(*)
			  INTO v_cnt
	   	      FROM all_cons_columns acc
	   	     WHERE acc.owner = s.owner AND acc.constraint_name = s.constraint_name;

			-- now we need to find the shadowed PK/UK corresponding to this constraint
			BEGIN
				SELECT uk_cons_id
				  INTO v_uk_cons_id
				  FROM (SELECT suk.uk_cons_id, COUNT(*) cnt
						  FROM cms.uk suk, all_cons_columns uk, all_constraints u
						 WHERE suk.owner = uk.owner AND suk.table_name = uk.table_name
						   AND suk.column_name = uk.column_name AND suk.pos = uk.position
						   AND u.owner = uk.owner AND u.constraint_name = uk.constraint_name
						   AND u.owner = s.owner AND u.constraint_name = s.constraint_name
						   AND (SELECT COUNT(*) 
						   		  FROM uk_cons_col sukcc
						   		 WHERE sukcc.app_sid = suk.app_sid AND sukcc.uk_cons_id = suk.uk_cons_id) = v_cnt				   
						 GROUP BY suk.uk_cons_id)
				  WHERE cnt = v_cnt;

			EXCEPTION
				WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
					-- (this is just for debugging, it can go eventually)
					declare 
						v_num number;
					begin
						select count(*) into v_num from uk_cons where tab_sid=r.tab_sid;
						security_pkg.debugmsg('parent sid is '||r.tab_sid||', uks='||v_num);
					end;
					FOR qr IN (SELECT * FROM cms.uk WHERE owner = s.owner AND table_name = s.table_name) LOOP
						security_pkg.debugmsg(qr.uk_cons_id||','||qr.uk_tab_sid||','||qr.owner||','||qr.table_name||','||qr.column_name||','||qr.pos);
					END LOOP;
					RAISE;
			END;
			--security_pkg.debugmsg('matched constraint to shadow uk constraint '||v_uk_cons_id);
			
			-- check that the constraint doesn't already exist
			--security_pkg.debugmsg('matching up on '||s.owner||'.'||v_actual_table_name||'.'||s.child_constraint_name);
			
			/*for qx in ( 
				SELECT owner, constraint_name, fk_cons_id
				  FROM (
					SELECT u.owner, u.constraint_name, count(*) ora_cnt, count(fuk.fk_cons_id) fk_cnt, MIN(fuk.fk_cons_id) fk_cons_id
					  FROM all_constraints u 
						JOIN all_cons_columns uk ON u.owner = uk.owner AND u.constraint_name = uk.constraint_name
						LEFT JOIN cms.fk fuk ON fuk.owner = uk.owner AND fuk.table_name = v_actual_table_name AND fuk.column_name = uk.column_name AND fuk.pos = uk.position
					  WHERE u.owner = s.child_owner
						AND u.constraint_name = s.child_constraint_name
					GROUP BY u.owner, u.constraint_name
				 )
				 WHERE fk_cnt = ora_cnt) loop
				security_pkg.debugmsg('match '||qx.owner||'.'||qx.constraint_name||' to '||qx.fk_cons_id);
			end loop;*/
			
			-- we have to check that the columns match AND the number of columns match too
			SELECT MIN(fk_cons_id)
			  INTO v_fk_cons_id
			  FROM (SELECT COUNT(*) ora_cnt, COUNT(fuk.fk_cons_id) fk_cnt, MIN(fuk.fk_cons_id) fk_cons_id
					  FROM all_constraints u 
					  JOIN all_cons_columns uk ON u.owner = uk.owner AND u.constraint_name = uk.constraint_name
					  LEFT JOIN cms.fk fuk ON fuk.owner = uk.owner AND fuk.table_name = v_actual_table_name AND fuk.column_name = uk.column_name AND fuk.pos = uk.position
					  WHERE u.owner = s.child_owner
						AND u.constraint_name = s.child_constraint_name			   
					  GROUP BY u.owner, u.constraint_name)
			 WHERE fk_cnt = ora_cnt;
			/*
			   for qr in (
					select fkcc.fk_cons_id,fkcc.column_sid 
					  from fk_cons_col fkcc,fk_cons fkc 
					 where fkc.tab_sid = v_sid_id 
						and fkc.fk_cons_id=fkcc.fk_cons_id 
					  order by fkcc.fk_cons_id, fkcc.pos
			   ) 
			   loop
					security_pkg.debugmsG('fk '||qr.fk_cons_id||', col_sid = '||qr.column_sid);
			   end loop;*/
			   
			IF v_fk_cons_id IS NULL THEN
--			IF v_cnt2 != v_cnt THEN -- not the same constraint or missing
				INSERT INTO fk_cons (fk_cons_id, tab_sid, r_cons_id, delete_rule, constraint_owner, constraint_name)
					SELECT fk_cons_id_seq.NEXTVAL, v_sid_id, v_uk_cons_id,
						   DECODE(s.child_delete_rule, 'CASCADE', 'C', 'SET NULL', 'N', 'R'),
						   s.child_owner, s.child_constraint_name
					  FROM dual;
	
				INSERT INTO fk_cons_col (fk_cons_id, column_sid, pos)
					SELECT fk_cons_id_seq.CURRVAL, tc.column_sid, acc.position
					  FROM tab_column tc, tab t, all_cons_columns acc
					 WHERE acc.owner = s.child_owner AND t.oracle_schema = s.child_owner AND t.oracle_schema = acc.owner AND
					 	   t.oracle_table = v_actual_table_name AND acc.constraint_name = s.child_constraint_name AND 
					 	   t.tab_sid = tc.tab_sid AND acc.column_name = tc.oracle_column AND
					 	   t.app_sid = SYS_CONTEXT('SECURITY', 'APP');
				
				/*
				select fk_cons_id_seq.CURRVAL into v_cnt from dual;
				security_pkg.debugmsg('didn''t match so added fk with id '||v_cnt);
			ELSE
				security_pkg.debugmsg('existing fk is '||v_fk_cons_id);*/
			END IF;
		END LOOP;
	END LOOP;
	
	IF v_parse_comments THEN
		-- note that we get 0 or 1 rows from the query below
		FOR r IN (SELECT comments
					FROM all_tab_comments
				   WHERE owner = in_owner AND table_name = v_actual_table_name AND comments IS NOT NULL) LOOP
			ParseTableComments(v_sid_id, r.comments, io_ddl);
		END LOOP;
		
		-- reparse child table comments (they may rely on FKs that have just been created)
		FOR r IN (SELECT fk.fk_tab_sid, atc.comments
					FROM all_tab_comments atc
					JOIN fk fk ON atc.owner = fk.owner AND atc.table_name = fk.table_name
				   WHERE atc.comments IS NOT NULL AND fk.r_tab_sid = v_sid_id
				   GROUP BY fk.fk_tab_sid, atc.comments) LOOP
			v_state.pos := 1;
			v_state.text := r.comments;
			WHILE ParseComments(v_state) LOOP
				CASE
					WHEN v_state.name = 'securable_fk' THEN
						ParseSecurableFkComment(r.fk_tab_sid, v_state.value);
				ELSE
					NULL;
				END CASE;
			END LOOP;
		END LOOP;
		
		-- Parse metadata in column descriptions, if any
		FOR r IN (SELECT tc.column_sid, acc.comments
					FROM all_col_comments acc, tab_column tc
				   WHERE tc.tab_sid = v_sid_id AND acc.owner = in_owner AND
			   			 acc.table_name = v_actual_table_name AND acc.column_name = tc.oracle_column AND 
			   			 acc.comments IS NOT NULL) LOOP
			ParseColumnComments(v_sid_id, r.column_sid, r.comments, io_ddl);
		END LOOP;
		
		-- clean up indexes
		DropUnusedFullTextIndexes(v_sid_id, io_ddl);
	END IF;		
	
	IF NOT in_is_view THEN
		CreateDefaultIndexes(v_sid_id, io_ddl);
	END IF;
	
	-- turn off charting on numbers by default
	-- when registering a new table
	UPDATE tab_column
	   SET show_in_breakdown = 0
	 WHERE col_type = CT_NORMAL
	   AND data_type = 'NUMBER';
END;

PROCEDURE UnregisterTable_(
	in_tab_sid					IN				tab.tab_sid%TYPE,
	in_owner					IN				tab.oracle_schema%TYPE,
	in_table_name				IN				tab.oracle_table%TYPE,
	io_ddl						IN OUT NOCOPY	t_ddl
)
AS
	v_first			BOOLEAN;
	v_a				VARCHAR2(4000);
	v_b				VARCHAR2(4000);
	v_child_name	VARCHAR2(60);
BEGIN
	-- drop all the stuff that was created
	-- views
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'drop view ' || q(in_owner) || '.' || q('H$' || in_table_name);
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'drop view ' || q(in_owner) || '.' || q(in_table_name);
	-- lock table
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'drop table ' || q(in_owner) || '.' || q('L$' || in_table_name);
	-- triggers	(only triggers on the table; triggers on the view are dropped with the view)
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'drop trigger '||q(in_owner)||'.'||q('J$'||in_table_name);
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'drop trigger '||q(in_owner)||'.'||q('V$'||in_table_name);
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'drop trigger '||q(in_owner)||'.'||q('E$'||in_table_name);

	-- package wrapper
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'drop package ' || q(in_owner) || '.' || q('T$' || in_table_name);
	
	-- rename the table back to the base name
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q('C$' || in_table_name) || 
		' rename to ' || q(in_table_name);
	-- drop the pk
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) || 
		' drop primary key';
	-- delete any retired or unpublished data
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 
		'DELETE FROM ' || q(in_owner) || '.' || q(in_table_name) || chr(10) ||
		 'where retired_dtm is not null or context_id <> 0';
		
	-- drop the extra columns we added
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) || 
		' drop column context_id';
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) || 
		' drop column created_dtm';
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) ||
		' drop column retired_dtm';
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) ||
		' drop column locked_by';
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) ||
		' drop column vers';
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) ||
		' drop column changed_by';
	io_ddl.extend(1);
	io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) ||
		' drop column change_description';

	-- reinstate the unique constraints
	FOR r IN (SELECT ukc.uk_cons_id, 
					 CASE WHEN t.pk_cons_id = ukc.uk_cons_id THEN 1 ELSE 0 END is_pk
				FROM uk_cons ukc, tab t
			   WHERE t.tab_sid = in_tab_sid AND ukc.tab_sid = in_tab_sid AND
			   		 t.tab_sid = ukc.tab_sid) LOOP
	
		io_ddl.extend(1);
		io_ddl(io_ddl.count) := 'alter table ' || q(in_owner) || '.' || q(in_table_name) ||
			' add ';
		IF r.is_pk = 1 THEN
			io_ddl(io_ddl.count) := io_ddl(io_ddl.count) || 'primary key (';
		ELSE
			io_ddl(io_ddl.count) := io_ddl(io_ddl.count) || 'unique (';
		END IF;
		
		v_first := TRUE;
		FOR s IN (SELECT tc.oracle_column
					FROM uk_cons_col ukcc, tab_column tc
				   WHERE ukcc.uk_cons_id = r.uk_cons_id AND ukcc.column_sid = tc.column_sid
				ORDER BY ukcc.pos) LOOP
			IF NOT v_first THEN
				io_ddl(io_ddl.count) := io_ddl(io_ddl.count) || ',';
			END IF;
			v_first := FALSE;
			io_ddl(io_ddl.count) := io_ddl(io_ddl.count) || q(s.oracle_column);
		END LOOP;
		io_ddl(io_ddl.count) := io_ddl(io_ddl.count) || ')';
		
		-- reinstate any child FKs of the UK under consideration
		FOR fk IN (SELECT fkc.fk_cons_id, fkt.oracle_schema owner, fkt.oracle_table table_name, fkt.managed
					 FROM fk_cons fkc, tab fkt
				    WHERE fkc.r_cons_id = r.uk_cons_id AND fkc.tab_sid = fkt.tab_sid) LOOP
			v_a := NULL;
			v_b := NULL;

			FOR fkc IN (SELECT fktc.oracle_column column_name, uktc.oracle_column r_column_name
						  FROM fk_cons_col fkcc, tab_column fktc, uk_cons_col ukcc, tab_column uktc
					     WHERE fkcc.fk_cons_id = fk.fk_cons_id AND fkcc.column_sid = fktc.column_sid AND
					   		   ukcc.uk_cons_id = r.uk_cons_id AND ukcc.column_sid = uktc.column_sid AND
					   		   ukcc.pos = fkcc.pos
					  ORDER BY ukcc.pos) LOOP
				IF v_a IS NOT NULL THEN
					v_a := v_a || ',';
					v_b := v_b || ',';
				END IF;
				v_a := v_a || q(fkc.column_name);
				v_b := v_b || q(fkc.r_column_name);
			END LOOP;
			
			IF fk.managed = 1 THEN
				v_child_name := q('C$' || fk.table_name);
			ELSE
				v_child_name := fk.table_name;
			END IF;
			io_ddl.extend(1);
			io_ddl(io_ddl.count) := 'alter table ' || q(fk.owner) || '.' || v_child_name ||
				' add foreign key (' || v_a || ') references ' || q(in_owner) || '.' || q(in_table_name) ||
				' (' || v_b || ')';
		END LOOP;
	END LOOP;
	
	-- stuff this table in a list so we don't try and unregister it twice
	INSERT INTO temp_refresh_table (tab_sid)
	VALUES (in_tab_sid);

	-- unregister any managed parent tables
	FOR r IN (SELECT ukt.tab_sid, ukt.oracle_schema, ukt.oracle_table
				FROM fk_cons fkc, uk_cons ukc, tab ukt
			   WHERE fkc.tab_sid = in_tab_sid AND fkc.r_cons_id = ukc.uk_cons_id AND
			   		 ukc.tab_sid = ukt.tab_sid AND ukt.managed = 1 AND
			   		 ukt.tab_sid NOT IN (SELECT tab_sid FROM temp_refresh_table)
			GROUP BY ukt.tab_sid, ukt.oracle_schema, ukt.oracle_table) LOOP		
		UnregisterTable_(r.tab_sid, r.oracle_schema, r.oracle_table, io_ddl);
	END LOOP;
	
	-- Delete the SO
	securableObject_pkg.DeleteSO(security_pkg.GetACT(), in_tab_sid);
END;

PROCEDURE UnregisterTable(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE
)
AS
	v_managed		tab.managed%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
	v_owner			tab.oracle_schema%TYPE;
	v_table_name	tab.oracle_table%TYPE;
	v_cms_sid		security_pkg.T_SID_ID;
	v_ddl 			t_ddl DEFAULT t_ddl();
BEGIN
	-- Get the CMS container
	v_cms_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms');
	
	-- Get the table object
	BEGIN
		SELECT tab_sid, managed, oracle_schema, oracle_table
		  INTO v_tab_sid, v_managed, v_owner, v_table_name
		  FROM tab
		 WHERE oracle_schema = dq(in_oracle_schema) AND oracle_table = dq(in_oracle_table) AND
		 	   app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
				'The table '||in_oracle_schema||'.'||in_oracle_table||' could not be found');
	END;
	
	-- TODO: probably want some stronger permission for altering the schema
	-- also might want to check the parent tables
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), v_tab_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Access denied unregistering the table '||in_oracle_schema||'.'||in_oracle_table||' with sid '||v_tab_sid);
	END IF;
	
	-- If it's managed, then we need to recurse to unregister the parent tables too
	IF v_managed = 1 THEN
		DELETE FROM temp_refresh_table;
		UnregisterTable_(v_tab_sid, v_owner, v_table_name, v_ddl);
		ExecuteDDL(v_ddl);
		
	-- Otherwise just drop the table SO
	ELSE
		-- Delete the SO
		securableobject_pkg.DeleteSO(security_pkg.GetACT(), v_tab_sid);
	END IF;
END;
	
PROCEDURE RegisterTable(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	VARCHAR2,
	in_managed					IN	BOOLEAN DEFAULT TRUE,
	in_allow_entire_schema		IN	BOOLEAN DEFAULT TRUE
)
AS
	v_act_id		security.security_pkg.T_ACT_ID;
	v_app_sid		security.security_pkg.T_SID_ID;
	v_ddl 			t_ddl DEFAULT t_ddl();
	v_tab_set		t_tab_set;
	v_owner			VARCHAR2(30);
	v_table_names	t_string_list;
	v_table_name	tab.oracle_table%TYPE;
	v_sid_id		security_pkg.T_SID_ID;
	v_cms_sid		security_pkg.T_SID_ID;
	v_managed		tab.managed%TYPE;
	v_is_view		tab.is_view%TYPE := 0;
	v_admins_sid	security.security_pkg.T_SID_ID;
BEGIN
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');

	-- Get or create the cms container
	BEGIN
		v_cms_sid := SecurableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'cms');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security.class_pkg.GetClassId('CmsContainer'), 'cms', v_cms_sid);
			
			v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators');
			
			-- Don't automatically inherit from app
			security.securableobject_pkg.ClearFlag(v_act_id, v_cms_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
  
			-- Remove inherited ACEs
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_cms_sid), security.security_pkg.SID_BUILTIN_EVERYONE);
			security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_cms_sid), v_admins_sid);
  
			-- Set some default permissions for the administrators group
			security.acl_pkg.AddACE(
				in_act_id			=> v_act_id,
				in_acl_id			=>  security.acl_pkg.GetDACLIDForSID(v_cms_sid),
				in_acl_index		=> -1,
				in_ace_type			=>  security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags		=>  security.security_pkg.ACE_FLAG_DEFAULT,
				in_sid_id			=>  v_admins_sid,
				in_permission_set	=>  cms.tab_pkg.PERMISSION_STD_ALL_EXPORT -- Standard WRITE + EXPORT + BULK EXPORT
			);

			security.acl_pkg.PropogateACEs(v_act_id, v_cms_sid);
	END;
	
	-- Treat the table name as a quoted list so we can do less typing
	ParseQuotedList(in_oracle_table, v_table_names);

	FOR i IN 1 .. v_table_names.COUNT LOOP
		v_table_name := v_table_names(i);
		IF LENGTH(v_table_name) > 28 THEN
			RAISE_APPLICATION_ERROR(-20001,
				'The table name '||v_table_name||' is too long -- it can be at most 28 characters');
		END IF;

		-- Check if the table is already registered
		BEGIN
			SELECT managed, oracle_schema, oracle_table, is_view
			  INTO v_managed, v_owner, v_table_name, v_is_view
			  FROM tab
			 WHERE oracle_schema = dq(in_oracle_schema) AND oracle_table = dq(v_table_name) AND
				   app_sid = SYS_CONTEXT('SECURITY', 'APP');

			-- It's already registered, is this a request to unmanage the table?
			IF NOT in_managed AND v_managed = 1 THEN
				RAISE_APPLICATION_ERROR(-20001, 'Cannot make the table '||in_oracle_schema||'.'||v_table_name||' unmanaged');
			END IF;
	
			-- RegisterTable_ can now do the business...
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- Normalise the owner/table name
				Normalise(in_oracle_schema, v_table_name, v_owner, v_table_name, v_is_view);
		END;
		
		IF in_managed AND v_is_view = 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot make the view '||in_oracle_schema||'.'||v_table_name||' managed');
		END IF;
	
		-- Add the schema or table to the application
		BEGIN
			IF in_allow_entire_schema THEN
				INSERT INTO app_schema
					(app_sid, oracle_schema)
				VALUES
					(SYS_CONTEXT('SECURITY', 'APP'), v_owner);
			ELSE
				INSERT INTO app_schema_table
					(app_sid, oracle_schema, oracle_table)
				VALUES
					(SYS_CONTEXT('SECURITY', 'APP'), v_owner, v_table_name);
			END IF;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

		RegisterTable_(v_cms_sid, v_owner, v_table_name, in_managed, v_is_view = 1, FALSE, FALSE, v_ddl, v_tab_set);
		v_sid_id := v_tab_set.first;
		WHILE v_sid_id IS NOT NULL
		LOOP	
			CreateView(v_sid_id, v_ddl);
			v_sid_id := v_tab_set.next(v_sid_id);
		END LOOP;
		CreateItemDescriptionView(SYS_CONTEXT('SECURITY', 'APP'), v_ddl);
	
		v_sid_id := v_tab_set.first;
		WHILE v_sid_id IS NOT NULL
		LOOP	
			CreateTriggers(v_sid_id, v_ddl);
			v_sid_id := v_tab_set.next(v_sid_id);
		END LOOP;
	END LOOP;
	
	ExecuteDDL(v_ddl);
	
	-- Clear any CMS caches
	chain.filter_pkg.ClearCacheForAllUsers (
		in_card_group_id => chain.filter_pkg.FILTER_TYPE_CMS
	);
END;

PROCEDURE AllowTable(
	in_oracle_schema			IN	app_schema_table.oracle_schema%TYPE,
	in_oracle_table				IN	app_schema_table.oracle_table%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO app_schema_table (app_sid, oracle_schema, oracle_table)
		VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_oracle_schema, in_oracle_table);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

-- TODO: nullable, default
PROCEDURE AddColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_type						IN	VARCHAR2,
	in_comment					IN	VARCHAR2 DEFAULT NULL,
	in_pos						IN	tab_column.pos%TYPE DEFAULT 0,
	in_calc_xml					IN	tab_column.calc_xml%TYPE DEFAULT NULL
)
AS
	v_ddl			t_ddl DEFAULT t_ddl();
	v_count			NUMBER;
	v_max_pos		tab_column.pos%TYPE;
	v_pos			tab_column.pos%TYPE DEFAULT in_pos;
	v_type			VARCHAR2(100) DEFAULT in_type;
	v_db_type		VARCHAR2(100) DEFAULT in_type;
	v_i				BINARY_INTEGER;
	v_j				BINARY_INTEGER;
	v_k				BINARY_INTEGER;
	v_prec			BINARY_INTEGER;
	v_scale			BINARY_INTEGER;
	v_tab_sid		tab.tab_sid%TYPE;
	v_column_sid	tab_column.column_sid%TYPE;
	v_data_length	NUMBER;
	v_char_length	NUMBER;
BEGIN
	GetTableForDDL(in_oracle_schema, in_oracle_table, TRUE, v_tab_sid);
	
	IF LENGTH(in_oracle_column) > 28 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The column name '||in_oracle_column||' is too long -- it can be at most 28 characters'); -- to allow for N$ prefixes etc
	END IF;
	   
	-- Check for a duplicate name (TODO: ought to be a constraint...)
	SELECT COUNT(*)
	  INTO v_count
	  FROM tab_column
	 WHERE oracle_column = dq(in_oracle_column)
	   AND tab_sid = v_tab_sid;
	IF v_count <> 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 
			'The table '||in_oracle_schema||'.'||in_oracle_table||' already has a column named '||in_oracle_column);
	END IF;
	
	-- If pos is out of range, then fix it up
	SELECT MAX(pos)
	  INTO v_max_pos
	  FROM tab_column
	 WHERE tab_sid = v_tab_sid;
	IF v_pos < 1 OR v_pos > v_max_pos THEN
		v_pos := v_max_pos + 1;
	END IF;
	
	-- parse type, prec '()'
	v_i := INSTR(in_type, '(');
	IF v_i <> 0 THEN
		v_j := INSTR(in_type, ')', v_i);
		IF v_j <= v_i + 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Invalid type '||in_type);
		END IF;
		v_type := SUBSTR(in_type, v_i + 1, v_j - v_i - 1);
		v_k := INSTR(v_type, ',');
		IF v_k <> 0 THEN
			v_prec := TO_NUMBER(SUBSTR(v_type, 1, v_k - 1));
			v_scale := TO_NUMBER(SUBSTR(v_type, v_k + 1));
			IF v_prec IS NULL OR v_scale IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Invalid type '||in_type);
			END IF;
		ELSE
			v_prec := TO_NUMBER(v_type);
			IF v_prec IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Invalid type '||in_type);
			END IF;
		END IF;
		v_type := SUBSTR(in_type, 1, v_i - 1);
	END IF;
	v_type := LOWER(v_type);
	v_db_type := v_type;
	IF v_type NOT IN ('varchar2','clob','blob','number','int','binary_double','date') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unsupported datatype '||in_type);
	END IF;
	IF v_type = 'varchar2' THEN
		IF v_scale IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'varchar2 may not have a scale ('||in_type||')');
		END IF;
		IF v_prec < 1 OR v_prec > 4000 THEN
			RAISE_APPLICATION_ERROR(-20001, 'varchar2 may have at minimum 1 and at most 4,000 characters ('||in_type||')');
		END IF;
		v_db_type := v_type || '('||v_prec||')';
		v_char_length := v_prec;
		v_data_length := v_prec;
		v_prec := NULL;
		v_scale := NULL;
	ELSIF v_type = 'number' THEN
		v_data_length := 22;
		IF v_scale IS NULL THEN
			v_scale := 0;
		END IF;
		IF v_prec IS NULL THEN
			v_prec := 0;
		END IF;
		IF v_prec < 1 OR v_prec > 38 THEN
			RAISE_APPLICATION_ERROR(-20001, 'numeric precision of specifier '||v_prec||' is out of range (1 to 38)');
		END IF;
		IF v_scale < -84 OR v_scale > 127 THEN
			RAISE_APPLICATION_ERROR(-20001, 'numeric scale of specifier '||v_scale||' is out of range (1 to 38)');
		END IF;
		v_db_type := v_type || '('||v_prec||','||v_scale||')';
	ELSE
		IF v_prec IS NOT NULL OR v_scale IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'precision or scale cannot be used with '||v_type);
		END IF;
		v_data_length := CASE v_type WHEN 'date' THEN 7
									 WHEN 'blob' THEN 4000
									 WHEN 'clob' THEN 4000
									 WHEN 'binary_double' THEN 8
									 WHEN 'int' THEN 22 END;
	END IF;

	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'ALTER TABLE '||q(dq(in_oracle_schema))||'.'||q('C$'||dq(in_oracle_table))||
						  ' ADD '||q(dq(in_oracle_column))||' '||v_db_type;
	IF in_comment IS NOT NULL THEN
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'COMMENT ON COLUMN '||q(dq(in_oracle_schema))||'.'||q('C$'||dq(in_oracle_table))||
							  '.'||q(dq(in_oracle_column))||' IS '''||REPLACE(in_comment,'''','''''')||'''';
	END IF;
	  
	-- fix up metadata
	UPDATE tab_column
	   SET pos = pos + 1
	 WHERE tab_sid = v_tab_sid
	   AND pos >= v_pos;

	INSERT INTO tab_column 
		(column_sid, tab_sid, col_type, oracle_column, description, pos, calc_xml, 
		 data_type, data_length, data_precision, data_scale, nullable, char_length)
	VALUES
		(column_id_seq.NEXTVAL, v_tab_sid, CASE WHEN in_calc_xml IS NOT NULL THEN CT_CALC ELSE CT_NORMAL END, dq(in_oracle_column), null, v_pos, in_calc_xml,
		 UPPER(v_type), v_data_length, v_prec, v_scale, 'Y', v_char_length)
	RETURNING
		column_sid INTO v_column_sid;
	IF in_comment IS NOT NULL THEN
		ParseColumnComments(v_tab_sid, v_column_sid, in_comment, v_ddl);
		-- clean up indexes
		DropUnusedFullTextIndexes(v_tab_sid, v_ddl);
	END IF;
	
	-- execute the DDL first, then recreate views -- we have to do it this way around
	-- as CreateTriggers looks at all_tab_columns
	ExecuteDDL(v_ddl);
	RecreateViewInternal(v_tab_sid);
END;

PROCEDURE UpdateColumn(
	in_column_sid				IN  tab_column.column_sid%TYPE,
	in_include_in_search		IN  tab_column.include_in_search%TYPE,
	in_show_in_filter			IN  tab_column.show_in_filter%TYPE,
	in_show_in_breakdown		IN  tab_column.show_in_breakdown%TYPE
)
AS
BEGIN
	IF csr.csr_data_pkg.SQL_CheckCapability('System management') = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Permission denied editing column: '||in_column_sid);
	END IF;
	
	UPDATE tab_column
	   SET include_in_search = in_include_in_search,
	       show_in_filter = in_show_in_filter,
		   show_in_breakdown = in_show_in_breakdown
	 WHERE column_sid = in_column_sid;
END;

PROCEDURE ParseQuotedList(
	in_quoted_list				IN	VARCHAR2,
	out_string_list				OUT	t_string_list
)
AS
	v_pos	BINARY_INTEGER DEFAULT 1;
	v_name	VARCHAR2(1000);
	v_len	BINARY_INTEGER;
BEGIN
	v_len := NVL(LENGTH(in_quoted_list), 0);
	WHILE v_pos <= v_len LOOP
		v_name := REGEXP_SUBSTR(in_quoted_list, '[ \t]*(("[^"]*")|([^,]*))[ \t]*', v_pos);
		v_pos := v_pos + LENGTH(v_name);
		v_name := TRIM(v_name);
        IF v_name IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Expected a name at offset '||v_pos||' in the quoted list '||in_quoted_list);
        END IF;
		out_string_list(out_string_list.count + 1) := v_name;
		
		IF v_pos <= v_len THEN
			IF SUBSTR(in_quoted_list, v_pos, 1) <> ',' THEN
				RAISE_APPLICATION_ERROR(-20001,
					'Expected '','' at offset '||v_pos||' in the quoted list '||in_quoted_list);
			END IF;
            v_pos := v_pos + 1;
		END IF;		
	END LOOP;
	IF out_string_list.count = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Empty quoted list');
	END IF;
END;

-- alter table X add unique (foo, bar);
PROCEDURE AddUniqueKey(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_constraint_name			IN	uk_cons.constraint_name%TYPE,
	in_oracle_columns			IN	VARCHAR2
)
AS
	v_cols			t_string_list;
	v_tab_sid		tab.tab_sid%TYPE;
	v_col_sid		tab_column.column_sid%TYPE;
	v_uk_cons_id	uk_cons.uk_cons_id%TYPE;
	v_check_sql		VARCHAR2(32767);
	v_violated		NUMBER;
BEGIN
	GetTableForDDL(in_oracle_schema, in_oracle_table, TRUE, v_tab_sid);
	ParseQuotedList(in_oracle_columns, v_cols);
	
	INSERT INTO uk_cons
		(uk_cons_id, tab_sid, constraint_owner, constraint_name)
	VALUES
		(uk_cons_id_seq.nextval, v_tab_sid, in_oracle_schema, in_constraint_name)
	RETURNING
		uk_cons_id INTO v_uk_cons_id;
	FOR i IN 1 .. v_cols.COUNT LOOP
		BEGIN
			SELECT column_sid
			  INTO v_col_sid
			  FROM tab_column
			 WHERE tab_sid = v_tab_sid AND oracle_column = dq(v_cols(i));
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001,
					'The column '||v_cols(i)||' does not exist in the table '||in_oracle_schema||'.'||in_oracle_table);
		END;
		INSERT INTO uk_cons_col
			(uk_cons_id, column_sid, pos)
		VALUES
			(v_uk_cons_id, v_col_sid, i);
	END LOOP;
	
	-- check the constraint wasn't violated
	v_check_sql := 
		'select min(1)'||chr(10)||
		'  from dual'||chr(10)||
		' where exists (select 1'||chr(10)||
		'                 from '||q(dq(in_oracle_schema))||'.'||q('C$'||dq(in_oracle_table))||chr(10)||
		'                where retired_dtm is null and vers > 0'||chr(10)||
		'             group by ';
	FOR i IN 1 .. v_cols.COUNT LOOP
		IF i <> 1 THEN
			v_check_sql := v_check_sql || ', ';
		END IF;
		v_check_sql := v_check_sql || v_cols(i);
	END LOOP;
	v_check_sql := v_check_sql||chr(10)||
		'               having count(*) > 1)';	
	EXECUTE IMMEDIATE v_check_sql INTO v_violated;
	
	IF v_violated IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001,
			'Cannot add a unique key on '||in_oracle_columns||' to the table '||in_oracle_schema||'.'||in_oracle_table||
			' since it contains duplicate rows');
	END IF;
	RecreateViewInternal(v_tab_sid);
END;

-- XXX: ought to check for duplicate fks
-- XXX: only checks for key violations globally (could have contexts with violated keys)
PROCEDURE AddForeignKey(
	in_from_schema				IN	tab.oracle_schema%TYPE,
	in_from_table				IN	tab.oracle_table%TYPE,
	in_from_columns				IN	VARCHAR2,
	in_to_schema				IN	tab.oracle_schema%TYPE,
	in_to_table					IN	tab.oracle_table%TYPE,
	in_to_columns				IN	VARCHAR2,
	in_constraint_name			IN	VARCHAR2,
	in_delete_rule				IN 	VARCHAR2 DEFAULT 'RESTRICT'
)
AS
	v_ddl						t_ddl DEFAULT t_ddl();
	v_check_sql					VARCHAR2(32767);
	v_violated					NUMBER;
	v_from_cols					t_string_list;
    v_from_tab_sid				tab.tab_sid%TYPE;
    v_to_tab_sid				tab.tab_sid%TYPE;
    v_to_cols					t_string_list;
    v_to_count					BINARY_INTEGER;
    v_uk_cons_id				uk_cons.uk_cons_id%TYPE;
    v_fk_cons_id				fk_cons.fk_cons_id%TYPE;
    v_delete_rule				fk_cons.delete_rule%TYPE;
    v_from_managed				tab.managed%TYPE;
    v_to_managed				tab.managed%TYPE;
    v_from_table_name			VARCHAR2(30);
    v_to_table_name				VARCHAR2(30);
BEGIN
	GetTableForDDL(in_from_schema, in_from_table, FALSE, v_from_tab_sid);

	SELECT managed, (CASE WHEN managed = 1 THEN 'C$' ELSE '' END) || oracle_table
	  INTO v_from_managed, v_from_table_name
	  FROM tab
	 WHERE tab_sid = v_from_tab_sid;
	 
	GetTableForDDL(in_to_schema, in_to_table, FALSE, v_to_tab_sid);
	
	SELECT managed, (CASE WHEN managed = 1 THEN 'C$' ELSE '' END) || oracle_table
	  INTO v_to_managed, v_to_table_name
	  FROM tab
	 WHERE tab_sid = v_to_tab_sid;

	IF v_from_managed = 0 AND v_to_managed = 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot add a foreign key from the unmanaged table '||in_from_schema||'.'||in_from_table||
			' to the managed table '||in_to_schema||'.'||in_to_table||' - make the from table managed first');
	END IF;

	IF UPPER(in_delete_rule) IN ('RESTRICT', 'R') THEN
		v_delete_rule := 'R';
	ELSIF UPPER(in_delete_rule) IN ('CASCADE', 'C') THEN
		v_delete_rule := 'C';
	ELSIF UPPER(in_delete_rule) IN ('SET NULL', 'SETNULL', 'N') THEN
		v_delete_rule := 'N';
	ELSE
		RAISE_APPLICATION_ERROR(-20001,
			'Unknown delete rule '||in_delete_rule||' - must be one of RESTRICT, CASCADE or SET NULL');
	END IF;
		
	ParseQuotedList(in_from_columns, v_from_cols);
	ParseQuotedList(in_to_columns, v_to_cols);	
	IF v_from_cols.COUNT <> v_to_cols.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001,
			'Cannot add a foreign key from the columns '||in_from_columns||' in the table '||in_from_schema||'.'||in_from_table||
			' to the columns '||in_to_columns||' in the table '||in_to_schema||'.'||in_to_table||' because there are not the same number '||
			' of columns in each list');
	END IF;
	
	-- find the uk we are referencing
	DELETE FROM temp_string_list;
	v_to_count := v_to_cols.COUNT; -- can't use .COUNT in SQL, sigh
	FOR i IN 1 .. v_to_count LOOP
		INSERT INTO temp_string_list (pos, value)
		VALUES (i, dq(v_to_cols(i)));
	END LOOP;
		
	BEGIN
		SELECT MIN(guk.uk_cons_id)
			INTO v_uk_cons_id
			FROM (
				  SELECT ukc.uk_cons_id, count(*) cnt
					FROM uk_cons ukc
					JOIN uk_cons_col ukcc ON ukc.uk_cons_id = ukcc.uk_cons_id
					WHERE ukc.TAB_SID = v_to_tab_sid
					GROUP BY ukc.uk_cons_id
				) guk
			JOIN uk_cons_col ucc ON guk.uk_cons_id = ucc.UK_CONS_ID
			JOIN tab_column tc ON tc.COLUMN_SID = ucc.COLUMN_SID
			JOIN temp_string_list tsl ON tsl.value = tc.oracle_column AND tsl.pos = ucc.pos
			WHERE guk.cnt = v_to_count
			GROUP BY guk.uk_cons_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001,
				'No unique key could be found for the columns '||in_to_columns||
				' in the table '||in_to_schema||'.'||in_to_table);
	END;
	
	-- check the columns have the same types
	FOR i IN 1 .. v_from_cols.COUNT LOOP
	    SELECT COUNT(*)
	      INTO v_violated
	      FROM all_tab_columns ftc, all_tab_columns ttc
	     WHERE ftc.owner = dq(in_from_schema)
	       AND ftc.table_name = v_from_table_name
	       AND ftc.column_name = dq(v_from_cols(i))
	       AND ttc.owner = dq(in_to_schema)
	       AND ttc.table_name = v_to_table_name
	       AND ttc.column_name = dq(v_to_cols(i))
	       AND (ftc.data_length != ttc.data_length
	            OR ftc.data_precision != ttc.data_precision
	            OR ftc.data_scale != ttc.data_scale
	            OR ftc.data_type != ttc.data_type);
	            
		IF v_violated <> 0 THEN
			RAISE_APPLICATION_ERROR(-20001,
				'Cannot create a foreign key relationship between '||in_from_schema||'.'||in_from_table||'.'||v_from_cols(i)||
				' and '||in_to_schema||'.'||in_to_table||'.'||v_to_cols(i)||' because the column datatypes differ');
		END IF;
	END LOOP;
	
	-- check the fk isn't violated
	v_check_sql :=
		'select count(*) '||chr(10)||
		'  from ('||chr(10)||
		'        select ';
	FOR i IN 1 .. v_from_cols.COUNT LOOP
		IF i <> 1 THEN
			v_check_sql := v_check_sql||',';
		END IF;
		v_check_sql := v_check_sql||q(dq(v_from_cols(i)));
	END LOOP;
	v_check_sql := v_check_sql||chr(10)||
		'          from '||q(dq(in_from_schema))||'.'||q(v_from_table_name)||chr(10);
	IF v_from_managed = 1 THEN
		v_check_sql := v_check_sql||
			'         where retired_dtm is null and vers > 0 and'||chr(10);
	ELSE
		v_check_sql := v_check_sql||
			'         where ';
	END IF;
	FOR i IN 1 .. v_from_cols.COUNT LOOP
		IF i <> 1 THEN
			v_check_sql := v_check_sql||' and ';
		END IF;
		v_check_sql := v_check_sql||q(dq(v_from_cols(i)))||' is not null';
	END LOOP;
	v_check_sql := v_check_sql||chr(10)||		
		'         minus'||chr(10)||
		'        select ';
	FOR i IN 1 .. v_to_cols.COUNT LOOP
		IF i <> 1 THEN
			v_check_sql := v_check_sql||',';
		END IF;
		v_check_sql := v_check_sql||q(dq(v_to_cols(i)));
	END LOOP;	
	v_check_sql := v_check_sql||chr(10)||
		'          from '||q(dq(in_to_schema))||'.'||q(v_to_table_name)||chr(10);
	IF v_to_managed = 1 THEN
		v_check_sql := v_check_sql||
			'         where retired_dtm is null and vers > 0'||chr(10);
	END IF;
	v_check_sql := v_check_sql||	
			'       )';

	IF m_trace THEN
		TraceClob(v_check_sql);	
	END IF;

	EXECUTE IMMEDIATE v_check_sql INTO v_violated;
	
	IF v_violated <> 0 THEN
		RAISE_APPLICATION_ERROR(-20001,
			'Cannot add a foreign key from '||in_from_columns||' in the table '||in_from_schema||'.'||in_from_table||
			' to the columns '||in_to_columns||' in the table '||in_to_schema||'.'||in_to_table||
			' since there are '||v_violated||' rows with missing parent keys');
	END IF;
		
	-- stuff an fk in
	INSERT INTO fk_cons 
		(fk_cons_id, tab_sid, r_cons_id, delete_rule, constraint_owner, constraint_name)
	VALUES
		(fk_cons_id_seq.nextval, v_from_tab_sid, v_uk_cons_id, v_delete_rule, in_from_schema, in_constraint_name);

	-- stuff columns in
	FOR i IN 1 .. v_from_cols.COUNT LOOP
		INSERT INTO fk_cons_col (app_sid, fk_cons_id, column_sid, pos)
			SELECT tc.app_sid, fk_cons_id_seq.currval, tc.column_sid, i
			  FROM tab_column tc
			 WHERE tab_sid = v_from_tab_sid AND tc.oracle_column = dq(v_from_cols(i));
	END LOOP;
	
	-- add a real FK if we are going to an unmanaged table
	IF v_to_managed = 0 THEN
		v_check_sql := 'alter table '||q(dq(in_from_schema))||'.'||q(v_from_table_name)||' add ';
		
		v_check_sql := v_check_sql || 'constraint ' || UPPER(SUBSTR(in_constraint_name, 1, 30));
		
		v_check_sql := v_check_sql || ' foreign key (';
		FOR i IN 1 .. v_from_cols.COUNT LOOP
			IF i > 1 THEN
				v_check_sql := v_check_sql || ',';
			END IF;
			v_check_sql := v_check_sql || q(dq(v_from_cols(i)));
		END LOOP;
	
		v_check_sql := v_check_sql || ') references '||q(dq(in_to_schema))||'.'||q(v_to_table_name)||' (';

		FOR i IN 1 .. v_to_cols.COUNT LOOP
			IF i > 1 THEN
				v_check_sql := v_check_sql || ',';
			END IF;
			v_check_sql := v_check_sql || q(dq(v_to_cols(i)));
		END LOOP;
		v_check_sql := v_check_sql || ')';
			
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := v_check_sql;
	END IF;
	
    -- recreate the triggers
	IF v_from_managed = 1 THEN
    	CreateTriggers(v_from_tab_sid, v_ddl);
	END IF;
	IF v_to_managed = 1 THEN
    	CreateTriggers(v_to_tab_sid, v_ddl);
	END IF;

    ExecuteDDL(v_ddl);
END;

PROCEDURE DropForeignKey(
	in_oracle_schema 		IN 	tab.oracle_schema%TYPE,
	in_table_name 			IN 	tab.oracle_table%TYPE,
	in_column_names 		IN 	VARCHAR2,
	in_ref_table_name 		IN 	tab.oracle_table%TYPE,
	in_ref_column_names		IN 	VARCHAR2
)
AS
	v_fk_name				fk_cons.constraint_name%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can drop FKs.');
	END IF;

	BEGIN
		SELECT constraint_name
		  INTO v_fk_name
		  FROM (
			SELECT fk.table_name, fkc.constraint_name, fk.fk_cons_id, LISTAGG(fk.column_name, ',') WITHIN GROUP (ORDER BY fk.pos) AS table_columns
			  FROM fk
			  JOIN fk_cons fkc ON fk.fk_cons_id = fkc.fk_cons_id
			 WHERE fk.owner = UPPER(in_oracle_schema)
			   AND fk.table_name = UPPER(in_table_name)
			 GROUP BY fk.table_name, fkc.constraint_name, fk.fk_cons_id) pt
		 WHERE table_columns = UPPER(in_column_names)
		  AND UPPER(in_ref_column_names) = (
			SELECT LISTAGG(fk.r_column_name, ',') WITHIN GROUP (ORDER BY fk.pos) AS table_columns
			  FROM fk
			  JOIN fk_cons fkc ON fk.fk_cons_id = fkc.fk_cons_id
			 WHERE fk.r_owner = UPPER(in_oracle_schema)
			   AND fk.r_table_name = UPPER(in_ref_table_name)
			   AND fkc.constraint_name = pt.constraint_name
			 GROUP BY fk.r_table_name, fkc.constraint_name);

		DropForeignKeyByName(in_oracle_schema, v_fk_name);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Constraint not found between tables '||in_table_name||'('||in_column_names||') and '||in_ref_table_name||'('||in_ref_column_names||')');
	END;
END;

PROCEDURE DropForeignKeyByName(
	in_oracle_schema 		IN 	tab.oracle_schema%TYPE,
	in_foreign_key_name 	IN 	fk_cons.constraint_name%TYPE
)
AS
	v_table_name 			tab.oracle_table%TYPE;
	v_managed 				NUMBER(1);
	v_ref_managed 			NUMBER(1);
	v_fk_cons_id			fk_cons.fk_cons_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can drop FKs.');
	END IF;

	BEGIN
		SELECT fk.fk_cons_id, fk.table_name, tab.managed, rtab.managed r_managed
		  INTO v_fk_cons_id, v_table_name, v_managed, v_ref_managed
		  FROM fk
		  JOIN tab ON fk.owner = tab.oracle_schema AND fk.table_name = tab.oracle_table
		  JOIN tab rtab ON fk.owner = rtab.oracle_schema AND fk.r_table_name = rtab.oracle_table
		 WHERE fk.owner = UPPER(in_oracle_schema)
		   AND fk.constraint_name = UPPER(in_foreign_key_name)
		 GROUP BY fk.fk_cons_id, fk.table_name, tab.managed, rtab.managed;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Constraint '||in_foreign_key_name||' not found');
	END;

	IF v_ref_managed = 1 THEN
		DELETE FROM fk_cons_col
		 WHERE fk_cons_id = v_fk_cons_id;

		DELETE FROM fk_cons
		 WHERE fk_cons_id = v_fk_cons_id;
	ELSE
		IF v_managed = 1 THEN
			EXECUTE IMMEDIATE 'ALTER TABLE '||UPPER(in_oracle_schema)||'.C$'||v_table_name||' DROP CONSTRAINT '||in_foreign_key_name;
		ELSE
			EXECUTE IMMEDIATE 'ALTER TABLE '||UPPER(in_oracle_schema)||'.'||v_table_name||' DROP CONSTRAINT '||in_foreign_key_name;
		END IF;
	END IF;

	RefreshUnmanaged(security_pkg.GetApp);
END;

PROCEDURE DropColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE
)
AS
	v_tab_sid		tab_column.tab_sid%TYPE;
	v_column_sid	tab_column.column_sid%TYPE;
	v_ddl			t_ddl DEFAULT t_ddl();
BEGIN
	GetColumnForDDL(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_column_sid);

	-- dropping a column drops any fks that it is part of as per usual oracle behaviour
	FOR r IN (SELECT DISTINCT fk_cons_id
				FROM fk_cons_col
			   WHERE column_sid = v_column_sid) LOOP
		DELETE FROM fk_cons_col
		 WHERE fk_cons_id = r.fk_cons_id;
		
		UPDATE tab
		   SET securable_fk_cons_id = NULL
		 WHERE securable_fk_cons_id = r.fk_cons_id;
		
		DELETE FROM fk_cons
		 WHERE fk_cons_id = r.fk_cons_id;
	END LOOP;

	-- same for check constraints
	FOR r IN (SELECT DISTINCT ck_cons_id
			    FROM ck_cons_col
			   WHERE column_sid = v_column_sid) LOOP
		DELETE FROM ck_cons_col
		 WHERE ck_cons_id = r.ck_cons_id;
		 
		DELETE FROM ck_cons
		 WHERE ck_cons_id = r.ck_cons_id;
	END LOOP;

	UPDATE tab_column
	   SET pos = pos - 1
	 WHERE tab_sid = v_tab_sid AND pos > (
	 		SELECT pos 
	 		  FROM tab_column
	 		 WHERE column_sid = v_column_sid);

	DELETE FROM tab_column
	 WHERE tab_sid = v_tab_sid AND column_sid = v_column_sid;

	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'ALTER TABLE '||q(dq(in_oracle_schema))||'.'||q('C$'||dq(in_oracle_table))||
						  'DROP COLUMN '||q(dq(in_oracle_column));

	-- execute the DDL first, then recreate views -- we have to do it this way around
	-- as CreateTriggers looks at all_tab_columns
	ExecuteDDL(v_ddl);
	RecreateViewInternal(v_tab_sid);
END;

PROCEDURE GetTableForWrite(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	out_tab_sid					OUT	tab_column.column_sid%TYPE
)
AS
BEGIN
	BEGIN
		SELECT t.tab_sid
  		  INTO out_tab_sid
  		  FROM tab t
 	     WHERE oracle_schema = dq(in_oracle_schema) AND
 	     	   oracle_table = dq(in_oracle_table) AND
			   app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 
				'Could not find the table '||in_oracle_schema||'.'||in_oracle_table);
	END;

	-- XXX: need some separate permission type?
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), out_tab_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Write access denied on the table '||q(in_oracle_schema)||'.'||q(in_oracle_table));
	END IF;
END;

PROCEDURE GetColumnForWrite(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	out_tab_sid					OUT	tab.tab_sid%TYPE,
	out_col_sid					OUT	tab_column.column_sid%TYPE
)
AS
BEGIN	
	BEGIN
		SELECT t.tab_sid, tc.column_sid
  		  INTO out_tab_sid, out_col_sid
  		  FROM tab t, tab_column tc
 	     WHERE t.oracle_schema = dq(in_oracle_schema) AND
 	     	   t.oracle_table = dq(in_oracle_table) AND 
			   t.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND
 	     	   tc.oracle_column = dq(in_oracle_column) AND
 	     	   t.tab_sid = tc.tab_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 
				'Could not find the column '||in_oracle_schema||'.'||in_oracle_table||'.'||in_oracle_column);
	END;

	-- XXX: need some separate permission type?
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), out_tab_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Access denied writing to the column '||
				q(in_oracle_column)||' in the table '||q(in_oracle_schema)||'.'||q(in_oracle_table));
	END IF;
END;

PROCEDURE GetTableForDDL(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_check_managed			IN	BOOLEAN DEFAULT TRUE,
	out_tab_sid					OUT	tab_column.column_sid%TYPE
)
AS
	v_managed		tab.managed%TYPE;
BEGIN
	GetTableForWrite(in_oracle_schema, in_oracle_table, out_tab_sid);
	
	SELECT managed
	  INTO v_managed
	  FROM tab
	 WHERE tab_sid = out_tab_sid;
	IF v_managed = 0 AND in_check_managed = TRUE THEN
		RAISE_APPLICATION_ERROR(-20001, 
			'Cannot modify the unmanaged table '||in_oracle_schema||'.'||in_oracle_table);
	END IF;

	EXECUTE IMMEDIATE 'lock table '||q(dq(in_oracle_schema))||'.'||q(
		(CASE WHEN v_managed = 1 THEN 'C$' ELSE '' END)||dq(in_oracle_table))||' in exclusive mode';
END;

PROCEDURE GetColumnForDDL(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	out_tab_sid					OUT	tab.tab_sid%TYPE,
	out_col_sid					OUT	tab_column.column_sid%TYPE
)
AS
BEGIN
	GetTableForDDL(in_oracle_schema, in_oracle_table, TRUE, out_tab_sid);
	BEGIN
		SELECT column_sid
  		  INTO out_col_sid
  		  FROM tab_column
 	     WHERE oracle_column = dq(in_oracle_column) AND tab_sid = out_tab_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 
				'Could not find the column '||in_oracle_schema||'.'||in_oracle_table||'.'||in_oracle_column);
	END;
END;
	
PROCEDURE SetColumnDescription(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_description				IN	tab_column.description%TYPE
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET description = in_description
	 WHERE column_sid = v_col_sid;
END;

PROCEDURE SetColumnHelp(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	out_help					OUT	tab_column.help%TYPE
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET help = EMPTY_CLOB()
	 WHERE column_sid = v_col_sid
 		   RETURNING help INTO out_help;
END;

PROCEDURE SetColumnHelp(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_helptext					IN	VARCHAR2
)
AS
	v_help_clob					CLOB;
BEGIN		
	SetColumnHelp(UPPER(in_oracle_schema), in_oracle_table, in_oracle_column, v_help_clob);
	dbms_lob.writeappend(v_help_clob, LENGTH(in_helptext), in_helptext);
END;

PROCEDURE SetColumnIncludeInSearch(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_include_in_search		IN	tab_column.include_in_search%TYPE
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET include_in_search = in_include_in_search
	 WHERE column_sid = v_col_sid;
END;

PROCEDURE SetColumnShowInFilter(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_show_in_filter			IN	tab_column.show_in_filter%TYPE
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET show_in_filter = in_show_in_filter
	 WHERE column_sid = v_col_sid;
END;

PROCEDURE SetColumnShowInBreakdown(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_show_in_breakdown		IN	tab_column.show_in_breakdown%TYPE
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET show_in_breakdown = in_show_in_breakdown
	 WHERE column_sid = v_col_sid;
END;

PROCEDURE SetColumnRestrictedByPolicy(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_restricted_by_policy		IN	tab_column.restricted_by_policy%TYPE
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET restricted_by_policy = in_restricted_by_policy
	 WHERE column_sid = v_col_sid;
END;

PROCEDURE SetEnumeratedColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_enumerated_desc_field	IN	tab_column.enumerated_desc_field%TYPE DEFAULT NULL,
	in_enumerated_pos_field		IN	tab_column.enumerated_pos_field%TYPE DEFAULT NULL,
	in_enumerated_colpos_field	IN	tab_column.enumerated_colpos_field%TYPE DEFAULT NULL,
	in_enumerated_colour_field	IN	tab_column.enumerated_colour_field%TYPE DEFAULT NULL,
	in_enumerated_extra_fields	IN	tab_column.enumerated_extra_fields%TYPE DEFAULT NULL
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET col_type = tab_pkg.CT_ENUMERATED, 
	   	   enumerated_desc_field = dq(in_enumerated_desc_field),
	   	   enumerated_pos_field = dq(in_enumerated_pos_field),
	   	   enumerated_colpos_field = dq(in_enumerated_colpos_field),
	   	   enumerated_colour_field = dq(in_enumerated_colour_field),
		   enumerated_extra_fields = in_enumerated_extra_fields
	 WHERE column_sid = v_col_sid;
END;

PROCEDURE SetSearchEnumColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_enumerated_desc_field	IN	tab_column.enumerated_desc_field%TYPE DEFAULT NULL,
	in_enumerated_pos_field		IN	tab_column.enumerated_pos_field%TYPE DEFAULT NULL
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET col_type = tab_pkg.CT_SEARCH_ENUM, 
	   	   enumerated_desc_field = dq(in_enumerated_desc_field),
	   	   enumerated_pos_field = dq(in_enumerated_pos_field)
	 WHERE column_sid = v_col_sid;
END;

PROCEDURE SetConstrainedEnumColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_enumerated_desc_field	IN	tab_column.enumerated_desc_field%TYPE DEFAULT NULL,
	in_enumerated_pos_field		IN	tab_column.enumerated_pos_field%TYPE DEFAULT NULL,
	in_enumerated_colpos_field	IN	tab_column.enumerated_colpos_field%TYPE DEFAULT NULL,
	in_enumerated_colour_field	IN	tab_column.enumerated_colour_field%TYPE DEFAULT NULL,
	in_enumerated_extra_fields	IN	tab_column.enumerated_extra_fields%TYPE DEFAULT NULL
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET col_type = tab_pkg.CT_CONSTRAINED_ENUM, 
	   	   enumerated_desc_field = dq(in_enumerated_desc_field),
	   	   enumerated_pos_field = dq(in_enumerated_pos_field),
	   	   enumerated_colpos_field = dq(in_enumerated_colpos_field),
	   	   enumerated_colour_field = dq(in_enumerated_colour_field),
		   enumerated_extra_fields = in_enumerated_extra_fields
	 WHERE column_sid = v_col_sid;
END;

PROCEDURE SetVideoColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_video_code				IN	NUMBER DEFAULT 1
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET col_type = CASE WHEN in_video_code = 0 THEN tab_pkg.CT_NORMAL ELSE tab_pkg.CT_VIDEO_CODE END
	 WHERE column_sid = v_col_sid;
END;


PROCEDURE SetChartColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_chart					IN	NUMBER DEFAULT 1
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET col_type = CASE WHEN in_chart = 0 THEN tab_pkg.CT_NORMAL ELSE tab_pkg.CT_CHART END
	 WHERE column_sid = v_col_sid;
END;


PROCEDURE SetHtmlColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_oracle_column			IN	tab_column.oracle_column%TYPE,
	in_html						IN	NUMBER DEFAULT 1
)
AS
	v_col_sid		tab_column.column_sid%TYPE;
	v_tab_sid		tab.tab_sid%TYPE;
BEGIN
	GetColumnForWrite(in_oracle_schema, in_oracle_table, in_oracle_column, v_tab_sid, v_col_sid);

	UPDATE tab_column
	   SET col_type = CASE WHEN in_html = 0 THEN tab_pkg.CT_NORMAL ELSE tab_pkg.CT_HTML END
	 WHERE column_sid = v_col_sid;
END;


PROCEDURE SetFileColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_file_column				IN	tab_column.oracle_column%TYPE,
	in_mime_column				IN	tab_column.oracle_column%TYPE,
	in_name_column				IN	tab_column.oracle_column%TYPE
)
AS
	v_tab_sid		tab_column.tab_sid%TYPE;
	v_col_sid		tab_column.column_sid%TYPE;
BEGIN
	GetTableForWrite(in_oracle_schema, in_oracle_table, v_tab_sid);

	UPDATE tab_column
	   SET col_type = tab_pkg.CT_FILE_DATA, master_column_sid = column_sid
	 WHERE tab_sid = v_tab_sid AND oracle_column = dq(in_file_column)
  		   RETURNING column_sid INTO v_col_sid;
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
			'Could not find the column '||in_oracle_schema||'.'||in_oracle_table||'.'||in_file_column);
	END IF;
	IF in_mime_column IS NOT NULL THEN
		UPDATE tab_column
		   SET col_type = tab_pkg.CT_FILE_MIME, master_column_sid = v_col_sid
		 WHERE tab_sid = v_tab_sid AND oracle_column = dq(in_mime_column);
		IF SQL%ROWCOUNT = 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
				'Could not find the column '||in_oracle_schema||'.'||in_oracle_table||'.'||in_mime_column);
		END IF;
	END IF;
	IF in_name_column IS NOT NULL THEN
		UPDATE tab_column
		   SET col_type = tab_pkg.CT_FILE_NAME, master_column_sid = v_col_sid
		 WHERE tab_sid = v_tab_sid AND oracle_column = dq(in_name_column);
		IF SQL%ROWCOUNT = 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
				'Could not find the column '||in_oracle_schema||'.'||in_oracle_table||'.'||in_name_column);
		END IF;
	END IF;
END;

PROCEDURE DropAllTables
AS
	v_cms_sid		security_pkg.T_SID_ID;
	v_drop_physical	BOOLEAN;
BEGIN
	
	-- Clean up registered managed tables, dropping tables with a parent first
	-- This may not work if there are grandparents, but none currently exist in Live
	FOR r IN (SELECT oracle_schema, oracle_table, managed
				FROM cms.tab 
			   WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') ORDER BY parent_tab_sid) LOOP
		IF r.managed = 1 THEN
			-- HMM... this scares me! i.e. if your register a managed table that is 
			-- shared (i.e. via APP_SID) then it'll be dropped from Oracle.
			-- Someone could blindly call this and delete (say) the RISKS schema
			-- stuff and more.
			v_drop_physical := FALSE; --TRUE; 
		ELSE
			v_drop_physical := FALSE;
		END IF;
		DropTable(r.oracle_schema, r.oracle_table, TRUE, v_drop_physical);
	END LOOP;
	
	-- Clean up possibly left over SOs
	BEGIN
		v_cms_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms');
		FOR r IN (SELECT sid_id
					FROM security.securable_object 
				   WHERE parent_sid_id = v_cms_sid) LOOP
			SecurableObject_pkg.DeleteSO(security_pkg.GetACT(), r.sid_id);
		END LOOP;
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	-- Clean up any granted/automatically granted permissions
	DELETE FROM app_schema
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM app_schema_table
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE DropTable(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_cascade_constraints		IN	BOOLEAN DEFAULT FALSE,
	in_drop_physical			IN	BOOLEAN DEFAULT TRUE
)
AS
	v_tab_sid		security_pkg.T_SID_ID;
	v_itab_sid		security_pkg.T_SID_ID;
	v_so_tab_sid	security_pkg.T_SID_ID;
	v_ddl			t_ddl DEFAULT t_ddl();
	v_owner			VARCHAR2(30);
	v_table_name	VARCHAR2(30);
	v_has_fks		NUMBER;
	v_shared		NUMBER;
BEGIN
	-- Normalise owner/table
	v_owner := dq(in_oracle_schema);
	v_table_name := dq(in_oracle_table);
	
	-- Check for an issue join table and kill that as well
	-- XXX: should this check from all_tables? i.e. when we create, we check all_tables
	-- and if there's a problem during registration then when we re-run, the I$XXX table
	-- exists but it doesn't get dropped.
	BEGIN
		SELECT tab_sid
		  INTO v_itab_sid
		  FROM tab
		 WHERE oracle_schema = v_owner AND oracle_table = 'I$'||v_table_name
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		DropTable(v_owner, q('I$'||v_table_name), TRUE, TRUE);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Check for an SO
			BEGIN
				v_so_tab_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms/' || 
					q(v_owner) || '.' ||q('I$'||v_table_name));
					DropTable(v_owner, q('I$'||v_table_name), TRUE, TRUE);
			EXCEPTION
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					NULL;
			END;
	END;

	-- find all full text indexes for this table
	FOR r IN (
		SELECT owner, index_name
		  FROM all_indexes 
		 WHERE ityp_owner = 'CTXSYS'
		   AND index_name LIKE 'FTI$%'
		   AND table_owner = v_owner
		   AND table_name = v_table_name
	)
	LOOP	
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'drop index '||q(r.owner)||'.'||q(r.index_name);
	END LOOP;


	-- Check for an SO
	BEGIN
		v_so_tab_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms/' || 
			q(v_owner) || '.' ||q(v_table_name));
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	-- Check for an entry in TAB
	BEGIN
		SELECT tab_sid
  		  INTO v_tab_sid
  		  FROM tab
 	     WHERE oracle_schema = v_owner AND oracle_table = v_table_name AND
 	     	   app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	-- Check for FK constraints if we have an entry in TAB
	IF v_tab_sid IS NOT NULL THEN
		-- Cascading constraints so just drop them
		IF in_cascade_constraints THEN
			DELETE FROM fk_cons_col
			 WHERE fk_cons_id IN (SELECT fk_cons_id
			 						FROM fk_cons fk, uk_cons uk
			 					   WHERE fk.r_cons_id = uk.uk_cons_id AND uk.tab_sid = v_tab_sid);
								   
			UPDATE tab
			   SET securable_fk_cons_id = NULL
			 WHERE securable_fk_cons_id IN (
				SELECT fk_cons_id
			 	  FROM fk_cons fk, uk_cons uk
				 WHERE fk.r_cons_id = uk.uk_cons_id AND uk.tab_sid = v_tab_sid);
	
			DELETE FROM fk_cons
			 WHERE fk_cons_id IN (SELECT fk_cons_id
			 						FROM fk_cons fk, uk_cons uk
			 					   WHERE fk.r_cons_id = uk.uk_cons_id AND uk.tab_sid = v_tab_sid);
		ELSE
			SELECT MIN(1)
			  INTO v_has_fks
			  FROM DUAL
			 WHERE EXISTS (SELECT *
							 FROM fk_cons fk, uk_cons uk
							WHERE fk.r_cons_id = uk.uk_cons_id AND uk.tab_sid = v_tab_sid);
			IF v_has_fks IS NOT NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'The table '||q(v_owner)||'.'||q(v_table_name)||
					' with sid '||v_tab_sid||' has cannot be dropped because it has foreign keys that refer to it');
			END IF;
		END IF;
				
		FOR r IN (
			SELECT customer_alert_type_id 
			  FROM csr.cms_alert_type
			 WHERE tab_sid = v_tab_sid
		)
		LOOP
			csr.alert_pkg.DeleteTemplate(r.customer_alert_type_id);				
		END LOOP;
	END IF;
			
	-- Nuke the SO if found.  Also cleans up keys, etc.
	IF v_so_tab_sid IS NOT NULL THEN
		BEGIN
			SecurableObject_pkg.DeleteSO(security_pkg.GetACT(), v_so_tab_sid);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;

	-- If we had a missing SO but data in the TAB then clean that up too
	ELSIF v_tab_sid IS NOT NULL THEN
		DeleteObject(security_pkg.GetACT(), v_tab_sid);
	END IF;
		
	IF NOT in_drop_physical THEN
		RETURN;
	END IF;
	
	-- if this table is shared by any other apps, don't drop the physical table
	SELECT COUNT(*)
	  INTO v_shared
	  FROM oracle_tab
	 WHERE oracle_schema = v_owner
	   AND oracle_table = v_table_name;
	IF v_shared != 0 THEN
		RETURN;
	END IF;

	-- Nuke the views, base table and packages if found
	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'DROP VIEW ' || q(v_owner) || '.' || q('H$' || v_table_name);
	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'DROP VIEW ' || q(v_owner) || '.' || q(v_table_name);
	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'DROP TABLE ' || q(v_owner) || '.' || q('L$' || v_table_name);
	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'DROP TABLE ' || q(v_owner) || '.' || q('C$' || v_table_name) || ' CASCADE CONSTRAINTS';
	-- probably generates ORA-00942 (table/view doesn't exist, but if registration was incomplete the table may still exist)
	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'DROP TABLE ' || q(v_owner) || '.' || q(v_table_name) || ' CASCADE CONSTRAINTS';
	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 'DROP PACKAGE ' || q(v_owner) || '.' || q('T$' || v_table_name);

	FOR i in v_ddl.first .. v_ddl.last LOOP
		BEGIN
			IF m_trace THEN
				IF SUBSTR(v_ddl(i), -1) = ';' THEN
					dbms_output.put_line(v_ddl(i));
					dbms_output.put_line('/');
				ELSE
					dbms_output.put_line(v_ddl(i)||';');
				END IF;
			END IF;
			IF NOT m_trace_only THEN
				ExecuteClob(v_ddl(i));
			END IF;
		EXCEPTION
			-- skip bits that don't exist
			WHEN PACKAGE_DOES_NOT_EXIST THEN
				NULL;
			WHEN TABLE_DOES_NOT_EXIST THEN
				NULL;
			WHEN USER_DOES_NOT_EXIST THEN
				NULL;
		END;
	END LOOP;
END;

PROCEDURE RenameColumn(
	in_oracle_schema			IN	tab.oracle_schema%TYPE,
	in_oracle_table				IN	tab.oracle_table%TYPE,
	in_old_name					IN	tab_column.oracle_column%TYPE,
	in_new_name					IN	tab_column.oracle_column%TYPE
)
AS
	v_cms_sid		security_pkg.T_SID_ID;
	v_tab_sid		security_pkg.T_SID_ID;
	v_col_sid		security_pkg.T_SID_ID;
	v_new_name		VARCHAR2(30);
	v_count			NUMBER;
	v_ddl 			t_ddl default t_ddl();
	v_managed		NUMBER;
	v_is_part_of_pk	NUMBER;
	v_tab_name		VARCHAR2(30);
BEGIN
	GetColumnForDDL(in_oracle_schema, in_oracle_table, in_old_name, v_tab_sid, v_col_sid);
	
	v_new_name := dq(in_new_name);
	UPDATE tab_column
	   SET oracle_column = v_new_name
	 WHERE column_sid = v_col_sid;

	-- Check for a duplicate name (TODO: ought to be a constraint...)
	SELECT COUNT(*)
	  INTO v_count
	  FROM tab_column
	 WHERE oracle_column = v_new_name
	   AND tab_sid = v_tab_sid;
	IF v_count > 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 
			'The table '||in_oracle_schema||'.'||in_oracle_table||' already has a column named '||in_new_name);
	END IF;

	SELECT managed
	  INTO v_managed
	  FROM tab
	 WHERE tab_sid = v_tab_sid;
	IF v_managed = 1 THEN
		v_tab_name := 'C$'||dq(in_oracle_table);
	ELSE
		v_tab_name := dq(in_oracle_table);
	END IF;

	v_ddl.extend(1);
	v_ddl(v_ddl.count) := 
		'alter table '||q(dq(in_oracle_schema))||'.'||q(v_tab_name)||' rename column '||q(dq(in_old_name))||' to '||q(v_new_name);

	-- If column is part of the primary key, and this is a managed table, then
	-- need to rename the column in the lock table too
	SELECT MIN(1)
	  INTO v_is_part_of_pk
	  FROM tab t
	  JOIN uk_cons_col c ON t.pk_cons_id = c.uk_cons_id
	 WHERE t.tab_sid = v_tab_sid
	   AND c.column_sid = v_col_sid;
	
	IF v_managed = 1 AND v_is_part_of_pk = 1 THEN
		v_ddl.extend(1);
		v_ddl(v_ddl.count) :=
			'alter table '||q(dq(in_oracle_schema))||'.'||q('L$'||dq(in_oracle_table))||' rename column '||q(dq(in_old_name))||' to '||q(v_new_name);
	END IF;

	-- execute the DDL first, then recreate views -- we have to do it this way around
	-- as CreateTriggers looks at all_tab_columns
	ExecuteDDL(v_ddl);
	RecreateViewInternal(v_tab_sid);
END;

PROCEDURE GetTableDefinitions_(
	in_tables						IN	security.T_SO_TABLE,
	out_tab_cur						OUT SYS_REFCURSOR,
	out_col_cur						OUT	SYS_REFCURSOR,
	out_ck_cur						OUT	SYS_REFCURSOR,
	out_ck_col_cur					OUT	SYS_REFCURSOR,
	out_uk_cur						OUT	SYS_REFCURSOR,
	out_fk_cur						OUT	SYS_REFCURSOR,
	out_flow_tab_col_cons_cur		OUT	SYS_REFCURSOR,
	out_flow_state_user_col_cur		OUT	SYS_REFCURSOR,
	out_measure_cur 				OUT	SYS_REFCURSOR,
	out_measure_conv_cur 			OUT	SYS_REFCURSOR,
	out_measure_conv_period_cur		OUT SYS_REFCURSOR
)
AS
	v_tcrp_count				NUMBER(10);
BEGIN
	OPEN out_tab_cur FOR
		SELECT t.tab_sid, t.oracle_schema, t.oracle_table, t.description, t.format_sql, 
			   t.pk_cons_id, t.managed, t.auto_registered, t.cms_editor, t.issues, t.flow_sid,
			   t.region_col_sid, t.policy_function, t.is_view, t.policy_view, t.has_rid_column,
			   t.helper_pkg, t.show_in_company_filter, t.parent_tab_sid, t.show_in_property_filter,
			   t.securable_fk_cons_id, t.is_basedata, t.show_in_product_filter
		  FROM tab t, TABLE (in_tables) c
		 WHERE t.tab_sid = c.sid_id;
	
	SELECT COUNT(*)
	  INTO v_tcrp_count
	  FROM tab_column_role_permission;
	
	IF v_tcrp_count = 0 THEN
		-- We can do a much simpler query if there are no tab_column_role_permissions (the most common case)
		OPEN out_col_cur FOR
			SELECT /*+ALL_ROWS*/ t.tab_sid, tc.data_type, tc.data_length, tc.data_precision, tc.data_scale, 
				   tc.nullable, tc.char_length, tc.column_sid, tc.pos, tc.oracle_column, tc.description,
				   tc.col_type, tc.master_column_sid, tc.enumerated_desc_field, tc.enumerated_pos_field,
				   tc.enumerated_colpos_field, tc.enumerated_hidden_field, tc.enumerated_colour_field,
				   tc.enumerated_extra_fields, tc.help, tc.check_msg, tc.default_length,
				   tc.data_default, tc.value_placeholder,
				   TAB_COL_PERM_READ_WRITE permission, -- no role based permissions in use
				   NULL policy_function, -- no policy function
				   tc.calc_xml, tc.tree_desc_field, tc.tree_id_field, tc.tree_parent_id_field,
				   tc.owner_permission, tc.incl_in_active_user_filter, tc.coverable,
				   tc.measure_sid, tc.measure_conv_column_sid, tc.measure_conv_date_column_sid, tc.auto_sequence,
				   tc.show_in_filter, tc.show_in_breakdown, tc.include_in_search,
				   tc.form_selection_desc_field, tc.form_selection_pos_field,
				   tc.form_selection_form_field, tc.form_selection_hidden_field,
				   tc.restricted_by_policy, tc.format_mask
			  FROM TABLE (in_tables) c 
			  JOIN tab t ON t.tab_sid = c.sid_id
			  JOIN tab_column tc ON t.tab_sid = tc.tab_sid AND t.app_sid = tc.app_sid;
	ELSE	
		OPEN out_col_cur FOR
			SELECT /*+ALL_ROWS*/ t.tab_sid, tc.data_type, tc.data_length, tc.data_precision, tc.data_scale, 
				   tc.nullable, tc.char_length, tc.column_sid, tc.pos, tc.oracle_column, tc.description,
				   tc.col_type, tc.master_column_sid, tc.enumerated_colour_field, tc.enumerated_desc_field,
				   tc.enumerated_pos_field, tc.enumerated_hidden_field, tc.enumerated_colpos_field,
				   tc.enumerated_extra_fields, tc.help, tc.check_msg, tc.default_length,
				   tc.data_default, tc.value_placeholder,
				   CASE WHEN p2.column_sid IS NULL THEN TAB_COL_PERM_READ_WRITE -- no role based permissions in use
						ELSE NVL(p.permission, TAB_COL_PERM_NONE) -- role based permissions, so use max granted permission or default to none
				   END permission,
				   CASE WHEN p.permission = tab_pkg.TAB_COL_PERM_READ_POLICY THEN p.policy_function
						ELSE NULL
				   END policy_function, -- only return the function if the permission type matches
				   tc.calc_xml, tc.tree_desc_field, tc.tree_id_field, tc.tree_parent_id_field,
				   tc.owner_permission, tc.incl_in_active_user_filter, tc.coverable,
				   tc.measure_sid, tc.measure_conv_column_sid, tc.measure_conv_date_column_sid, tc.auto_sequence,
				   tc.show_in_filter, tc.show_in_breakdown, tc.include_in_search,
				   tc.form_selection_desc_field, tc.form_selection_pos_field,
				   tc.form_selection_form_field, tc.form_selection_hidden_field,
				   tc.restricted_by_policy, tc.format_mask
			  FROM TABLE (in_tables) c 
			  JOIN tab t ON t.tab_sid = c.sid_id
			  JOIN tab_column tc ON t.tab_sid = tc.tab_sid AND t.app_sid = tc.app_sid
			  -- left join because calc columns don't appear in atc
			  LEFT JOIN (
					-- XXX: probable security hole here. It ignores regions, so you might be in the "medical"
					-- role for another region, different to this incident, but you'd still get to see the info.
					-- On the flip side checking regions would be hard work as we'd need to pull the flow region.
					-- (similar code to IsOwner function I guess?)
					SELECT tcrp.column_sid, MAX(tcrp.permission) permission, MAX(tcrp.policy_function) policy_function
					  FROM security.act act 
					  JOIN tab_column_role_permission tcrp ON tcrp.role_sid = act.sid_id
					  JOIN tab_column tc ON tc.column_sid = tcrp.column_sid AND tc.app_sid = tcrp.app_sid 
					  JOIN TABLE (in_tables) t ON t.sid_id = tc.tab_sid
					 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
					 GROUP BY tcrp.column_sid
				   ) p ON tc.column_sid = p.column_sid
			  LEFT JOIN (
					-- If the ACT has no column permissions, but permissions exist on the column for other roles then 
					-- the ACT will receive no permissions instead of the default Read/Write.
					SELECT column_sid, MAX(permission) permission
					  FROM cms.tab_column_role_permission
					 GROUP BY column_sid
				   ) p2 ON tc.column_sid = p2.column_sid;
	
	END IF;
	 
	-- Cached check constraints	
	OPEN out_ck_cur FOR
		SELECT ck.ck_cons_id, ck.constraint_owner, ck.constraint_name, ck.tab_sid, ck.search_condition
		  FROM ck_cons ck, TABLE (in_tables) c
		 WHERE c.sid_id = ck.tab_sid;
	OPEN out_ck_col_cur FOR
		SELECT ckc.ck_cons_id, ckc.column_sid
		  FROM ck_cons ck, ck_cons_col ckc, TABLE (in_tables) c
		 WHERE c.sid_id = ck.tab_sid AND ck.ck_cons_id = ckc.ck_cons_id;
               
	OPEN out_uk_cur FOR
		SELECT ukcc.uk_cons_id, ukc.constraint_owner, ukc.constraint_name, ukc.tab_sid, ukcc.column_sid, ukcc.pos
		  FROM uk_cons ukc, uk_cons_col ukcc, TABLE (in_tables) c
		 WHERE c.sid_id = ukc.tab_sid AND ukc.uk_cons_id = ukcc.uk_cons_id
	     ORDER BY ukcc.uk_cons_id, ukcc.pos;
	
	OPEN out_fk_cur FOR
		SELECT fkcc.fk_cons_id, fkc.constraint_owner, fkc.constraint_name, fkc.tab_sid, fkc.r_cons_id, fkc.delete_rule, fkcc.column_sid, fkcc.pos
		  FROM TABLE (in_tables) c, uk_cons ukc, fk_cons fkc, fk_cons_col fkcc
		 WHERE c.sid_id = fkc.tab_sid AND fkc.r_cons_id = ukc.uk_cons_id AND
		 	   fkc.fk_cons_id = fkcc.fk_cons_id
	  ORDER BY fkcc.fk_cons_id, fkcc.pos;

	OPEN out_flow_tab_col_cons_cur FOR
		SELECT ftcc.column_sid, ftcc.flow_state_id, ftcc.nullable
		  FROM flow_tab_column_cons ftcc, TABLE (in_tables) t, tab_column tc
		 WHERE t.sid_id = tc.tab_sid
		   AND tc.app_sid = ftcc.app_sid AND tc.column_sid = ftcc.column_sid;
	
	OPEN out_flow_state_user_col_cur FOR
		SELECT fsc.column_sid, fsc.flow_state_id, fsc.is_editable, tc.tab_sid
		  FROM csr.flow_state_cms_col fsc, TABLE (in_tables) t, tab_column tc
		 WHERE t.sid_id = tc.tab_sid
		   AND tc.app_sid = fsc.app_sid
		   AND tc.column_sid = fsc.column_sid
		 UNION
		-- Map flow state user columns to any child views that have columns
		-- of the same names, so that views of the table with the flow_item_id
		-- can respect the permissions of that table (mostly)
		SELECT tc.column_sid, fsc.flow_state_id, fsc.is_editable, tc.tab_sid
		  FROM TABLE (in_tables) c
		  JOIN tab t ON c.sid_id = t.tab_sid
		  JOIN fk_cons f ON t.tab_sid = f.tab_sid
		  JOIN uk_cons u ON f.r_cons_id = u.uk_cons_id
		  JOIN tab_column ptc ON u.tab_sid = ptc.tab_sid
		  JOIN csr.flow_state_cms_col fsc ON ptc.column_sid = fsc.column_sid
		  JOIN tab_column tc ON t.tab_sid = tc.tab_sid AND ptc.oracle_column = tc.oracle_column
		 WHERE t.is_view = 1;
		 
	-- measure details
	OPEN out_measure_cur FOR
		SELECT m.measure_sid, m.name, m.description, m.scale, m.format_mask, m.regional_aggregation,
			   m.custom_field, m.option_set_id, m.pct_ownership_applies, m.std_measure_conversion_id,
			   NVL(m.factor, smc.a) factor, NVL(m.m, sm.m) m, NVL(m.kg, sm.kg) kg, 
			   NVL(m.s, sm.s) s, NVL(m.a, sm.a) a, NVL(m.k, sm.k) k, NVL(m.mol, sm.mol) mol,
			   NVL(m.cd, sm.cd) cd, smc.description std_measure_description,
			   m.divisibility, m.lookup_key
		  FROM csr.measure m
		  LEFT JOIN csr.std_measure_conversion smc ON m.std_measure_conversion_id = smc.std_measure_conversion_id
		  LEFT JOIN csr.std_measure sm ON smc.std_measure_id = sm.std_measure_id
		  WHERE (m.measure_sid, m.app_sid) IN (
			SELECT tc.measure_sid, tc.app_sid
			  FROM TABLE (in_tables) t
			  JOIN tab_column tc ON t.sid_id = tc.tab_sid
			  WHERE tc.measure_sid IS NOT NULL
		);

	OPEN out_measure_conv_cur FOR
		SELECT mc.measure_conversion_id, mc.measure_sid, mc.std_measure_conversion_id, mc.description,
			   mc.a, mc.b, mc.c, mc.lookup_key
		  FROM csr.measure_conversion mc
		 WHERE (mc.measure_sid, mc.app_sid) IN (
			 SELECT tc.measure_sid, tc.app_sid
         FROM TABLE (in_tables) t, tab_column tc
			  WHERE t.sid_id = tc.tab_sid
			    AND tc.measure_sid IS NOT NULL
			);
		   
	OPEN out_measure_conv_period_cur FOR
		SELECT mcp.measure_conversion_id, mcp.start_dtm, mcp.end_dtm, mcp.a, mcp.b, mcp.c
		  FROM TABLE (in_tables) t, tab_column tc, csr.measure m, csr.measure_conversion mc,
		  	   csr.measure_conversion_period mcp
		 WHERE t.sid_id = tc.tab_sid
		   AND tc.app_sid = m.app_sid AND tc.measure_sid = m.measure_sid
		   AND m.app_sid = mc.app_sid AND m.measure_sid = mc.measure_sid
		   AND mc.app_sid = mcp.app_sid AND mc.measure_conversion_id = mcp.measure_conversion_id;		   
END;

PROCEDURE GetTableDefinition(
	in_tab_sid						IN	security_pkg.T_SID_ID,
	out_tab_cur						OUT	SYS_REFCURSOR,
	out_col_cur						OUT	SYS_REFCURSOR,
	out_ck_cur						OUT	SYS_REFCURSOR,
	out_ck_col_cur					OUT	SYS_REFCURSOR,
	out_uk_cur						OUT	SYS_REFCURSOR,
	out_fk_cur						OUT	SYS_REFCURSOR,
	out_flow_tab_col_cons_cur		OUT	SYS_REFCURSOR,
	out_flow_state_user_col_cur		OUT	SYS_REFCURSOR,
	out_measure_cur 				OUT	SYS_REFCURSOR,
	out_measure_conv_cur 			OUT	SYS_REFCURSOR,
	out_measure_conv_period_cur		OUT SYS_REFCURSOR
)
AS
	v_act_id					security_pkg.T_ACT_ID;
	v_tables					security.T_SO_TABLE;
BEGIN
	v_act_id := security_pkg.GetACT();
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_tab_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the table with SID '||in_tab_sid);
	END IF;
	
	v_tables := security.T_SO_TABLE();
	v_tables.extend(1);
	v_tables(1) := security.T_SO_ROW(in_tab_sid, null, null, null, null, null, null);
	GetTableDefinitions_(v_tables, out_tab_cur, out_col_cur, out_ck_cur, out_ck_col_cur, out_uk_cur, out_fk_cur,
		out_flow_tab_col_cons_cur, out_flow_state_user_col_cur, out_measure_cur, out_measure_conv_cur,
		out_measure_conv_period_cur);
END;

PROCEDURE GetTableDefinitions(
	out_tab_cur						OUT	SYS_REFCURSOR,
	out_col_cur						OUT	SYS_REFCURSOR,
	out_ck_cur						OUT	SYS_REFCURSOR,
	out_ck_col_cur					OUT	SYS_REFCURSOR,
	out_uk_cur						OUT	SYS_REFCURSOR,
	out_fk_cur						OUT	SYS_REFCURSOR,
	out_flow_tab_col_cons_cur		OUT	SYS_REFCURSOR,
	out_flow_state_user_col_cur		OUT	SYS_REFCURSOR,
	out_measure_cur 				OUT	SYS_REFCURSOR,
	out_measure_conv_cur 			OUT	SYS_REFCURSOR,
	out_measure_conv_period_cur		OUT SYS_REFCURSOR
)
AS
	v_act_id	security_pkg.T_ACT_ID DEFAULT security_pkg.GetACT();
	v_cms_sid	security_pkg.T_SID_ID;
	v_tables	security.T_SO_TABLE;
BEGIN
	-- Get the cms container
	BEGIN
		v_cms_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			SecurableObject_pkg.CreateSO(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), class_pkg.GetClassId('CmsContainer'), 'cms', v_cms_sid);
	END;
	
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_cms_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the schema with SID '||v_cms_sid);
	END IF;
	
	v_tables := SecurableObject_pkg.GetChildrenWithPermAsTable(v_act_id, v_cms_sid, security_pkg.PERMISSION_READ);
	GetTableDefinitions_(v_tables, out_tab_cur, out_col_cur, out_ck_cur, out_ck_col_cur, out_uk_cur, out_fk_cur,
		out_flow_tab_col_cons_cur, out_flow_state_user_col_cur, out_measure_cur, out_measure_conv_cur,
		out_measure_conv_period_cur);
END;

PROCEDURE GetTables(
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_act_id	security_pkg.T_ACT_ID DEFAULT security_pkg.GetACT();
	v_tab_class	security_pkg.T_CLASS_ID;
	v_cms_sid	security_pkg.T_SID_ID;
BEGIN
	-- Get the cms container
	BEGIN
		v_cms_sid := SecurableObject_pkg.GetSIDFromPath(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 'cms');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			SecurableObject_pkg.CreateSO(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), class_pkg.GetClassId('CmsContainer'), 'cms', v_cms_sid);
	END;
	
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_cms_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the schema with SID '||v_cms_sid);
	END IF;

	v_tab_class := class_pkg.GetClassID('CMSTable');
	OPEN out_cur FOR
		SELECT t.tab_sid, t.oracle_schema, t.oracle_table, t.description, t.format_sql, t.cms_editor, t.issues
		  FROM tab t,
		  	   TABLE (SecurableObject_pkg.GetChildrenWithPermAsTable(v_act_id, v_cms_sid, security_pkg.PERMISSION_READ) ) c
		 WHERE t.tab_sid = c.sid_id AND c.class_id = v_tab_class
  	  ORDER BY c.sid_id;
END;

PROCEDURE GetDetails(
	in_tab_sid					IN	tab.tab_sid%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_act_id			security_pkg.T_ACT_ID;
BEGIN
	v_act_id := security_pkg.GetACT();
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_tab_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the table with SID '||in_tab_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT tab_sid, app_sid, oracle_schema, oracle_table, description, format_sql, pk_cons_id, 
			   managed, auto_registered, cms_editor, issues
		  FROM tab
		 WHERE tab_sid = in_tab_sid;
END;

PROCEDURE GoToContextIfExists(
	in_context_id				IN	security_pkg.T_SID_ID
)
AS
	v_count 					NUMBER(10);
	v_context_id				security_pkg.T_SID_ID;
BEGIN
	SELECT COUNT (*)
	  INTO v_count
	  FROM fast_context
 	 WHERE context_id = in_context_id 
 	   AND parent_context_id = in_context_id;
	
	v_context_id := in_context_id;	
	IF v_count = 0 THEN
		v_context_id := 0;
	END IF;
	
	GoToContext(v_context_id);
END;

PROCEDURE GoToContext(
	in_context_id				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	security_pkg.GoToContext(in_context_id);
END;

PROCEDURE PublishItem(
	in_from_context				IN	context.context_id%TYPE,
	in_to_context				IN	context.context_id%TYPE,
	in_tab_sid					IN	tab.tab_sid%TYPE,
	in_item_id					IN	security_pkg.T_SID_ID
)
AS
	v_table_name		tab.oracle_table%TYPE;
	v_owner				tab.oracle_schema%TYPE;
	v_count				NUMBER(10);
BEGIN	
	SELECT COUNT (*)
	  INTO v_count
	  FROM fast_context
	 WHERE context_id = in_from_context 
       AND parent_context_id = in_to_context;
       
    IF v_count = 0 THEN
    	RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Cannot publish from context '|| in_from_context || ' to context ' || in_to_context);    
    END IF;
	
	BEGIN
		SELECT t.oracle_schema, t.oracle_table
		  INTO v_owner, v_table_name
		  FROM tab t
		 WHERE t.tab_sid = in_tab_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The item with id '||in_item_id||' could not be found');
	END;
	EXECUTE IMMEDIATE
		'begin '||q(v_owner)||'.'||q('T$'||v_table_name)||'.p(:1,:2,:3); end;'
	USING
		in_from_context, in_to_context, in_item_id;
		
	DELETE FROM link_track
	 WHERE item_id = in_item_id
	   AND context_id IN (SELECT parent_context_id
	                        FROM context
	                       WHERE context_id <> in_to_context
	                  CONNECT BY PRIOR parent_context_id = context_id
	                  START WITH context_id = in_from_context);

	UPDATE link_track
	   SET context_id = in_to_context
	 WHERE item_id = in_item_id
	   AND context_id = in_from_context;
END;

PROCEDURE SearchContent(
	in_tab_sids					IN	security_pkg.T_SID_IDS,
	in_part_description			IN  varchar2,
	in_item_ids					IN  security_pkg.T_SID_IDS,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_sql 						VARCHAR2(32767);
	v_tab_sids 					security.T_SID_TABLE;
	v_tab_sid_count				NUMBER(10);
	v_item_ids					security.T_SID_TABLE;
	v_item_id_count				NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the application with SID '||SYS_CONTEXT('SECURITY', 'APP'));
	END IF;	
	
	v_tab_sids := security_pkg.SidArrayToTable(in_tab_sids);
	v_tab_sid_count := v_tab_sids.COUNT;
	
	v_item_ids := security_pkg.SidArrayToTable(in_item_ids);
	v_item_id_count := v_item_ids.COUNT;
	
	v_sql := 
		'   SELECT t.tab_sid, t.oracle_schema, t.oracle_table, t.description tab_description,'||chr(10)||
		'          id.item_id, id.description, id.locked_by, u.full_name locked_by_name, fc.CONTEXT_ID can_steal' ||chr(10)||
		'     FROM tab t, cms.item_description_'||SYS_CONTEXT('SECURITY', 'APP')||' id, cms_user u, fast_context fc' ||chr(10)||
		'    WHERE id.tab_sid = t.tab_sid'||chr(10)||
		'      AND u.user_sid(+) = id.locked_by' ||chr(10)||
		'      AND fc.context_id(+) = NVL(SYS_CONTEXT(''SECURITY'',''CONTEXT_ID''), 0)' ||chr(10)||
		'      AND fc.parent_context_id(+) = id.locked_by' ||chr(10)||
		'      AND LOWER(id.description) like LOWER(''%''||:1||''%'')'||chr(10)||
		'      AND (0 = :2 OR t.tab_sid IN (SELECT * FROM TABLE(:3)))'||chr(10)||
		'      AND (0 = :4 OR id.item_id IN (SELECT * FROM TABLE(:5)))'||chr(10);

	OPEN out_cur FOR v_sql
	USING in_part_description, v_tab_sid_count, v_tab_sids, v_item_id_count, v_item_ids;
END;

PROCEDURE GetAppDisplayTemplates(
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission is denied on the application with SID '||SYS_CONTEXT('SECURITY', 'APP'));
	END IF;
	
	OPEN out_cur FOR
		SELECT dt.display_template_id, dt.tab_sid, dt.template_url, dt.priority, dt.name, dt.description, dt.app_sid
		  FROM tab t, display_template dt
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.tab_sid = dt.tab_sid;
END;

PROCEDURE EnsureContextExists(
	in_context					IN	context.context_id%TYPE
)
AS
	v_count						number(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM context
	 WHERE context_id = in_context;

	IF v_count = 0 THEN
		INSERT INTO context (context_id, parent_context_id)
		VALUES (in_context, 0);

		INSERT INTO fast_context (context_id, parent_context_id)
		VALUES (in_context, 0);

		INSERT INTO fast_context (context_id, parent_context_id)
		VALUES (in_context, in_context);
	END IF;
END;

PROCEDURE GetItemsBeingTracked(
	in_path						IN  link_track.path%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_path						link_track.path%TYPE;
BEGIN
	IF SUBSTR(in_path, LENGTH(in_path), 1) = '/' THEN
		v_path := SUBSTR(in_path, 1, LENGTH(in_path) - 1);
	ELSE
		v_path := in_path;
	END IF;

	OPEN out_cur FOR
		'SELECT lt.item_id, lt.context_id, lt.column_sid, lt.path, id.description, cu.full_name'||chr(10)||
		'  FROM link_track lt, item_description_'||SYS_CONTEXT('SECURITY', 'APP')||' id, cms_user cu'||chr(10)||
		' WHERE (LOWER (lt.path) LIKE LOWER (:1||''/%'')'||chr(10)||
		'        OR LOWER (lt.path) = LOWER (:2))'||chr(10)||
		'   AND id.item_id(+) = lt.item_id'||chr(10)|| -- hmm, foul. try to think of something better than item_description here.
		'   AND cu.user_sid(+) = lt.context_id'||chr(10)||
		' ORDER BY context_id'
	USING v_path, v_path;		
END;

PROCEDURE GetUserContent(
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		'SELECT id.* '||
		'  FROM tab t, item_description_'||SYS_CONTEXT('SECURITY', 'APP')||' id '||
		' WHERE id.locked_by = :1 '||
		'   AND t.tab_sid = id.tab_sid '||
		' ORDER BY t.oracle_table'
	USING security_pkg.getsid();
END;

PROCEDURE GetFlowSidFromLabel(
	in_flow_label					IN	csr.flow.label%TYPE,
	out_flow_sid					OUT	csr.flow.flow_sid%TYPE
)
AS
	v_act_id			 	security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
	v_workflows_sid		 	security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT flow_sid
		  INTO out_flow_sid
		  FROM csr.flow
		 WHERE label = in_flow_label;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'The workflow with label '||in_flow_label||' could not be found');
		WHEN TOO_MANY_ROWS THEN
			--let the SO decide
			BEGIN
				v_workflows_sid	:= securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.getApp,  'Workflows');
				out_flow_sid 	:= securableobject_pkg.GetSIDFromPath(v_act_id, v_workflows_sid, in_flow_label);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'No active workflow found with label '||in_flow_label);
			END;
	END;
	
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), out_flow_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the flow '||in_flow_label||' with sid '||out_flow_sid);
	END IF;
END;

PROCEDURE GetFlowRegions(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_flow_region_selector			IN	NUMBER,
	in_phrase						IN  VARCHAR2,
	in_root_lookup_key				IN  VARCHAR2,
	in_tag_lookup_keys				IN  VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_flow_sid						csr.flow.flow_sid%TYPE;
	v_and_count						NUMBER;
	v_or_count						NUMBER;
	v_use_and						NUMBER := 0;
BEGIN
	
	GetFlowSidFromLabel(in_flow_label, v_flow_sid);
	
	SELECT COUNT(*)
	  INTO v_and_count 
	  FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_tag_lookup_keys,'+')); 

	SELECT COUNT(*)
	  INTO v_or_count 
	  FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_tag_lookup_keys,',')); 
	  
	IF v_and_count > 1 AND v_or_count = 1 THEN
		v_use_and := 1;
	END IF;
	
	-- This has security based on user sid
	OPEN out_cur FOR
		SELECT r.region_sid, r.description, r.active, r.geo_country
		  FROM csr.v$region r
		 WHERE (r.app_sid, r.region_sid) IN (
				SELECT rrm.app_sid, rrm.region_sid
				  FROM csr.flow f, csr.flow_state fs, csr.flow_state_role fsr, csr.region_role_member rrm, csr.region r
				 WHERE f.flow_sid = v_flow_sid
				   AND f.app_sid = fs.app_sid AND f.default_state_id = fs.flow_state_id
				   AND fs.app_sid = fsr.app_sid AND fs.flow_state_id = fsr.flow_state_id
				   AND fsr.app_sid = rrm.app_sid AND fsr.role_sid = rrm.role_sid
				   AND rrm.app_sid = r.app_sid AND rrm.region_sid = r.region_sid
				   AND (
						in_flow_region_selector = tab_pkg.FLOW_REGIONS_ALL 
						OR (in_flow_region_selector = tab_pkg.FLOW_REGIONS_PROPERTIES AND r.region_type = csr.csr_data_pkg.REGION_TYPE_PROPERTY) 
						OR (in_flow_region_selector = tab_pkg.FLOW_REGIONS_ROOTS AND rrm.region_Sid = rrm.inherited_from_sid)
					)
				   AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
				UNION
				SELECT app_sid, region_sid
				  FROM (
					SELECT *
					  FROM csr.region
					 WHERE EXISTS (
						SELECT act.act_id
						  FROM csr.flow f
						  JOIN csr.flow_state fs ON fs.app_sid = f.app_sid AND f.default_state_id = fs.flow_state_id
						  JOIN csr.flow_state_role fsr ON fs.app_sid = fsr.app_sid AND fs.flow_state_id = fsr.flow_state_id
						  JOIN security.act act ON act.sid_id = fsr.group_sid 
						 WHERE act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
						   AND f.flow_sid = v_flow_sid
						)
						AND (
							in_flow_region_selector = tab_pkg.FLOW_REGIONS_ALL 
							OR in_flow_region_selector = tab_pkg.FLOW_REGIONS_ROOTS 
							OR (in_flow_region_selector = tab_pkg.FLOW_REGIONS_PROPERTIES AND region_type = csr.csr_data_pkg.REGION_TYPE_PROPERTY) 
						)
					) START WITH region_sid IN (SELECT region_sid FROM csr.region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY','SID'))
				  CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid 
		 		)
		   AND (in_phrase IS NULL OR LOWER(r.description) LIKE LOWER(in_phrase||'%'))
		   AND (in_root_lookup_key IS NULL OR (r.app_sid, r.region_sid) IN (
				SELECT app_sid, region_sid
				  FROM csr.region
				 START WITH lookup_key = in_root_lookup_key
				CONNECT BY PRIOR region_sid = parent_sid
		   ))
		   AND (in_tag_lookup_keys IS NULL OR v_use_and = 1 OR ( EXISTS (
				SELECT NULL
				  FROM csr.region_tag rt
				  JOIN csr.tag t ON rt.tag_id = t.tag_id	
				  JOIN TABLE(CSR.UTILS_PKG.SPLITSTRING(in_tag_lookup_keys,',')) tt ON tt.item = t.lookup_key
				 WHERE rt.app_sid = r.app_sid AND rt.region_sid = r.region_sid
				 GROUP BY rt.app_sid, rt.region_sid
		   )))
		   AND (in_tag_lookup_keys IS NULL OR v_use_and = 0 OR( EXISTS (
				SELECT NULL
				  FROM csr.region_tag rt
				  JOIN csr.tag t ON rt.tag_id = t.tag_id	
				  JOIN TABLE(CSR.UTILS_PKG.SPLITSTRING(in_tag_lookup_keys,'+')) tt ON tt.item = t.lookup_key
				 WHERE rt.app_sid = r.app_sid AND rt.region_sid = r.region_sid
				 GROUP BY rt.app_sid, rt.region_sid
				HAVING COUNT(*) = v_and_count
		   )))
		   AND r.region_sid NOT IN ( SELECT region_sid FROM csr.v$region
									START WITH parent_sid = (SELECT trash_sid FROM csr.customer WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')) 
									CONNECT BY PRIOR region_sid = parent_sid AND PRIOR app_sid = app_sid)
		 ORDER BY r.description;
END;

PROCEDURE GetFlowItemRegions(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- This has security based on user sid
	OPEN out_cur FOR
		SELECT region_sid, description
		  FROM csr.v$region
		 WHERE (app_sid, region_sid) IN (	
		 		SELECT rrm.app_sid, rrm.region_sid
				  FROM csr.flow_item fi, csr.flow_state fs, csr.flow_state_role fsr, csr.region_role_member rrm
				 WHERE fi.flow_item_id = in_flow_item_id
				   AND fi.app_sid = fs.app_sid AND fi.current_state_id = fs.flow_state_id
				   AND fs.app_sid = fsr.app_sid AND fs.flow_state_id = fsr.flow_state_id
				   AND fsr.app_sid = rrm.app_sid AND fsr.role_sid = rrm.role_sid
				   AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID'));
END;

PROCEDURE GetCurrentFlowState(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_flow_sid						csr.flow.flow_sid%TYPE;
BEGIN
	SELECT flow_sid
	  INTO v_flow_sid
	  FROM csr.flow_item
	 WHERE flow_item_id = in_flow_item_id;
	 
	IF NOT security.security_pkg.IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), v_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the workflow with sid '||v_flow_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT fs.flow_state_id, fs.flow_sid, fs.label, fs.lookup_key, fs.attributes_xml, fs.is_deleted
		  FROM csr.flow_state fs, csr.flow_item fi
		 WHERE fi.flow_item_id = in_flow_item_id
		   AND fi.current_state_id = fs.flow_state_id;
END;

PROCEDURE GetDefaultFlowState(
	in_tab_sid						IN	tab.tab_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_flow_sid						csr.flow.flow_sid%TYPE;
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), in_tab_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the table with sid '||in_tab_sid);
	END IF;
	
	SELECT flow_sid
	  INTO v_flow_sid
	  FROM tab
	 WHERE tab_sid = in_tab_sid;
	IF v_flow_sid IS NULL THEN
		OPEN out_cur FOR
			SELECT null flow_state_id, null flow_sid, null label, null lookup_key, null attributes_xml, null is_deleted
			  FROM dual
			 WHERE 1 = 0;
		RETURN;
	END IF;
	   
	IF NOT security.security_pkg.IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), v_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the workflow with sid '||v_flow_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT fs.flow_state_id, fs.flow_sid, fs.label, fs.lookup_key, fs.attributes_xml, fs.is_deleted
		  FROM csr.flow_state fs, csr.flow f
		 WHERE f.flow_sid = v_flow_sid
		   AND fs.flow_state_id = f.default_state_id;
END;

PROCEDURE GetFlowTransitions(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_region_sids				security_pkg.T_SID_IDS;
BEGIN
	SELECT in_region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM DUAL;
	  
	GetFlowTransitions(in_flow_label, v_region_sids, out_cur);
END;
	
PROCEDURE GetFlowTransitions(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_flow_sid						csr.flow.flow_sid%TYPE;
	v_regions_table					security.T_SID_TABLE;
	v_regions_exist					NUMBER := CASE WHEN in_region_sids IS NOT NULL AND in_region_sids.COUNT > 0 AND in_region_sids(1) IS NOT NULL THEN 1 ELSE 0 END;
BEGIN
	GetFlowSidFromLabel(in_flow_label, v_flow_sid);
	
	IF in_region_sids IS NULL OR (in_region_sids.COUNT = 1 AND in_region_sids(1) IS NULL) THEN
		v_regions_table := security.T_SID_TABLE();
	ELSE
		v_regions_table	:= security_pkg.SidArrayToTable(in_region_sids);
	END IF;
	
	-- This has security based on user sid
	--
	-- If owner_can_set then we assume that the owner is the person who will create this row (this
	-- SP is just called pre insertion when we don't have a flow_item_id). This is generally the
	-- case although I can see the case where this might not be set via a trigger but is some drop
	-- down used for allocating the 'owner' user. This approach wouldn't work in this situation. The
	-- javascript would need to be patched up to figure out if the user was the owner based on the 
	-- current dropdown value and then pass this through. For now (and for Vestas!) this will do.
	OPEN out_cur FOR
		SELECT flow_state_transition_id, from_state_id, to_state_id, flow_sid, verb, ask_for_comment, 
			   pos, attributes_xml, helper_sp, lookup_key, mandatory_fields_message, button_icon_path
		  FROM csr.flow_state_transition
		 WHERE (app_sid, flow_state_transition_id) IN ( -- IN because you can be in more than one role
		 		SELECT fst.app_sid, fst.flow_state_transition_id
		 		  FROM csr.flow f, csr.flow_state_transition fst, csr.flow_state_transition_role fstr, csr.region_role_member rrm, TABLE (CAST (v_regions_table AS security.T_SID_TABLE)) rs
				 WHERE f.flow_sid = v_flow_sid
				   AND f.app_sid = fst.app_sid AND f.default_state_id = fst.from_state_id
				   AND fst.app_sid = fstr.app_sid AND fst.flow_state_transition_id = fstr.flow_state_transition_id
				   AND fstr.app_sid = rrm.app_sid AND fstr.role_sid = rrm.role_sid
				   AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
				   AND rrm.region_sid = rs.column_value
				   AND fstr.role_sid IS NOT NULL
				 UNION
				SELECT fst.app_sid, fst.flow_state_transition_id
		 		  FROM csr.flow f
		 		  JOIN csr.flow_state_transition fst ON f.app_sid = fst.app_sid AND f.default_state_id = fst.from_state_id AND owner_can_set = 1
		 		 WHERE f.flow_sid = v_flow_sid
				 UNION
				SELECT fst.app_sid, fst.flow_state_transition_id
		 		  FROM csr.flow f
		 		  JOIN csr.flow_state_transition fst ON f.app_sid = fst.app_sid AND f.default_state_id = fst.from_state_id 
				  JOIN security.act act ON act.sid_id = fst.group_sid_can_set
		 		 WHERE f.flow_sid = v_flow_sid
				   AND act.act_id = sys_context('SECURITY', 'ACT')
				 UNION
				SELECT fst.app_sid, fst.flow_state_transition_id
				  FROM csr.flow f
		 		  JOIN csr.flow_state_transition fst ON f.app_sid = fst.app_sid AND f.default_state_id = fst.from_state_id 
				  JOIN csr.flow_state_transition_role fstr ON fstr.app_sid = fst.app_sid AND fst.flow_state_transition_id = fstr.flow_state_transition_id
				  JOIN security.act ON act.sid_id = fstr.group_sid OR (v_regions_exist = 0 AND act.sid_id = fstr.role_sid)	--if there is no flow region then also treat the role as a group.
				 WHERE f.flow_sid = v_flow_sid AND act.act_id = sys_context('SECURITY', 'ACT')
		);
END;

PROCEDURE GetFlowItemTransitions(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	in_is_owner						IN 	csr.flow_state_transition.owner_can_set%TYPE DEFAULT 0,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_region_sids				security_pkg.T_SID_IDS;
BEGIN
	SELECT in_region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM DUAL;
	  
	GetFlowItemTransitions(in_flow_item_id, v_region_sids, in_is_owner, out_cur);
END;

PROCEDURE GetFlowItemTransitions(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_is_owner						IN 	csr.flow_state_transition.owner_can_set%TYPE DEFAULT 0,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_regions_table					security.T_SID_TABLE;
	v_user_flow_trans_ids			security.T_SID_TABLE;
	v_regions_exist					NUMBER := CASE WHEN in_region_sids IS NOT NULL AND in_region_sids.COUNT > 0 AND in_region_sids(1) IS NOT NULL THEN 1 ELSE 0 END;
BEGIN
	v_regions_table	:= security_pkg.SidArrayToTable(in_region_sids);
	v_user_flow_trans_ids := GetUserFlowItemTransitions(in_flow_item_id, in_region_sids);

	-- This has security based on user sid
	OPEN out_cur FOR
		SELECT flow_state_transition_id, from_state_id, to_state_id, flow_sid, verb, ask_for_comment, 
			   pos, attributes_xml, helper_sp, lookup_key, mandatory_fields_message, button_icon_path
		  FROM csr.flow_state_transition
		 WHERE (app_sid, flow_state_transition_id) IN ( -- IN because you can be in more than one role/group - XXX: could this be combined into a single select with left joins (or is the rrm too much of a nightmare)?
		 		SELECT fst.app_sid, fst.flow_state_transition_id
		 		  FROM csr.flow_item fi
		 		  JOIN csr.flow_state_transition fst ON fi.app_sid = fst.app_sid AND fi.current_state_id = fst.from_state_id
		 		  JOIN csr.flow_state_transition_role fstr ON fst.app_sid = fstr.app_sid AND fst.flow_state_transition_id = fstr.flow_state_transition_id
		 		  JOIN csr.region_role_member rrm ON fstr.app_sid = rrm.app_sid AND fstr.role_sid = rrm.role_sid 
		 		  	AND rrm.user_sid = SYS_CONTEXT('SECURITY','SID') 
				  JOIN TABLE (v_regions_table) rs
		 		  	ON rrm.region_sid = rs.column_value
				 WHERE fi.flow_item_id = in_flow_item_id
				 UNION
				SELECT fst.app_sid, fst.flow_state_transition_id
		 		  FROM csr.flow_item fi
		 		  JOIN csr.flow_state_transition fst ON fi.app_sid = fst.app_sid AND fi.current_state_id = fst.from_state_id 
		 		   AND owner_can_set = 1 AND in_is_owner = 1
				 WHERE fi.flow_item_id = in_flow_item_id
				 UNION
				SELECT CAST(SYS_CONTEXT('SECURITY','APP') AS NUMBER(10)), column_value
				  FROM TABLE(v_user_flow_trans_ids)
				 UNION 
				SELECT fst.app_sid, fst.flow_state_transition_id
				  FROM csr.flow_item fi
		 		  JOIN csr.flow_state_transition fst ON fi.app_sid = fst.app_sid AND fi.current_state_id = fst.from_state_id
				  JOIN csr.flow_state_transition_role fstr ON fstr.app_sid = fst.app_sid AND fst.flow_state_transition_id = fstr.flow_state_transition_id
				  JOIN security.act ON act.sid_id = fstr.group_sid OR (v_regions_exist = 0 AND act.sid_id = fstr.role_sid)	--if there is no flow region then also treat the role as a group.
				 WHERE fi.flow_item_id = in_flow_item_id 
				 AND act.act_id = sys_context('SECURITY', 'ACT')
			)
		 ORDER BY pos;
END;

PROCEDURE EnterFlow(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	out_flow_item_id				OUT	csr.flow_item.flow_item_id%TYPE
)
AS
	v_flow_sid						csr.flow.flow_sid%TYPE;
BEGIN
	GetFlowSidFromLabel(in_flow_label, v_flow_sid);
	csr.flow_pkg.AddCmsItem(v_flow_sid, in_region_sid, out_flow_item_id);	
END;

PROCEDURE EnterFlow(
	in_flow_label					IN	csr.flow.label%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_flow_item_id				OUT	csr.flow_item.flow_item_id%TYPE
)
AS
	v_flow_sid						csr.flow.flow_sid%TYPE;
BEGIN
	GetFlowSidFromLabel(in_flow_label, v_flow_sid);
	csr.flow_pkg.AddCmsItem(v_flow_sid, in_region_sids, out_flow_item_id);	
END;


-- we have to check after insertion too in the situation where we're using owner users.
-- The C# calls this.
PROCEDURE CheckFlowEntry(
	in_tab_sid				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
	v_region_sids				security_pkg.T_SID_IDS;
BEGIN
	SELECT in_region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM DUAL;
	
	CheckFlowEntry(in_tab_sid, in_flow_item_id, v_region_sids);
END;

PROCEDURE CheckFlowEntry(
	in_tab_sid				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sids			IN	security_pkg.T_SID_IDS
)
AS
	v_flow_sid				security_pkg.T_SID_ID;
	v_flow_state_id			csr.flow_state.flow_state_id%TYPE;
BEGIN	
	SELECT flow_sid, current_state_id
	  INTO v_flow_sid, v_flow_state_id
	  FROM csr.flow_item
	 WHERE flow_item_Id = in_flow_item_id;
	 
	IF tab_pkg.IsOwner(in_tab_sid, in_flow_item_id) = 0 AND
		csr.flow_pkg.CanSeeDefaultState(v_flow_sid, in_region_sids) = 0 AND
		GetAccessLevelForState(in_tab_sid, in_flow_item_id, v_flow_state_id, in_region_sids) = 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 
			'The user with sid '||SYS_CONTEXT('SECURITY', 'SID')||' is not the owner of flow item with id '||in_flow_item_id||'.');
	END IF;
END;

FUNCTION INTERNAL_IsColumnNull(
	in_column_sid 			IN   tab_column.column_sid%TYPE,
	in_flow_item_id			IN   csr.flow_item.flow_item_id%TYPE
) RETURN BOOLEAN
AS
	CURSOR c_tab IS 
        SELECT t.tab_sid, t.oracle_schema, t.oracle_table, tc.oracle_column
          FROM tab_column tc
		  JOIN tab t
		    ON tc.tab_sid = t.tab_sid
         WHERE tc.column_sid = in_column_sid;
    r_tab   c_tab%ROWTYPE;
    v_sql							VARCHAR(4000); -- should be big enough
	v_out_cur						SYS_REFCURSOR;
	v_flow_item_id_column_name 	 	tab_column.oracle_column%TYPE;
	v_cnt 							NUMBER(10);
BEGIN
	-- security not required - internal function
	OPEN c_tab;
    FETCH c_tab INTO r_tab;
    CLOSE c_tab;
	
	SELECT oracle_column
	  INTO v_flow_item_id_column_name
	  FROM tab_column
	 WHERE tab_sid = r_tab.tab_sid
	   AND col_type = tab_pkg.CT_FLOW_ITEM;

    -- write SQL statement to pull the row and check if a value is set
	v_sql := 'SELECT COUNT(*) cnt FROM '||q(r_tab.oracle_schema)||'.'||q(r_tab.oracle_table)
		|| ' WHERE '||q(v_flow_item_id_column_name)||' = '||in_flow_item_id||' AND '||q(r_tab.oracle_column)||' IS NULL';

	OPEN v_out_cur FOR v_sql;
	FETCH v_out_cur INTO v_cnt;
	CLOSE v_out_cur;

	RETURN v_cnt = 1;
END;

PROCEDURE CheckFlowStateEntry(
	in_tab_sid				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	in_to_flow_state_id		IN  csr.flow_state.flow_state_id%TYPE
)
AS
	v_flow_state_label	 	csr.flow_state.label%TYPE;
BEGIN
	FOR r IN (
		SELECT column_sid
		  FROM flow_tab_column_cons
		 WHERE flow_state_id = in_to_flow_state_id
		   AND nullable = 0
	) LOOP
		-- for each mandatory column, check that it is set.
		-- XXX: if performance becomes an issue, just bung this into one dynamic check with OR's 
		-- instead of checking each column individually.
		IF INTERNAL_IsColumnNull(r.column_sid, in_flow_item_id) THEN
			SELECT label
			  INTO v_flow_state_label
			  FROM csr.flow_state
			 WHERE flow_state_id = in_to_flow_state_id;
		
			RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_FLOW_STATE_CHANGE_FAILED, 'To enter the state '''||v_flow_state_label||''' additional mandatory fields must be completed');
		END IF;
	END LOOP;
END;

FUNCTION CloneFlowItem(
	in_flow_item_id				IN  csr.flow_item.flow_item_id%TYPE
) RETURN csr.flow_item.flow_item_id%TYPE
AS
	v_flow_item_id			csr.flow_item.flow_item_id%TYPE;
	v_flow_state_log_id		csr.flow_state_log.flow_state_log_id%TYPE;
BEGIN
	SELECT csr.flow_item_id_seq.NEXTVAL
	  INTO v_flow_item_id
	  FROM DUAL;

	INSERT INTO csr.flow_item
		(flow_item_id, flow_sid, current_state_id)
		SELECT v_flow_item_id, flow_sid, current_state_id
		  FROM csr.flow_item
		 WHERE flow_item_id = in_flow_item_id;

	v_flow_state_log_id := csr.flow_pkg.AddToLog(in_flow_item_id => v_flow_item_id);
	
	RETURN v_flow_item_id;
END;

FUNCTION GetFlowItemEditable(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	in_tab_sid 						IN  security_pkg.T_SID_ID DEFAULT NULL
) RETURN csr.flow_state_role.is_editable%TYPE
AS
	v_is_editable				csr.flow_state_role.is_editable%TYPE;
BEGIN
	GetFlowItemEditable(in_flow_item_id, in_region_sid, in_tab_sid, v_is_editable);
	RETURN v_is_editable;
END;

PROCEDURE GetFlowItemEditable(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sid					IN	csr.region.region_sid%TYPE,
	in_tab_sid 						IN  security_pkg.T_SID_ID DEFAULT NULL,
	out_editable					OUT	csr.flow_state_role.is_editable%TYPE
)
AS
	v_region_sids				security_pkg.T_SID_IDS;
BEGIN
	SELECT in_region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM DUAL;
	  
	GetFlowItemEditable(in_flow_item_id, v_region_sids, in_tab_sid, out_editable);
END;

PROCEDURE GetFlowItemEditable(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_tab_sid 						IN  security_pkg.T_SID_ID DEFAULT NULL,
	out_editable					OUT	csr.flow_state_role.is_editable%TYPE
)
AS
	v_is_editable_by_owner   		csr.flow_state.is_editable_by_owner%TYPE;
	v_regions_table					security.T_SID_TABLE;
	v_flow_state_id					csr.flow_state.flow_state_id%TYPE;
BEGIN
	v_regions_table	:= security_pkg.SidArrayToTable(in_region_sids);
	
	SELECT NVL(MAX(fsrg.is_editable), 0) -- if it's editable in any role, then you can edit it, e.g. if an admin and a data provider
	  INTO out_editable
	  FROM csr.flow_item fi
	  JOIN (
		SELECT fsr.flow_state_id, fsr.app_sid, fsr.is_editable
		  FROM csr.flow_state_role fsr
		  JOIN csr.region_role_member rrm ON fsr.app_sid = rrm.app_sid AND fsr.role_sid = rrm.role_sid AND SYS_CONTEXT('SECURITY','SID') = rrm.user_sid
		  JOIN TABLE(CAST (v_regions_table AS security.T_SID_TABLE)) rs ON rrm.region_sid = rs.column_value
		 UNION 
		SELECT fsr.flow_state_id, fsr.app_sid, fsr.is_editable
		  FROM csr.flow_state_role fsr
		  JOIN security.act ON act.sid_id = fsr.group_sid AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
		) fsrg ON fsrg.flow_state_id = fi.current_state_id AND fsrg.app_sid = SYS_CONTEXT('SECURITY','APP')
	 WHERE fi.flow_item_id = in_flow_item_id;

	IF out_editable = 0 AND in_tab_sid IS NOT NULL THEN
		SELECT fs.is_editable_by_owner, fi.current_state_id
		  INTO v_is_editable_by_owner, v_flow_state_id
		  FROM csr.flow_item fi
		  JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id
		 WHERE flow_item_id = in_flow_item_id;
		-- do some further checks
		IF tab_pkg.IsOwner(in_tab_sid, in_flow_item_id) = 1 AND v_is_editable_by_owner = 1 THEN
			out_editable := 1;
		END IF;
	END IF;
	
	IF out_editable = 0 AND GetAccessLevelForState(in_tab_sid, in_flow_item_id, v_flow_state_id, in_region_sids) = 2 THEN
		-- check if the current user is in the list of CMS user columns for the current state
		out_editable := 1;
	END IF;
END;

FUNCTION CanSetDefaultStateTrans(
	in_flow_sid				IN	csr.flow.flow_sid%TYPE
)RETURN NUMBER
AS
	v_count			NUMBER;
BEGIN

	SELECT DECODE(COUNT(*), 0, 0, 1)
	  INTO v_count
	  FROM csr.flow f
	  JOIN csr.flow_state_transition fst ON f.app_sid = fst.app_sid AND f.default_state_id = fst.from_state_id
	  JOIN security.act ON act.sid_id = fst.group_sid_can_set
	 WHERE f.flow_sid = in_flow_sid
	   AND act.act_id = sys_context('SECURITY', 'ACT');
	   
	RETURN v_count;
END;

PROCEDURE GetDefaultFlowStateEditable(
	in_flow_sid						IN	csr.flow.flow_sid%TYPE,
	out_editable					OUT	csr.flow_state_role.is_editable%TYPE
)
AS
BEGIN

	SELECT NVL(MAX(is_editable), 0)
	  INTO out_editable
	  FROM csr.flow f
	  JOIN csr.flow_state fs ON f.app_sid = fs.app_sid AND f.default_state_id = fs.flow_state_id
	  JOIN csr.flow_state_role fsr ON fs.app_sid = fsr.app_sid AND fs.flow_state_id = fsr.flow_state_id
	  JOIN security.act ON (act.sid_id = fsr.role_sid OR act.sid_id = fsr.group_sid)
	 WHERE f.flow_sid = in_flow_sid
	   AND act.act_id = sys_context('SECURITY', 'ACT');
END;

-- THIS IS OLD JBUSH HACKERY I BELIVE AND SHOULD DIE?
PROCEDURE UpdateUnmanagedFlowStateLabel(
    in_tab_sid                      security_pkg.T_SID_ID,
    in_flow_state_id                csr.flow_state.flow_state_id%TYPE,
    in_where_clause                 VARCHAR2
)
AS
    v_label         csr.flow_state.label%TYPE;
    v_ora_schema    VARCHAR2(30 BYTE);
    v_tab_name      VARCHAR2(30 BYTE);
BEGIN
    SELECT oracle_schema, oracle_table INTO v_ora_schema, v_tab_name FROM cms.tab WHERE tab_sid = in_tab_sid;
    SELECT label INTO v_label FROM csr.flow_state WHERE flow_state_id = in_flow_state_id;

    -- dynamic SQL, risky and nasty! Must find a better way of dealing with unmanaged cms tables in workflows!
    -- Yes - it's called bind variables
    EXECUTE IMMEDIATE 'UPDATE ' || v_ora_schema || '.' || v_tab_name || ' SET flow_state_label = ''' || v_label || ''' WHERE ' || in_where_clause;
END;

PROCEDURE GetFlowStatesForTables(
	in_table_sids					IN	security.security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_tab_sids 					security.T_SID_TABLE;
BEGIN
	v_tab_sids := security_pkg.SidArrayToTable(in_table_sids);
	OPEN out_cur FOR
		SELECT fsperm.tab_sid, fs.flow_state_id, fs.label, fs.lookup_key, fs.attributes_xml, fs.is_deleted
		  FROM csr.flow_state fs, (
				SELECT t.tab_sid, fs.flow_state_id
				  FROM tab t, csr.flow_state fs, csr.flow_state_role fsr, csr.flow_state_cms_col fscc, security.act, TABLE(v_tab_sids) ts
			  	 WHERE t.tab_sid = ts.column_value
			  	   AND t.app_sid = fs.app_sid AND t.flow_sid = fs.flow_sid
				   AND fs.app_sid = fsr.app_sid(+) AND fs.flow_state_id = fsr.flow_state_id(+)
				   AND fs.app_sid = fscc.app_sid(+) AND fs.flow_state_id = fscc.flow_state_id(+)
				   AND (fsr.role_sid = act.sid_id OR fsr.group_sid = act.sid_id OR fscc.flow_state_id IS NOT NULL)
				   AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
			  	 GROUP BY t.tab_sid, fs.flow_state_id) fsperm
		 WHERE fs.flow_state_id = fsperm.flow_state_id
		   AND fs.is_deleted = 0
		 ORDER BY fsperm.tab_sid, LOWER(fs.label);
END;

PROCEDURE GetFlowItemSubscribed(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE,
	out_subscribed					OUT	NUMBER
)
AS
BEGIN
	SELECT COUNT(*)
	  INTO out_subscribed
	  FROM csr.flow_item_subscription
	 WHERE flow_item_id = in_flow_item_id
	   AND user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;

PROCEDURE SubscribeToFlowItem(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO csr.flow_item_subscription
			(flow_item_id, user_sid)
		VALUES
			(in_flow_item_id, SYS_CONTEXT('SECURITY', 'SID'));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE UnsubscribeFromFlowItem(
	in_flow_item_id					IN	csr.flow_item.flow_item_id%TYPE
)
AS
BEGIN
	DELETE FROM csr.flow_item_subscription
	 WHERE flow_item_id = in_flow_item_id
	   AND user_sid = SYS_CONTEXT('SECURITY', 'SID');
END;

PROCEDURE GetPrimaryKeys(
	in_tab_sid					IN   security_pkg.T_SID_ID,
	out_pk_columns				OUT  SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), in_tab_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 
			'Access denied reading table with sid '||in_tab_sid);
	END IF;

	-- pass back the primary key columns with a column alias
	OPEN out_pk_columns FOR 
		SELECT t.oracle_schema, t.oracle_table, tc.oracle_column, 'PK$'||rownum column_alias
		  FROM tab t
		  JOIN tab_column tc ON t.tab_sid = tc.tab_sid
		  JOIN uk_cons ukc ON ukc.tab_sid = t.tab_sid AND ukc.uk_cons_id = t.pk_cons_id
		  JOIN uk_cons_col ukcc ON ukc.uk_cons_id = ukcc.uk_cons_id AND ukcc.column_sid = tc.column_sid
		 WHERE t.tab_sid = in_tab_sid
		 ORDER BY ukcc.pos;
END;

FUNCTION IsOwner(
	in_tab_sid 				IN   security_pkg.T_SID_ID,
	in_flow_item_id			IN   csr.flow_item.flow_item_id%TYPE
) RETURN NUMBER
AS
	CURSOR c_tab IS 
        SELECT oracle_schema, oracle_table, issues, managed, flow_sid
          FROM tab
         WHERE tab_sid = in_tab_sid;
    r_tab   c_tab%ROWTYPE;
    v_sql				VARCHAR(4000); -- should be big enough
	v_owner_cur			SYS_REFCURSOR;
	v_first 	 		BOOLEAN := true;
	v_cnt 				NUMBER(10);
BEGIN
	-- security not required since we only pull data where we're in the right roles etc etc.
	OPEN c_tab;
    FETCH c_tab INTO r_tab;
    CLOSE c_tab;

    -- write SQL statement to pull the row and check if the current user is in one of the owner_sid columns
	v_sql := 'SELECT COUNT(*) cnt FROM '||q(r_tab.oracle_schema)||'.'||q(r_tab.oracle_table)
		|| ' WHERE flow_item_id = '||in_flow_item_id||' AND (';

	FOR r IN (
	    SELECT oracle_column
	      FROM tab_column
	     WHERE tab_sid = in_tab_sid
	       AND col_type = tab_pkg.CT_OWNER_USER
	)
	LOOP
		IF v_first THEN
			v_first := FALSE;
		ELSE
			v_sql := v_sql ||' OR ';
		END IF;
		v_sql := v_sql || r.oracle_column || ' = SYS_CONTEXT(''SECURITY'', ''SID'')';

	END LOOP;

	v_sql := v_sql || ')';

	IF v_first = TRUE THEN
		-- huh - no columns selected - abort
		RETURN 0;
	END IF;

	OPEN v_owner_cur FOR v_sql;
	FETCH v_owner_cur INTO v_cnt;
	CLOSE v_owner_cur;

	IF v_cnt = 0 THEN
		RETURN 0;
	ELSE
		RETURN 1;
	END IF;
END;

FUNCTION GetAccessLevelForState(
	in_tab_sid 				IN	security_pkg.T_SID_ID,
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	in_flow_state_id		IN	csr.flow_state.flow_state_id%TYPE,
	in_region_sids			IN  security.security_pkg.T_SID_IDS
) RETURN NUMBER
AS
	CURSOR c_tab IS 
		SELECT oracle_schema, oracle_table, issues, managed, flow_sid
		  FROM tab
		 WHERE tab_sid = in_tab_sid;
	r_tab   c_tab%ROWTYPE;
	v_sql				VARCHAR(4000); -- should be big enough
	v_first 	 		BOOLEAN := true;
	v_access_cur		SYS_REFCURSOR;
	v_access_level		NUMBER(10);
	v_regions_exist		NUMBER := CASE WHEN in_region_sids IS NOT NULL AND in_region_sids.COUNT > 0 AND in_region_sids(1) IS NOT NULL THEN 1 ELSE 0 END;
BEGIN
	-- security not required since we only pull data where we're in the right roles etc etc.
	OPEN c_tab;
	FETCH c_tab INTO r_tab;
	CLOSE c_tab;

	-- write SQL statement to pull the row and check if the current user is in one of the owner_sid columns
	v_sql := 'SELECT NVL(GREATEST(';

	FOR r IN (
		SELECT c.oracle_column, c.col_type, fsc.is_editable + 1 access_level, coverable
		  FROM tab_column c
		  JOIN csr.flow_state_cms_col fsc ON c.column_sid = fsc.column_sid
		 WHERE c.tab_sid = in_tab_sid
		   AND fsc.flow_state_id = in_flow_state_id
		   AND (col_type != CT_ROLE OR (col_type = CT_ROLE AND v_regions_exist = 1))
	)
	LOOP
		IF v_first THEN
			v_first := FALSE;
		ELSE
			v_sql := v_sql ||', ';
		END IF;
		
		IF r.col_type = tab_pkg.CT_ROLE THEN		
			v_sql := v_sql || 'NVL(CASE WHEN ' || r.oracle_column || ' IN (
				SELECT rrm.role_sid
				  FROM csr.region_role_member rrm
				 WHERE rrm.user_sid = SYS_CONTEXT(''SECURITY'',''SID'')
				   AND rrm.region_sid IN (';
				   
			FOR i IN 1 .. in_region_sids.COUNT LOOP
				IF i > 1 THEN
					v_sql := v_sql || ', ';
				END IF;
			
				v_sql := v_sql || in_region_sids(i);
			END LOOP;
			
			v_sql := v_sql|| ')) THEN '||r.access_level||' END, 0)';
		ELSIF r.col_type = tab_pkg.CT_COMPANY THEN
			v_sql := v_sql || 'NVL(CASE WHEN ' || r.oracle_column || ' = SYS_CONTEXT(''SECURITY'', ''CHAIN_COMPANY'') THEN '
					||r.access_level || ' END, 0)';
		ELSE
			IF r.coverable = 1 THEN
				v_sql := v_sql || 'NVL(CASE WHEN ' || r.oracle_column || ' = SYS_CONTEXT(''SECURITY'', ''SID'') OR '||
				r.oracle_column||' IN (SELECT user_being_covered_sid
										 FROM csr.v$current_user_cover
										) THEN '
						||r.access_level || ' END, 0)';
			ELSE
				v_sql := v_sql || 'NVL(CASE WHEN ' || r.oracle_column || ' = SYS_CONTEXT(''SECURITY'', ''SID'') THEN '
						||r.access_level || ' END, 0)';
			END IF;
		END IF;
	END LOOP;
	
	IF v_first = TRUE THEN
		-- huh - no columns selected - abort
		RETURN 0;
	END IF;
	
	v_sql := v_sql || '),0) FROM '||q(r_tab.oracle_schema)||'.'||q(r_tab.oracle_table)
		|| ' WHERE flow_item_id = '||in_flow_item_id;

	OPEN v_access_cur FOR v_sql;
	FETCH v_access_cur INTO v_access_level;
	CLOSE v_access_cur;
	
	RETURN v_access_level;
	
END;

FUNCTION GetUserFlowItemTransitions(
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	in_region_sids			IN  security.security_pkg.T_SID_IDS
) RETURN security.T_SID_TABLE
AS
	v_tab_sid				security_pkg.T_SID_ID;
	v_flow_state_id			csr.flow_state.flow_state_id%TYPE;
	t_flow_ids				security.T_SID_TABLE;
	v_sql					VARCHAR2(4000);
	v_first 	 			BOOLEAN := true;
	CURSOR c_tab IS 
		SELECT oracle_schema, oracle_table, issues, managed, flow_sid
		  FROM tab
		 WHERE tab_sid = v_tab_sid;
	r_tab   c_tab%ROWTYPE;
	v_regions_exist	NUMBER := CASE WHEN in_region_sids IS NOT NULL AND in_region_sids.COUNT > 0 AND in_region_sids(1) IS NOT NULL THEN 1 ELSE 0 END;
BEGIN
	SELECT t.tab_sid, fi.current_state_id
	  INTO v_tab_sid, v_flow_state_id
	  FROM cms.tab t
	  JOIN csr.flow_item fi ON t.flow_sid = fi.flow_sid
	 WHERE fi.flow_item_id = in_flow_item_id;
	
	OPEN c_tab;
	FETCH c_tab INTO r_tab;
	CLOSE c_tab;
	
	-- Assumes the flow_item_id column is always called flow_item_id?
	v_sql := 'BEGIN SELECT flow_state_transition_id BULK COLLECT INTO :1 FROM '||
		q(r_tab.oracle_schema)||'.'||q(r_tab.oracle_table)||' t '||
		'JOIN csr.flow_item fi ON t.flow_item_id = fi.flow_item_id '||
		'JOIN csr.flow_state_transition fst ON fi.current_state_id = fst.from_state_id '||
		'WHERE t.flow_item_id = '||in_flow_item_id||' AND (';
	
	FOR r IN (
		SELECT c.oracle_column, c.col_type, fsc.flow_state_transition_id
		  FROM tab_column c
		  JOIN csr.flow_state_transition_cms_col fsc ON c.column_sid = fsc.column_sid
		 WHERE c.tab_sid = v_tab_sid
		   AND fsc.from_state_id = v_flow_state_id
		   AND (c.col_type != CT_ROLE OR (c.col_type = CT_ROLE AND v_regions_exist = 1)) 
	)
	LOOP
		IF v_first THEN
			v_first := FALSE;
		ELSE
			v_sql := v_sql ||' OR ';
		END IF;
				
		IF r.col_type = tab_pkg.CT_ROLE THEN		
			v_sql := v_sql || '(t.' || r.oracle_column || ' IN (
				SELECT rrm.role_sid
				  FROM csr.region_role_member rrm
				 WHERE rrm.user_sid = SYS_CONTEXT(''SECURITY'',''SID'')
				   AND rrm.region_sid IN (';
				   
			FOR i IN 1 .. in_region_sids.COUNT LOOP
				IF i > 1 THEN
					v_sql := v_sql || ', ';
				END IF;
			
				v_sql := v_sql || in_region_sids(i);
			END LOOP;
			
			v_sql := v_sql|| ')) AND fst.flow_state_transition_id = ' || r.flow_state_transition_id || ')';
		ELSIF r.col_type = tab_pkg.CT_COMPANY THEN
			v_sql := v_sql || '(t.' || r.oracle_column || ' = SYS_CONTEXT(''SECURITY'', ''CHAIN_COMPANY'') AND fst.flow_state_transition_id = ' || r.flow_state_transition_id || ')';
		ELSIF r.col_type IN (tab_pkg.CT_OWNER_USER, tab_pkg.CT_USER) THEN
			v_sql := v_sql || '(t.' || r.oracle_column || ' = SYS_CONTEXT(''SECURITY'', ''SID'') AND fst.flow_state_transition_id = ' || r.flow_state_transition_id || ')';
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Col type:'||r.col_type||' not supported for getting user flow transitions for flow_item_id:'||in_flow_item_id); 
		END IF;

	END LOOP;
	
	FOR r IN (
		SELECT c.oracle_column, fsc.flow_state_transition_id
		  FROM tab_column c
		  JOIN csr.flow_state_transition_cms_col fsc ON c.column_sid = fsc.column_sid
		 WHERE c.tab_sid = v_tab_sid
		   AND fsc.from_state_id = v_flow_state_id
		   AND c.coverable = 1
	)
	LOOP
		v_sql := v_sql || ' OR (t.' || r.oracle_column || ' IN (SELECT user_being_covered_sid FROM csr.v$current_user_cover) AND fst.flow_state_transition_id = ' || r.flow_state_transition_id || ')';
	END LOOP;
	
	v_sql := v_sql || '); END;';
	
	IF v_first = TRUE THEN
		-- huh - no columns selected - abort
		RETURN t_flow_ids;
	END IF;
	
	EXECUTE IMMEDIATE v_sql USING OUT t_flow_ids;
	
	RETURN t_flow_ids;
END;

PROCEDURE GetSchemaForExport(
	out_app_schema_cur				OUT	SYS_REFCURSOR,
	out_app_schema_table_cur		OUT	SYS_REFCURSOR,
	out_tab_cur						OUT	SYS_REFCURSOR,
	out_tab_column_cur				OUT	SYS_REFCURSOR,
	out_tab_column_measure_cur		OUT	SYS_REFCURSOR,
	out_tab_column_role_perm_cur	OUT	SYS_REFCURSOR,
	out_flow_tab_column_cons_cur	OUT	SYS_REFCURSOR,
	out_uk_cons_cur					OUT	SYS_REFCURSOR,
	out_uk_cons_col_cur				OUT	SYS_REFCURSOR,
	out_fk_cons_cur					OUT	SYS_REFCURSOR,
	out_fk_cons_col_cur				OUT	SYS_REFCURSOR,
	out_ck_cons_cur					OUT	SYS_REFCURSOR,
	out_ck_cons_col_cur				OUT	SYS_REFCURSOR,
	out_form_cur					OUT	SYS_REFCURSOR,
	out_form_version_cur			OUT	SYS_REFCURSOR,
	out_filter_cur					OUT	SYS_REFCURSOR,
	out_display_template			OUT	SYS_REFCURSOR,
	out_web_publication				OUT	SYS_REFCURSOR,
	out_link_track					OUT	SYS_REFCURSOR,
	out_image						OUT	SYS_REFCURSOR,
	out_image_tag					OUT	SYS_REFCURSOR,
	out_tag							OUT	SYS_REFCURSOR,
	out_tab_column_link				OUT	SYS_REFCURSOR,
	out_tab_column_link_type		OUT	SYS_REFCURSOR,
	out_tab_aggregate_ind			OUT	SYS_REFCURSOR,
	out_tab_issue_aggregate_ind		OUT	SYS_REFCURSOR,
	out_cms_aggregate_type			OUT	SYS_REFCURSOR,
	out_doc_template				OUT	SYS_REFCURSOR,
	out_doc_template_file			OUT SYS_REFCURSOR,
	out_doc_template_version		OUT SYS_REFCURSOR,
	out_cms_data_helper				OUT	SYS_REFCURSOR,
	out_enum_tabs_cur				OUT	SYS_REFCURSOR,
	out_enum_groups_cur				OUT	SYS_REFCURSOR,
	out_enum_groups_members_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security, only used by csrexp
	OPEN out_app_schema_cur FOR
		SELECT oracle_schema
		  FROM app_schema;
		  
	OPEN out_app_schema_table_cur FOR
		SELECT oracle_schema, oracle_table
		  FROM app_schema_table;
		  
	OPEN out_tab_cur FOR
		SELECT tab_sid, oracle_schema, oracle_table, description, format_sql,
			   pk_cons_id, managed, auto_registered, cms_editor, issues,
			   flow_sid, policy_function, policy_view, is_view, helper_pkg, show_in_company_filter,
			   parent_tab_sid, show_in_property_filter, securable_fk_cons_id, is_basedata,
			   enum_translation_tab_sid, show_in_product_filter
		  FROM tab;

	OPEN out_tab_column_cur FOR
		SELECT column_sid, tab_sid, oracle_column, description, pos, col_type,
			   master_column_sid, enumerated_desc_field, enumerated_pos_field,
			   enumerated_colpos_field, enumerated_hidden_field, enumerated_colour_field,
			   enumerated_extra_fields, help, check_msg, calc_xml, data_type, data_length,
			   data_precision, data_scale, nullable, char_length, value_placeholder, helper_pkg,
			   tree_desc_field, tree_id_field, tree_parent_id_field, full_text_index_name,
			   incl_in_active_user_filter, owner_permission, coverable, default_length,
			   data_default, measure_sid, measure_conv_column_sid, measure_conv_date_column_sid,
			   auto_sequence, show_in_filter, show_in_breakdown, include_in_search, 
			   form_selection_desc_field, form_selection_pos_field, form_selection_form_field, 
			   form_selection_hidden_field, restricted_by_policy, format_mask
		  FROM tab_column;		  

	OPEN out_tab_column_measure_cur FOR
		SELECT column_sid, measure_sid
		  FROM tab_column_measure;

	OPEN out_tab_column_role_perm_cur FOR
		SELECT column_sid, role_sid, permission, policy_function
		  FROM tab_column_role_permission;

	OPEN out_flow_tab_column_cons_cur FOR
		SELECT column_sid, flow_state_id, nullable
		  FROM flow_tab_column_cons;

	OPEN out_uk_cons_cur FOR
		SELECT uk_cons_id, tab_sid, constraint_owner, constraint_name
		  FROM uk_cons;

	OPEN out_uk_cons_col_cur FOR
		SELECT uk_cons_id, column_sid, pos
		  FROM uk_cons_col;
	
	OPEN out_fk_cons_cur FOR
		SELECT fk_cons_id, tab_sid, r_cons_id, delete_rule, constraint_owner, constraint_name
		  FROM fk_cons;

	OPEN out_fk_cons_col_cur FOR
		SELECT fk_cons_id, column_sid, pos
		  FROM fk_cons_col;

	OPEN out_ck_cons_cur FOR
		SELECT ck_cons_id, tab_sid, search_condition, constraint_owner, constraint_name
		  FROM cms.ck_cons;
		  
	OPEN out_ck_cons_col_cur FOR
		SELECT ck_cons_id, column_sid
		  FROM ck_cons_col;
	
	OPEN out_form_cur FOR
		SELECT form_sid, description, parent_tab_sid, lookup_key, current_version, is_report_builder, 
		       short_path, use_quick_chart, draft_form_xml, draft_file_name
		  FROM form;
	
	OPEN out_form_version_cur FOR
		SELECT form_sid, form_version, file_name, form_xml, published_dtm, published_by_sid, version_comment
		  FROM form_version;
	
	OPEN out_filter_cur FOR
		SELECT filter_sid, tab_sid, name, created_by_user_sid, filter_xml, parent_sid
		  FROM filter;

	OPEN out_display_template FOR
		SELECT display_template_id, tab_sid, template_url, priority, name, description
		  FROM display_template;

	OPEN out_web_publication FOR
		SELECT web_publication_id, display_template_id, item_id
		  FROM web_publication;

	OPEN out_link_track FOR
		SELECT item_id, context_id, column_sid, path, query_string
		  FROM link_track;
		  
	OPEN out_image FOR
		SELECT image_id, mime_type, sha1, filename, description, data,
			   modified_dtm, width, height, recycled
		  FROM image;
		  
	OPEN out_image_tag FOR
		SELECT parent_tag_id, image_id
		  FROM image_tag;

	OPEN out_tag FOR
		SELECT tag_id, tag, parent_tag_id
		  FROM tag;
		  
	OPEN out_tab_column_link FOR
		SELECT tab_column_link_id, column_sid_1, item_id_1, column_sid_2, item_id_2
		  FROM tab_column_link;
		  
	OPEN out_tab_column_link_type FOR
		SELECT column_sid, link_column_sid, label, base_link_url
		  FROM tab_column_link_type;
		
	OPEN out_tab_aggregate_ind FOR
		SELECT tab_aggregate_ind_id, tab_sid, column_sid, ind_sid
		  FROM tab_aggregate_ind;
		  		
	OPEN out_tab_issue_aggregate_ind FOR
		SELECT tab_sid, raised_ind_sid, rejected_ind_sid, closed_on_time_ind_sid, 
		       closed_late_ind_sid, closed_late_u30_ind_sid, closed_late_u60_ind_sid, 
			   closed_late_u90_ind_sid, closed_late_o90_ind_sid, closed_ind_sid, open_ind_sid, closed_td_ind_sid,
			   rejected_td_ind_sid, open_od_ind_sid, open_nod_ind_sid, open_od_u30_ind_sid, open_od_u60_ind_sid,
			   open_od_u90_ind_sid, open_od_o90_ind_sid
		  FROM tab_issue_aggregate_ind;
	
	OPEN out_cms_aggregate_type FOR
		SELECT cms_aggregate_type_id, tab_sid, first_arg_column_sid, second_arg_column_sid,
			   operation, description, analytic_function, score_type_id, format_mask, normalize_by_aggregate_type_id
		  FROM cms_aggregate_type;
		  
	OPEN out_doc_template FOR
		SELECT doc_template_id, name, lookup_key, lang
		  FROM doc_template;
	
	OPEN out_doc_template_file FOR
		SELECT doc_template_file_id, file_name, file_mime, file_data, uploaded_dtm
		  FROM doc_template_file;

	OPEN out_doc_template_version FOR
		SELECT doc_template_id, version, comments, doc_template_file_id, log_dtm, user_sid, published_dtm, active
		  FROM doc_template_version;

	OPEN out_cms_data_helper FOR
		SELECT lookup_key, helper_procedure
		  FROM data_helper;
		  
	OPEN out_enum_tabs_cur FOR
		SELECT tab_sid, label, replace_existing_filters
		  FROM enum_group_tab;
	
	OPEN out_enum_groups_cur FOR
		SELECT tab_sid, enum_group_id, group_label 	
		  FROM enum_group;

	OPEN out_enum_groups_members_cur FOR 
		SELECT enum_group_id, enum_group_member_id
		  FROM enum_group_member;
END;

PROCEDURE GetDDLForExport(
	out_tables_cur					OUT	SYS_REFCURSOR,
	out_tab_column_cur				OUT	SYS_REFCURSOR,
	out_cons_cur					OUT	SYS_REFCURSOR,
	out_cons_column_cur				OUT	SYS_REFCURSOR,
	out_indexes_cur					OUT	SYS_REFCURSOR,
	out_ind_column_cur				OUT	SYS_REFCURSOR,
	out_ind_expr_cur				OUT	SYS_REFCURSOR,
	out_tab_privs_cur				OUT	SYS_REFCURSOR,
	out_tab_comments_cur			OUT	SYS_REFCURSOR,
	out_col_comments_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN	
	OPEN out_tables_cur FOR
		SELECT owner, table_name, rownum table_id
		  FROM (SELECT at.owner, at.table_name
		  		  FROM all_tables at, v$cms_schema s
		 		 WHERE at.owner = s.oracle_schema
		 		 ORDER BY owner, table_name);
		  
	OPEN out_tab_column_cur FOR
		SELECT atc.owner, atc.table_name, atc.column_name, atc.data_type, atc.data_length,
			   atc.data_precision, atc.data_scale, atc.nullable, atc.column_id, atc.data_default
		  FROM all_tab_columns atc, all_tables at, v$cms_schema s
		 WHERE atc.owner = s.oracle_schema
		   AND atc.owner = at.owner
		   AND atc.table_name = at.table_name;

	OPEN out_cons_cur FOR
		SELECT ac.owner, ac.table_name, ac.constraint_name, ac.constraint_type,
			   ac.search_condition, ac.r_owner, ac.r_constraint_name, ac.deferrable,
			   ac.deferred, ac.generated, ac.delete_rule, ac.index_name, ac.status
		  FROM all_constraints ac, all_tables at, v$cms_schema s
		 WHERE ac.owner = s.oracle_schema
		   AND ac.owner = at.owner
		   AND ac.table_name = at.table_name;

	OPEN out_cons_column_cur FOR
		SELECT acc.owner, acc.table_name, acc.constraint_name, acc.column_name, acc.position
		  FROM all_cons_columns acc, all_tables at, v$cms_schema s
		 WHERE acc.owner = s.oracle_schema
		   AND acc.owner = at.owner
		   AND acc.table_name = at.table_name;
		 
	OPEN out_indexes_cur FOR
		SELECT ai.owner, ai.index_name, ai.table_owner, ai.table_name, ai.generated
		  FROM all_indexes ai, all_tables at, v$cms_schema s
		 WHERE ai.owner = s.oracle_schema
		   AND at.owner = s.oracle_schema
		   AND ai.table_owner = at.owner
		   AND ai.table_name = at.table_name;

	OPEN out_ind_column_cur FOR
		SELECT ai.index_owner, ai.index_name, ai.table_owner, ai.table_name, ai.column_name,
			   ai.column_position, ai.descend
		  FROM all_ind_columns ai, all_tables at, v$cms_schema s
		 WHERE ai.index_owner = s.oracle_schema
		   AND ai.table_owner = s.oracle_schema
		   AND ai.table_owner = at.owner
		   AND ai.table_name = at.table_name;

	OPEN out_ind_expr_cur FOR
		SELECT ai.index_owner, ai.index_name, ai.table_owner, ai.table_name,
			   ai.column_expression, ai.column_position
		  FROM all_ind_expressions ai, all_tables at, v$cms_schema s
		 WHERE ai.index_owner = s.oracle_schema
		   AND ai.table_owner = s.oracle_schema
		   AND ai.table_owner = at.owner
		   AND ai.table_name = at.table_name;

	OPEN out_tab_privs_cur FOR
		SELECT p.grantee, owner, p.table_name, p.privilege
		  FROM dba_tab_privs p, v$cms_schema s
		 WHERE grantee = s.oracle_schema;
		 
	OPEN out_tab_comments_cur FOR
		SELECT atc.owner, atc.table_name, atc.comments
		  FROM all_tab_comments atc, all_tables at, v$cms_schema s
		 WHERE atc.owner = s.oracle_schema
		   AND atc.owner = at.owner
		   AND atc.table_name = at.table_name
		   AND atc.comments IS NOT NULL;

	OPEN out_col_comments_cur FOR
		SELECT acc.owner, acc.table_name, acc.column_name, acc.comments
		  FROM all_col_comments acc, all_tables at, v$cms_schema s
		 WHERE acc.owner = s.oracle_schema
		   AND acc.owner = at.owner
		   AND acc.table_name = at.table_name
		   AND acc.comments IS NOT NULL;
END;

-- create the schema with no constraints or indexes
-- (these are added after the data is loaded)
PROCEDURE CreateImportedSchema
AS
    v_sql							CLOB;
    v_temp_sql						CLOB;
    v_pkg							CLOB; 
    v_pkg_body						CLOB; 
    v_isql							CLOB;
    v_iselect						CLOB;
    v_ifrom							CLOB;
    v_iwhere						CLOB;
    v_mapped						BOOLEAN;
    v_map_table						VARCHAR2(65);
    v_map_old_column				VARCHAR2(30);
    v_map_new_column				VARCHAR2(30);
	v_first							BOOLEAN;
	v_first_table					BOOLEAN;
	v_force_outer					BOOLEAN;
	v_force_nvl						BOOLEAN;
	v_static_mapping				BOOLEAN;
	v_ddl 							t_ddl DEFAULT t_ddl();
	v_key_maps						T_KEY_MAP_TABLE;
	v_col_type						tab_column.col_type%TYPE;
	TYPE T_MAP_TABLE IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(65);
	v_map_tables					t_map_table;
	v_tidy_pos						csrimp.cms_tidy_ddl.pos%TYPE := 1;
BEGIN
	EnableTrace;
	IF HasUnprocessedDDL THEN
		ExecDDLFromLog;
		RETURN;
	END IF;
	
	-- no security, only used by csrexp
	v_key_maps := T_KEY_MAP_TABLE(
		T_KEY_MAP('CSR', 'REGION', 'REGION_SID', 'MAP_SID', 'OLD_SID', 'NEW_SID'),
		T_KEY_MAP('CSR', 'IND', 'IND_SID', 'MAP_SID', 'OLD_SID', 'NEW_SID'),
		T_KEY_MAP('CSR', 'CSR_USER', 'CSR_USER_SID', 'MAP_SID', 'OLD_SID', 'NEW_SID'),
		T_KEY_MAP('CSR', 'MEASURE', 'MEASURE_SID', 'MAP_SID', 'OLD_SID', 'NEW_SID'),
		T_KEY_MAP('CSR', 'CUSTOMER', 'APP_SID', 'MAP_SID', 'OLD_SID', 'NEW_SID'),
		T_KEY_MAP('CSR', 'ISSUE', 'ISSUE_ID', 'MAP_ISSUE', 'OLD_ISSUE_ID', 'NEW_ISSUE_ID'),
		T_KEY_MAP('CSR', 'FLOW_ITEM', 'FLOW_ITEM_ID', 'MAP_FLOW_ITEM', 'OLD_FLOW_ITEM', 'NEW_FLOW_ITEM'),
		T_KEY_MAP('CSR', 'MEASURE_CONVERSION', 'MEASURE_CONVERSION_ID', 'MAP_MEASURE_CONVERSION', 'OLD_MEASURE_CONVERSION_ID', 'NEW_MEASURE_CONVERSION_ID'),
		T_KEY_MAP('CSR', 'COMPLIANCE_PERMIT', 'COMPLIANCE_PERMIT_ID', 'MAP_COMPLIANCE_PERMIT', 'OLD_COMPLIANCE_PERMIT_ID', 'NEW_COMPLIANCE_PERMIT_ID'),
		T_KEY_MAP('CHAIN', 'COMPANY', 'COMPANY_SID', 'MAP_SID', 'OLD_SID', 'NEW_SID'),
		T_KEY_MAP('CHAIN', 'BUSINESS_RELATIONSHIP', 'BUSINESS_RELATIONSHIP_ID', 'MAP_CHAIN_BUSINE_RELATIO', 'OLD_BUSINESS_RELATIONSHIP_ID', 'NEW_BUSINESS_RELATIONSHIP_ID'),
		T_KEY_MAP('CHAIN', 'PRODUCT', 'PRODUCT_ID', 'MAP_CHAIN_PRODUCT', 'OLD_PRODUCT_ID', 'NEW_PRODUCT_ID'),
		T_KEY_MAP('CHEM', 'SUBSTANCE', 'SUBSTANCE_ID', 'MAP_CHEM_SUBSTANCE', 'OLD_SUBSTANCE_ID', 'NEW_SUBSTANCE_ID')
	);

	FOR r IN (SELECT new_oracle_schema
			 	FROM csrimp.map_cms_schema
			   WHERE old_oracle_schema NOT IN (
			   			SELECT oracle_schema
			   			  FROM sys_schema)) LOOP
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'CREATE USER '||q(r.new_oracle_schema)||' IDENTIFIED BY '||q(r.new_oracle_schema)||' QUOTA UNLIMITED ON USERS';

		-- might be duplicates (which works fine), but all cms schemas need these grants for the triggers/views
		-- and some existing ones have them via having general privileges (which we don't give above)
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'GRANT EXECUTE ON cms.tab_pkg TO '||q(r.new_oracle_schema);
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'GRANT EXECUTE ON security.security_pkg TO '||q(r.new_oracle_schema);
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'GRANT SELECT ON cms.context TO '||q(r.new_oracle_schema);
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'GRANT SELECT ON cms.fast_context TO '||q(r.new_oracle_schema);	
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'GRANT SELECT ON cms.uk_cons TO '||q(r.new_oracle_schema);	
		
		-- in case issues tables are in use
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'GRANT SELECT, REFERENCES ON csr.issue TO '||q(r.new_oracle_schema);	
		
		-- grant for import
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'GRANT REFERENCES ON csrimp.csrimp_session TO '||q(r.new_oracle_schema);
		INSERT INTO csrimp.cms_tidy_ddl (pos, ddl)
		-- it's ok to drop the constraints to csrimp.csrimp_session -- we drop all the tables
		VALUES (v_tidy_pos, 'REVOKE REFERENCES ON csrimp.csrimp_session FROM '||q(r.new_oracle_schema)||' CASCADE CONSTRAINTS');
		v_tidy_pos := v_tidy_pos + 1;
	END LOOP;

	FOR r IN (SELECT p.grantee, p.owner, p.table_name, p.privilege, ms.new_oracle_schema
				FROM imp_tab_privs p, csrimp.map_cms_schema ms, all_users au
			   WHERE p.grantee = ms.old_oracle_schema
			     AND ms.old_oracle_schema NOT IN (
			     		SELECT oracle_schema
			     		  FROM sys_schema)
			     AND p.owner NOT IN ( -- run grants across schemas in the import later
			     		SELECT old_oracle_schema
			     		  FROM csrimp.map_cms_schema)
			     AND au.username = p.owner
			     AND (p.owner, p.table_name) IN (
			     		SELECT owner, object_name
			     		  FROM all_objects)) LOOP
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'GRANT '||r.privilege||' ON '||q(r.owner)||'.'||q(r.table_name)||' TO '||q(r.new_oracle_schema);
	END LOOP;

	FOR schma IN (SELECT old_oracle_schema, new_oracle_schema
					FROM csrimp.map_cms_schema
			       WHERE old_oracle_schema NOT IN (
							SELECT oracle_schema
			     		  	  FROM sys_schema)) LOOP
		v_map_tables.DELETE;

		v_pkg := 
			'create or replace package '||q(schma.new_oracle_schema)||'.m$imp_pkg as'||chr(10)||chr(10)||
			'procedure gatherStats;'||chr(10)||chr(10)||
			'procedure import;'||chr(10)||chr(10)||
			'end;';
		v_pkg_body := 
			'create or replace package body '||q(schma.new_oracle_schema)||'.m$imp_pkg as'||chr(10)||chr(10)||
			'procedure gatherStats'||chr(10)||'as'||chr(10)||
			'begin'||chr(10)||
			'    dbms_stats.gather_schema_stats('||chr(10)||
			'        ownname => NULL,'||chr(10)||
			'        granularity => ''AUTO'','||chr(10)||
			'        block_sample => FALSE,'||chr(10)||
			'        cascade => TRUE,'||chr(10)||
			'        degree => DBMS_STATS.DEFAULT_DEGREE,'||chr(10)||
			'        method_opt => ''FOR ALL COLUMNS SIZE 1'','||chr(10)||
			'        options => ''GATHER'');'||chr(10)||
			'end;'||chr(10)||
			chr(10)||			
			'procedure import'||chr(10)||'as'||chr(10)||
			'begin'||chr(10);
		 
		v_first_table := TRUE;	
	    FOR r IN (SELECT it.owner, it.table_name, it.table_id, t.tab_sid old_tab_sid
	                FROM imp_tables it, csrimp.cms_tab t
	               WHERE it.owner = schma.old_oracle_schema
	                 AND it.owner = t.oracle_schema(+)
					 AND (CASE
					 		WHEN SUBSTR(it.table_name, 1, 2) IN ('L$', 'C$') THEN SUBSTR(it.table_name, 3) 
					 		ELSE it.table_name 
					 	  END) = t.oracle_table(+)) LOOP
	
			/*IF r.old_tab_sid IS NULL THEN
				security_pkg.debugmsg('LOST TABLE '||r.owner||'.'||r.table_name);
			END IF;*/
			
			v_isql := '    insert into '||q(schma.new_oracle_schema)||'.'||q(r.table_name)||' ('||chr(10);
			v_iselect := chr(10)||'    )'||chr(10)||'    select ';
			v_ifrom := '      from '||q(schma.new_oracle_schema)||'.M$'||r.table_id||' m';
			dbms_lob.createtemporary(v_iwhere, TRUE);
			
			v_sql := ' ';
			v_first := TRUE;
	
			FOR s IN (SELECT column_name, data_type, data_length, data_precision, data_scale, nullable,
							 data_default, column_id
					    FROM imp_tab_columns itc
					   WHERE owner = r.owner AND table_name = r.table_name
					   ORDER BY column_id) LOOP
	
				IF NOT v_first THEN
					WriteAppend(v_sql, ',' || chr(10));
					WriteAppend(v_isql, ',' || chr(10));
				END IF;
				WriteAppend(v_sql, q(s.column_name) || ' ' || s.data_type);
				WriteAppend(v_isql, '        '||q(s.column_name));
				IF s.data_type IN ('CHAR', 'NCHAR', 'NVARCHAR2', 'VARCHAR2', 'RAW') THEN
					WriteAppend(v_sql, '(' || s.data_length || ')');
				ELSIF s.data_type = 'NUMBER' AND (s.data_precision IS NOT NULL OR s.data_scale IS NOT NULL) THEN
					WriteAppend(v_sql, '(' || NVL(TO_CHAR(s.data_precision), '*') || ',' || s.data_scale || ')');
				END IF;
				IF s.data_default IS NOT NULL THEN
					WriteAppend(v_sql, ' DEFAULT ' || s.data_default);
				END IF;
				IF s.nullable = 'N' THEN
					WriteAppend(v_sql, ' NOT NULL');
				END IF;
				 
				-- find the column type to see if it needs mapping
				v_mapped := FALSE;
				v_force_outer := FALSE;
				v_force_nvl := FALSE; -- weird hack for measure_conversion where we want to NVL through the original value -- see below where it's used
				v_static_mapping := FALSE;
				IF r.old_tab_sid IS NOT NULL THEN
					BEGIN
						SELECT col_type
						  INTO v_col_type
						  FROM csrimp.cms_tab_column
						 WHERE tab_sid = r.old_tab_sid
						   AND oracle_column = s.column_name;
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							-- This is just a column that wasn't in cms metadata
							v_col_type := NULL;
							--security_pkg.debugmsg(r.table_name||'.'||s.column_name||' NOT FOUND TS '||r.old_tab_sid);
					END;
					
					--security_pkg.debugmsg(r.table_name||'.'||s.column_name||' FOUND TYPE IS '||v_col_type);
					-- root_delegation_sid is a hard-coded column name used by "grids" on delegations
					IF s.data_type = 'NUMBER' THEN
						IF v_col_type IN (CT_USER, CT_OWNER_USER, CT_REGION, CT_INDICATOR, CT_FLOW_REGION, CT_COMPANY, CT_INTERNAL_AUDIT) OR
						   s.column_name = 'ROOT_DELEGATION_SID' THEN
							v_map_table := 'CSRIMP.MAP_SID';
							v_map_old_column := 'OLD_SID';
							v_map_new_column := 'NEW_SID';
							v_mapped := TRUE;
						ELSIF v_col_type = CT_FLOW_ITEM THEN
							v_map_table := 'CSRIMP.MAP_FLOW_ITEM';
							v_map_old_column := 'OLD_FLOW_ITEM_ID';
							v_map_new_column := 'NEW_FLOW_ITEM_ID';
							v_mapped := TRUE;
						ELSIF v_col_type = CT_SUBSTANCE THEN
							v_map_table := 'CSRIMP.MAP_CHEM_SUBSTANCE';
							v_map_old_column := 'OLD_SUBSTANCE_ID';
							v_map_new_column := 'NEW_SUBSTANCE_ID';
							v_mapped := TRUE;
						ELSIF v_col_type = CT_BUSINESS_RELATIONSHIP THEN
							v_map_table := 'CSRIMP.MAP_CHAIN_BUSINE_RELATIO';
							v_map_old_column := 'OLD_BUSINESS_RELATIONSHIP_ID';
							v_map_new_column := 'NEW_BUSINESS_RELATIONSHIP_ID';
							v_mapped := TRUE;
						ELSIF v_col_type = CT_PERMIT THEN
							v_map_table := 'CSRIMP.MAP_COMPLIANCE_PERMIT';
							v_map_old_column := 'OLD_COMPLIANCE_PERMIT_ID';
							v_map_new_column := 'NEW_COMPLIANCE_PERMIT_ID';
							v_mapped := TRUE;
						ELSIF v_col_type = CT_PRODUCT THEN
							v_map_table := 'CSRIMP.MAP_CHAIN_PRODUCT';
							v_map_old_column := 'OLD_PRODUCT_ID';
							v_map_new_column := 'NEW_PRODUCT_ID';
							v_mapped := TRUE;
						ELSIF v_col_type = CT_MEASURE_CONVERSION OR
							  SUBSTR(s.column_name, LENGTH(s.column_name)-6, 7) = '_UOM_ID' OR
 							  SUBSTR(s.column_name, LENGTH(s.column_name)-3, 4) = '_UOM' THEN -- TODO
							-- hack for UOM measure_Conversion_Id tables which crop up a fair bit because we don't have
							-- decent out-of-the-box support for units
							v_map_table := 'CSRIMP.MAP_MEASURE_CONVERSION';
							v_map_old_column := 'OLD_MEASURE_CONVERSION_ID';
							v_map_new_column := 'NEW_MEASURE_CONVERSION_ID';
							v_force_outer := TRUE;
							v_force_nvl := TRUE; -- odd hack as we have '1' as the base unit of measure
							v_mapped := TRUE;
						ELSIF v_col_type = CT_APP_SID THEN
							-- short circuit app sid mappings to save work
							v_map_new_column := 'SYS_CONTEXT(''SECURITY'', ''APP'')';
							v_static_mapping := TRUE;
						ELSIF (SUBSTR(r.table_name, 1, 2) = 'C$' AND s.column_name = 'CHANGED_BY') OR 
							  (SUBSTR(r.table_name, 1, 2) = 'L$' AND s.column_name = 'LOCKED_BY') THEN
							v_map_table := 'CSRIMP.MAP_SID';
							v_map_old_column := 'OLD_SID';
							v_map_new_column := 'NEW_SID';
							v_force_outer := TRUE;
							v_mapped := TRUE;
						END IF;
					END IF;
				END IF;

				-- if we didn't recognise the column's type, check for an FK to one that we do
				IF NOT v_mapped THEN
					FOR t in ( SELECT rtc.col_type
								 FROM cms.imp_cons_columns acc, cms.imp_constraints ac,
									  cms.imp_constraints rac, cms.imp_cons_columns racc,
									  csrimp.cms_tab rt, csrimp.cms_tab_column rtc
								WHERE acc.owner = schma.old_oracle_schema
								  AND acc.table_name = r.table_name
								  AND acc.column_name = s.column_name
								  AND acc.owner = ac.owner
								  AND acc.constraint_name = ac.constraint_name
								  AND ac.constraint_type = 'R'
								  AND ac.r_owner = rac.owner
								  AND ac.r_constraint_name = rac.constraint_name
								  AND rac.owner = racc.owner
								  AND rac.constraint_name = racc.constraint_name
								  AND racc.owner = rt.oracle_schema
								  AND racc.table_name = rt.oracle_table
								  AND rt.tab_sid = rtc.tab_sid
								  AND racc.column_name = rtc.oracle_column ) LOOP

						v_col_type := t.col_type;
						
						-- root_delegation_sid is a hard-coded column name used by "grids" on delegations
						IF v_col_type IN (CT_USER, CT_OWNER_USER, CT_REGION, CT_INDICATOR, CT_FLOW_REGION, CT_COMPANY, CT_INTERNAL_AUDIT) OR s.column_name = 'ROOT_DELEGATION_SID' THEN
							v_map_table := 'CSRIMP.MAP_SID';
							v_map_old_column := 'OLD_SID';
							v_map_new_column := 'NEW_SID';
							v_mapped := TRUE;
						ELSIF v_col_type = CT_FLOW_ITEM THEN
							v_map_table := 'CSRIMP.MAP_FLOW_ITEM';
							v_map_old_column := 'OLD_FLOW_ITEM_ID';
							v_map_new_column := 'NEW_FLOW_ITEM_ID';
							v_mapped := TRUE;
						ELSIF v_col_type = CT_SUBSTANCE THEN
							v_map_table := 'CSRIMP.MAP_CHEM_SUBSTANCE';
							v_map_old_column := 'OLD_SUBSTANCE_ID';
							v_map_new_column := 'NEW_SUBSTANCE_ID';
							v_mapped := TRUE;
						ELSIF v_col_type = CT_BUSINESS_RELATIONSHIP THEN
							v_map_table := 'CSRIMP.MAP_CHAIN_BUSINE_RELATIO';
							v_map_old_column := 'OLD_BUSINESS_RELATIONSHIP_ID';
							v_map_new_column := 'NEW_BUSINESS_RELATIONSHIP_ID';
							v_mapped := TRUE;
						ELSIF v_col_type = CT_PERMIT THEN
							v_map_table := 'CSRIMP.MAP_COMPLIANCE_PERMIT';
							v_map_old_column := 'OLD_COMPLIANCE_PERMIT_ID';
							v_map_new_column := 'NEW_COMPLIANCE_PERMIT_ID';
							v_mapped := TRUE;
						ELSIF v_col_type = CT_PRODUCT THEN
							v_map_table := 'CSRIMP.MAP_CHAIN_PRODUCT';
							v_map_old_column := 'OLD_PRODUCT_ID';
							v_map_new_column := 'NEW_PRODUCT_ID';
							v_mapped := TRUE;
						ELSIF SUBSTR(s.column_name, LENGTH(s.column_name)-6, 7) = '_UOM_ID' OR SUBSTR(s.column_name, LENGTH(s.column_name)-3, 4) = '_UOM'  THEN -- TODO
							-- hack for UOM measure_Conversion_Id tables which crop up a fair bit because we don't have
							-- decent out-of-the-box support for units
							v_map_table := 'CSRIMP.MAP_MEASURE_CONVERSION';
							v_map_old_column := 'OLD_MEASURE_CONVERSION_ID';
							v_map_new_column := 'NEW_MEASURE_CONVERSION_ID';
							v_force_outer := TRUE;
							v_force_nvl := TRUE; -- odd hack as we have '1' as the base unit of measure
							v_mapped := TRUE;
						ELSIF v_col_type = CT_APP_SID THEN
							-- short circuit app sid mappings to save work
							v_map_new_column := 'SYS_CONTEXT(''SECURITY'', ''APP'')';
							v_static_mapping := TRUE;
						ELSIF (SUBSTR(r.table_name, 1, 2) = 'C$' AND s.column_name = 'CHANGED_BY') OR 
							  (SUBSTR(r.table_name, 1, 2) = 'L$' AND s.column_name = 'LOCKED_BY') THEN
							v_map_table := 'CSRIMP.MAP_SID';
							v_map_old_column := 'OLD_SID';
							v_map_new_column := 'NEW_SID';
							v_force_outer := TRUE;
							v_mapped := TRUE;
						END IF;

						EXIT WHEN v_mapped;

					END LOOP;
				END IF;
				
				-- if we couldn't map based on column type, check for an RI constraint to a table
				-- we know about
				IF NOT v_mapped THEN
					BEGIN
						SELECT 'CSRIMP.' || km.map_table_name, km.map_old_column_name, km.map_new_column_name
						  INTO v_map_table, v_map_old_column, v_map_new_column
						  FROM imp_cons_columns acc, imp_constraints ac, imp_constraints rac,
						  	   imp_cons_columns racc, TABLE(v_key_maps) km
						 WHERE acc.owner = schma.old_oracle_schema
						   AND acc.table_name = r.table_name
						   AND acc.column_name = s.column_name
						   AND acc.owner = ac.owner
						   AND acc.constraint_name = ac.constraint_name
						   AND ac.constraint_type = 'R'
						   AND ac.r_owner = rac.owner
						   AND ac.r_constraint_name = rac.constraint_name
						   AND rac.owner = racc.owner
						   AND rac.constraint_name = racc.constraint_name
						   AND rac.table_name = km.table_name
						   AND rac.owner = km.table_owner
						   AND racc.column_name = km.id_column_name;
	
						v_mapped := TRUE;
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							-- we might also have a managed (fake) constraint to a table we know about
							IF SUBSTR(r.table_name, 1, 2) IN ('C$', 'L$') THEN								
								BEGIN
									SELECT 'CSRIMP.' || km.map_table_name, km.map_old_column_name, km.map_new_column_name
									  INTO v_map_table, v_map_old_column, v_map_new_column
									  FROM csrimp.cms_fk_cons fkc, csrimp.cms_fk_cons_col fkcc,
									       csrimp.cms_uk_cons ukc, csrimp.cms_uk_cons_col ukcc,
									  	   csrimp.cms_tab_column fktc, csrimp.cms_tab_column uktc,
									  	   csrimp.cms_tab fkt, csrimp.cms_tab ukt,
									  	   TABLE(v_key_maps) km
									 WHERE fkt.oracle_schema = schma.old_oracle_schema
									   AND fkt.oracle_table = SUBSTR(r.table_name, 3)
									   AND fktc.oracle_column = s.column_name
									   AND fkc.fk_cons_id = fkcc.fk_cons_id
									   AND fkc.r_cons_id = ukc.uk_cons_id
									   AND ukc.uk_cons_id = ukcc.uk_cons_id
									   AND fkcc.pos = ukcc.pos
									   AND fkcc.column_sid = fktc.column_sid
									   AND ukcc.column_sid = uktc.column_sid
									   AND fktc.tab_sid = fkt.tab_sid
									   AND uktc.tab_sid = ukt.tab_sid
									   AND ukt.oracle_table = km.table_name
									   AND ukt.oracle_schema = km.table_owner
									   AND uktc.oracle_column = km.id_column_name;
									--security_pkg.debugmsg('mapped to fake '||r.table_name||'.'||s.column_name);
									v_mapped := TRUE;
								EXCEPTION
									WHEN NO_DATA_FOUND THEN
										-- nothing, so no id mapping to do
										--security_pkg.debugmsg('failed to map '||r.table_name||'.'||s.column_name);
										NULL;
								END;
							END IF;
					END;
				END IF;
	
				IF NOT v_first THEN
					WriteAppend(v_iselect, ','||chr(10)||'           ');
				END IF;
	
				IF v_mapped	THEN
					IF NOT v_map_tables.EXISTS(v_map_table) THEN
						v_ddl.extend(1);
						v_ddl(v_ddl.count) := 'GRANT SELECT ON '||v_map_table||' TO '||q(schma.new_oracle_schema);
						INSERT INTO csrimp.cms_tidy_ddl (pos, ddl)
						VALUES (v_tidy_pos, 'REVOKE SELECT ON '||v_map_table||' FROM '||q(schma.new_oracle_schema));
						v_tidy_pos := v_tidy_pos + 1;
						v_map_tables(v_map_table) := 1;
					END IF;
					IF v_force_nvl THEN
						WriteAppend(v_iselect, 'NVL(m'||s.column_id||'.'||v_map_new_column||', m.'||q(s.column_name)||')');
					ELSE
						WriteAppend(v_iselect, 'm'||s.column_id||'.'||v_map_new_column);
					END IF;
					WriteAppend(v_ifrom, ','||chr(10)||
						'           '||v_map_table||' m'||s.column_id);
						
					IF dbms_lob.getLength(v_iwhere) = 0 THEN
						WriteAppend(v_iwhere, chr(10)||'     where ');
					ELSE
						WriteAppend(v_iwhere, chr(10)||'       and ');
					END IF;
					WriteAppend(v_iwhere, 'm.'||q(s.column_name)||' = m'||s.column_id||'.'||v_map_old_column);
					IF s.nullable = 'Y' OR v_force_outer THEN
						WriteAppend(v_iwhere, '(+)');
					END IF;
				ELSIF v_static_mapping THEN
					WriteAppend(v_iselect, v_map_new_column);
				ELSE
					WriteAppend(v_iselect, 'm.'||q(s.column_name));
				END IF;
				
				v_first := FALSE;
			END LOOP;
	
			dbms_lob.append(v_isql, v_iselect);
			WriteAppend(v_isql, chr(10));
			dbms_lob.append(v_isql, v_ifrom);		
			IF dbms_lob.getLength(v_iwhere) > 0 THEN
				dbms_lob.append(v_isql, v_iwhere);
			END IF;
			WriteAppend(v_isql, ';'||chr(10));
			IF NOT v_first_table THEN
				WriteAppend(v_isql, chr(10));
			END IF;
			v_first_table := FALSE;
			dbms_lob.append(v_pkg_body, v_isql);
	
			v_temp_sql := 'CREATE TABLE '||q(schma.new_oracle_schema)||'.'||q(r.table_name)||' ('||chr(10);
			dbms_lob.append(v_temp_sql, v_sql);
			WriteAppend(v_temp_sql, ')');
			v_ddl.extend(1);
			v_ddl(v_ddl.count) := v_temp_sql;
			
			v_temp_sql := 'CREATE TABLE '||q(schma.new_oracle_schema)||'.M$'||r.table_id||' ('||chr(10);
			WriteAppend(v_temp_sql, '        CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT(''SECURITY'', ''CSRIMP_SESSION_ID'') NOT NULL,'||chr(10));
			dbms_lob.append(v_temp_sql, v_sql);
			WriteAppend(v_temp_sql, ','||chr(10)||
				'        FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) '||chr(10)||
				'        ON DELETE CASCADE'||chr(10)||
				')');
			v_ddl.extend(1);
			v_ddl(v_ddl.count) := v_temp_sql;
			
			-- the truncate is to avoid ORA-14452: attempt to create, alter or drop an index on temporary table already in use
			-- which we get (even though the session created the table and is the only user) otherwise
			INSERT INTO csrimp.cms_tidy_ddl (pos, ddl)
			VALUES (v_tidy_pos, 'TRUNCATE TABLE '||q(schma.new_oracle_schema)||'.M$'||r.table_id);
			v_tidy_pos := v_tidy_pos + 1;
			INSERT INTO csrimp.cms_tidy_ddl (pos, ddl)
			VALUES (v_tidy_pos, 'DROP TABLE '||q(schma.new_oracle_schema)||'.M$'||r.table_id);
			v_tidy_pos := v_tidy_pos + 1;
			
			v_temp_sql := 'GRANT SELECT, INSERT, UPDATE, DELETE ON '||q(schma.new_oracle_schema)||'.M$'||r.table_id||' TO TOOL_USER';
			v_ddl.extend(1);
			v_ddl(v_ddl.count) := v_temp_sql;
		END LOOP;
		
		IF v_first_table THEN
			WriteAppend(v_pkg_body, '    null;');	
		END IF;
		WriteAppend(v_pkg_body, 'end;'||chr(10)||chr(10)||'end;');

		v_ddl.extend(1);
		v_ddl(v_ddl.count) := v_pkg;
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := v_pkg_body;
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'GRANT EXECUTE ON '||q(schma.new_oracle_schema)||'.m$imp_pkg TO csrimp';
	
		INSERT INTO csrimp.cms_tidy_ddl (pos, ddl)
		VALUES (v_tidy_pos, 'DROP PACKAGE '||q(schma.new_oracle_schema)||'.m$imp_pkg');
		v_tidy_pos := v_tidy_pos + 1;
	END LOOP;
	
	-- table comments
	FOR r IN (SELECT ms.new_oracle_schema, c.table_name, c.comments
				FROM imp_tab_comments c, csrimp.map_cms_schema ms
			   WHERE c.owner = ms.old_oracle_schema
			     AND c.comments IS NOT NULL
				 AND ms.old_oracle_schema NOT IN (
			     		SELECT oracle_schema
			     		  FROM sys_schema)) LOOP
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'COMMENT ON TABLE '||q(r.new_oracle_schema)||'.'||q(r.table_name)||' IS '''||
			REPLACE(r.comments, '''', '''''')||'''';
	END LOOP;
	
	-- column comments
	FOR r IN (SELECT ms.new_oracle_schema, c.table_name, c.column_name, c.comments
				FROM imp_col_comments c, csrimp.map_cms_schema ms
			   WHERE c.owner = ms.old_oracle_schema
			     AND c.comments IS NOT NULL
			     AND ms.old_oracle_schema NOT IN (
			     		SELECT oracle_schema
			     		  FROM sys_schema)) LOOP
		v_ddl.extend(1);
		v_ddl(v_ddl.count) := 'COMMENT ON COLUMN '||q(r.new_oracle_schema)||'.'||q(r.table_name)||'.'||q(r.column_name)||' IS '''||
			REPLACE(r.comments, '''', '''''')||'''';
	END LOOP;

	ExecuteDDL(v_ddl);
END;

-- adds constraints/indexes
PROCEDURE PostCreateImportedSchema
AS
    v_sql							CLOB;
	v_ddl 							t_ddl DEFAULT t_ddl();
	v_first							BOOLEAN;
    v_cnt      						NUMBER;
    v_col_name 						VARCHAR2(30);
    v_nullable						VARCHAR2(1);
BEGIN
	EnableTrace;
	IF HasUnprocessedDDL THEN
		ExecDDLFromLog;
	ELSE
		-- run grants across schemas in the import now the objects exist (if they do)
		FOR r IN (SELECT mso.new_oracle_schema owner, p.table_name, p.privilege, msg.new_oracle_schema grantee
					FROM imp_tab_privs p
					JOIN csrimp.map_cms_schema mso ON p.owner = mso.old_oracle_schema
					JOIN csrimp.map_cms_schema msg ON p.grantee = msg.old_oracle_schema
					JOIN all_users au ON p.owner = au.username
				   WHERE msg.old_oracle_schema NOT IN (
							SELECT oracle_schema
							  FROM sys_schema)
					 AND (mso.new_oracle_schema, p.table_name) IN (
							SELECT owner, object_name
							  FROM all_objects)) LOOP
			v_ddl.extend(1);
			v_ddl(v_ddl.count) := 'GRANT '||r.privilege||' ON '||q(r.owner)||'.'||q(r.table_name)||' TO '||q(r.grantee);
		END LOOP;

		-- Only handles normal indexes
		FOR r in (SELECT i.owner, i.index_name, i.index_type, i.table_name, ms.new_oracle_schema
					FROM imp_indexes i, csrimp.map_cms_schema ms
				   WHERE i.owner = ms.old_oracle_schema
					 AND i.owner = table_owner
					 AND i.generated = 'N'
					 AND i.index_name NOT LIKE '%FTI$%' -- skip for now
					 AND ms.old_oracle_schema NOT IN (
							SELECT oracle_schema
							  FROM cms.sys_schema)) LOOP
			v_sql := 'CREATE INDEX '||q(r.new_oracle_schema)||'.'||q(r.index_name)||' ON '||q(r.new_oracle_schema)||'.'||q(r.table_name)||' (';
			v_first := TRUE;
			
			FOR s IN (SELECT NVL(iie.column_expression, q(iic.column_name)) column_name, iic.descend
						FROM imp_ind_columns iic, imp_ind_expressions iie
					   WHERE iic.index_owner = r.owner
						 AND iic.index_name = r.index_name
						 AND iic.index_owner = iie.index_owner(+)
						 AND iic.index_name = iie.index_name(+)
						 AND iic.column_position = iie.column_position(+)) LOOP
				IF NOT v_first THEN
					WriteAppend(v_sql, ', ');
				END IF;
				v_first := FALSE;
				WriteAppend(v_sql, s.column_name || ' ' || s.descend);
			END LOOP;

			WriteAppend(v_sql, ')');
			v_ddl.extend(1);
			v_ddl(v_ddl.count) := v_sql;
		END LOOP;

		FOR r in (SELECT c.owner, c.table_name, c.constraint_name, c.search_condition,
						 c.deferred, c.deferrable, c.generated, ms.new_oracle_schema,
						 c.status
					FROM imp_constraints c, csrimp.map_cms_schema ms
				   WHERE c.constraint_type IN ('C')
					 AND c.owner = ms.old_oracle_schema
					 AND ms.old_oracle_schema NOT IN (
							SELECT oracle_schema
							  FROM sys_schema)) LOOP

			SELECT COUNT(*), MIN(icc.column_name), MIN(itc.nullable)
			  INTO v_cnt, v_col_name, v_nullable
			  FROM imp_cons_columns icc, imp_tab_columns itc
			 WHERE icc.owner = r.owner AND icc.constraint_name = r.constraint_name AND
				   icc.owner = itc.owner AND icc.table_name = itc.table_name AND
				   icc.column_name = itc.column_name;
		
			IF NOT (v_cnt = 1 AND r.search_condition = '"'||v_col_name||'" IS NOT NULL' AND v_nullable = 'N') THEN
					 
				v_sql := 'ALTER TABLE '||q(r.new_oracle_schema)||'.'||q(r.table_name)||' ADD';
				IF r.generated = 'USER NAME' THEN
					WriteAppend(v_sql, ' CONSTRAINT '||q(r.constraint_name));
				END IF;
				WriteAppend(v_sql, ' CHECK (');
				dbms_lob.append(v_sql, r.search_condition);
				WriteAppend(v_sql, ')');
				
				IF r.deferred = 'DEFERRED' THEN
					WriteAppend(v_sql, ' INITIALLY DEFERRED');
				END IF;
				IF r.deferrable = 'DEFERRABLE' THEN
					WriteAppend(v_sql, ' DEFERRABLE');
				END IF;
				IF r.status = 'DISABLED' THEN
					WriteAppend(v_sql, ' DISABLE');
				END IF;
				
				v_ddl.extend(1);
				v_ddl(v_ddl.count) := v_sql;
			END IF;
		END LOOP;

		FOR r in (SELECT c.owner, c.table_name, c.constraint_name, c.constraint_type, c.index_name,
						 c.deferrable, c.deferred, c.generated, ms.new_oracle_schema, c.status
					FROM imp_constraints c, csrimp.map_cms_schema ms
				   WHERE c.constraint_type IN ('P', 'U')
					 AND c.owner = ms.old_oracle_schema
					 AND ms.old_oracle_schema NOT IN (
							SELECT oracle_schema
							  FROM sys_schema)) LOOP
			v_sql := 'ALTER TABLE '||q(r.new_oracle_schema)||'.'||q(r.table_name)||' ADD';
			IF r.generated = 'USER NAME' THEN
				WriteAppend(v_sql, ' CONSTRAINT '||q(r.constraint_name));
			END IF;
			IF r.constraint_type = 'U' THEN
				WriteAppend(v_sql, ' UNIQUE');
			ELSE
				WriteAppend(v_sql, ' PRIMARY KEY');
			END IF;
			
			WriteAppend(v_sql, ' (');
			v_first := TRUE;
			FOR s IN (SELECT column_name
						FROM imp_cons_columns
					   WHERE owner = r.owner
						 AND constraint_name = r.constraint_name
					   ORDER BY position) LOOP
				IF NOT v_first THEN
					WriteAppend(v_sql, ', ');
				END IF;
				v_first := FALSE;
				WriteAppend(v_sql, q(s.column_name));
			END LOOP;
			WriteAppend(v_sql, ')');
			
			IF r.deferred = 'DEFERRED' THEN
				WriteAppend(v_sql, ' INITIALLY DEFERRED');
			END IF;
			IF r.deferrable = 'DEFERRABLE' THEN
				WriteAppend(v_sql, ' DEFERRABLE');
			END IF;
			IF r.status = 'DISABLED' THEN
				WriteAppend(v_sql, ' DISABLE');
			END IF;
			
			-- Note that we are assuming that there's not a constraint on a table in the schema we
			-- are exporting that is using an index owned by a different schema (which is possible,
			-- but a bit of an odd thing to do).
			IF r.index_name IS NOT NULL AND r.generated = 'USER NAME' THEN
				WriteAppend(v_sql, ' USING INDEX '||q(r.new_oracle_schema)||'.'||q(r.index_name));
			END IF;

			v_ddl.extend(1);
			v_ddl(v_ddl.count) := v_sql;		
		END LOOP;

		FOR r in (
				  -- All imported foreign key constraints and the constraints they reference,
				  -- with duplicate key constraints removed (yes, you really can get these)
				  SELECT ac.owner, ac.table_name, ac.constraint_name, ac.constraint_type, 
						 ac.deferrable, ac.deferred, ac.generated, ac.status,
						 ac.delete_rule, dc.r_owner, dc.r_table_name, dc.r_constraint_name,
						 ms.new_oracle_schema, msr.new_oracle_schema r_new_oracle_schema 
					FROM (
						  -- the collapsed key constraints, and a row number in constraint name order
						  -- for constraints that involve exactly the same columns (i.e. are duplicates) 
						  SELECT owner, table_name, constraint_name,
								 r_owner, r_table_name, r_constraint_name,
								 ROW_NUMBER() OVER (
									PARTITION BY owner, table_name, cols, r_owner, r_table_name, r_cols
									ORDER BY constraint_name
								 ) rn
							FROM (
								  -- all imported key constraints with columns collapsed to a single row per constraint,
								  -- with a string containing a list of column ids in the foreign key constraint and 
								  -- a list of column ids in the referenced primary/unique constraint in the same
								  -- order as they appear in the constraints
								  SELECT owner, table_name, r_owner, r_table_name,
										 constraint_name,
										 listagg(column_id, ',') WITHIN GROUP (ORDER BY position) cols,
										 r_constraint_name,
										 listagg(r_column_id, ',') WITHIN GROUP (ORDER BY r_position) r_cols
									FROM (
										  -- all imported foreign key constraint columns matched to the primary/unique key
										  -- constraint columns.  Also selects the position in the key constraint (position)
										  -- and column ordinal (column_id).
										  SELECT ac.owner, ac.constraint_name, ac.table_name,
												 acc.column_name, rac.owner r_owner, rac.constraint_name r_constraint_name,
												 rac.table_name r_table_name,
												 racc.column_name r_column_name, acc.position, racc.position r_position,
												 atc.column_id, ratc.column_id r_column_id
											FROM cms.imp_constraints ac, cms.imp_cons_columns acc,
												 cms.imp_constraints rac, cms.imp_cons_columns racc,
												 cms.imp_tab_columns atc, cms.imp_tab_columns ratc
										   WHERE ac.csrimp_session_id = acc.csrimp_session_id
											 AND ac.csrimp_session_id = rac.csrimp_session_id 
											 AND ac.csrimp_session_id = racc.csrimp_session_id
											 AND ac.csrimp_session_id = atc.csrimp_session_id
											 AND ac.csrimp_session_id = ratc.csrimp_session_id
											 AND ac.owner = acc.owner AND ac.constraint_name = acc.constraint_name
											 AND ac.r_owner = rac.owner AND ac.r_constraint_name = rac.constraint_name
											 AND rac.owner = racc.owner AND rac.constraint_name = racc.constraint_name
											 AND acc.position = racc.position
											 AND ac.owner = atc.owner AND ac.table_name = atc.table_name AND acc.column_name = atc.column_name
											 AND rac.owner = ratc.owner AND rac.table_name = ratc.table_name AND racc.column_name = ratc.column_name
											 AND ac.owner NOT IN (
													SELECT oracle_schema
													  FROM cms.sys_schema)
											 AND ac.constraint_type IN ('R')
											 )
										   GROUP BY owner,table_name, constraint_name,r_owner, r_table_name, r_constraint_name)) dc,
						 cms.imp_constraints ac, csrimp.map_cms_schema ms, csrimp.map_cms_schema msr
				   WHERE dc.rn = 1
					 AND dc.owner = ac.owner
					 AND dc.table_name = ac.table_name
					 AND dc.constraint_name = ac.constraint_name
					 AND dc.owner = ms.old_oracle_schema
					 AND dc.r_owner = msr.old_oracle_schema) LOOP
			v_sql := 'ALTER TABLE '||q(r.new_oracle_schema)||'.'||q(r.table_name)||' ADD';
			IF r.generated = 'USER NAME' THEN
				WriteAppend(v_sql, ' CONSTRAINT '||q(r.constraint_name));
			END IF;
			WriteAppend(v_sql, ' FOREIGN KEY (');
			v_first := TRUE;
			FOR s IN (SELECT column_name
						FROM imp_cons_columns
					   WHERE owner = r.owner
						 AND constraint_name = r.constraint_name
					   ORDER BY position) LOOP
				IF NOT v_first THEN
					WriteAppend(v_sql, ', ');
				END IF;
				v_first := FALSE;
				WriteAppend(v_sql, q(s.column_name));
			END LOOP;
			WriteAppend(v_sql, ') REFERENCES ');
			WriteAppend(v_sql, q(r.r_new_oracle_schema));
			WriteAppend(v_sql, '.'||q(r.r_table_name)||' (');
			
			v_first := TRUE;
			FOR s IN (SELECT column_name
						FROM imp_cons_columns
					   WHERE owner = r.r_owner
						 AND constraint_name = r.r_constraint_name
					   ORDER BY position) LOOP
				IF NOT v_first THEN
					WriteAppend(v_sql, ', ');
				END IF;
				v_first := FALSE;
				WriteAppend(v_sql, q(s.column_name));
			END LOOP;
			WriteAppend(v_sql, ')');

			IF r.delete_rule = 'CASCADE' THEN
				WriteAppend(v_sql, ' ON DELETE CASCADE');
			ELSIF r.delete_rule = 'SET NULL' THEN
				WriteAppend(v_sql, ' ON DELETE SET NULL');
			END IF;

			IF r.deferred = 'DEFERRED' THEN
				WriteAppend(v_sql, ' INITIALLY DEFERRED');
			END IF;
			IF r.deferrable = 'DEFERRABLE' THEN
				WriteAppend(v_sql, ' DEFERRABLE');
			END IF;
			IF r.status = 'DISABLED' THEN
				WriteAppend(v_sql, ' DISABLE');
			END IF;
			
			v_ddl.extend(1);
			v_ddl(v_ddl.count) := v_sql;		
		END LOOP;	

		-- add constraints / indexes
		ExecuteDDL(v_ddl);
	END IF;
	
	-- create views
	RecreateViews;

	-- drop the temporary tables and import map package
	v_ddl := t_ddl();
	SELECT ddl
	  BULK COLLECT INTO v_ddl
	  FROM csrimp.cms_tidy_ddl
	 ORDER BY pos;
	ExecuteDDL(v_ddl);
END;

PROCEDURE TestDDLImport(
	in_owner						IN	tab.oracle_schema%TYPE,
	in_new_owner					IN	tab.oracle_schema%TYPE
)
AS
	v_owner							VARCHAR2(30);
	v_new_owner						VARCHAR2(30);
BEGIN
	-- no security, never used
	v_owner	:= dq(in_owner);
	v_new_owner := dq(in_new_owner);

	INSERT INTO csrimp.map_cms_schema
		(old_oracle_schema, new_oracle_schema)
	VALUES
		(v_owner, v_new_owner);

	DELETE FROM csrimp.cms_tab;
	DELETE FROM csrimp.cms_tab_column;
	DELETE FROM imp_tables;
	DELETE FROM imp_tab_columns;
	DELETE FROM imp_constraints;
	DELETE FROM imp_cons_columns;
	DELETE FROM imp_indexes;
	DELETE FROM imp_ind_columns;
	DELETE FROM imp_tab_privs;
	DELETE FROM imp_tab_comments;
	DELETE FROM imp_col_comments;
	
	INSERT INTO csrimp.cms_tab (tab_sid, oracle_schema, oracle_table, description,
		format_sql, pk_cons_id, managed, auto_registered, cms_editor, issues,
		flow_sid)
		SELECT tab_sid, oracle_schema, oracle_table, description,
			   format_sql, pk_cons_id, managed, auto_registered, cms_editor, issues,
			   flow_sid
		  FROM tab;

	INSERT INTO csrimp.cms_tab_column (column_sid, tab_sid, oracle_column,
		description, pos, col_type, master_column_sid, enumerated_desc_field,
		enumerated_pos_field, enumerated_colpos_field, enumerated_hidden_field,
		enumerated_colour_field, enumerated_extra_fields, help, check_msg,
		calc_xml, data_type, data_length, data_precision, data_scale, nullable,
		char_length, value_placeholder, helper_pkg, tree_desc_field,
		tree_id_field, tree_parent_id_field, full_text_index_name)
		SELECT column_sid, tab_sid, oracle_column, description, pos, col_type,
			   master_column_sid, enumerated_desc_field, enumerated_pos_field,
			   enumerated_colpos_field, enumerated_hidden_field, 
			   enumerated_colour_field, enumerated_extra_fields, help,
			   check_msg, calc_xml, data_type, data_length, data_precision,
			   data_scale, nullable, char_length, value_placeholder, helper_pkg,
			   tree_desc_field, tree_id_field, tree_parent_id_field,
			   full_text_index_name
		  FROM tab_column;

	INSERT INTO imp_tables (owner, table_name, table_id)
		SELECT owner, table_name, rownum
		  FROM (SELECT owner, table_name
		  		  FROM all_tables
		 		 WHERE owner = v_owner
		 		 ORDER BY owner, table_name);
		  
	INSERT INTO imp_tab_columns (owner, table_name, column_name, data_type, data_length,
		data_precision, data_scale, nullable, column_id, data_default)
		SELECT owner, table_name, column_name, data_type, data_length,
			   data_precision, data_scale, nullable, column_id, to_lob(data_default)
		  FROM all_tab_columns
		 WHERE owner = v_owner;

	INSERT INTO imp_constraints (owner, table_name, constraint_name, constraint_type,
		search_condition, r_owner, r_constraint_name,
		deferrable, deferred, generated, delete_rule, index_name)
		SELECT owner, table_name, constraint_name, constraint_type,
			   to_lob(search_condition), r_owner, r_constraint_name,
			   deferrable, deferred, generated, delete_rule, index_name
		  FROM all_constraints
		 WHERE owner = v_owner;

	INSERT INTO imp_cons_columns (owner, table_name, constraint_name, column_name, position)
		SELECT owner, table_name, constraint_name, column_name, position
		  FROM all_cons_columns
		 WHERE owner = v_owner;
		 
	INSERT INTO imp_indexes (owner, index_name, table_owner, table_name, generated)
		SELECT owner, index_name, table_owner, table_name, generated
		  FROM all_indexes
		 WHERE owner = v_owner;

	INSERT INTO imp_ind_columns (index_owner, index_name, table_owner, table_name, column_name,
		column_position, descend)
		SELECT index_owner, index_name, table_owner, table_name, column_name,
			   column_position, descend
		  FROM all_ind_columns
		 WHERE index_owner = v_owner;

	INSERT INTO imp_tab_privs (grantee, owner, table_name, privilege)
		SELECT grantee, owner, table_name, privilege
		  FROM dba_tab_privs
		 WHERE grantee = v_owner;

	INSERT INTO imp_tab_comments (owner, table_name, comments)
		SELECT owner, table_name, comments
		  FROM all_tab_comments
		 WHERE owner = v_owner
		   AND comments IS NOT NULL;

	INSERT INTO imp_col_comments (owner, table_name, column_name, comments)
		SELECT owner, table_name, column_name, comments
		  FROM all_col_comments
		 WHERE owner = v_owner
		   AND comments IS NOT NULL;

	EnableTraceOnly;
	CreateImportedSchema;
	PostCreateImportedSchema;
END;

PROCEDURE GetTablesForExport(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security, only used by csrexp
	OPEN out_cur FOR
		SELECT owner, table_name, rownum table_id
		  FROM (SELECT owner, table_name
		  		  FROM all_tables
		 		 WHERE owner IN (
		 		 		SELECT oracle_schema
		 		 		  FROM v$cms_schema)
		 		 ORDER BY owner, table_name);
END;

PROCEDURE GetTableDataForExport(
	in_owner						IN	VARCHAR2,
	in_table_name					IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security, only used by csrexp
	OPEN out_cur FOR
		'SELECT * FROM '||dq(in_owner)||'.'||dq(in_table_name);
END;

PROCEDURE SetCmsSchemaMappings(
	in_old_schemas					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_new_schemas					IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_is_sys						NUMBER;
	v_existing_users				VARCHAR2(4000);
BEGIN
	IF NOT (in_old_schemas.COUNT = 0 OR (in_old_schemas.COUNT = 1 AND in_old_schemas(1) IS NULL)) THEN
		FOR i IN 1 .. in_old_schemas.COUNT LOOP
			-- sanity check the mapping
			SELECT COUNT(*)
			  INTO v_is_sys
			  FROM sys_schema
			 WHERE oracle_schema = dq(in_old_schemas(i));
			IF v_is_sys > 0 THEN
				RAISE_APPLICATION_ERROR(-20001, 'Attempting to map from the system schema '||in_old_schemas(i));
			END IF;
			
			SELECT COUNT(*)
			  INTO v_is_sys
			  FROM sys_schema
			 WHERE oracle_schema = dq(in_new_schemas(i));
			IF v_is_sys > 0 THEN
				RAISE_APPLICATION_ERROR(-20001, 'Attempting to map to the system schema '||in_new_schemas(i));
			END IF;

			INSERT INTO csrimp.map_cms_schema
				(old_oracle_schema, new_oracle_schema)
			VALUES
				(dq(in_old_schemas(i)), dq(in_new_schemas(i)));
		END LOOP;
	END IF;
	
	-- make other schemas map to themselves (e.g. CSR->CSR, POSTCODE->POSTCODE)
	-- (it's ok to import data from a non-sys user without remapping, they
	-- will just get created)
	INSERT INTO csrimp.map_cms_schema (old_oracle_schema, new_oracle_schema)
		SELECT DISTINCT oracle_schema, oracle_schema
		  FROM csrimp.cms_tab
		 WHERE oracle_schema NOT IN (
		 		SELECT old_oracle_schema
		 		  FROM csrimp.map_cms_schema);

	-- ensure the non-sys users don't exist
	FOR r IN (SELECT ms.new_oracle_schema
				FROM csrimp.map_cms_schema ms, all_users au
			   WHERE au.username = ms.new_oracle_schema
			     AND ms.new_oracle_schema NOT IN (
			     		SELECT oracle_schema
			     		  FROM sys_schema)) LOOP
		IF v_existing_users IS NOT NULL THEN
			v_existing_users := v_existing_users || ', ';
		END IF;
		v_existing_users := v_existing_users || r.new_oracle_schema;
	END LOOP;
	
	IF v_existing_users IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Attempting to import cms data to existing users: '||v_existing_users);
	END IF;
END;

PROCEDURE GetOracleNames(
	in_flow_sid				IN	security_pkg.T_SID_ID,
	out_tab_sid				OUT	security_pkg.T_SID_ID,
	out_oracle_schema		OUT tab.oracle_schema%TYPE,
	out_oracle_table		OUT tab.oracle_table%TYPE,
	out_flow_item_col_name	OUT tab_column.oracle_column%TYPE
)
AS
	v_exists				NUMBER;
BEGIN
	--todo: cache that info to avoid calling it for each iteration
	BEGIN
		SELECT tab_sid, oracle_schema, oracle_table
		  INTO out_tab_sid, out_oracle_schema, out_oracle_table
		  FROM tab t
		 WHERE t.flow_sid = in_flow_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(ERR_FLOW_TAB_NOT_FOUND, 'cms.tab record for ' || out_oracle_schema || '.' || out_oracle_table || ' not found for flow_sid:'||in_flow_sid);
	END;
	
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE (table_name = out_oracle_table OR table_name = 'C$' || out_oracle_table)
	   AND owner = out_oracle_schema;
	
	IF v_exists = 0 THEN
		RAISE_APPLICATION_ERROR(ERR_FLOW_TAB_NOT_FOUND, 'Oracle table ' || out_oracle_schema || '.' || out_oracle_table || ' not found for flow_sid:'||in_flow_sid);
	END IF;
	
	BEGIN
		SELECT oracle_column
		  INTO out_flow_item_col_name
		  FROM tab_column
		 WHERE tab_sid = out_tab_sid
		   AND col_type = tab_pkg.CT_FLOW_ITEM; 
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(ERR_FLOW_ITEM_COL_NOT_FOUND, 'cms.tab_column flow item record not found for tab_sid:'||out_tab_sid);
	END;
	
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_tab_columns
	 WHERE (table_name = out_oracle_table OR table_name = 'C$' || out_oracle_table)
	   AND owner = out_oracle_schema
	   AND column_name = out_flow_item_col_name;
	
	IF v_exists = 0 THEN
		RAISE_APPLICATION_ERROR(ERR_FLOW_ITEM_COL_NOT_FOUND, 'Oracle flow item column ' || out_oracle_schema || '.' || out_oracle_table || '.' || out_flow_item_col_name || ' not found');
	END IF;
END;

PROCEDURE GetOracleNamesByFlowItem(
	in_flow_item_id			IN	csr.flow_item.flow_item_id%TYPE,
	out_tab_sid				OUT	security_pkg.T_SID_ID,
	out_oracle_schema		OUT tab.oracle_schema%TYPE,
	out_oracle_table		OUT tab.oracle_table%TYPE,
	out_flow_item_col_name	OUT tab_column.oracle_column%TYPE
)
AS
	v_flow_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT flow_sid
	  INTO v_flow_sid
	  FROM csr.flow_item
	 WHERE flow_item_id = in_flow_item_id;
	 
	GetOracleNames(v_flow_sid, out_tab_sid, out_oracle_schema, out_oracle_table, out_flow_item_col_name);
END;

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE
AS 
	v_region_sid			security_pkg.T_SID_ID;
	v_region_sids_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
	v_tab_sid				security_pkg.T_SID_ID;
	v_oracle_schema			tab.oracle_schema%TYPE;
	v_oracle_table			tab.oracle_table%TYPE;
	v_flow_item_col_name	tab_column.oracle_column%TYPE;
BEGIN
	GetOracleNamesByFlowItem(in_flow_item_id, v_tab_sid, v_oracle_schema, v_oracle_table, v_flow_item_col_name);
	
	FOR r IN ( 
		SELECT oracle_column
		  FROM tab_column
		 WHERE tab_sid = v_tab_sid
		   AND col_type = CT_FLOW_REGION
	)
	LOOP
		EXECUTE IMMEDIATE 
			'SELECT '|| q(r.oracle_column) || '
			   FROM '|| q(v_oracle_schema) || '.' || q(v_oracle_table) || ' 
			  WHERE '|| q(v_flow_item_col_name) || ' = :flow_item_id'
			   INTO v_region_sid
			  USING in_flow_item_id; 
			
			v_region_sids_t.extend;  
			v_region_sids_t(v_region_sids_t.COUNT) := v_region_sid;
		
	END LOOP;
	
	RETURN v_region_sids_t;
END;

FUNCTION FlowItemRecordExists(
	in_flow_item_id				IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER
AS 
	v_tab_sid				security_pkg.T_SID_ID;
	v_oracle_schema			tab.oracle_schema%TYPE;
	v_oracle_table			tab.oracle_table%TYPE;
	v_flow_item_col_name	tab_column.oracle_column%TYPE;
	v_exists				NUMBER;
BEGIN
	BEGIN
		GetOracleNamesByFlowItem(in_flow_item_id, v_tab_sid, v_oracle_schema, v_oracle_table, v_flow_item_col_name);
	EXCEPTION
		WHEN FLOW_TAB_NOT_FOUND OR FLOW_ITEM_COL_NOT_FOUND THEN
			RETURN 0;
	END;

	EXECUTE IMMEDIATE 
		'SELECT DECODE(COUNT(*), 0, 0, 1) 
		   FROM '|| q(v_oracle_schema) || '.' || q(v_oracle_table) || ' 
		  WHERE '|| q(v_flow_item_col_name) || ' = :flow_item_id'
		   INTO v_exists
		  USING in_flow_item_id; 
	
	RETURN v_exists;
END;

FUNCTION GetFlowRoleSid(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE, 
	in_col_sid			IN	tab_column.column_sid%TYPE
)RETURN security_pkg.T_SID_ID
AS 
	v_role_sid				security_pkg.T_SID_ID;
	v_tab_sid				security_pkg.T_SID_ID;
	v_oracle_schema			tab.oracle_schema%TYPE;
	v_oracle_table			tab.oracle_table%TYPE;
	v_flow_item_col_name	tab_column.oracle_column%TYPE;
	v_role_col_name			tab_column.oracle_column%TYPE;
BEGIN
	GetOracleNamesByFlowItem(in_flow_item_id, v_tab_sid, v_oracle_schema, v_oracle_table, v_flow_item_col_name);
	
	SELECT oracle_column
	  INTO v_role_col_name
	  FROM tab_column tc
	 WHERE column_sid = in_col_sid;
	 
	EXECUTE IMMEDIATE 
		'SELECT '|| q(v_role_col_name) || '
		   FROM '|| q(v_oracle_schema) || '.' || q(v_oracle_table) || ' 
		  WHERE '|| q(v_flow_item_col_name) || ' = :flow_item_id'
		   INTO v_role_sid
		  USING in_flow_item_id;
	
	RETURN v_role_sid;
END;

FUNCTION GetFlowCompanySid(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE, 
	in_col_sid			IN	tab_column.column_sid%TYPE
)RETURN security_pkg.T_SID_ID
AS 
	v_company_sid			security_pkg.T_SID_ID;
	v_tab_sid				security_pkg.T_SID_ID;
	v_oracle_schema			tab.oracle_schema%TYPE;
	v_oracle_table			tab.oracle_table%TYPE;
	v_flow_item_col_name	tab_column.oracle_column%TYPE;
	v_company_col_name		tab_column.oracle_column%TYPE;
BEGIN
	GetOracleNamesByFlowItem(in_flow_item_id, v_tab_sid, v_oracle_schema, v_oracle_table, v_flow_item_col_name);
	
	SELECT oracle_column
	  INTO v_company_col_name
	  FROM tab_column tc
	 WHERE column_sid = in_col_sid;
	 
	EXECUTE IMMEDIATE 
		'SELECT '|| q(v_company_col_name) || '
		   FROM '|| q(v_oracle_schema) || '.' || q(v_oracle_table) || ' 
		  WHERE '|| q(v_flow_item_col_name) || ' = :flow_item_id'
		   INTO v_company_sid
		  USING in_flow_item_id;
	
	RETURN v_company_sid;
END;

PROCEDURE GenerateUserColumnAlerts(
	in_flow_item_id				IN	csr.flow_item.flow_item_id%TYPE,
	in_set_by_user_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id		IN	csr.flow_state_log.flow_state_log_id%TYPE,
	in_flow_state_transition_id	IN  csr.flow_state_transition.flow_state_transition_id%TYPE
)
AS
	v_tab_sid				security_pkg.T_SID_ID;
	v_oracle_schema			tab.oracle_schema%TYPE;
	v_oracle_table			tab.oracle_table%TYPE;
	v_oracle_column			tab_column.oracle_column%TYPE;
	v_flow_item_col_name	tab_column.oracle_column%TYPE;
	v_coverable				tab_column.coverable%TYPE;
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	GetOracleNamesByFlowItem(in_flow_item_id, v_tab_sid, v_oracle_schema, v_oracle_table, v_flow_item_col_name);

	FOR r IN(
		SELECT fi.app_sid, fta.flow_transition_alert_id, ftacc.alert_manager_flag,
			in_set_by_user_sid, tc.column_sid, in_flow_item_id, in_flow_state_log_id
		  FROM csr.flow_item fi 
		  JOIN csr.flow_state_transition fst ON fi.flow_sid = fst.flow_sid
		  JOIN csr.flow_transition_alert fta ON fst.flow_state_transition_id = fta.flow_state_transition_id
		  JOIN csr.flow_transition_alert_cms_col ftacc ON fta.flow_transition_alert_id = ftacc.flow_transition_alert_id
		  JOIN cms.tab_column tc ON ftacc.column_sid = tc.column_sid
		 WHERE fi.app_sid = security_pkg.getApp
		   AND fi.flow_item_id = in_flow_item_id
		   AND fta.deleted = 0
		   AND fta.to_initiator = 0
		   AND fst.flow_state_transition_id = in_flow_state_transition_id
		   AND tc.col_type IN (cms.tab_pkg.CT_USER, cms.tab_pkg.CT_OWNER_USER)
		   AND ftacc.alert_manager_flag IN (0, 1, 2) --TODO: add check constraint
	)
	LOOP
				
		SELECT oracle_column, coverable
		  INTO v_oracle_column, v_coverable
		  FROM tab_column
		 WHERE column_sid = r.column_sid;	
		
		EXECUTE IMMEDIATE 
		'SELECT '|| q(v_oracle_column) || '
		   FROM '|| q(v_oracle_schema) || '.' || q(v_oracle_table) || ' 
		  WHERE '|| q(v_flow_item_col_name) || ' = :flow_item_id '
		   INTO v_user_sid
		  USING in_flow_item_id;
		
		IF v_user_sid IS NOT NULL THEN
		
			IF r.alert_manager_flag IN (0, 2) THEN --AlertUserOnly, AlertUserAndManager
				--add user col type users
				INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
					from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
				SELECT r.app_sid, csr.flow_item_gen_alert_id_seq.nextval, r.flow_transition_alert_id, 
					in_set_by_user_sid, v_user_sid, r.column_sid, in_flow_item_id, in_flow_state_log_id
				  FROM dual
				 WHERE NOT EXISTS(
					SELECT 1 
					  FROM csr.flow_item_generated_alert figa
					 WHERE figa.app_sid = r.app_sid
					   AND figa.flow_transition_alert_id = r.flow_transition_alert_id
					   AND figa.flow_state_log_id = in_flow_state_log_id
					   AND figa.to_user_sid = v_user_sid
				  );
				
				--find coverable
				IF v_coverable = 1 THEN 
					FOR j IN (
						SELECT user_giving_cover_sid
						  FROM csr.user_cover
						 WHERE user_being_covered_sid = v_user_sid
						   AND start_dtm < SYSDATE
						   AND (end_dtm IS NULL OR end_dtm > SYSDATE)
						   AND cover_terminated = 0
						   AND user_giving_cover_sid <> v_user_sid
					)
					LOOP
						INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
							from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
						SELECT r.app_sid, csr.flow_item_gen_alert_id_seq.nextval, r.flow_transition_alert_id, 
							in_set_by_user_sid, j.user_giving_cover_sid, r.column_sid, in_flow_item_id, in_flow_state_log_id
						  FROM dual
						 WHERE NOT EXISTS(
							SELECT 1 
							  FROM csr.flow_item_generated_alert figa
							 WHERE figa.app_sid = r.app_sid
							   AND figa.flow_transition_alert_id = r.flow_transition_alert_id
							   AND figa.flow_state_log_id = in_flow_state_log_id
							   AND figa.to_user_sid = j.user_giving_cover_sid
						  );
				
					END LOOP;
				END IF;
			END IF;
			--line managers
			IF r.alert_manager_flag IN (1, 2) THEN--AlertUserManagerOnly, AlertUserAndManager
				INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
							from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
				SELECT r.app_sid, csr.flow_item_gen_alert_id_seq.nextval, r.flow_transition_alert_id, 
							in_set_by_user_sid, line_manager_sid, r.column_sid, in_flow_item_id, in_flow_state_log_id
				  FROM csr.csr_user
				 WHERE csr_user_sid = v_user_sid
				   AND line_manager_sid IS NOT NULL
				   AND line_manager_sid <> v_user_sid
				   AND NOT EXISTS(
						SELECT 1 
						  FROM csr.flow_item_generated_alert figa
						 WHERE figa.app_sid = r.app_sid
						   AND figa.flow_transition_alert_id = r.flow_transition_alert_id
						   AND figa.flow_state_log_id = in_flow_state_log_id
						   AND figa.to_user_sid = line_manager_sid
					);
			END IF;
		END IF;
	END LOOP;	
END;

PROCEDURE GenerateRoleColumnAlerts(
	in_flow_item_id				IN	csr.flow_item.flow_item_id%TYPE,
	in_set_by_user_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id		IN	csr.flow_state_log.flow_state_log_id%TYPE,
	in_flow_state_transition_id	IN	csr.flow_state_transition.flow_state_transition_id%TYPE,
	in_region_sids_t			IN	security.T_SID_TABLE
)
AS
	v_role_sid					security_pkg.T_SID_ID;
BEGIN
	
	--specified CMS role column by splitting out into users
	FOR r IN(
		SELECT ftacc.column_sid, fta.flow_transition_alert_id
		  FROM csr.flow_item fi
		  JOIN csr.flow_state_transition fst ON fi.flow_sid = fst.flow_sid
		  JOIN csr.flow_transition_alert fta ON fst.flow_state_transition_id = fta.flow_state_transition_id
		  JOIN csr.flow_transition_alert_cms_col ftacc ON fta.flow_transition_alert_id = ftacc.flow_transition_alert_id
		  JOIN cms.tab_column tc ON ftacc.column_sid = tc.column_sid
		 WHERE fi.app_sid = security_pkg.GetApp
		   AND fi.flow_item_id = in_flow_item_id
		   AND fta.deleted = 0
		   AND fta.to_initiator = 0
		   AND fst.flow_state_transition_id = in_flow_state_transition_id
		   AND tc.col_type IN (cms.tab_pkg.CT_ROLE)
	)
	LOOP
		v_role_sid := GetFlowRoleSid(in_flow_item_id, r.column_sid);
		IF v_role_sid IS NOT NULL THEN 
			--Get the users in that role
			--security_pkg.debugmsg('CT_ROLE users for role_sid:' || v_role_sid || ' flow_transition_alert_id:' || r.flow_transition_alert_id);
			INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
				from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id, processed_dtm)
			SELECT rrm.app_sid, csr.flow_item_gen_alert_id_seq.nextval, r.flow_transition_alert_id, in_set_by_user_sid,
				rrm.user_sid, r.column_sid, in_flow_item_id, in_flow_state_log_id, NULL
			  FROM csr.region_role_member rrm 
			  JOIN TABLE(in_region_sids_t) t ON t.column_value = rrm.region_sid -- perf may be improved if we pass region_sid value when in_region_sids_t length = 1
			  JOIN csr.csr_user cu ON rrm.app_sid = cu.app_sid AND rrm.user_sid = cu.csr_user_sid AND cu.send_alerts = 1
			 WHERE rrm.role_sid = v_role_sid
			   AND NOT EXISTS ( 
				SELECT 1 
				  FROM csr.flow_item_generated_alert figa
				 WHERE figa.app_sid = rrm.app_sid
				   AND figa.flow_transition_alert_id = r.flow_transition_alert_id
				   AND figa.flow_state_log_id = in_flow_state_log_id
				   AND figa.to_user_sid = rrm.user_sid
				
				);
		END IF;
	END LOOP;
END;

PROCEDURE GenerateCompanyColumnAlerts(
	in_flow_item_id				IN	csr.flow_item.flow_item_id%TYPE,
	in_set_by_user_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_log_id		IN	csr.flow_state_log.flow_state_log_id%TYPE,
	in_flow_state_transition_id	IN	csr.flow_state_transition.flow_state_transition_id%TYPE
)
AS
	v_company_sid					security_pkg.T_SID_ID;
BEGIN
	
	--specified CMS company column by splitting out into users
	FOR r IN(
		SELECT ftacc.column_sid, fta.flow_transition_alert_id
		  FROM csr.flow_item fi
		  JOIN csr.flow_state_transition fst ON fi.flow_sid = fst.flow_sid
		  JOIN csr.flow_transition_alert fta ON fst.flow_state_transition_id = fta.flow_state_transition_id
		  JOIN csr.flow_transition_alert_cms_col ftacc ON fta.flow_transition_alert_id = ftacc.flow_transition_alert_id
		  JOIN cms.tab_column tc ON ftacc.column_sid = tc.column_sid
		 WHERE fi.app_sid = security_pkg.GetApp
		   AND fi.flow_item_id = in_flow_item_id
		   AND fta.deleted = 0
		   AND fta.to_initiator = 0
		   AND fst.flow_state_transition_id = in_flow_state_transition_id
		   AND tc.col_type IN (cms.tab_pkg.CT_COMPANY)
	)
	LOOP
		v_company_sid := GetFlowCompanySid(in_flow_item_id, r.column_sid);
		IF v_company_sid IS NOT NULL THEN 
			--Get the users in that company
			--security_pkg.debugmsg('CT_COMPANY users for company_sid:' || v_company_sid || ' flow_transition_alert_id:' || r.flow_transition_alert_id);
			INSERT INTO csr.flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
				from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id, processed_dtm)
			SELECT ccu.app_sid, csr.flow_item_gen_alert_id_seq.nextval, r.flow_transition_alert_id, in_set_by_user_sid,
				ccu.user_sid, r.column_sid, in_flow_item_id, in_flow_state_log_id, NULL
			  FROM chain.v$company_user ccu
			  JOIN csr.csr_user cu ON ccu.app_sid = cu.app_sid AND ccu.user_sid = cu.csr_user_sid AND cu.send_alerts = 1
			 WHERE ccu.company_sid = v_company_sid
			   AND NOT EXISTS ( 
				SELECT 1 
				  FROM csr.flow_item_generated_alert figa
				 WHERE figa.app_sid = ccu.app_sid
				   AND figa.flow_transition_alert_id = r.flow_transition_alert_id
				   AND figa.flow_state_log_id = in_flow_state_log_id
				   AND figa.to_user_sid = ccu.user_sid
				
				);
		END IF;
	END LOOP;
END;

--mark flow generated alerts as processed when the flow item has been deleted from cms
PROCEDURE MarkGenAlertsRefDeletedCms(
	in_flow_transition_alert_id IN csr.flow_transition_alert.flow_transition_alert_id %TYPE
)
AS
	v_tab_sid				security_pkg.T_SID_ID;
	v_oracle_schema			tab.oracle_schema%TYPE;
	v_oracle_table			tab.oracle_table%TYPE;
	v_flow_item_col_name	tab_column.oracle_column%TYPE;
	v_flow_sid				security_pkg.T_SID_ID;
	v_is_managed			tab.managed%TYPE;
BEGIN
	SELECT flow_sid
	  INTO v_flow_sid
	  FROM csr.flow_transition_alert fta 
	  JOIN csr.flow_state_transition fst ON fta.flow_state_transition_id = fst.flow_state_transition_id
	 WHERE fta.flow_transition_alert_id = in_flow_transition_alert_id;
	
	GetOracleNames(v_flow_sid, v_tab_sid, v_oracle_schema, v_oracle_table, v_flow_item_col_name);
		
	SELECT managed
	  INTO v_is_managed
	  FROM tab
	 WHERE tab_sid = v_tab_sid;
	
	IF v_is_managed = 1 THEN
		EXECUTE IMMEDIATE
			'UPDATE csr.flow_item_generated_alert 
				SET processed_dtm = SYSDATE
			  WHERE app_sid = security_pkg.getapp
				AND processed_dtm IS NULL
				AND flow_item_id NOT IN (
					SELECT '|| q(v_flow_item_col_name) ||' 
					  FROM '|| q(v_oracle_schema) || '.' || q('C$'||v_oracle_table) ||'
					 WHERE vers > 0 
					   AND retired_dtm IS NULL
				)
				AND flow_transition_alert_id = :in_flow_transition_alert_id'
			   USING IN in_flow_transition_alert_id;
	ELSE 
		EXECUTE IMMEDIATE
			'UPDATE csr.flow_item_generated_alert 
				SET processed_dtm = SYSDATE
			  WHERE app_sid = security_pkg.getapp
				AND processed_dtm IS NULL
				AND flow_item_id NOT IN (
					SELECT '|| q(v_flow_item_col_name) ||' 
					  FROM '|| q(v_oracle_schema) || '.' || q(v_oracle_table) ||
				')
				AND flow_transition_alert_id = :in_flow_transition_alert_id'
			   USING IN in_flow_transition_alert_id;
	END IF;
END;

FUNCTION TryGetCompanyColTypeName(
	in_tab_sid		IN tab_column.tab_sid%TYPE,
	out_col_name	OUT tab_column.oracle_column%TYPE
)RETURN BOOLEAN
AS
BEGIN
	BEGIN
		SELECT tc.oracle_column
		  INTO out_col_name
		  FROM tab_column tc
		  JOIN uk_cons_col ucc ON tc.column_sid = ucc.column_sid
		  JOIN uk_cons uc ON ucc.uk_cons_id = uc.uk_cons_id
		 WHERE tc.col_type = tab_pkg.CT_COMPANY
		   AND tc.tab_sid = in_tab_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;
	
	RETURN TRUE;
END;

FUNCTION GetParentTabSid(
	in_col_sid		IN tab_column.column_sid%TYPE
)RETURN tab.tab_sid%TYPE
AS
	v_tab_sid	tab.tab_sid%TYPE;
BEGIN
	SELECT uc.tab_sid
	  INTO v_tab_sid
	  FROM fk_cons_col fcc
	  JOIN fk_cons fc ON fc.fk_cons_id = fcc.fk_cons_id
	  JOIN uk_cons uc ON uc.uk_cons_id = fc.r_cons_id
	 WHERE fcc.column_sid = in_col_sid;
	
	RETURN v_tab_sid;
END;

FUNCTION TryGetEnumDescription(
	in_enum_tab_sid		IN tab_column.tab_sid%TYPE,
	in_fk_col_sid		IN tab_column.column_sid%TYPE,
	in_enum_id			IN NUMBER,
	out_description		OUT VARCHAR2
)RETURN BOOLEAN
AS
	v_schema			tab.oracle_schema%TYPE;
	v_table				tab.oracle_table%TYPE;
	v_id_col_name		tab_column.oracle_column%TYPE;
	v_desc_col_name		tab_column.oracle_column%TYPE;
BEGIN
	--Get the schema, table, id_col
	BEGIN
		SELECT t.oracle_schema, t.oracle_table, tc.oracle_column
		  INTO v_schema, v_table, v_id_col_name
		  FROM tab t
		  JOIN uk_cons uc ON uc.tab_sid = t.tab_sid
		  JOIN uk_cons_col ucc ON ucc.uk_cons_id = uc.uk_cons_id
		  JOIN fk_cons fc ON fc.r_cons_id = uc.uk_cons_id
		  JOIN fk_cons_col fcc ON fcc.fk_cons_id = fc.fk_cons_id
		  JOIN tab_column tc ON tc.column_sid = ucc.column_sid
		 WHERE t.tab_sid = in_enum_tab_sid
		   AND fcc.column_sid = in_fk_col_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;
	
	SELECT tc.enumerated_desc_field
	  INTO v_desc_col_name
	  FROM tab_column tc
	 WHERE tc.column_sid = in_fk_col_sid;
	 
	BEGIN
		EXECUTE IMMEDIATE 
			'SELECT '|| q(v_desc_col_name) || '
			   FROM '|| q(v_schema) || '.' || q(v_table) || ' 
			  WHERE '|| q(v_id_col_name) || ' = :1'
			   INTO out_description
			  USING in_enum_id; 
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;
	
	RETURN TRUE;
END;

FUNCTION TryGetEnumValFromMapTable(
	in_enum_tab_sid		IN tab_column.tab_sid%TYPE,
	in_fk_col_sid		IN tab_column.column_sid%TYPE,
	in_original_text	IN VARCHAR2,
	out_enum_id			OUT NUMBER,
	out_translated_val	OUT VARCHAR2
)RETURN BOOLEAN
AS
	v_map_tab_sid			tab_column.tab_sid%TYPE;
	v_map_schema			tab.oracle_schema%TYPE;
	v_map_table				tab.oracle_table%TYPE;
	v_map_desc_col_name		tab_column.oracle_column%TYPE;
	v_map_enum_id_col_name	tab_column.oracle_column%TYPE;
BEGIN
	--Get the mapping table + col
	BEGIN
		SELECT t.enum_translation_tab_sid, mt.oracle_schema, mt.oracle_table, tc.oracle_column
		  INTO v_map_tab_sid, v_map_schema, v_map_table, v_map_enum_id_col_name
		  FROM tab t
		  JOIN tab mt ON mt.tab_sid = t.enum_translation_tab_sid
		  JOIN fk_cons fc ON fc.tab_sid = mt.tab_sid
		  JOIN fk_cons_col fcc ON fcc.fk_cons_id = fc.fk_cons_id
		  JOIN tab_column tc ON tc.column_sid = fcc.column_sid
		 WHERE t.tab_sid = in_enum_tab_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;
	
	--infer the column name from the data type - we expect only one varchar col in the translation table
	SELECT oracle_column
	  INTO v_map_desc_col_name
	  FROM tab_column tc
	 WHERE tc.tab_sid = v_map_tab_sid
	   AND data_type = 'VARCHAR2';
	
	BEGIN
		EXECUTE IMMEDIATE 
			'SELECT '|| q(v_map_enum_id_col_name) || '
			   FROM '|| q(v_map_schema) || '.' || q(v_map_table) || ' 
			  WHERE lower('|| q(v_map_desc_col_name) || ') = :1'
			   INTO out_enum_id
			  USING lower(in_original_text); 
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;

	--get the actual description for the enum - needed for logging purposes
	IF NOT TryGetEnumDescription(
			in_enum_tab_sid		=> in_enum_tab_sid,
			in_fk_col_sid		=> in_fk_col_sid,
			in_enum_id			=> out_enum_id,
			out_description		=> out_translated_val
		)
	THEN
		RETURN FALSE;
	END IF;
	
	RETURN TRUE;
END;

FUNCTION TryGetEnumVal(
	in_tab_sid			IN tab_column.tab_sid%TYPE,
	in_fk_col_sid		IN tab_column.column_sid%TYPE,
	in_original_text	IN VARCHAR2,
	out_enum_id			OUT NUMBER
)RETURN BOOLEAN
AS
	v_uk_col_name	tab_column.oracle_column%TYPE;
	v_desc_col_name	tab_column.oracle_column%TYPE;
	v_schema_name	tab.oracle_schema%TYPE;
	v_table_name	tab.oracle_table%TYPE;
BEGIN
	--get enum id column name using the fk col 
	SELECT oracle_column, t.oracle_schema, t.oracle_table
	  INTO v_uk_col_name, v_schema_name, v_table_name
	  FROM tab_column tc
	  JOIN tab t ON t.tab_sid = tc.tab_sid
	  JOIN uk_cons_col ucc ON ucc.column_sid = tc.column_sid
	  JOIN fk_cons fc ON fc.r_cons_id = ucc.uk_cons_id
	  JOIN fk_cons_col fcc ON fcc.fk_cons_id = fc.fk_cons_id
	 WHERE tc.tab_sid = in_tab_sid
	   AND fcc.column_sid = in_fk_col_sid;
	
	--get desc_field column name
	SELECT tc.enumerated_desc_field
	  INTO v_desc_col_name
	  FROM tab_column tc
	 WHERE tc.column_sid = in_fk_col_sid;
	   
	BEGIN
		EXECUTE IMMEDIATE 
			'SELECT '|| q(v_uk_col_name) || '
			   FROM '|| q(v_schema_name) || '.' || q(v_table_name) || ' 
			  WHERE lower('|| q(v_desc_col_name) || ') = :1'
			   INTO out_enum_id
			  USING lower(in_original_text); 
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;
	
	RETURN TRUE;
END;

FUNCTION GetUCColsInclColType(
	in_tab_sid			cms.tab.tab_sid%TYPE,
	in_col_type_incl	cms.tab_column.col_type%TYPE
) RETURN security.T_VARCHAR2_TABLE
AS
	v_cols			security.T_VARCHAR2_TABLE;
	v_uk_cons_id	uk_cons.uk_cons_id%TYPE;
BEGIN
	BEGIN
		 SELECT uk_cons_id 
		   INTO v_uk_cons_id
		   FROM uk_cons uc
		  WHERE uc.tab_sid = in_tab_sid
			AND EXISTS (
				SELECT 1
				  FROM uk_cons_col ucc2
				  JOIN tab_column tc2 ON tc2.column_sid = ucc2.column_sid
				 WHERE ucc2.uk_cons_id = uc.uk_cons_id
				   AND tc2.col_type = in_col_type_incl
			);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			RAISE_APPLICATION_ERROR(-20001, 'Expected exactly one unique constraint that contains a column of column type:'||in_col_type_incl);
		WHEN TOO_MANY_ROWS THEN 
			RAISE_APPLICATION_ERROR(-20001, 'Expected exactly one unique constraint that contains a column of column type:'||in_col_type_incl);
	END;
	
	SELECT security.T_VARCHAR2_ROW(tc.column_sid, tc.oracle_column)
	  BULK COLLECT INTO v_cols
	  FROM tab_column tc
	  JOIN uk_cons_col ucc ON ucc.column_sid = tc.column_sid
	 WHERE ucc.uk_cons_id = v_uk_cons_id;
	
	RETURN v_cols;
END;

PROCEDURE GatherStats
AS
BEGIN
	dbms_stats.gather_schema_stats(
		ownname => NULL,
		granularity => 'AUTO', 
		block_sample => FALSE, 
		cascade => TRUE, 
		degree => DBMS_STATS.DEFAULT_DEGREE, 
		method_opt => 'FOR ALL COLUMNS SIZE 1', 
		options => 'GATHER');	
END;

PROCEDURE GetEnumGroups(
	out_enum_tabs_cur				OUT	SYS_REFCURSOR,
	out_enum_groups_cur				OUT	SYS_REFCURSOR,
	out_enum_groups_members_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security, its effectively basedata
	OPEN out_enum_tabs_cur FOR
		SELECT tab_sid, label, replace_existing_filters
		  FROM enum_group_tab
		 ORDER BY tab_sid;
	
	OPEN out_enum_groups_cur FOR
		SELECT tab_sid, enum_group_id, group_label 	
		  FROM enum_group
		 ORDER BY tab_sid, enum_group_id;

	OPEN out_enum_groups_members_cur FOR 
		SELECT enum_group_id, enum_group_member_id
		  FROM enum_group_member
		 ORDER BY enum_group_id, enum_group_member_id;
END;

PROCEDURE SaveEnumGroup(
	in_enum_group_id				IN  enum_group.enum_group_id%TYPE,
	in_tab_sid     					IN  enum_group.tab_sid%TYPE,	
	in_group_label					IN  enum_group.group_label%TYPE,
	in_member_ids     				IN  security.security_pkg.T_SID_IDS,
	out_enum_group_id				OUT enum_group.enum_group_id%TYPE
)
AS
	v_member_id_table 	security.t_sid_table := security_pkg.SidArrayToTable(in_member_ids);
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied editing enum groups');
	END IF;
	
	IF in_enum_group_id IS NULL THEN
		INSERT INTO enum_group (tab_sid, enum_group_id, group_label) 
			 VALUES (in_tab_sid, enum_group_id_seq.NEXTVAL, in_group_label)
		  RETURNING enum_group_id INTO out_enum_group_id;
	ELSE
		UPDATE enum_group 
		   SET group_label = in_group_label
		 WHERE tab_sid = in_tab_sid
		   AND enum_group_id = in_enum_group_id;
		
		out_enum_group_id := in_enum_group_id;
	END IF;
	
	-- Now sort out the members
	DELETE FROM enum_group_member
	 WHERE app_sid = security_pkg.GetApp
	   AND enum_group_id = out_enum_group_id ;
		
	INSERT INTO enum_group_member (enum_group_id, enum_group_member_id)
		SELECT out_enum_group_id,  s.column_value
		  FROM TABLE(v_member_id_table) s;
END;

PROCEDURE SaveEnumTab(
	in_tab_sid						IN  enum_group_tab.tab_sid%TYPE,
	in_label						IN  enum_group_tab.label%TYPE,
	in_replace_existing_filters		IN  enum_group_tab.replace_existing_filters%TYPE
)
AS
	v_exists						NUMBER;
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied editing enum groups');
	END IF;
	
	SELECT COUNT (tab_sid) 
	  INTO v_exists
	  FROM enum_group_tab 
	 WHERE tab_sid = in_tab_sid;
		
	IF v_exists = 0 THEN
		INSERT INTO enum_group_tab (tab_sid, label, replace_existing_filters) 
			 VALUES (in_tab_sid, in_label, in_replace_existing_filters);
	ELSE
		UPDATE enum_group_tab 
		   SET label = in_label,
		       replace_existing_filters = in_replace_existing_filters
		 WHERE tab_sid = in_tab_sid;
	END IF;
END;

PROCEDURE DeleteRemainingEnumGroups (
	in_tab_sid						IN  enum_group_tab.tab_sid%TYPE,
	in_group_ids_to_keep			IN  security.security_pkg.T_SID_IDS
) 
AS
	v_group_ids_to_keep				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_group_ids_to_keep);
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied editing enum groups');
	END IF;
	
	DELETE FROM enum_group_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND enum_group_id IN (
		SELECT enum_group_id
		  FROM enum_group
		 WHERE tab_sid = in_tab_sid
		   AND enum_group_id NOT IN (SELECT column_value FROM TABLE(v_group_ids_to_keep))
	 );
	
	DELETE FROM enum_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND tab_sid = in_tab_sid
	   AND enum_group_id NOT IN (SELECT column_value FROM TABLE(v_group_ids_to_keep));
END;

PROCEDURE DeleteEnumTab(
	in_tab_sid						IN  enum_group.tab_sid%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied editing enum groups');
	END IF;
	
	DELETE FROM enum_group_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND enum_group_id IN (
		SELECT enum_group_id 
		  FROM enum_group 
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND tab_sid =  in_tab_sid
	  );
		 
	DELETE FROM enum_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND tab_sid = in_tab_sid;
		 
	DELETE FROM enum_group_tab 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND tab_sid = in_tab_sid;
END;

PROCEDURE GetCmsTableFlowValues(
	in_aggregate_ind_group_id	IN	csr.aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security.security_pkg.T_OUTPUT_CUR
)
AS
	v_cms_query			VARCHAR2(1000);
BEGIN
	-- No special permissions required. Permission check made in GetFlowStateValues.
	DELETE FROM csr.temp_flow_item_region;

	-- Run in a loop as there can be more than one flow_region column
	FOR r IN (
		SELECT t.oracle_schema, t.oracle_table, tc1.oracle_column flow_item_col, tc2.oracle_column flow_region_col
		  FROM csr.flow f
		  JOIN tab t ON f.flow_sid = t.flow_sid
		  JOIN tab_column tc1 ON t.tab_sid = tc1.tab_sid AND tc1.col_type = cms.tab_pkg.CT_FLOW_ITEM
		  JOIN tab_column tc2 ON t.tab_sid = tc2.tab_sid AND tc2.col_type = cms.tab_pkg.CT_FLOW_REGION
		 WHERE f.app_sid = SYS_CONTEXT('security', 'app')
		   AND f.aggregate_ind_group_id = in_aggregate_ind_group_id
	) LOOP

		v_cms_query := 'INSERT INTO csr.temp_flow_item_region (flow_item_id, region_sid)
						SELECT ' || r.flow_item_col || ', ' || r.flow_region_col || '
						  FROM ' || r.oracle_schema || '.' || r.oracle_table || '
						 WHERE ' || r.flow_item_col || ' IS NOT NULL
						   AND ' || r.flow_region_col || ' IS NOT NULL';
		EXECUTE IMMEDIATE v_cms_query;
	
	END LOOP;

	csr.flow_report_pkg.INTERNAL_GetFlowStateValues(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		in_start_dtm				=> in_start_dtm,
		in_end_dtm					=> in_end_dtm,
		values_cur					=> out_cur
	);
END;

END;
/
