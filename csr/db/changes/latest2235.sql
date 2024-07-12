-- Please update version.sql too -- this keeps clean builds in sync
define version=2235
@update_header

------------- target dash

CREATE TABLE CSR.TARGET_DASHBOARD_REG_MEMBER(
    APP_SID        					NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TARGET_DASHBOARD_SID      		NUMBER(10, 0)    NOT NULL,
    REGION_SID     					NUMBER(10, 0)    NOT NULL,
    DESCRIPTION    					VARCHAR2(255)    NOT NULL,
    POS            					NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_TARGET_DASH_REG_MEMBER PRIMARY KEY (APP_SID, TARGET_DASHBOARD_SID, REGION_SID)
)
;

CREATE INDEX CSR.IX_TARGET_DASH_REG_MEMBER_REG ON CSR.TARGET_DASHBOARD_REG_MEMBER (APP_SID, REGION_SID);

ALTER TABLE CSR.TARGET_DASHBOARD_REG_MEMBER ADD CONSTRAINT FK_TARGET_DASH_REG_MEM_REG
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
;

alter table csr.target_dashboard_reg_member add constraint
fk_tgt_dash_reg_mem_tgt_dash foreign key (app_sid, target_dashboard_sid)
references csr.target_dashboard (app_sid, target_dashboard_sid);

insert into csr.target_dashboard_reg_member (app_sid, target_dashboard_sid, region_sid, description, pos)
	select td.app_sid, td.target_dashboard_sid, r.region_sid, r.description, r.pos
	  from csr.target_dashboard td, csr.range_region_member r
	 where td.app_sid = r.app_sid and td.target_dashboard_sid = r.range_sid;

ALTER TABLE CSR.TARGET_DASHBOARD_IND_MEMBER ADD (
	POS						 NUMBER(10),
    DESCRIPTION              VARCHAR2(1023) 
);

update csr.target_dashboard_ind_member tdi
   set (tdi.pos, tdi.description) = (
   		select rim.pos, rim.description
   		  from csr.range_ind_member rim
   		 where rim.app_sid = tdi.app_sid and rim.range_sid = tdi.target_dashboard_sid and rim.ind_sid = tdi.ind_sid);
   		 
update csr.target_dashboard_ind_member tdi
   set (tdi.description) = (
   		select id.description
   		  from csr.ind_description id
   		 where id.lang = 'en' AND tdi.ind_sid = id.ind_sid AND tdi.app_sid = id.app_sid)
 where description is null;

alter table csr.target_dashboard_ind_member modify description not null;

update csr.target_dashboard_ind_member tdi1
   set (tdi1.pos) = (
		select row_number() over (partition by app_sid, target_dashboard_sid order by pos) rn
		  from csr.target_dashboard_ind_member tdi2
		 where tdi1.app_sid = tdi2.app_sid and tdi1.target_dashboard_sid = tdi2.target_dashboard_sid and tdi1.ind_sid = tdi2.ind_sid)
  where tdi1.pos is null;

alter table csr.target_dashboard_ind_member modify pos not null;

insert into csr.target_dashboard_ind_member (app_sid, target_dashboard_sid, ind_sid, pos, description)
	select rim.app_sid, td.target_dashboard_sid, rim.ind_sid, rim.pos, rim.description
	  from csr.range_ind_member rim, csr.target_dashboard td
	 where rim.app_sid = td.app_sid and rim.range_sid = td.target_dashboard_sid
	   and (rim.app_sid, rim.range_sid, rim.ind_sid)
	   not in (select app_sid, target_dashboard_sid, ind_sid
	   			 from csr.target_dashboard_ind_member);

---------- forms
   
CREATE TABLE CSR.FORM_IND_MEMBER(
    APP_SID                  NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FORM_SID                NUMBER(10, 0)     NOT NULL,
    IND_SID                  NUMBER(10, 0)     NOT NULL,
    DESCRIPTION              VARCHAR2(1023)    NOT NULL,
    POS                      NUMBER(10, 0)     NOT NULL,
    SCALE                    NUMBER(10, 0),
    FORMAT_MASK              VARCHAR2(255),
    MEASURE_DESCRIPTION      VARCHAR2(255),
    FLAGS                    NUMBER(10, 0)     DEFAULT 0 NOT NULL,
    MULTIPLIER_IND_SID       NUMBER(10, 0),
    MEASURE_CONVERSION_ID    NUMBER(10, 0),
    CONSTRAINT PK_FORM_IND_MEMBER PRIMARY KEY (APP_SID, FORM_SID, IND_SID)
)
;

ALTER TABLE CSR.FORM_IND_MEMBER ADD CONSTRAINT FK_FORM_IND_MEMBER_FORM
    FOREIGN KEY (APP_SID, FORM_SID)
    REFERENCES CSR.FORM(APP_SID, FORM_SID)
;

