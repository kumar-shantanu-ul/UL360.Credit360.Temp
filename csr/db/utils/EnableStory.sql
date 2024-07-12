REM sqlplus gets in a twist when you run logon &&2 and then within this script &&1 is now &&2 
PROMPT host, oracle_user
DEFINE host = '&&1'
DEFINE usr = '&&2'


connect &&usr/&&usr@&_CONNECT_IDENTIFIER

PROMPT > Create user / drop old tables
PROMPT ===========================================
DECLARE
	TYPE t_tabs IS TABLE OF VARCHAR2(30);
	v_list t_tabs := t_tabs(
		'STORY',
		'STORY_ATTACHMENT',
		'FOCUS_AREA'
	);
BEGIN
	user_pkg.LogonAdmin('&&host');
	cms.tab_pkg.enabletrace;
	FOR i IN 1 .. v_list.count 
	LOOP
		cms.tab_pkg.DropTable(UPPER('&&usr'), v_list(i), true);
	END LOOP;	
	COMMIT;
END;
/



CREATE TABLE FOCUS_AREA(
    FOCUS_AREA_ID    NUMBER(10, 0)    NOT NULL,
    LABEL            VARCHAR2(100)    NOT NULL,
    CONSTRAINT PK_FOCUS_AREA PRIMARY KEY (FOCUS_AREA_ID)
);


-- 
-- TABLE: STORY 
--
CREATE TABLE STORY(
    STORY_ID          NUMBER(10, 0)     NOT NULL,
    FOCUS_AREA_ID     NUMBER(10, 0)     NOT NULL,
    TITLE			  VARCHAR2(1000)    NOT NULL,
    DESCRIPTION       CLOB    			 NOT NULL,
    ACTIVITY_DTM      DATE              NOT NULL,
    ENTERED_BY_SID    NUMBER(10, 0),
    CONSTRAINT PK_STORY PRIMARY KEY (STORY_ID)
);



COMMENT ON TABLE STORY IS 'desc="A CR Story"';
COMMENT ON COLUMN STORY.STORY_ID IS 'desc="ID",autoincrement';
COMMENT ON COLUMN STORY.FOCUS_AREA_ID IS 'desc="Focus area",enum,enum_desc_col=label';
COMMENT ON COLUMN STORY.DESCRIPTION IS 'desc="Description of activity",html';
COMMENT ON COLUMN STORY.TITLE IS 'desc="Title"';
COMMENT ON COLUMN STORY.ACTIVITY_DTM IS 'desc="Date of activity"';
COMMENT ON COLUMN STORY.ENTERED_BY_SID IS 'desc="Story entered by",user';
-- 
-- TABLE: STORY_ATTACHMENT 
--

CREATE TABLE STORY_ATTACHMENT(
    STORY_ATTACHMENT_ID    NUMBER(10, 0)    NOT NULL,
    STORY_ID               NUMBER(10, 0)    NOT NULL,
    DOC_FILE               BLOB             NOT NULL,
    DOC_MIME               VARCHAR2(100)    NOT NULL,
    DOC_NAME               VARCHAR2(100)    NOT NULL,
    CONSTRAINT PK_STORY_ATTACHMENT PRIMARY KEY (STORY_ATTACHMENT_ID)
);



COMMENT ON TABLE STORY_ATTACHMENT IS 'desc="A document associated to a CR story"';
COMMENT ON COLUMN STORY_ATTACHMENT.STORY_ATTACHMENT_ID IS 'desc="Id",auto';
COMMENT ON COLUMN STORY_ATTACHMENT.STORY_ID IS 'desc="Story ID"';
COMMENT ON COLUMN STORY_ATTACHMENT.DOC_FILE IS 'desc="Document",file,file_mime=doc_mime,file_name=doc_name';
COMMENT ON COLUMN STORY_ATTACHMENT.DOC_MIME IS 'desc="File type"';
COMMENT ON COLUMN STORY_ATTACHMENT.DOC_NAME IS 'desc="File name"';


-- 
-- TABLE: STORY 
--
ALTER TABLE STORY ADD CONSTRAINT FK_STORY_FOCUS_AREA 
    FOREIGN KEY (FOCUS_AREA_ID)
    REFERENCES FOCUS_AREA(FOCUS_AREA_ID);


-- 
-- TABLE: STORY_ATTACHMENT 
--
ALTER TABLE STORY_ATTACHMENT ADD CONSTRAINT FK_STORY_ATTACHMENT 
    FOREIGN KEY (STORY_ID)
    REFERENCES STORY(STORY_ID);


BEGIN
	INSERT INTO focus_area (focus_area_id, label) VALUES (0, 'Other');
	INSERT INTO focus_area (focus_area_id, label) VALUES (1, 'Community');
	INSERT INTO focus_area (focus_area_id, label) VALUES (2, 'Customers');
	INSERT INTO focus_area (focus_area_id, label) VALUES (3, 'Environment');
	INSERT INTO focus_area (focus_area_id, label) VALUES (4, 'People');
	INSERT INTO focus_area (focus_area_id, label) VALUES (5, 'Suppliers');
