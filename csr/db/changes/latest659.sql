-- Please update version.sql too -- this keeps clean builds in sync
define version=659
@update_header

CREATE OR REPLACE PACKAGE csr.region_pkg AS
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID
);

END;
/

CREATE OR REPLACE PACKAGE BODY csr.region_pkg AS
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;


PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	NULL;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
BEGIN
	NULL;
END;
PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID
) AS
BEGIN
	NULL;
END;
END;
/

declare
	v_sid		number(10);
	v_region_sid		number(10);
	v_admins	number(10);
begin
	for r in (
		select distinct app_sid, host from customer
	)
	loop
		dbms_output.put_line('doing '||r.host||'...');
		begin
			user_pkg.logonadmin(r.host);
		exception
			when others then 
				dbms_output.put_line('not found');
				goto skip;
		end loop;
		if r.app_sid != security_pkg.getapp then
			dbms_output.put_line('skipping '||r.host||' due to mismatched app sids: '||r.app_sid||' in csr.customer, but logging on gives '||security_pkg.getapp);
			goto skip;
		end if;
		begin
			v_admins := securableobject_pkg.GetSIDFromPath(security_pkg.getact, r.app_sid, 'Groups/Administrators');
		exception
			when security_pkg.OBJECT_NOT_FOUND then
				v_admins := null;
		end;
		begin
			v_sid := securableobject_pkg.getsidfrompath(security_pkg.getact, r.app_sid, 'DelegationPlans');
		exception
			when security_pkg.OBJECT_NOT_FOUND then
				securableobject_pkg.createso(security_pkg.getact, r.app_sid, security_pkg.SO_CONTAINER, 'DelegationPlans', v_sid);

				securableObject_pkg.ClearFlag(security_pkg.getact, v_sid, security_pkg.SOFLAG_INHERIT_DACL); 
				if v_admins IS NOT NULL THEN
					acl_pkg.AddACE(security_pkg.getact, acl_pkg.GetDACLIDForSID(v_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
						security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins, security_pkg.PERMISSION_STANDARD_ALL);

				END IF;
		end;
		dbms_output.put_line('app sid is ' ||r.app_sid);
		
		begin
			group_pkg.CreateGroupWithClass(security_pkg.getact, v_sid, security_pkg.GROUP_TYPE_SECURITY,
				REPLACE('DelegPlansRegion', '/', '\'), class_pkg.getClassID('CSRRegion'), v_region_sid);
				
			INSERT INTO region (region_sid, parent_sid, app_sid, name, description, active, pos, geo_type, 
				geo_latitude, geo_longitude, info_xml, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, lookup_key,
				acquisition_dtm)
			VALUES (v_region_sid, v_sid, r.app_sid, REPLACE('DelegPlansRegion', '/', '\'), 'DelegPlansRegion', 1, 1, 5,
				null, null, null, null, null, null, null, null, null, null);
			
			-- add object to the DACL (the region is a group, so it has permissions on itself)
			acl_pkg.AddACE(security_pkg.getact, acl_pkg.GetDACLIDForSID(v_region_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_region_sid, security_pkg.PERMISSION_STANDARD_READ);

			acl_pkg.PropogateACEs(security_pkg.getact, v_sid);
		exception
			when security_pkg.DUPLICATE_OBJECT_NAME THEN
				null;
		end;
		
		<<skip>>
		user_pkg.logonadmin();
	end loop;
end;
/

@../region_pkg
@../region_body
@../csr_data_body

@update_tail


