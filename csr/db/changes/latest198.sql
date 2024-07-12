
-- Please update version.sql too -- this keeps clean builds in sync
define version=198
@update_header

alter table autocreate_user add (
    APPROVED_DTM            DATE,
    APPROVED_BY_USER_SID    NUMBER(10, 0),
    CREATED_USER_SID        NUMBER(10, 0)
);

ALTER TABLE AUTOCREATE_USER ADD CONSTRAINT RefCSR_USER787 
    FOREIGN KEY (APPROVED_BY_USER_SID)
    REFERENCES CSR_USER(CSR_USER_SID)
;

ALTER TABLE AUTOCREATE_USER ADD CONSTRAINT RefCSR_USER789 
    FOREIGN KEY (CREATED_USER_SID)
    REFERENCES CSR_USER(CSR_USER_SID)
;


-- we need to add these in since they write to the audit log
-- which has an FK constraint on csr_user. csr_data_pkg has been
-- updated to automatically create and destroy these rows in future
insert into csr_user
	(csr_user_sid, email, guid, region_mount_point_sid, indicator_mount_point_sid, app_sid,
	full_name, user_name, friendly_name, info_xml, send_alerts, show_portal_help)
	select so.sid_id, 'support@credit360.com',  user_pkg.GenerateACT, c.region_root_sid, c.ind_root_sid, 
		c.app_sid, 'User Creator', 'UserCreatorDaemon', 'User Creator', null, 0, 0
	  from security.securable_object so, customer c
	 where so.name='UserCreatorDaemon'
	   and so.application_sid_id = c.app_sid;

@update_tail