END;
/

/* registering the tables */
PROMPT > Registering tables...
PROMPT ======================

spool registerTables.log

begin
    dbms_output.enable(NULL); -- unlimited output, lovely
    user_pkg.LogonAdmin('&&host');
	cms.tab_pkg.enabletrace;
	cms.tab_pkg.registertable(UPPER('&&usr'), 'STORY,STORY_ATTACHMENT', TRUE);
    commit;
END;
/

spool off

CREATE OR REPLACE TRIGGER STORY_BI BEFORE INSERT ON "C$STORY" FOR EACH ROW
BEGIN
    :new.entered_by_sid := SYS_CONTEXT('SECURITY','SID');
END;
/


declare
	v_forms			security_pkg.T_SID_ID;
	v_www_sid		security_pkg.T_SID_ID;	
	v_story_list	security_pkg.T_SID_ID;
	v_groups_sid			security_pkg.T_SID_ID;
	v_admins_sid			security_pkg.T_SID_ID;
	v_regusers_sid			security_pkg.T_SID_ID;
begin
    user_pkg.LogonAdmin('&&host');
	v_www_sid := securableobject_pkg.GetSidFromPath(security_pkg.getACT, security_pkg.getApp, 'wwwroot');


	v_groups_sid 		:= securableobject_pkg.GetSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Groups');
    v_admins_sid 		:= securableobject_pkg.GetSidFromPath(security_pkg.getACT, v_groups_sid, 'Administrators');
    v_regusers_sid 		:= securableobject_pkg.GetSidFromPath(security_pkg.getACT, v_groups_sid, 'RegisteredUsers');
	
	begin
		security.web_pkg.CreateResource(security_pkg.getACT, v_www_sid, 
			securableobject_pkg.GetSIDFromPath(security_pkg.getACT, v_www_sid,'csr'), 'forms', v_forms);
		acl_pkg.AddACE(security_pkg.getACT, acl_pkg.GetDACLIDForSID(v_forms), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, 
			v_regusers_sid, security_pkg.PERMISSION_STANDARD_READ);
	exception
		when security_pkg.DUPLICATE_OBJECT_NAME then
			v_forms := securableobject_pkg.GetSIDFromPath(security_pkg.getACT, v_www_sid,'csr/forms');
	end;

	begin
		security.web_pkg.CreateResource(security_pkg.getACT, v_www_sid, v_www_sid, 'forms', v_forms);
	exception
		when security_pkg.DUPLICATE_OBJECT_NAME then
			v_forms := securableobject_pkg.GetSIDFromPath(security_pkg.getACT, v_www_sid,'forms');
	end;
	
	begin
		security.web_pkg.CreateResource(security_pkg.getACT, v_www_sid, v_forms, 'story', v_story_list);
	exception
		when security_pkg.DUPLICATE_OBJECT_NAME then
			v_story_list := securableobject_pkg.GetSIDFromPath(security_pkg.getACT, v_www_sid,'forms/story');
	end;
	
	update security.web_resource 
	   set rewrite_path ='/fp/cms/form.acds?_FORM_PATH=/csr/forms/story/story_list.xml' 
	 where sid_Id = v_story_list;
end;
/

/*
connect csr/csr@&_CONNECT_IDENTIFIER

DECLARE
	v_sid					security_pkg.T_SID_ID;
	v_grids_sid				security_pkg.T_SID_ID;
	v_ind_root_sid 			security_pkg.T_SID_ID;
	v_delegation_grid_id	delegation_grid.delegation_grid_id%TYPE;
BEGIN
	user_pkg.LogonAdmin('&&host');
	SELECT ind_root_sid  
	  INTO v_ind_root_sid
	  FROM customer;

	BEGIN
		v_grids_sid := securableobject_pkg.GetSidFromPath(
			security_pkg.getACT, v_ind_root_sid, 'Grids');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND	THEN
			indicator_pkg.CreateIndicator(
				in_act_id 			=> security_pkg.getACT,
				in_parent_sid_id	=> v_ind_root_sid,
				in_app_sid			=> security_pkg.getApp,
				in_name				=> 'Grids',
				in_description		=> 'Grids',
				out_sid_id			=> v_grids_sid
			);
	END;
	
	
	-- START: PROTECTED_AREA
	BEGIN
		v_sid := securableobject_pkg.GetSidFromPath(
			security_pkg.getACT, v_grids_sid, 'STORY');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			indicator_pkg.CreateIndicator(
				in_act_id 			=> security_pkg.getACT,
				in_parent_sid_id	=> v_grids_sid,
				in_app_sid			=> security_pkg.getApp,
				in_name				=> 'STORY',
				in_description		=> 'Case study',
				out_sid_id			=> v_sid
			);
			INSERT INTO delegation_grid (delegation_grid_id, path, ind_sid)
				VALUES (delegation_grid_id_seq.nextval, '/csr/forms/story/story_grid.xml', v_sid)
				RETURNING delegation_grid_id INTO v_delegation_grid_id;
	END;
	-- END: PROTECTED_AREA
	
	
	COMMIT;
END;
/
*/
exit
