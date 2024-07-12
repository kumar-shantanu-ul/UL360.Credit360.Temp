-- Please update version.sql too -- this keeps clean builds in sync
define version=266
@update_header

alter table val add last_changed_dtm date default sysdate not null ;
update val set last_changed_dtm = (select vc.changed_dtm from val_change vc where val.last_val_change_id = vc.val_change_id);

CREATE OR REPLACE VIEW val_converted (
	app_sid, val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, 
	aggr_est_number, alert, flags, source_id, entry_measure_conversion_id, entry_val_number, 
	last_val_change_id, note, source_type_id, factor, last_changed_dtm
) AS
	SELECT v.app_sid, v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
		   v.entry_val_number * NVL(NVL(mc.conversion_factor, mcp.conversion_factor),1) val_number, -- we derive val_number from entry_val_number in case of pct_ownership
		   v.aggr_est_number,
		   v.alert, v.flags, v.source_id,
		   v.entry_measure_conversion_id, v.entry_val_number, v.last_val_change_id,
		   v.note, v.source_type_id,
		   NVL(mc.conversion_factor, mcp.conversion_factor) factor,
		   last_changed_dtm
	  FROM val v, measure_conversion mc, measure_conversion_period mcp
	 WHERE mc.measure_conversion_id = mcp.measure_conversion_id(+)
	   AND v.entry_measure_conversion_id = mc.measure_conversion_id(+)
	   AND (v.period_start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
	   AND (v.period_start_dtm < mcp.end_dtm or mcp.end_dtm is null);      

/*
the much faster option involves rebuilding

CREATE TABLE VAL2(
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
    LAST_VAL_CHANGE_ID             NUMBER(10, 0),
    NOTE                           CLOB              DEFAULT EMPTY_CLOB(),
    LAST_CHANGED_DTM               DATE              DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_VAL2 PRIMARY KEY (APP_SID, VAL_ID)
    USING INDEX
TABLESPACE INDX
)
;

lock table val in exclusive mode;

insert into val2
	select v.app_sid, v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
		   v.val_number, v.aggr_est_number, v.alert, v.source_type_id, v.flags, v.source_id,
		   v.entry_measure_conversion_id, v.entry_val_number, v.last_val_change_id, 
		   v.note, vc.changed_dtm
	  from val v, val_change vc
	 where v.last_val_change_id = vc.val_change_id;
	 
drop table val cascade constraints;
alter table val2 rename to val;
alter table val rename constraint pk_val2 to pk_val;
alter index pk_val2 rename to pk_val;
alter table val modify lob(note) (cache);

ALTER TABLE VAL ADD CHECK 
	(LAST_VAL_CHANGE_ID IS NOT NULL) 
	DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE VAL ADD CONSTRAINT RefMEASURE_CONVERSION5 
    FOREIGN KEY (APP_SID, ENTRY_MEASURE_CONVERSION_ID)
    REFERENCES MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

ALTER TABLE VAL ADD CONSTRAINT RefREGION6 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)
;

ALTER TABLE VAL ADD CONSTRAINT RefSOURCE_TYPE205 
    FOREIGN KEY (SOURCE_TYPE_ID)
    REFERENCES SOURCE_TYPE(SOURCE_TYPE_ID)
;

ALTER TABLE VAL ADD CONSTRAINT FK_VAL_IND 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES IND(APP_SID, IND_SID)
;

ALTER TABLE VAL ADD CONSTRAINT FK_VAL_VAL_CHANGE 
    FOREIGN KEY (APP_SID, LAST_VAL_CHANGE_ID)
    REFERENCES VAL_CHANGE(APP_SID, VAL_CHANGE_ID)
;

CREATE INDEX IDX_VAL_REGION_SID ON VAL(APP_SID, REGION_SID)
TABLESPACE INDX
;
-- 
-- INDEX: IDX_VAL_PERIOD 
--

CREATE INDEX IDX_VAL_PERIOD ON VAL(APP_SID, PERIOD_END_DTM, PERIOD_START_DTM)
TABLESPACE INDX
;
-- 
-- INDEX: IDX_VAL_LAST_VAL_CHANGE_ID 
--

CREATE UNIQUE INDEX IDX_VAL_LAST_VAL_CHANGE_ID ON VAL(APP_SID, LAST_VAL_CHANGE_ID)
TABLESPACE INDX
;
-- 
-- INDEX: IDX_VAL_IND_SID 
--

CREATE INDEX IDX_VAL_IND_SID ON VAL(APP_SID, IND_SID)
TABLESPACE INDX
;
-- 
-- INDEX: UK_VAL_UNIQUE 
--

CREATE UNIQUE INDEX UK_VAL_UNIQUE ON VAL(APP_SID, IND_SID, REGION_SID, PERIOD_START_DTM, PERIOD_END_DTM)
TABLESPACE INDX
;
-- 
-- INDEX: IDX_VAL_EMC 
--

CREATE INDEX IDX_VAL_EMC ON VAL(APP_SID, ENTRY_MEASURE_CONVERSION_ID)
TABLESPACE INDX
;
-- 
-- INDEX: IDX_VAL_SOURCE 
--

CREATE INDEX IDX_VAL_SOURCE ON VAL(APP_SID, SOURCE_ID)
TABLESPACE INDX
;

grant select, references on val to britishland;
grant select, references, update, delete on val to actions;

begin
	dbms_stats.gather_table_stats(ownname=> 'CSR', tabname=>'VAL',estimate_percent=>100, method_opt=>'for all columns size auto',degree=>4,cascade=>TRUE);
end;

*/

@update_tail

