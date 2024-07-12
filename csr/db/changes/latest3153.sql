define version=3153
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
/*
 * US10705 pulled from release (latest3150_14)
 *
CREATE TABLE CSR.TAB_DESCRIPTION(
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TAB_ID				NUMBER(10, 0)	NOT NULL,
	LANG				VARCHAR2(10)	NOT NULL,
	DESCRIPTION			VARCHAR2(1023)	NOT NULL,
	LAST_CHANGED_DTM	DATE,
	CONSTRAINT PK_TAB_DESCRIPTION PRIMARY KEY (APP_SID, TAB_ID, LANG)
)
;
CREATE TABLE CSRIMP.TAB_DESCRIPTION(
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAB_ID				NUMBER(10, 0)	NOT NULL,
	LANG				VARCHAR2(10)	NOT NULL,
	DESCRIPTION			VARCHAR2(1023)	NOT NULL,
	LAST_CHANGED_DTM	DATE,
	CONSTRAINT PK_TAB_DESCRIPTION PRIMARY KEY (CSRIMP_SESSION_ID, TAB_ID, LANG),
	CONSTRAINT FK_TAB_DESCRIPTION FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
)
;
CREATE TABLE CSR.TAB_PORTLET_DESCRIPTION(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TAB_PORTLET_ID				NUMBER(10, 0)	NOT NULL,
	LANG						VARCHAR2(10)	NOT NULL,
	DESCRIPTION					VARCHAR2(1023)	NOT NULL,
	LAST_CHANGED_DTM			DATE,
	CONSTRAINT PK_TAB_PORTLET_DESCRIPTION PRIMARY KEY (APP_SID, TAB_PORTLET_ID, LANG)
)
;
CREATE TABLE CSRIMP.TAB_PORTLET_DESCRIPTION(
	CSRIMP_SESSION_ID 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAB_PORTLET_ID				NUMBER(10, 0)	NOT NULL,
	LANG						VARCHAR2(10)	NOT NULL,
	DESCRIPTION					VARCHAR2(1023)	NOT NULL,
	LAST_CHANGED_DTM			DATE,
	CONSTRAINT PK_TAB_PORTLET_DESCRIPTION PRIMARY KEY (CSRIMP_SESSION_ID, TAB_PORTLET_ID, LANG),
	CONSTRAINT FK_TAB_PORTLET_DESC_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
)
;
*/

