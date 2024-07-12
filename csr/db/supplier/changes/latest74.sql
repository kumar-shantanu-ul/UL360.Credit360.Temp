-- Please update version.sql too -- this keeps clean builds in sync
define version=74
@update_header

-- clean up menu names
DECLARE
	v_act	security_pkg.T_ACT_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 3600, v_act);

    -- delete these - they're pointless
    for r in (
        select w.website_name, so.name, sid_id 
          from security.securable_object so, security.website w 
         where so.name IN ('supplier_editproduct','supplier_editsupplier','supplier_productquestionnaires','supplier_questionnaire_questionnaire')
           and so.application_sid_id = w.application_sid_Id
    )
    loop
        dbms_output.put_line('deleting "'||r.name||'" menu from "'||r.website_name||'"...');
        securableobject_pkg.deleteso(v_act, r.sid_id);
    end loop;
    
    -- rename these
    update security.securable_object set name = 'supplier_admin_products' where name = 'supplier_searchproduct';
    update security.securable_object set name = 'supplier_admin_suppliers' where name = 'supplier_searchsupplier';
END;
/

@update_tail
