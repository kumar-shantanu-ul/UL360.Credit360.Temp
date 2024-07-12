-- Please update version.sql too -- this keeps clean builds in sync
define version=2151
@update_header

DECLARE
	v_new_class_id 			security.security_pkg.T_SID_ID;
	v_act 					security.security_pkg.T_ACT_ID;
BEGIN	
	security.user_pkg.LogonAdmin;
	-- create csr app classes (inherits from aspenapp)
	BEGIN	
		security.class_pkg.CreateClass(security.security_pkg.GetAct, NULL, 'CMSFilter', 'cms.filter_pkg', null, v_new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	COMMIT;
END;
/

DECLARE
	v_filters_sid	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	-- Fix superadmin personal filters add while not logged into an app so the SO
	-- doesn't become app-specific. clear app_sid if they exist already.
	FOR r IN (
		SELECT csr_user_sid
		  FROM csr.superadmin
	) LOOP
		BEGIN
			v_filters_sid := security.securableobject_pkg.GetSidFromPath(
				security.security_pkg.GetAct, r.csr_user_sid, 'CMS Filters');
			UPDATE security.securable_object
			   SET application_sid_id = NULL
			 WHERE sid_id = v_filters_sid;
		EXCEPTION WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(
				security.security_pkg.GetAct, r.csr_user_sid,
				security.security_pkg.SO_CONTAINER, 'CMS Filters', v_filters_sid);
		END;
	END LOOP;
END;
/

--*** Split session filters out of cms.filter table and make saved filters securable objects***
-- create table for session filter
CREATE TABLE CMS.ACTIVE_SESSION_FILTER (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    ACTIVE_SESSION_FILTER_ID NUMBER(10) NOT NULL,
    TAB_SID NUMBER(10) NOT NULL,
    USER_SID NUMBER(10) NOT NULL,
    FILTER_XML XMLTYPE NOT NULL,
    CONSTRAINT PK_ACTIVE_SESSION_FILTER PRIMARY KEY (APP_SID, ACTIVE_SESSION_FILTER_ID),
    CONSTRAINT UK_ACTIVE_SESSION_FILTER UNIQUE (APP_SID, TAB_SID, USER_SID)
);

ALTER TABLE CMS.ACTIVE_SESSION_FILTER ADD CONSTRAINT TAB_ACTIVE_SESSION_FILTER 
    FOREIGN KEY (APP_SID, TAB_SID) REFERENCES CMS.TAB (APP_SID,TAB_SID);
	
create index cms.ix_act_sess_filter_tab_sid on cms.active_session_filter (app_sid, tab_sid);

CREATE SEQUENCE CMS.ACTIVE_SESSION_FILTER_ID_SEQ;

--RLS
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
		'ACTIVE_SESSION_FILTER'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					
					--dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CMS',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CMS',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
					WHEN FEATURE_NOT_ENABLED THEN
						DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
						exit;
				end;
			end loop;
		end;
	end loop;
end;
/
	
-- take backup of cms.filter table
CREATE TABLE cms.xxx_filter_backup
  AS (SELECT * FROM cms.filter);

-- move session filter filters to new table and remove from old table
INSERT INTO cms.active_session_filter (app_sid, active_session_filter_id, tab_sid, user_sid, filter_xml)
SELECT app_sid, cms.active_session_filter_id_seq.NEXTVAL, tab_sid, user_sid, filter_xml
  FROM cms.filter
 WHERE is_active_session_filter = 1;

DELETE FROM cms.filter
 WHERE is_active_session_filter = 1;


-- rename user_sid to created_by_user_sid, add nullable parent sid to filter and remove is_active_session_filter table
ALTER TABLE cms.filter RENAME COLUMN user_sid TO created_by_user_sid;
ALTER TABLE cms.filter ADD (parent_sid NUMBER(10));
ALTER TABLE cms.filter DROP COLUMN is_active_session_filter;

-- Add existing cms filters to the SO tree (the id's are already from the SO sequence)
DECLARE
	v_duplicates 			NUMBER;
	v_owner_sid 			security.Security_Pkg.T_SID_ID;
	v_parent_sid 			security.Security_Pkg.T_SID_ID;
	v_class_id 				security.Security_Pkg.T_CLASS_ID;
	v_name					cms.filter.name%TYPE;
BEGIN
	v_class_id := security.class_pkg.GetClassID('CMSFilter');
	
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT * FROM (
			SELECT f.filter_sid, f.name, ROW_NUMBER() OVER (PARTITION BY f.created_by_user_sid, f.name ORDER BY f.filter_sid) rn
			  FROM cms.filter f
			  JOIN csr.superadmin sa ON f.created_by_user_sid = sa.csr_user_sid
			)
		 WHERE rn > 1
	) LOOP
		UPDATE cms.filter
		   SET name = name||' ('||r.rn||')'
		 WHERE filter_sid = r.filter_sid;
	END LOOP;

	FOR r IN (
		SELECT c.app_sid, c.host, f.filter_sid, f.tab_sid, f.name, f.created_by_user_sid
		  FROM cms.filter f
		  JOIN csr.customer c 
		    ON f.app_sid = c.app_sid
		  LEFT JOIN security.securable_object so
		    ON f.filter_sid = so.sid_id
		 WHERE so.sid_id IS NULL
	) LOOP
		security.user_pkg.logonadmin(r.host);
		
		IF r.created_by_user_sid IS NULL THEN
			-- public filter, store under tab			
			-- get or create folder under tab
			BEGIN
				v_parent_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, r.tab_sid, 'Filters');			 
			EXCEPTION 
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					-- Create the filters SO and give user full access.
					security.securableobject_pkg.CreateSO(security.security_pkg.GetAct, r.tab_sid, security.security_pkg.SO_CONTAINER, 'Filters', v_parent_sid);
			END;
		ELSE
			-- user filter, store under user
			BEGIN
				v_parent_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, r.created_by_user_sid, 'CMS Filters');			 
			EXCEPTION 
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					-- Create the filters SO and give user full access.
					security.securableobject_pkg.CreateSO(security.security_pkg.GetAct, r.created_by_user_sid, security.security_pkg.SO_CONTAINER, 'CMS Filters', v_parent_sid);
					
					security.acl_pkg.AddACE(security.security_pkg.GetAct, security.acl_pkg.GetDACLIDForSID(v_parent_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT, r.created_by_user_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			END;
		END IF;
		
		UPDATE cms.filter
		   SET parent_sid = v_parent_sid
		 WHERE app_sid = r.app_sid
		   AND filter_sid = r.filter_sid;
		
		-- create SO for filter reusing sid (tweaked version of securableobject_pkg.CreateSO)
		v_name := r.name;
		IF v_name IS NOT NULL THEN
			IF INSTR(v_name, '/') <> 0 THEN
				v_name := REPLACE(v_name, '/', '_');
			END IF;
		
			-- Check for duplicates
			SELECT COUNT(*) INTO v_duplicates
			  FROM security.securable_object
			 WHERE parent_sid_id = v_parent_sid
			   AND LOWER(name) = LOWER(v_name);
			IF v_duplicates <> 0 THEN
				v_name := v_name||' ('||v_duplicates||')';
			END IF;
			-- The path separator is not valid in an object name (in theory it is possible, but it
			-- needs to be quotable, and we don't support that at present, so it's better to not
			-- let people create objects that they can't find)
			
		END IF;

		-- Get object owner sid
		security.User_Pkg.GetSID(security.security_pkg.GetAct, v_owner_sid);

		-- Insert a new object
		BEGIN
			INSERT INTO security.securable_object (sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner)
			VALUES (r.filter_sid, v_parent_sid, NULL, v_class_id, v_name,
					security.Security_Pkg.SOFLAG_INHERIT_DACL, v_owner_sid);
		EXCEPTION
			WHEN dup_val_on_index THEN
				INSERT INTO security.securable_object (sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner)
				VALUES (r.filter_sid, v_parent_sid, NULL, v_class_id, v_name||'( '||r.tab_sid||')',
						security.Security_Pkg.SOFLAG_INHERIT_DACL, v_owner_sid);
		END;
				
		-- inherit ACEs from parent (...)
		IF v_parent_sid IS NOT NULL THEN
			security.Acl_Pkg.PASSACEStochild(v_parent_sid, r.filter_sid);
		END IF;
	END LOOP;
END;
/

-- make parent_sid not null
ALTER TABLE cms.filter MODIFY parent_sid NOT NULL;

-- csrimp
ALTER TABLE csrimp.cms_filter RENAME COLUMN user_sid TO created_by_user_sid;
ALTER TABLE csrimp.cms_filter DROP COLUMN is_active_session_filter;
ALTER TABLE csrimp.cms_filter ADD (parent_sid NUMBER(10));
UPDATE csrimp.cms_filter SET parent_sid = NVL(created_by_user_sid, tab_sid);
ALTER TABLE csrimp.cms_filter MODIFY parent_sid NOT NULL;

-- dummy procs for grant
create or replace package cms.filter_pkg as
procedure dummy;
end;
/
create or replace package body cms.filter_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on cms.filter_pkg to security, web_user;

@..\..\..\aspen2\cms\db\tab_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\folderlib_body
@..\csr_user_body
@..\csrimp\imp_body
@..\..\..\aspen2\cms\db\tab_body
@..\..\..\aspen2\cms\db\filter_body

@update_tail