ALTER TABLE csr.target_dashboard_ind_member DROP COLUMN description;
ALTER TABLE csr.target_dashboard_reg_member DROP COLUMN description;
ALTER TABLE csrimp.target_dashboard_ind_member DROP COLUMN description;
ALTER TABLE csrimp.target_dashboard_reg_member DROP COLUMN description;
TRUNCATE TABLE surveys.answer_file;
ALTER TABLE surveys.answer_file DISABLE CONSTRAINT FK_ANSWER_FILE_FILE;
TRUNCATE TABLE surveys.submission_file;
ALTER TABLE surveys.answer_file ENABLE CONSTRAINT FK_ANSWER_FILE_FILE;
ALTER TABLE surveys.submission_file DROP COLUMN URI;
ALTER TABLE surveys.submission_file ADD FILE_PATH VARCHAR2(2000) NOT NULL;
DECLARE
	TYPE t_varchar2_array		IS TABLE OF VARCHAR2(30);
	v_owner						VARCHAR2(30) := 'SURVEYS';
	v_table_name				VARCHAR2(30);
	v_object_list				t_varchar2_array;
	v_object_rename_to_list		t_varchar2_array;
	FUNCTION ColumnExists(
		in_owner			IN	all_tab_columns.owner%TYPE,
		in_table_name		IN	all_tab_columns.table_name%TYPE,
		in_column_name		IN	all_tab_columns.column_name%TYPE
	) RETURN BOOLEAN
	AS
		v_count					NUMBER(10);
	BEGIN
		SELECT COUNT(*) 
		  INTO v_count
		  FROM all_tab_columns
		 WHERE owner = UPPER(in_owner)
		   AND table_name = UPPER(in_table_name)
		   AND column_name = UPPER(in_column_name);
		RETURN v_count != 0;
	END;
	FUNCTION ConstraintExists(
		in_owner			IN	all_constraints.owner%TYPE,
		in_table_name		IN	all_constraints.table_name%TYPE,
		in_constraint_name	IN	all_constraints.constraint_name%TYPE
	) RETURN BOOLEAN
	AS
		v_count					NUMBER(10);
	BEGIN
		SELECT COUNT(*) 
		  INTO v_count
		  FROM all_constraints
		 WHERE owner = UPPER(in_owner)
		   AND table_name = UPPER(in_table_name)
		   AND constraint_name = UPPER(in_constraint_name); 
		
		RETURN v_count != 0;
	END;
	FUNCTION IndexExists(
		in_owner			IN	all_indexes.owner%TYPE,
		in_index_name		IN	all_indexes.index_name%TYPE
	) RETURN BOOLEAN
	AS
		v_count					NUMBER(10);
	BEGIN
		SELECT COUNT(*) 
		  INTO v_count
		  FROM all_indexes
		 WHERE owner = UPPER(in_owner)
		   AND index_name = UPPER(in_index_name); 
		
		RETURN v_count != 0;
	END;
	
	FUNCTION TableExists(
		in_owner			IN	all_tables.owner%TYPE,
		in_table_name		IN	all_tables.table_name%TYPE
	) RETURN BOOLEAN
	AS
		v_count					NUMBER(10);
	BEGIN
		SELECT COUNT(*) 
		  INTO v_count
		  FROM all_tables
		 WHERE owner = UPPER(in_owner)
		   AND table_name = UPPER(in_table_name); 
		
		RETURN v_count != 0;
	END;
	
	PROCEDURE RenameColumns(
		in_owner					IN	all_tab_columns.owner%TYPE,
		in_table_name				IN	all_tab_columns.table_name%TYPE,
		in_column_list				IN	t_varchar2_array,
		in_column_rename_to_list	IN	t_varchar2_array
	)
	AS
	BEGIN
		FOR i IN 1 .. in_column_list.COUNT
		LOOP
			IF ColumnExists(in_owner, in_table_name, in_column_list(i)) THEN
				EXECUTE IMMEDIATE 'ALTER TABLE '||in_owner||'.'||in_table_name||' RENAME COLUMN '|| in_column_list(i)||' TO '||in_column_rename_to_list(i);
			END IF;
		END LOOP;		
	END;
	PROCEDURE RenameConstraints(
		in_owner						IN	all_constraints.owner%TYPE,
		in_table_name					IN	all_constraints.table_name%TYPE,
		in_constraint_list				IN	t_varchar2_array,
		in_constraint_rename_to_list	IN	t_varchar2_array
	)
	AS
	BEGIN
		FOR i IN 1 .. in_constraint_list.COUNT
		LOOP
			IF ConstraintExists(in_owner, in_table_name, in_constraint_list(i)) THEN
				EXECUTE IMMEDIATE 'ALTER TABLE '||in_owner||'.'||in_table_name||' RENAME CONSTRAINT '|| in_constraint_list(i)||' TO '||in_constraint_rename_to_list(i);
			END IF;
		END LOOP;		
	END;
	PROCEDURE RenameIndexes(
		in_owner					IN	all_indexes.owner%TYPE,
		in_index_list				IN	t_varchar2_array,
		in_index_rename_to_list		IN	t_varchar2_array
	)
	AS
	BEGIN
		FOR i IN 1 .. in_index_list.COUNT
		LOOP
			IF IndexExists(in_owner, in_index_list(i)) THEN
				EXECUTE IMMEDIATE 'ALTER INDEX '||in_owner||'.'||in_index_list(i)||' RENAME '|| ' TO '||in_index_rename_to_list(i);
			END IF;
		END LOOP;		
	END;
	
	PROCEDURE RenameTables(
		in_owner 					IN	all_tables.owner%TYPE,
		in_table_list				IN	t_varchar2_array,
		in_table_rename_to_list		IN	t_varchar2_array
	)
	AS
	BEGIN
		FOR i IN 1 .. in_table_list.COUNT
		LOOP
			IF TableExists(in_owner, in_table_list(i)) THEN
				EXECUTE IMMEDIATE 'ALTER TABLE '||in_owner||'.'||in_table_list(i)||' RENAME '|| ' TO '||in_table_rename_to_list(i);
			END IF;
		END LOOP;		
	END;
