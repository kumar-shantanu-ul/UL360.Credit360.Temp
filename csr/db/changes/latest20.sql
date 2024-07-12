-- Please update version.sql too -- this keeps clean builds in sync
define version=20
@update_header

-- make all indicators and regions in trash inactive
 update region set active = 0 where region_sid in (
     select region_sid 
       from trash t, region r
      where t.trash_sid = r.region_sid and active = 1);
      
 update ind set active = 0 where ind_sid in (
     select ind_sid 
       from trash t, ind i
      where t.trash_sid = i.ind_sid and active = 1);


 -- tidy up inds that have already been deleted
     delete from ind where ind_sid in (
     select ind_sid from ind
      minus
      select sid_id from security.securable_object);

-- more making trash inactive
declare
	v_act varchar(38);
begin
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
     update ind set active = 0 
      where ind_sid in (
     select ind_sid 
       from ind
      where securableobject_pkg.GetPathFromSID(v_act, ind_sid) like '%/Trash/%'
      and active = 1);
      -- now regions
     update region set active = 0 
      where region_sid in (
     select region_sid 
       from region
      where securableobject_pkg.GetPathFromSID(v_act, region_sid) like '%/Trash/%'
      and active = 1);
end;    
/

update csr_user set indicator_mount_point_sid = null where csr_user_sid IN (select csr_user_sid from csr_User cu, ind i where cu.indicator_mount_point_sid = i.ind_sid and i.active =0);
      
update csr_user set region_mount_point_sid = null where csr_user_sid IN (select csr_user_sid from csr_User cu, region r where cu.region_mount_point_sid = r.region_sid and r.active =0);

@update_tail
