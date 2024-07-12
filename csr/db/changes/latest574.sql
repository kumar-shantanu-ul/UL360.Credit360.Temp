-- Please update version.sql too -- this keeps clean builds in sync
define version=574
@update_header

alter table val drop constraint fk_val_val_change;
create or replace function get_search_condition( p_cons_name in varchar2 ) 
return varchar2
authid current_user
is
	l_search_condition user_constraints.search_condition%type;
begin
	select search_condition into l_search_condition
	  from user_constraints
  	 where constraint_name = p_cons_name;

	return l_search_condition;
end;
/

begin
	for r in (select constraint_name from user_constraints where table_name='VAL' and get_search_condition(constraint_name)='LAST_VAL_CHANGE_ID IS NOT NULL') loop
		execute immediate 'alter table val drop constraint '||r.constraint_name;
	end loop;
end;
/
drop function get_search_condition;

alter table val rename column last_val_change_id to changed_by_sid;
alter table val rename column last_changed_dtm to changed_dtm;
begin
	for r in (select constraint_name from user_constraints where table_name='VAL_CHANGE') loop
		execute immediate 'alter table val_change drop constraint '||r.constraint_name||' cascade';
	end loop;
	for r in (select index_name from user_indexes where table_name='VAL_CHANGE' and index_type not in ('LOB')) loop
		execute immediate 'drop index '||r.index_name;
	end loop;
end;
/
--alter table old_val_change rename to val_change;
alter table val_change rename to old_val_change;

CREATE TABLE CSR.VAL_CHANGE(
    APP_SID                        NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    VAL_CHANGE_ID                  NUMBER(10, 0)     NOT NULL,
    IND_SID                        NUMBER(10, 0)     NOT NULL,
    REGION_SID                     NUMBER(10, 0)     NOT NULL,
    PERIOD_START_DTM               DATE              DEFAULT SYSDATE NOT NULL,
    PERIOD_END_DTM                 DATE              DEFAULT sysdate NOT NULL,
    VAL_NUMBER                     NUMBER(24, 10),
    SOURCE_TYPE_ID                 NUMBER(10, 0)     NOT NULL,
    SOURCE_ID                      NUMBER,
    ENTRY_MEASURE_CONVERSION_ID    NUMBER(10, 0),
    ENTRY_VAL_NUMBER               NUMBER(24, 10),
    NOTE                           CLOB              DEFAULT EMPTY_CLOB(),
    CHANGED_BY_SID                 NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    CHANGED_DTM                    DATE              NOT NULL,
    REASON                         VARCHAR2(1024)    NOT NULL,
    CONSTRAINT CK_VAL_CHANGE_DATES CHECK (PERIOD_START_DTM = TRUNC(PERIOD_START_DTM, 'MON') AND PERIOD_END_DTM = TRUNC(PERIOD_END_DTM, 'MON') AND PERIOD_END_DTM > PERIOD_START_DTM),
    CONSTRAINT PK_VAL_CHANGE PRIMARY KEY (APP_SID, VAL_CHANGE_ID)
)
;
begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'VAL_CHANGE',
        policy_name     => 'VAL_CHANGE_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
end;
/

GRANT DELETE ON "CSR"."VAL_CHANGE" TO "ACTIONS";
GRANT INSERT ON "CSR"."VAL_CHANGE" TO "ACTIONS";
GRANT SELECT ON "CSR"."VAL_CHANGE" TO "ACTIONS";
GRANT UPDATE ON "CSR"."VAL_CHANGE" TO "ACTIONS";

insert into val_change (app_sid, val_change_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, source_type_id, source_id, entry_measure_conversion_id, entry_val_number, note, changed_by_sid, changed_dtm, reason)
  select app_sid, val_change_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, source_type_id, source_id, entry_measure_conversion_id, entry_val_number, note, changed_by_sid, changed_dtm, reason
    from old_val_change
   where source_type_id not in (5,6);