BEGIN
	-- rename columns response_submission
	v_table_name := 'RESPONSE_SUBMISSION';
	v_object_list := t_varchar2_array('SUBMISSION_ID', 'SUBMITTED_DTM', 'SUBMITTED_BY_USER_SID');
	v_object_rename_to_list := t_varchar2_array('SNAPSHOT_ID', 'SNAPSHOT_DTM', 'SNAPSHOT_BY_USER_SID');
	RenameColumns(v_owner, v_table_name, v_object_list, v_object_rename_to_list);
	
	-- rename columns response
	v_table_name := 'RESPONSE';
	v_object_list := t_varchar2_array('LATEST_SUBMISSION_ID');
	v_object_rename_to_list := t_varchar2_array('LATEST_SNAPSHOT_ID');
	RenameColumns(v_owner, v_table_name, v_object_list, v_object_rename_to_list);
	-- rename columns answer
	v_table_name := 'ANSWER';
	v_object_list := t_varchar2_array('SUBMISSION_ID');
	v_object_rename_to_list := t_varchar2_array('SNAPSHOT_ID');
	RenameColumns(v_owner, v_table_name, v_object_list, v_object_rename_to_list);
	
	-- rename columns submission_file
	v_table_name := 'SUBMISSION_FILE';
	v_object_list := t_varchar2_array('SUBMISSION_ID', 'SUBMISSION_FILE_ID');
	v_object_rename_to_list := t_varchar2_array('SNAPSHOT_ID', 'SNAPSHOT_FILE_ID');
	RenameColumns(v_owner, v_table_name, v_object_list, v_object_rename_to_list);
	-- rename columns answer_file
	v_table_name := 'ANSWER_FILE';
	v_object_list := t_varchar2_array('SUBMISSION_FILE_ID');
	v_object_rename_to_list := t_varchar2_array('SNAPSHOT_FILE_ID');
	RenameColumns(v_owner, v_table_name, v_object_list, v_object_rename_to_list);
	-- rename constraints response_submission
	v_table_name := 'RESPONSE_SUBMISSION';
	v_object_list := t_varchar2_array('FK_RESPONSE_SUB_SURVEY_VERSION', 'FK_SUBMISSION_RESPONSE', 'FK_SUBMISSION_USER', 'PK_SURVEY_RESPONSE_SUBMISSION');
	v_object_rename_to_list := t_varchar2_array('FK_RESPONSE_SNAP_SURVEY_VER', 'FK_SNAPSHOT_RESPONSE', 'FK_SNAPSHOT_USER', 'PK_SURVEY_RESPONSE_SNAPSHOT');
	RenameConstraints(v_owner, v_table_name, v_object_list, v_object_rename_to_list);
	-- rename constraints response
	v_table_name := 'RESPONSE';
	v_object_list := t_varchar2_array('FK_RESPONSE_SUBMISSION');
	v_object_rename_to_list := t_varchar2_array('FK_RESPONSE_SNAPSHOT');
	RenameConstraints(v_owner, v_table_name, v_object_list, v_object_rename_to_list);
	-- rename constraints answer
	v_table_name := 'ANSWER';
	v_object_list := t_varchar2_array('FK_SUBMISSION_ANSWER');
	v_object_rename_to_list := t_varchar2_array('FK_SNAPSHOT_ANSWER');
	RenameConstraints(v_owner, v_table_name, v_object_list, v_object_rename_to_list);
	-- rename constraints submission_file
	v_table_name := 'SUBMISSION_FILE';
	v_object_list := t_varchar2_array('FK_SUBMISSION_FILE_RESPONSE', 'FK_SUB_FILE_CUSTOMER', 'FK_SUB_FILE_UPLOADED_USER', 'PK_SUBMISSION_FILE');
	v_object_rename_to_list := t_varchar2_array('FK_SNAPSHOT_FILE_RESPONSE', 'FK_SNAPSHOT_FILE_CUSTOMER', 'FK_SNAPSHOT_FILE_UPLOADED_USER', 'PK_SNAPSHOT_FILE');
	RenameConstraints(v_owner, v_table_name, v_object_list, v_object_rename_to_list);
	-- rename indexes
	v_object_list := t_varchar2_array('IX_RESPONSE_SUBM_SUBMITTED_BY_', 'IX_RESPONSE_SUB_SURVEY_VERSION', 'IX_RESPONSE_SURVEY', 'UK_ANSWER_SUBMISSION');
	v_object_rename_to_list := t_varchar2_array('IX_RESPONSE_SNAP_SUBMITTED_BY_', 'IX_RESPONSE_SNAP_SURVEY_VER', 'IX_RESPONSE_SNAP_SURVEY', 'UK_ANSWER_SNAPSHOT');
	RenameIndexes(v_owner, v_object_list, v_object_rename_to_list);	
	-- rename tables
	v_object_list := t_varchar2_array('RESPONSE_SUBMISSION', 'SUBMISSION_FILE');
	v_object_rename_to_list := t_varchar2_array('RESPONSE_SNAPSHOT', 'SNAPSHOT_FILE');
	RenameTables(v_owner, v_object_list, v_object_rename_to_list);	
