declare
    v_re_sid    security_pkg.T_SID_ID;
begin
    user_pkg.LogonAdmin('swissre.credit360.com');
    v_re_sid 			:= securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Groups/Regional Approvers');
    for r in (
        select delegation_sid, so.dacl_Id
          from delegation d, security.securable_object so 
         where parent_sid = app_sid
           and d.delegation_sid = so.sid_id
    )
    loop
        -- remove aces that might be set
        acl_pkg.RemoveACEsForSid(SYS_CONTEXT('SECURITY','ACT'), r.dacl_id, v_re_sid);
        -- add a new ace
        acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), r.dacl_id, -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, v_re_sid, csr_data_pkg.PERMISSION_OVERRIDE_DELEGATOR); --+ csr_data_pkg.PERMISSION_STANDARD_DELEGATOR);
        acl_pkg.PropogateACEs(SYS_CONTEXT('SECURITY','ACT'), r.delegation_sid);
    end loop;
end;
/
