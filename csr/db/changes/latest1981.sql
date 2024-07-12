-- Please update version.sql too -- this keeps clean builds in sync
define version=1981
@update_header

CREATE SEQUENCE CSR.INITIATIVE_USER_GROUP_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

ALTER TABLE CSR.INITIATIVE ADD (
    CONSTRAINT UK_INITIATIVE_FLOW  UNIQUE (APP_SID, INITIATIVE_SID, FLOW_SID),
    CONSTRAINT UK_INITIATIVE_PROJECT  UNIQUE (APP_SID, INITIATIVE_SID, PROJECT_SID)
);

CREATE TABLE CSR.INITIATIVE_USER_GROUP(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    INITIATIVE_USER_GROUP_ID    NUMBER(10, 0)    NOT NULL,
    LABEL                       VARCHAR2(255)    NOT NULL,
    LOOKUP_KEY                  VARCHAR2(255),
    CONSTRAINT PK_INITIATIVE_USER_GROUP PRIMARY KEY (APP_SID, INITIATIVE_USER_GROUP_ID)
);


CREATE TABLE CSR.INITIATIVE_PROJECT_USER_GROUP(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PROJECT_SID                 NUMBER(10, 0)    NOT NULL,
    INITIATIVE_USER_GROUP_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_INIT_PROJECT_USER_GROUP PRIMARY KEY (APP_SID, PROJECT_SID, INITIATIVE_USER_GROUP_ID)
);
 
 
CREATE TABLE CSR.INITIATIVE_USER_FLOW_STATE(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    INITIATIVE_SID              NUMBER(10, 0)    NOT NULL,
    INITIATIVE_USER_GROUP_ID    NUMBER(10, 0)    NOT NULL,
    USER_SID                    NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_ID               NUMBER(10, 0)    NOT NULL,
    FLOW_SID                    NUMBER(10, 0)    NOT NULL,
    IS_EDITABLE                 NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (IS_EDITABLE IN (0,1)),
    CONSTRAINT PK_INITIATIVE_USER_FLOW_STATE PRIMARY KEY (INITIATIVE_SID, INITIATIVE_USER_GROUP_ID, USER_SID, FLOW_STATE_ID, APP_SID)
);

INSERT INTO CSR.INITIATIVE_USER_GROUP (APP_SID, INITIATIVE_USER_GROUP_ID, LABEL)
	SELECT APP_SID, csr.INITIATIVE_USER_GROUP_ID_SEQ.nextval, 'Select associated users'
	  FROM (
		SELECT DISTINCT app_sid FROM csr.initiative_project
	  );

INSERT INTO CSR.INITIATIVE_PROJECT_USER_GROUP (APP_SID, PROJECT_SID, INITIATIVE_USER_GROUP_ID)
	SELECT ip.APP_SID, ip.PROJECT_SID, iug.INITIATIVE_USER_GROUP_ID
	  FROM CSR.INITIATIVE_PROJECT ip, CSR.INITIATIVE_USER_GROUP iug
	 WHERE ip.app_sid = iug.app_sid;
	 

INSERT INTO CSR.INITIATIVE_USER_FLOW_STATE (APP_SID, INITIATIVE_SID, INITIATIVE_USER_GROUP_ID, USER_SID, FLOW_STATE_ID, FLOW_SID, IS_EDITABLE)
	SELECT iu.APP_SID, iu.INITIATIVE_SID, iug.INITIATIVE_USER_GROUP_ID, iu.USER_SID, iu.FLOW_STATE_ID, iu.FLOW_SID, iu.IS_EDITABLE
	  FROM CSR.INITIATIVE_USER_GROUP iug, CSR.INITIATIVE_USER iu
	 WHERE iug.app_sid = iu.app_sid;
 
ALTER TABLE CSR.INITIATIVE_USER DROP PRIMARY KEY DROP INDEX;

ALTER TABLE CSR.INITIATIVE_USER ADD (
    INITIATIVE_USER_GROUP_ID    NUMBER(10, 0),
	PROJECT_SID                 NUMBER(10, 0)
);

ALTER TABLE CSR.INITIATIVE_USER DROP CONSTRAINT FK_FLOW_STATE_INIT_USER;
ALTER TABLE CSR.INITIATIVE_USER DROP CONSTRAINT FK_INIT_INIT_USER;

