-- Please update version.sql too -- this keeps clean builds in sync
define version=289
@update_header

-- we've changed it so that delegator has permissions that propagate down
-- so that they can read files uploaded to a sub-delegation.
DECLARE
    v_act   security_pkg.T_ACT_ID;
BEGIN
    user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 100000, v_act);
    FOR r IN (
        SELECT so.sid_Id, acl.ROWID rid
          FROM SECURITY.securable_object so, SECURITY.acl
         WHERE so.dacl_id = acl.acl_id
           AND so.sid_id IN (
              SELECT delegation_sid
                FROM delegation
               START WITH app_Sid = parent_sid
             CONNECT BY PRIOR delegation_sid = parent_sid
           )
           AND acl.sid_Id = so.sid_Id
           AND ace_type = 1
           AND ace_flags = 2
    )
    LOOP 
        UPDATE SECURITY.acl
           SET ace_flags = 3
         WHERE ROWID = r.rid;
    END LOOP;
    -- now propagate down
    FOR r IN (
        SELECT delegation_sid
          FROM delegation
         WHERE parent_sid = app_sid
    )
    LOOP
        acl_pkg.PropogateACEs(v_act, r.delegation_sid);
    END LOOP;
END;
/

SET DEFINE OFF

@..\delegation_pkg
@..\delegation_body

SET DEFINE ON

@update_tail