END;
/
ALTER TABLE surveys.survey_section ADD HIDE_TITLE NUMBER(1) DEFAULT 0 NOT NULL;
/*
 * US10705 pulled from release (latest3150_14)
 *
ALTER TABLE CSR.TAB_DESCRIPTION ADD CONSTRAINT FK_TAB_DESCRIPTION_TAB
	FOREIGN KEY (APP_SID, TAB_ID)
	REFERENCES CSR.TAB(APP_SID, TAB_ID)
	ON DELETE CASCADE
;
ALTER TABLE CSR.TAB_PORTLET_DESCRIPTION ADD CONSTRAINT FK_TAB_PORTLET_DESCRIPTION
	FOREIGN KEY (APP_SID, TAB_PORTLET_ID)
	REFERENCES CSR.TAB_PORTLET(APP_SID, TAB_PORTLET_ID)
	ON DELETE CASCADE
;
*/
ALTER TABLE surveys.survey_section MODIFY HIDE_TITLE NUMBER(1,0);
ALTER TABLE surveys.survey_section ADD CONSTRAINT CHK_SS_HIDE_TITLE_0_1 CHECK (HIDE_TITLE IN (0,1));
DECLARE
	v_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tables
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'MAP_PLUGIN_TYPE';
	
	IF v_count != 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE csrimp.map_plugin_type CASCADE CONSTRAINTS';
	END IF;
END;
/


GRANT SELECT ON cms.uk_cons_col TO chain;
/*
 * US10705 pulled from release (latest3150_14)
 *
grant select,insert,update,delete on csrimp.tab_description to tool_user;
grant insert on csr.tab_description to csrimp;
grant select,insert,update,delete on csrimp.tab_portlet_description to tool_user;
grant insert on csr.tab_portlet_description to csrimp;
*/
GRANT EXECUTE ON surveys.survey_pkg to csr;
GRANT INSERT ON security.web_resource to surveys;
GRANT SELECT, INSERT, UPDATE ON csr.compliance_item_history TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_item_history TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_root_regions TO tool_user;