ALTER TABLE CSR.INITIATIVE_USER DROP COLUMN FLOW_STATE_ID;
ALTER TABLE CSR.INITIATIVE_USER DROP COLUMN FLOW_SID;
ALTER TABLE CSR.INITIATIVE_USER DROP COLUMN IS_EDITABLE;

BEGIN
	FOR r IN (
		SELECT i.project_sid, i.initiative_sid, iug.initiative_user_group_id
		  FROM csr.initiative i
		  JOIN csr.initiative_user_group iug ON i.app_sid = iug.app_sid
	)
	LOOP
		UPDATE csr.initiative_user
		   SET initiative_user_group_id = r.initiative_user_group_id,
			project_sid = r.project_sid
		 WHERE initiative_sid = r.initiative_sid;
	END LOOP;
END;
/

ALTER TABLE CSR.INITIATIVE_USER MODIFY INITIATIVE_USER_GROUP_ID NOT NULL;
ALTER TABLE CSR.INITIATIVE_USER MODIFY PROJECT_SID NOT NULL;

-- xx_init_usr
-- clean up dupes
DELETE FROM CSR.INITIATIVE_USER
 WHERE ROWID IN (
	SELECT RID 
	  FROM (
		SELECT ROWID RID, ROW_NUMBER() OVER (PARTITION BY APP_SID, INITIATIVE_SID, USER_SID, INITIATIVE_USER_GROUP_ID ORDER BY INITIATIVE_SID) RN
		  FROM CSR.INITIATIVE_USER
	) WHERE RN > 1
);

-- HERE
ALTER TABLE CSR.INITIATIVE_USER ADD CONSTRAINT PK_INITIATIVE_USER PRIMARY KEY (APP_SID, INITIATIVE_SID, USER_SID, INITIATIVE_USER_GROUP_ID);


ALTER TABLE CSR.INITIATIVE_PROJECT_USER_GROUP ADD CONSTRAINT FK_INIT_PRJ_INIT_PRJ_USR_GRP 
    FOREIGN KEY (APP_SID, PROJECT_SID)
    REFERENCES CSR.INITIATIVE_PROJECT(APP_SID, PROJECT_SID) ON DELETE CASCADE;

ALTER TABLE CSR.INITIATIVE_PROJECT_USER_GROUP ADD CONSTRAINT FK_INT_US_GRP_INT_PRJ_USR_GRP 
    FOREIGN KEY (APP_SID, INITIATIVE_USER_GROUP_ID)
    REFERENCES CSR.INITIATIVE_USER_GROUP(APP_SID, INITIATIVE_USER_GROUP_ID) ON DELETE CASCADE;


ALTER TABLE CSR.INITIATIVE_USER ADD CONSTRAINT FK_INIT_INIT_USER 
    FOREIGN KEY (APP_SID, INITIATIVE_SID)
    REFERENCES CSR.INITIATIVE(APP_SID, INITIATIVE_SID) ON DELETE CASCADE;
 
ALTER TABLE CSR.INITIATIVE_USER ADD CONSTRAINT FK_INIT_PRJ_USR_GRP_INIT_USR 
    FOREIGN KEY (APP_SID, PROJECT_SID, INITIATIVE_USER_GROUP_ID)
    REFERENCES CSR.INITIATIVE_PROJECT_USER_GROUP(APP_SID, PROJECT_SID, INITIATIVE_USER_GROUP_ID);

ALTER TABLE CSR.INITIATIVE_USER_FLOW_STATE ADD CONSTRAINT FK_FL_ST_INIT_USR_FL_ST 
    FOREIGN KEY (APP_SID, FLOW_STATE_ID, FLOW_SID)
    REFERENCES CSR.FLOW_STATE(APP_SID, FLOW_STATE_ID, FLOW_SID) ON DELETE CASCADE;

ALTER TABLE CSR.INITIATIVE_USER_FLOW_STATE ADD CONSTRAINT FK_INIT_INIT_USR_FL_ST 
    FOREIGN KEY (APP_SID, INITIATIVE_SID, FLOW_SID)
    REFERENCES CSR.INITIATIVE(APP_SID, INITIATIVE_SID, FLOW_SID) ON DELETE CASCADE;

