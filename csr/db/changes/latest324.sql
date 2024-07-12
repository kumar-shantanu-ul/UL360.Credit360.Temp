-- Please update version.sql too -- this keeps clean builds in sync
define version=324
@update_header

-- requires delegation package to compile -- might cause problems!
@../delegation_pkg
@../delegation_body

-- fixes up duff sheet_inherited_value data
declare
	v_cnt 	number;
	v_skip 	boolean;
begin
    for c in (select host from customer) loop
    	begin
        	user_pkg.logonadmin(c.host);
        	v_skip := false;
        exception 
        	when security_pkg.object_not_found then
        		security_pkg.debugmsg('skipping host with no website: '||c.host);
		        dbms_output.put_line('skipping host with no website: '||c.host);
        		v_skip := true;
        end;

		if not v_skip then
	  		select count(*) cnt 
	  		  into v_cnt
	  		  from (select svp.sheet_value_id parent_sheet_value_id, svp.sheet_id parent_sheet_id, drp.aggregate_to_region_sid parent_region_sid, svp.ind_sid parent_ind_sid, svp.val_number parent_val_number,
						   svc.sheet_value_id child_sheet_value_id, svc.sheet_id child_sheet_id, svc.region_sid child_region_sid, svc.ind_sid child_ind_sid, svc.val_number child_val_number
					  from (select app_sid, sheet_value_id, inherited_value_id
							  from sheet_inherited_value
								   start with (app_sid, sheet_value_id) in (select app_sid, sheet_value_id from sheet_value)
								   connect by prior inherited_value_id = sheet_value_id) siv,
						   sheet_value svp, sheet sp, delegation_ind dip, delegation_region drp,
						   sheet_value svc, sheet sc, delegation_ind dic, delegation_region drc
					 where -- child sheet value
						   siv.app_sid = svc.app_sid and siv.sheet_value_id = svc.sheet_value_id and
						   svc.app_sid = sc.app_sid and svc.sheet_id = sc.sheet_id and
						   sc.app_sid = dic.app_sid and sc.delegation_sid = dic.delegation_sid and
						   sc.app_sid = drc.app_Sid and sc.delegation_Sid = drc.delegation_sid and
						   svc.app_sid = dic.app_sid and svc.ind_sid = dic.ind_sid and
						   svc.app_sid = drc.app_sid and svc.region_sid = drc.region_sid and
						   -- parent sheet values
						   siv.app_sid = svp.app_sid and siv.inherited_value_id = svp.sheet_value_id and
						   svp.app_sid = sp.app_sid and svp.sheet_id = sp.sheet_id and
						   sp.app_sid = dip.app_sid and sp.delegation_sid = dip.delegation_sid and
						   sp.app_Sid = drp.app_sid and sp.delegation_sid = drp.delegation_sid and
						   svp.app_sid = dip.app_sid and svp.ind_sid = dip.ind_sid and
						   svp.app_sid = drp.app_sid and svp.region_sid = drp.region_sid)
			  where parent_ind_sid != child_ind_sid or parent_region_sid != child_region_sid;
	
			if v_cnt != 0 then
				security_pkg.debugmsg('fixing '|| v_cnt || ' inherited sheet value issues in '||c.host);
		        dbms_output.put_line('fixing '|| v_cnt || ' inherited sheet value issues in '||c.host);
	
		        for r in (
		            select delegation_sid 
		              from delegation
		             where app_sid = parent_sid -- top level
		        )
		        loop
		            delegation_pkg.fixsheetinheritedvalues(r.delegation_sid);
		        end loop;	        
	        	commit;
	        else
				security_pkg.debugmsg('no inherited sheet value issues in '||c.host);
				dbms_output.put_line('no inherited sheet value issues in '||c.host);
	        end if;

	        security_pkg.setapp(null);
		end if;        
    end loop;
end;
/

@update_tail