CREATE OR REPLACE VIEW val_converted (
	app_sid, val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, 
	aggr_est_number, alert, flags, source_id, entry_measure_conversion_id, entry_val_number, 
	note, source_type_id, factor_a, factor_b, factor_c, changed_by_sid, changed_dtm
) AS
	SELECT v.app_sid, v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
	       -- we derive val_number from entry_val_number in case of pct_ownership
	       -- we round the value to avoid Arithmetic Overflows from converting Oracle Decimals to .NET Decimals
		   ROUND(NVL(NVL(mc.a, mcp.a), 1) * POWER(v.entry_val_number, NVL(NVL(mc.b, mcp.b), 1)) + NVL(NVL(mc.c, mcp.c), 0),10) val_number,
		   v.aggr_est_number,
		   v.alert, v.flags, v.source_id,
		   v.entry_measure_conversion_id, v.entry_val_number,
		   v.note, v.source_type_id,
		   NVL(mc.a, mcp.a) factor_a,
		   NVL(mc.b, mcp.b) factor_b,
		   NVL(mc.c, mcp.c) factor_c,
		   v.changed_by_sid, v.changed_dtm
	  FROM val v, measure_conversion mc, measure_conversion_period mcp
	 WHERE mc.measure_conversion_id = mcp.measure_conversion_id(+)
	   AND v.entry_measure_conversion_id = mc.measure_conversion_id(+)
	   AND (v.period_start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
	   AND (v.period_start_dtm < mcp.end_dtm or mcp.end_dtm is null);      

drop table error_log;
drop package error_pkg;

create table val_changed_by (app_sid number(10), val_id number(10), changed_by_sid number(10),constraint pk_val_changed_by primary key (app_sid,val_id)) 
organization index;

insert into val_changed_by
	select app_sid,val_id,min(changed_by_sid) keep (dense_rank first order by val_change_id desc)
	  from old_val_change
	 where val_id is not null
	 group by app_sid, val_id;

rename val to old_val;
alter table old_val rename constraint pk_val to pk_old_val;
alter table old_val rename constraint ck_val_num to ck_old_val_num;
alter table old_val rename constraint ck_val_dates to ck_old_val_dates;
alter index pk_val rename to pk_old_val;

CREATE TABLE CSR.VAL(
    APP_SID                        NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    VAL_ID                         NUMBER(10, 0)     NOT NULL,
    IND_SID                        NUMBER(10, 0)     NOT NULL,
    REGION_SID                     NUMBER(10, 0)     NOT NULL,
    PERIOD_START_DTM               DATE              NOT NULL,
    PERIOD_END_DTM                 DATE,
    VAL_NUMBER                     NUMBER(24, 10),
    AGGR_EST_NUMBER                NUMBER(24, 10),
    ALERT                          VARCHAR2(255),
    SOURCE_TYPE_ID                 NUMBER(10, 0)     NOT NULL,
    FLAGS                          NUMBER(10, 0)     DEFAULT 0 NOT NULL,
    SOURCE_ID                      NUMBER(10, 0),
    ENTRY_MEASURE_CONVERSION_ID    NUMBER(10, 0),
    ENTRY_VAL_NUMBER               NUMBER(24, 10),
    NOTE                           CLOB              DEFAULT EMPTY_CLOB(),
    CHANGED_DTM               	   DATE              DEFAULT SYSDATE NOT NULL,
    CHANGED_BY_SID				   NUMBER(10, 0)	 DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    CONSTRAINT CK_VAL_NUM CHECK ((val_number IS NOT NULL AND entry_val_number IS NOT NULL) OR (val_number IS NULL AND entry_val_number IS NULL)),
    CONSTRAINT CK_VAL_DATES CHECK (PERIOD_START_DTM = TRUNC(PERIOD_START_DTM, 'MON') AND PERIOD_END_DTM = TRUNC(PERIOD_END_DTM, 'MON') AND PERIOD_END_DTM > PERIOD_START_DTM),
    CONSTRAINT PK_VAL PRIMARY KEY (APP_SID, VAL_ID)
)
;
begin
    dbms_rls.add_policy(
        object_schema   => 'CSR',
        object_name     => 'VAL',
        policy_name     => 'VAL_POLICY',
        function_schema => 'CSR',
        policy_function => 'appSidCheck',
        statement_types => 'select, insert, update, delete',
        update_check	=> true,
        policy_type     => dbms_rls.context_sensitive );
end;
/

GRANT DELETE ON "CSR"."VAL" TO "ACTIONS";
GRANT SELECT ON "CSR"."VAL" TO "ACTIONS";
GRANT UPDATE ON "CSR"."VAL" TO "ACTIONS";
GRANT REFERENCES ON "CSR"."VAL" TO "ACTIONS";
--GRANT SELECT ON "CSR"."VAL" TO "WORLDBANK";
--GRANT SELECT ON "CSR"."VAL" TO "BRITISHLAND";
--GRANT REFERENCES ON "CSR"."VAL" TO "BRITISHLAND";
--GRANT SELECT ON "CSR"."VAL" TO "ALI";

insert into val (app_sid, val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, aggr_est_number, alert, source_type_id, flags, source_id,
			     entry_measure_conversion_id, entry_val_number, note, changed_dtm, changed_by_sid)
	select ov.app_sid, ov.val_id, ov.ind_sid, ov.region_sid, ov.period_start_dtm, ov.period_end_dtm, ov.val_number, ov.aggr_est_number, ov.alert, ov.source_type_id, ov.flags, ov.source_id,
		   ov.entry_measure_conversion_id, ov.entry_val_number, ov.note, ov.changed_dtm, nvl(vcb.changed_by_sid, 3)
	  from old_val ov, val_changed_by vcb
	where ov.app_sid = vcb.app_sid(+) and ov.val_id = vcb.val_id(+);
	   
drop table val_changed_by;
drop table old_val cascade constraints;
CREATE INDEX CSR.IDX_VAL_REGION_SID ON CSR.VAL(APP_SID, REGION_SID)
;
CREATE INDEX CSR.IDX_VAL_PERIOD ON CSR.VAL(APP_SID, PERIOD_END_DTM, PERIOD_START_DTM)
;
CREATE INDEX CSR.IDX_VAL_IND_SID ON CSR.VAL(APP_SID, IND_SID)
;
-- remove any duplicates that came in whilst val was being populated
begin
	dbms_output.enable(null);
	for r in (select app_sid,ind_sid,region_sid,period_start_dtm,period_end_dtm,max(val_id) latest_val_id
				from val v
 			   group by app_sid,ind_sid,region_sid,period_start_dtm,period_end_dtm
			   having count(*) > 1) loop
		delete from val
		 where app_sid = r.app_sid and ind_sid = r.ind_sid and region_sid = r.region_sid
		   and period_start_dtm = r.period_start_dtm and period_end_dtm = r.period_end_dtm
		   and val_id != r.latest_val_id;
		dbms_output.put_line('deleted '||sql%rowcount||' dups for app='||r.app_sid||',ind='||r.ind_sid||',reg='||r.region_sid||',start='||r.period_start_dtm||',end='||r.period_end_dtm);
	end loop;
end;
/
alter table val add constraint UK_VAL_UNIQUE unique (APP_SID, IND_SID, REGION_SID, PERIOD_START_DTM, PERIOD_END_DTM)
using index tablespace indx;
CREATE INDEX CSR.IDX_VAL_EMC ON CSR.VAL(APP_SID, ENTRY_MEASURE_CONVERSION_ID)
;
CREATE INDEX CSR.IDX_VAL_CHANGED_BY ON CSR.VAL(APP_SID, CHANGED_BY_SID)
;
create index ix_dataview_updated_by on dataview(app_sid, last_updated_sid);
create index ix_supplier_region on supplier(app_sid, region_sid);
CREATE INDEX CSR.IDX_VAL_SOURCE ON CSR.VAL(APP_SID, SOURCE_ID)
;
CREATE INDEX CSR.IDX_VAL_CHANGE_IRP ON CSR.VAL_CHANGE(APP_SID, IND_SID, REGION_SID, PERIOD_END_DTM, PERIOD_START_DTM)
;
CREATE INDEX CSR.IDX_VAL_CHANGE_USER_DATE ON CSR.VAL_CHANGE(APP_SID, CHANGED_BY_SID, CHANGED_DTM DESC, VAL_CHANGE_ID)
;
CREATE INDEX CSR.IDX_VAL_CHANGE_REGION_SID ON CSR.VAL_CHANGE(APP_SID, REGION_SID)
;
CREATE INDEX CSR.IDX_VAL_CHANGE_EMC ON CSR.VAL_CHANGE(APP_SID, ENTRY_MEASURE_CONVERSION_ID)
;
ALTER TABLE CSR.IMP_VAL ADD CONSTRAINT RefVAL156 
    FOREIGN KEY (APP_SID, SET_VAL_ID)
    REFERENCES CSR.VAL(APP_SID, VAL_ID)
;
ALTER TABLE CSR.VAL ADD CONSTRAINT RefMEASURE_CONVERSION5 
    FOREIGN KEY (APP_SID, ENTRY_MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

ALTER TABLE CSR.VAL ADD CONSTRAINT RefSOURCE_TYPE205 
    FOREIGN KEY (SOURCE_TYPE_ID)
    REFERENCES SOURCE_TYPE(SOURCE_TYPE_ID)
;

ALTER TABLE CSR.VAL ADD CONSTRAINT RefREGION1232 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
;

ALTER TABLE CSR.VAL ADD CONSTRAINT FK_VAL_IND 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.VAL ADD CONSTRAINT FK_VAL_CSR_USER
    FOREIGN KEY (APP_SID, CHANGED_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.VAL_CHANGE ADD CONSTRAINT RefMEASURE_CONVERSION66 
    FOREIGN KEY (APP_SID, ENTRY_MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

ALTER TABLE CSR.VAL_CHANGE ADD CONSTRAINT RefSOURCE_TYPE206 
    FOREIGN KEY (SOURCE_TYPE_ID)
    REFERENCES SOURCE_TYPE(SOURCE_TYPE_ID)
;

ALTER TABLE CSR.VAL_CHANGE ADD CONSTRAINT RefIND961 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.VAL_CHANGE ADD CONSTRAINT RefCSR_USER1045 
    FOREIGN KEY (APP_SID, CHANGED_BY_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.VAL_CHANGE ADD CONSTRAINT RefREGION1233 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
;

delete from val_accuracy where (app_sid, val_id) not in (select app_sid, val_id from val);

ALTER TABLE VAL_ACCURACY ADD CONSTRAINT RefVAL441 
    FOREIGN KEY (APP_SID, VAL_ID)
    REFERENCES CSR.VAL(APP_SID, VAL_ID)
;

delete from val_file where (app_sid, val_id) not in (select app_sid, val_id from val);
ALTER TABLE VAL_FILE ADD CONSTRAINT RefVAL741 
    FOREIGN KEY (APP_SID, VAL_ID)
    REFERENCES CSR.VAL(APP_SID, VAL_ID)
;

create index ix_val_change_source_type on VAL_CHANGE(SOURCE_TYPE_ID) tablespace indx;
create index ix_val_source_type on VAL(SOURCE_TYPE_ID) tablespace indx;

begin
	user_pkg.logonadmin;
	for r in (select sid_id from security.menu where lower(action) like '/csr/site/dataexplorer/errorlist.acds%') loop
		securableobject_pkg.deleteso(sys_context('security','act'),r.sid_id);
	end loop;
end;
/

begin
dbms_stats.gather_table_stats(ownname=>'CSR',tabname=>'VAL',estimate_percent=>null,cascade=>true);
dbms_stats.gather_table_stats(ownname=>'CSR',tabname=>'VAL_CHANGE',estimate_percent=>null,cascade=>true);
end;
/

@../calc_pkg.sql
@../schema_pkg.sql
@../calc_body.sql
@../csr_data_body.sql
@../imp_body.sql
@../indicator_body.sql
@../rag_body.sql
@../region_body.sql
@../schema_body.sql
@../sheet_body.sql
@../stored_calc_datasource_body.sql
@../system_status_body.sql
@../val_body.sql
@../val_datasource_body.sql

@update_tail
