-- Please update version.sql too -- this keeps clean builds in sync
define version=11
@update_header

DECLARE
	new_class_id 	security_pkg.T_CLASS_ID;
	v_act varchar(38);
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	new_class_id:=class_pkg.GetClassId('CSRDelegation');
	class_pkg.AddPermission(v_act, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA, 'Alter delegation details');
	class_PKG.createmapping(v_act, security_pkg.SO_CONTAINER, security_pkg.PERMISSION_CHANGE_PERMISSIONS, new_class_id, csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA);
END;
/


INSERT INTO security.GROUP_TABLE (SID_ID, GROUP_TYPE)
	select delegation_sid, 1 from csr.delegation;


@csr_data_pkg

declare
	v_act varchar(38);
	v_perm	number(10);
begin
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	for r in (select delegation_sid, parent_sid, csr_root_sid from csr.delegation) 
	loop
		IF r.parent_sid = r.csr_root_sid THEN
			v_perm := csr_data_pkg.PERMISSION_STANDARD_DELEGATOR;
		ELSE
			v_perm := csr_data_pkg.PERMISSION_STANDARD_DELEGEE;
		END IF;
		acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(r.delegation_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_INHERIT_INHERITABLE, r.delegation_sid, v_perm);
		IF r.Parent_sid != r.csr_root_sid THEN
		acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(r.delegation_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_INHERIT_INHERITABLE, r.parent_sid, csr_data_pkg.PERMISSION_STANDARD_DELEGATOR);
		END IF;
		acl_pkg.PropogateACEs(v_act, r.delegation_sid);
	end loop;
end;
/


declare
	v_act varchar(38);
begin
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
    for r in (select user_sid, delegation_sid from delegation_user) 
    loop
	    group_pkg.AddMember(v_act, r.user_sid, r.delegation_sid);
    end loop;
end;
/

commit;


CREATE TABLE CUSTOMER(
    CSR_ROOT_SID    NUMBER(10, 0)    NOT NULL,
    NAME            VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK125 PRIMARY KEY (CSR_ROOT_SID)
)
;


begin
insert into customer 
select so.sid_id, sop.name from security.securable_object so, security.securable_object sop
  where so.parent_Sid_id = sop.sid_id 
    and so.sid_id in (
		select distinct csr_root_sid from ind);
update customer set name='Agilent' where csr_root_sid=284569;
update customer set name='Boots' where csr_root_sid=638227;
update customer set name='Cairn Energy' where csr_root_sid=1223176;
update customer set name='Chevron' where csr_root_sid=945756;
update customer set name='Computershare' where csr_root_sid=1419772;
update customer set name='Encana' where csr_root_sid=1452377;
update customer set name='EON' where csr_root_sid=423277;
update customer set name='Ford' where csr_root_sid=351242;
update customer set name='HSBC' where csr_root_sid=964859;
update customer set name='ING' where csr_root_sid=1288515;
update customer set name='Jaguar' where csr_root_sid=944996;
update customer set name='John Lewis/Waitrose' where csr_root_sid=390359;
update customer set name='National Grid' where csr_root_sid=340540;
update customer set name='Pick N Pay' where csr_root_sid=1170635;
update customer set name='RWE' where csr_root_sid=1291907;
update customer set name='Starbucks' where csr_root_sid=713559;
update customer set name='Whistler' where csr_root_sid=1311368;
end;
/


@update_tail
