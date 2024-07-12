-- Please update version.sql too -- this keeps clean builds in sync
define version=1172
@update_header

-- flag indicator descriptions were changed to the short version (previously ind_selection_group_member.description)
-- when they were added to the delegation, so we've populated delegation_ind_description with those overriden
-- values, however we don't need these rows -- the code ignores them and uses ind_sel_group_member_desc.description instead.
delete from csr.delegation_ind_description
 where (app_sid, ind_sid) in (
 		select app_sid, ind_sid
		  from csr.ind_selection_group_member);


-- grants apparently missing from live
grant select,update,insert on csr.delegation_ind to csrimp;
grant insert,select on csr.delegation_grid_aggregate_ind to csrimp;
grant select on csr.ind_selection_group to csrimp;
grant select on csr.ind_selection_group_member to csrimp;
grant select on csr.v$ind_selection_group_dep to csrimp;

@../csrimp/imp_body

@update_tail