ALTER TABLE CSR.FORM_IND_MEMBER ADD CONSTRAINT FK_FORM_IND_MEMBER_IND
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.FORM_IND_MEMBER ADD CONSTRAINT FK_FORM_IND_MEMBER_MULT_IND
    FOREIGN KEY (APP_SID, MULTIPLIER_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.FORM_IND_MEMBER ADD CONSTRAINT FK_FORM_IND_MEMBER_MSR_CONV
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

create index csr.ix_form_ind_member_ind on csr.form_ind_member(app_sid, ind_sid);
create index csr.ix_form_ind_member_mult_ind on csr.form_ind_member (app_sid, multiplier_ind_sid);
create index csr.ix_form_ind_member_mesur_conv on csr.form_ind_member (app_sid, measure_conversion_id);

insert into csr.form_ind_member (app_sid, form_sid, ind_sid, description, pos, scale, format_mask, measure_description, flags, multiplier_ind_sid, measure_conversion_id)
	select rim.app_sid, f.form_sid, rim.ind_sid, rim.description, rim.pos, rim.scale, rim.format_mask, rim.measure_description, rim.flags, rim.multiplier_ind_sid, rim.measure_conversion_id
	  from csr.range_ind_member rim, csr.form f
	 where f.app_sid = rim.app_sid and f.form_sid = rim.range_sid;
	 

CREATE TABLE CSR.FORM_REGION_MEMBER(
    APP_SID        					NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FORM_SID      					NUMBER(10, 0)    NOT NULL,
    REGION_SID     					NUMBER(10, 0)    NOT NULL,
    DESCRIPTION    					VARCHAR2(255)    NOT NULL,
    POS            					NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_FORM_REGION_MEMBER PRIMARY KEY (APP_SID, FORM_SID, REGION_SID)
)
;
ALTER TABLE CSR.FORM_REGION_MEMBER ADD CONSTRAINT FK_FORM_REGION_MEMBER_REGION
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
;
ALTER TABLE CSR.FORM_REGION_MEMBER ADD CONSTRAINT FK_FORM_REGION_MEMBER_FORM
    FOREIGN KEY (APP_SID, FORM_SID)
    REFERENCES CSR.FORM(APP_SID, FORM_SID)
;

create index csr.ix_form_region_member_region on csr.form_region_member (app_sid, region_sid);

insert into csr.form_region_member (app_sid, form_sid, region_sid, description, pos)
	select f.app_sid, f.form_sid, r.region_sid, r.description, r.pos
	  from csr.form f, csr.range_region_member r
	 where f.app_sid = r.app_sid and f.form_sid = r.range_sid;

alter table csrimp.form_ind_member rename column range_sid to form_sid;
alter table csrimp.form_region_member rename column range_sid to form_sid;

delete from CSRIMP.TARGET_DASHBOARD_IND_MEMBER;
ALTER TABLE CSRIMP.TARGET_DASHBOARD_IND_MEMBER ADD (
	POS						 NUMBER(10) NOT NULL,
    DESCRIPTION              VARCHAR2(1023) NOT NULL
);

CREATE TABLE CSRIMP.TARGET_DASHBOARD_REG_MEMBER(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    TARGET_DASHBOARD_SID      		NUMBER(10, 0)    NOT NULL,
    REGION_SID     					NUMBER(10, 0)    NOT NULL,
    DESCRIPTION    					VARCHAR2(255)    NOT NULL,
    POS            					NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_TARGET_DASH_REG_MEMBER PRIMARY KEY (CSRIMP_SESSION_ID, TARGET_DASHBOARD_SID, REGION_SID),
    CONSTRAINT FK_TARGET_DASH_REG_MEMBER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

grant insert on csr.form_ind_member to csrimp;
grant insert on csr.form_region_member to csrimp;
grant insert on csr.target_dashboard_reg_member to csrimp;
grant select on csr.dataview_ind_member to actions;
grant select,insert,update,delete on csrimp.target_dashboard_reg_member to web_user;

begin
	/*
	delete from csr.range_region_member
	 where (app_sid, range_sid, region_sid) in (
		select tdr.app_sid, tdr.target_dashboard_sid, tdr.region_sid
		  from csr.target_dashboard_reg_member tdr);
	delete from csr.range_ind_member where (app_sid, range_sid, ind_sid) in (
		select app_sid, range_sid, ind_sid
		  from csr.target_dashboard_ind_member);
		 
	delete from csr.range_ind_member
	 where (app_sid, range_sid, ind_sid) in (
	 		select app_sid, form_sid, ind_sid
	 		  from csr.form_ind_member
	);
	delete from csr.range_region_member
	 where (app_sid, range_sid, region_sid) in (
		select app_sid, form_sid, region_sid
		  from csr.form_region_member);
	*/
	null;
end;
/

alter table csr.range_ind_member rename to old_range_ind_member;
alter table csr.range_region_member rename to old_range_region_member;

begin
	for r in (select * from all_objects where owner='CSR' and object_name='RANGE_PKG' and object_type='PACKAGE') loop
		execute immediate 'drop package csr.range_pkg';
	end loop;
end;
/

@../form_pkg
@../schema_pkg
@../target_dashboard_pkg

@../csr_app_body
@../form_body
@../indicator_body
@../measure_body
@../region_body
@../schema_body
@../target_dashboard_body
@../actions/task_body
@../csrimp/imp_body

@update_tail
