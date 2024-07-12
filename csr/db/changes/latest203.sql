-- Please update version.sql too -- this keeps clean builds in sync
define version=203
@update_header

alter table role rename column role_id to role_sid;
alter table region_role_member rename column role_id to role_sid;


@../region_pkg
@../region_body

@../role_pkg
@../role_body


GRANT EXECUTE ON role_pkg TO SECURITY;


-- create Role classes
DECLARE
	v_act				security_pkg.T_ACT_ID;
	v_class_id			security_pkg.T_CLASS_ID;
BEGIN	
	user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act);
    class_pkg.CreateClass(v_act, NULL, 'CSRRole', 'csr.role_pkg', NULL, v_class_id);
END;
/



-- turn role_id into role_sid 
alter table region_role_member disable constraint RefROLE764;

declare
	v_act				security_pkg.T_ACT_ID;
	v_sid               security_pkg.T_SID_ID;
	v_class_id			security_pkg.T_CLASS_ID;
	v_groups_sid		security_pkg.T_SID_ID;
begin
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/richard', 10000, v_act);
	-- create new groups
	v_class_id := class_pkg.GetClassId('CSRRole');
    for r in (
        select role_sid, app_sid, name from role
    )
    loop
    	security_pkg.SetACT(v_act, r.app_sid);
    	--
        v_groups_sid := securableobject_pkg.GetSidFromPath(v_act, r.app_sid, 'Groups');
        --
        group_pkg.CreateGroupWithClass(v_act, v_groups_sid, security_pkg.GROUP_TYPE_SECURITY,
            REPLACE(r.name,'/','\'), v_class_id, v_sid);    
        --
        update role set role_sid = v_sid where role_sId = r.role_sid;
        update region_role_member set role_sid = v_sid where role_sid = r.role_sid;
    end loop;
end;
/

alter table region_role_member enable constraint RefROLE764;


DROP SEQUENCE ROLE_ID_SEQ;

-- 
-- TABLE: APPROVAL_STEP_ROLE 
--

CREATE TABLE APPROVAL_STEP_ROLE(
    APPROVAL_STEP_ID    NUMBER(10, 0)    NOT NULL,
    ROLE_SID            NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK457 PRIMARY KEY (APPROVAL_STEP_ID, ROLE_SID)
)
;


-- TABLE: APPROVAL_STEP_ROLE 
--

ALTER TABLE APPROVAL_STEP_ROLE ADD CONSTRAINT RefROLE894 
    FOREIGN KEY (ROLE_SID)
    REFERENCES ROLE(ROLE_SID)
;

ALTER TABLE APPROVAL_STEP_ROLE ADD CONSTRAINT RefAPPROVAL_STEP895 
    FOREIGN KEY (APPROVAL_STEP_ID)
    REFERENCES APPROVAL_STEP(APPROVAL_STEP_ID)
;



@update_tail
