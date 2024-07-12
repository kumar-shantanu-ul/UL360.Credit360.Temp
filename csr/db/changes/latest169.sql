-- Please update version.sql too -- this keeps clean builds in sync
define version=169
@update_header

-- fix parent sid copies that weren't updated by simple reparenting of things under CSR

-- select * from DASHBOARD_ITEM where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = DASHBOARD_ITEM.DASHBOARD_ITEM_ID);

-- fix rubbish in dataviews
-- select dataview.parent_sid from DATAVIEW where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = DATAVIEW.DATAVIEW_sid);
delete from dataview where parent_sid not in (select sid_id from security.securable_object);
update dataview dv
   set dv.parent_sid = (select so.parent_sid_id from security.securable_object so where dv.dataview_sid = so.sid_id)
 where dv.dataview_sid in (
	select dataview.dataview_sid 
	  from DATAVIEW where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = DATAVIEW.DATAVIEW_sid));
		 

-- select * from DELEGATION where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = DELEGATION.DELEGATION_sid);
update delegation dv
   set dv.parent_sid = (select so.parent_sid_id from security.securable_object so where dv.delegation_sid = so.sid_id)
 where dv.delegation_sid in (
	select delegation.delegation_sid 
	  from delegation where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = delegation.delegation_sid));

-- select * from DOC_CURRENT where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = DOC_CURRENT.DOC_ID);

-- hmm, some wonky rows, nothing due to reparenting though.
-- delete from file_upload where parent_sid not in (select sid_id from security.securable_object);
-- select * from FILE_UPLOAD where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = FILE_UPLOAD.FILE_UPLOAD_sid);

-- select * from FORM where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = FORM.form_sid);
-- ok

-- select * from IMP_SESSION where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = IMP_SESSION.imp_session_sid);
-- ok

-- select * from IND where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = IND.IND_sid);

update ind dv
   set dv.parent_sid = (select so.parent_sid_id from security.securable_object so where dv.ind_sid = so.sid_id)
 where dv.ind_sid in (
	select ind.ind_sid 
	  from ind where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = ind.ind_sid));

-- select * from REGION where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = REGION.REGION_sid);
update region dv
   set dv.parent_sid = (select so.parent_sid_id from security.securable_object so where dv.region_sid = so.sid_id)
 where dv.region_sid in (
	select region.region_sid 
	  from region where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = region.region_sid));

-- select * from SECTION where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = SECTION.SECTION_sid);
-- ok

-- select * from TARGET_DASHBOARD where parent_sid <> (select parent_sid_id from security.securable_object where securable_object.sid_id = TARGET_DASHBOARD.TARGET_DASHBOARD_sid);
-- ok


@update_tail
