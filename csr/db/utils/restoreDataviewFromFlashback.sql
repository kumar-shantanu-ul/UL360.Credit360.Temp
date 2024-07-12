begin
insert into csr.ind_list (ind_sid)
	select sid_id from security.securable_object as of timestamp timestamp '2013-07-26 14:35:00'
	where sid_id not in (select sid_id from security.securable_object);
insert into csr.dataview
	select * from csr.dataview as of timestamp timestamp '2013-07-26 14:35:00'
	where dataview_sid in (select ind_sid from csr.ind_list);
insert into csr.DATAVIEW_ZONE
	select * from csr.DATAVIEW_ZONE as of timestamp timestamp '2013-07-26 14:35:00'
	where dataview_sid in (select ind_sid from csr.ind_list);
insert into csr.DATAVIEW_TREND
	select * from csr.DATAVIEW_TREND as of timestamp timestamp '2013-07-26 14:35:00'
	where dataview_sid in (select ind_sid from csr.ind_list);
insert into csr.DATAVIEW_SCENARIO_RUN
	select * from csr.DATAVIEW_SCENARIO_RUN as of timestamp timestamp '2013-07-26 14:35:00'
	where dataview_sid in (select ind_sid from csr.ind_list);
insert into csr.DATAVIEW_SCENARIO_RUN
	select * from csr.DATAVIEW_SCENARIO_RUN as of timestamp timestamp '2013-07-26 14:35:00'
	where dataview_sid in (select ind_sid from csr.ind_list);
insert into csr.DATAVIEW_REGION_MEMBER
	select * from csr.DATAVIEW_REGION_MEMBER as of timestamp timestamp '2013-07-26 14:35:00'
	where dataview_sid in (select ind_sid from csr.ind_list);
insert into csr.DATAVIEW_REGION_DESCRIPTION
	select * from csr.DATAVIEW_REGION_DESCRIPTION as of timestamp timestamp '2013-07-26 14:35:00'
	where dataview_sid in (select ind_sid from csr.ind_list);
insert into csr.DATAVIEW_IND_MEMBER
	select * from csr.DATAVIEW_IND_MEMBER as of timestamp timestamp '2013-07-26 14:35:00'
	where dataview_sid in (select ind_sid from csr.ind_list);
insert into csr.DATAVIEW_IND_DESCRIPTION
	select * from csr.DATAVIEW_IND_DESCRIPTION as of timestamp timestamp '2013-07-26 14:35:00'
	where dataview_sid in (select ind_sid from csr.ind_list);
insert into security.securable_object
	select * from security.securable_object as of timestamp timestamp '2013-07-26 14:35:00'
	where sid_id in (select ind_sid from csr.ind_list);
insert into security.acl
	select * from security.acl as of timestamp timestamp '2013-07-26 14:35:00'
	where acl_id in (select dacl_id from security.securable_object where sid_id in (select ind_sid from csr.ind_list));
end;
/