/*
 * US10705 pulled from release (latest3150_14)
 *
CREATE OR REPLACE VIEW csr.v$tab_user AS
SELECT t.tab_id, t.app_sid, t.layout, NVL(td.description, tden.description) name , t.is_shared, t.is_hideable, t.override_pos, tu.user_sid, tu.pos, tu.is_owner, tu.is_hidden, t.portal_group
  FROM csr.tab t
  JOIN csr.tab_user tu ON t.app_sid = tu.app_sid AND t.tab_id = tu.tab_id
  LEFT JOIN csr.tab_description td ON td.app_sid = tu.app_sid AND t.tab_id = td.tab_id AND td.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
  LEFT JOIN csr.tab_description tden ON tden.app_sid = tu.app_sid AND t.tab_id = tden.tab_id AND tden.lang = 'en';




BEGIN
	INSERT INTO csr.tab_description(app_sid, tab_id, lang, description, last_changed_dtm)
		SELECT t.app_sid, t.tab_id, ts.lang, NVL(td.translated, t.name), SYSDATE
		  FROM csr.tab t 
		  JOIN aspen2.translation_set ts ON ts.application_sid = t.app_sid
		LEFT JOIN aspen2.translation tr ON tr.original = t.name
		AND tr.application_sid = t.app_sid
		LEFT JOIN aspen2.translated td ON td.original_hash = tr.original_hash
		AND td.application_sid = tr.application_sid 
		AND td.lang = ts.lang
		 WHERE NOT EXISTS
			(SELECT 1 FROM csr.tab_description WHERE tab_id = t.tab_id AND lang = ts.lang AND app_sid = t.app_sid);
END;
/

BEGIN
	INSERT INTO csr.tab_portlet_description(app_sid,tab_portlet_id, lang, description, last_changed_dtm)
	SELECT cp.app_sid, tp.tab_portlet_id, l.lang, COALESCE(SUBSTR(REGEXP_SUBSTR(dbms_lob.substr(tp.state,255,1),'portletTitle":"[^"]*',1),16), td.translated, p.name) description, SYSDATE
	  FROM csr.customer_portlet cp
	  JOIN csr.tab_portlet tp ON cp.customer_portlet_sid = tp.customer_portlet_sid AND cp.app_sid = tp.app_sid
	  JOIN csr.portlet p ON p.portlet_id = cp.portlet_id
	  JOIN (
		SELECT application_sid, lang
		  FROM aspen2.translation_set
		UNION
		SELECT app_sid, 'en'
		  FROM csr.customer_portlet
		) l ON l.application_sid = cp.app_sid
	  LEFT JOIN aspen2.translation tr ON p.name = tr.original AND tr.application_sid = cp.app_sid
	  LEFT JOIN aspen2.translated td ON tr.original_hash = td.original_hash AND tr.application_sid = td.application_sid AND td.lang = l.lang;
END;
/
*/
DECLARE
	v_card_id		NUMBER(10);
BEGIN
	-- log off first
	security.user_pkg.LogonAdmin;
	
	SELECT MIN(card_id)
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Region.Filters.RegionFilter';
	
	-- disable region filter card for sites that aren't using it
	-- as its slowing page loads down a lot
	DELETE FROM chain.card_group_card
	 WHERE card_id = v_card_id
	   AND app_sid NOT IN (
		SELECT f.app_sid
		  FROM chain.filter_type ft
		  JOIN chain.filter f ON ft.filter_type_id = f.filter_type_id
		 WHERE ft.card_id = v_card_id
		 UNION
		SELECT fic.app_sid
		  FROM chain.filter_item_config fic
		 WHERE LOWER(fic.item_name) LIKE 'regionfilter%'
		   AND fic.include_in_filter = 1
	);
END;
/
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (101, 'Extended region filtering', 'EnableRegionFiltering', 'Enable region filtering adapters on CMS and compliance pages, to allow filtering records by fields on a region. NOTE: This is disabled by default as it can have a significant impact on the page load times, especially for sites with large numbers of tags/tag groups.');

