-- Please update version.sql too -- this keeps clean builds in sync
define version=930
@update_header

alter table csr.deleg_plan_deleg_region add tag_id number(10);
alter table csr.deleg_plan_deleg_region add constraint fk_del_plan_del_reg_tag foreign key (app_sid, tag_id) references csr.tag(app_sid, tag_id);
create index csr.ix_del_plan_del_reg_tag on csr.deleg_plan_deleg_region (app_sid, tag_id);
alter table csr.deleg_plan_deleg_region modify region_selection varchar2(2);
alter table csr.deleg_plan add dynamic number(1) default 0 not null;
alter table csr.deleg_plan add constraint ck_dynamic check (dynamic in (0,1));
alter table csr.deleg_plan_deleg_region drop constraint CHK_DLG_PLN_DLG_RGN_RS;
alter table csr.deleg_plan_deleg_region add CONSTRAINT CHK_DLG_PLN_DLG_RGN_RS CHECK (REGION_SELECTION IN ('R','L','P','RT','LT','PT'));
 
create table csr.DELEG_PLAN_DELEG_REGION_DELEG (
    APP_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEG_PLAN_COL_DELEG_ID    NUMBER(10, 0)    NOT NULL,
    REGION_SID                 NUMBER(10, 0)    NOT NULL,
    applied_to_region_sid	   number(10, 0)	not null,
    MAPS_TO_ROOT_DELEG_SID     NUMBER(10, 0)	not null,
    HAS_MANUAL_AMENDS          NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    constraint pk_dlg_plan_dlg_reg_dlg primary key (app_sid, deleg_plan_col_deleg_id, region_sid, applied_to_region_sid),
    constraint fk_dlgpldlgregdlg_dlgpldlgreg foreign key (app_sid, deleg_plan_col_deleg_id, region_sid)
    references csr.deleg_plan_deleg_region (app_sid, deleg_plan_col_deleg_id, region_sid),
    constraint ck_delgplndlgregdelg_man_amnd CHECK (HAS_MANUAL_AMENDS IN (0,1))    
);

insert into csr.deleg_plan_deleg_region_deleg (app_sid, deleg_plan_col_deleg_id, region_sid, maps_to_root_deleg_sid, applied_to_region_sid)
	select app_sid, deleg_plan_col_deleg_id, region_sid, maps_to_root_deleg_sid, region_sid
	  from csr.deleg_plan_deleg_region dpdr
	 where maps_to_root_deleg_sid is not null
	 ;
alter table csr.deleg_plan_deleg_region drop constraint FK_DELEG_DLG_PLN_DLG_REG;
alter table csr.deleg_plan_deleg_region drop column maps_to_root_deleg_sid;
alter table csr.deleg_plan_deleg_region_deleg add constraint fk_delegplndelegregdlg_deleg
foreign key (app_sid, maps_to_root_deleg_sid) references csr.delegation (app_sid, delegation_sid);
alter table csr.deleg_plan_deleg_region_deleg add constraint fk_dlg_pln_dlg_reg_dlg_reg
foreign key (app_sid, applied_to_region_sid) references csr.region (app_sid, region_sid);
create index csr.ix_dlg_pln_dlg_reg_dlg_reg on csr.deleg_plan_deleg_region_deleg (app_sid, applied_to_region_sid);

CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_DELEG_REGION AS
	SELECT dpc.app_sid, dpc.deleg_plan_sid, dpdr.deleg_plan_col_deleg_id, dpc.deleg_plan_col_id, dpc.is_hidden, 
		   dpcd.delegation_sid, dpdr.region_sid, dpdr.pending_deletion, dpdr.region_selection,
		   dpdr.tag_id
	  FROM deleg_plan_deleg_region dpdr
	  JOIN deleg_plan_col_deleg dpcd ON dpdr.app_sid = dpcd.app_sid AND dpdr.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
	  JOIN deleg_plan_col dpc ON dpcd.app_sid = dpc.app_sid AND dpcd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id;

@../csr_data_pkg
@../tag_pkg
@../deleg_plan_pkg

@../csr_data_body
@../tag_body
@../delegation_body
@../deleg_plan_body

@update_tail