ALTER TABLE CSR.INITIATIVE_USER_FLOW_STATE ADD CONSTRAINT FK_INIT_USR_INIT_USR_FL_STATE 
    FOREIGN KEY (APP_SID, INITIATIVE_SID, USER_SID, INITIATIVE_USER_GROUP_ID)
    REFERENCES CSR.INITIATIVE_USER(APP_SID, INITIATIVE_SID, USER_SID, INITIATIVE_USER_GROUP_ID) ON DELETE CASCADE;

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	TYPE T_TABS IS TABLE OF VARCHAR2(30);
	v_list T_TABS;
BEGIN	
	v_list := t_tabs(  
		'INITIATIVE_USER_GROUP',
		'INITIATIVE_PROJECT_USER_GROUP',
		'INITIATIVE_USER_FLOW_STATE'
	);
	FOR I IN 1 .. v_list.count 
	LOOP
		BEGIN			
		    DBMS_RLS.ADD_POLICY(
		        object_schema   => 'CSR',
		        object_name     => v_list(i),
		        policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
		        function_schema => 'CSR',
		        policy_function => 'appSidCheck',
		        statement_types => 'select, insert, update, delete',
		        update_check	=> true,
		        policy_type     => dbms_rls.context_sensitive );
		    	DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));				
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
		END;
	END LOOP;
END;
/


CREATE OR REPLACE VIEW csr.v$my_initiatives AS
SELECT	i.app_sid, i.initiative_sid,
		ir.region_sid,
		fi.current_state_id flow_state_id,
		fs.label flow_state_label,
		fs.lookup_key flow_state_lookup_key,
		fs.state_colour flow_state_colour,
		r.role_sid,
		r.name role_name,
		fsr.is_editable,
		rg.active,
		null owner_sid
  FROM	region_role_member rrm
  JOIN	role r
		 ON rrm.role_sid = r.role_sid
		AND rrm.app_sid = r.app_sid
  JOIN flow_state_role fsr
		 ON fsr.role_sid = r.role_sid
		AND fsr.app_sid = r.app_sid
  JOIN flow_state fs
		 ON fsr.flow_state_id = fs.flow_state_id
		AND fsr.app_sid      = fs.app_sid
  JOIN flow_item fi
		 ON fs.flow_state_id = fi.current_state_id
		AND fs.app_sid      = fi.app_sid
  JOIN initiative i
		 ON fi.flow_item_id = i.flow_Item_id
  JOIN initiative_region ir
		 ON i.initiative_sid = ir.initiative_sid
		AND rrm.region_sid = ir.region_sid
		AND rrm.app_sid    = ir.app_sid
  JOIN region rg
		 ON ir.region_sid    = rg.region_sid
		AND ir.app_Sid      = rg.app_sid
 WHERE	rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
   AND	i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
UNION ALL
SELECT	i.app_sid, i.initiative_sid, 
		ir.region_sid,
		fi.current_state_id flow_state_id,
		fs.label flow_state_label,
		fs.lookup_key flow_state_lookup_key,
		fs.state_colour flow_state_colour,
		null role_sid,
		null role_name,
		iufs.is_editable,
		rg.active,
		iu.user_sid owner_sid
  FROM	initiative_user iu
  JOIN	initiative i
		 ON iu.initiative_sid = i.initiative_sid
		AND iu.app_sid = i.app_sid
  JOIN	flow_item fi
		 ON i.flow_item_id = fi.flow_item_id
		AND i.app_sid = fi.app_sid
  JOIN flow_state fs
		 ON fi.current_state_id = fs.flow_state_id
		AND fi.flow_sid = fs.flow_sid
		AND fi.app_sid = fs.app_sid
  JOIN	initiative_user_flow_state iufs 
         ON iu.initiative_sid = iufs.initiative_sid 
        AND iu.initiative_user_group_id = iufs.initiative_user_group_id
        AND iu.user_sid = iufs.user_sid
        AND fs.flow_state_id = iufs.flow_State_id and fs.flow_sid = iufs.flow_sid and fs.app_sid = iufs.app_sid
  JOIN initiative_region ir
		 ON ir.initiative_sid = i.initiative_sid
		AND ir.app_sid = i.app_sid
  JOIN region rg
		 ON ir.region_sid = rg.region_sid
		AND ir.app_Sid = rg.app_sid
 WHERE	iu.user_sid = SYS_CONTEXT('SECURITY','SID')
   AND	i.app_sid = SYS_CONTEXT('SECURITY', 'APP');

@..\initiative_pkg
@..\initiative_grid_pkg

@..\initiative_body
@..\initiative_import_body
@..\initiative_grid_body
   
@update_tail