/*
 * DE7334 pulled from release (latest3150_20)
 *
DECLARE
	v_base_tag_group_id NUMBER;
	v_base_tag_id NUMBER;
	v_this_pos NUMBER;
BEGIN
	FOR r IN (
		SELECT a.app_sid, c.host, a.tag_group_id, a.name, a.lang
		  FROM csr.tag_group_description a
		  JOIN csr.tag_group_description b ON a.app_sid = b.app_sid AND a.name = b.name AND a.lang = b.lang AND a.tag_group_id != b.tag_group_id
		  JOIN csr.customer c ON c.app_sid = a.app_sid
		 GROUP BY a.app_sid, c.host, a.tag_group_id, a.name, a.lang
		 ORDER BY a.tag_group_id)
	LOOP
		SELECT MIN(tag_group_id) INTO v_base_tag_group_id
		  FROM csr.tag_group_description 
		 WHERE app_sid = r.app_sid AND
			name = r.name AND 
			lang = r.lang;
		IF r.tag_group_id = v_base_tag_group_id THEN
			dbms_output.put_line('skip '||v_base_tag_group_id);
			CONTINUE;
		END IF;
		
		dbms_output.put_line(r.host||' del '||r.tag_group_id);
		FOR i IN (SELECT tag_id, ind_sid FROM csr.ind_tag WHERE tag_id IN (SELECT tag_id FROM CSR.TAG_GROUP_MEMBER WHERE TAG_GROUP_ID = r.tag_group_id))
		LOOP
			SELECT pos INTO v_this_pos FROM csr.tag_group_member WHERE tag_id = i.tag_id;
			SELECT tag_id INTO v_base_tag_id FROM csr.tag_group_member WHERE tag_group_id = v_base_tag_group_id AND pos = v_this_pos;
			dbms_output.put_line('insert '||v_base_tag_id||','||i.ind_sid||' based on '||i.tag_id||' at '||v_this_pos);
			BEGIN
			INSERT INTO csr.ind_tag (tag_id, ind_sid, app_sid)
			VALUES (v_base_tag_id, i.ind_sid, r.app_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN 
					dbms_output.put_line('insert ignored on dup');
					NULL;
			END;
		END LOOP;
		DELETE FROM csr.ind_tag WHERE app_sid = r.app_sid AND tag_id IN (SELECT tag_id FROM CSR.TAG_GROUP_MEMBER WHERE TAG_GROUP_ID = r.tag_group_id);
		DELETE FROM csr.tag_group_member WHERE app_sid = r.app_sid AND tag_group_id = r.tag_group_id;
		DELETE FROM csr.tag WHERE app_sid = r.app_sid AND tag_id IN (SELECT tag_id FROM CSR.TAG_GROUP_MEMBER WHERE TAG_GROUP_ID = r.tag_group_id);
		DELETE FROM csr.tag_group WHERE app_sid = r.app_sid AND tag_group_id = r.tag_group_id;
		DELETE FROM csr.tag_group_description WHERE app_sid = r.app_sid AND tag_group_id = r.tag_group_id;
	END LOOP;
END;
/
CREATE UNIQUE INDEX CSR.UK_TAG_GROUP_DESCRIPTION_NAME ON CSR.TAG_GROUP_DESCRIPTION(APP_SID, NAME, LANG)
;
*/

GRANT EXECUTE ON csr.user_report_pkg TO web_user;


@..\scenario_pkg
@..\target_dashboard_pkg
@..\chain\test_chain_utils_pkg
--@..\surveys\survey_pkg
--@..\surveys\integration_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\chain\company_dedupe_pkg
@..\user_report_pkg
@..\portlet_pkg
@..\schema_pkg
@..\csr_app_pkg
@..\enable_pkg
@..\factor_pkg


--@..\surveys\survey_body
@..\scenario_body
@..\indicator_body
@..\region_body
@..\schema_body
@..\target_dashboard_body
@..\csrimp\imp_body
@..\chain\test_chain_utils_body
--@..\surveys\integration_body
@..\chain\company_dedupe_body
@..\user_report_body
@..\portlet_body
@..\enable_body
@..\csr_app_body
@..\factor_body
@..\chain\chain_body
@..\..\..\aspen2\cms\db\tab_body
--@..\surveys\question_library_body



@update_tail
