-- Please update version.sql too -- this keeps clean builds in sync
define version=1343
@update_header

-- FK_DELEG_USER_DUC wrong in the model, FK_CSR_USER_DUC1/2 are on live but not needed (table refs user_cover for the columns those constraints cover, which refs csr_user)
begin
	for r in (select constraint_name from all_constraints where constraint_name IN ('FK_DELEG_USER_DUC','FK_CSR_USER_DUC1','FK_CSR_USER_DUC2') and owner='CSR' and table_name='DELEGATION_USER_COVER') loop
		execute immediate 'ALTER TABLE csr.DELEGATION_USER_COVER DROP CONSTRAINT '||r.constraint_name;
	end loop;
end;
/

-- wrong on live, adds sane name for stuff built from the model
alter table csr.delegation_user drop primary key drop index;
alter table csr.delegation_user add constraint pk_delegation_user primary key (app_sid, delegation_sid, user_sid);

-- wrong order on live
alter table csr.delegation_user_cover drop primary key drop index;
alter table csr.delegation_user_cover add constraint PK_DELEGATION_USER_COVER primary key (app_sid, user_cover_id, user_giving_cover_sid, user_being_covered_sid, delegation_sid);

-- missing in both
alter table csr.delegation_user_cover add constraint FK_DUC_DELEGATION foreign key (app_sid, delegation_sid) references csr.delegation (app_sid, delegation_sid);

@update_tail
