-- Please update version.sql too -- this keeps clean builds in sync
define version=174
@update_header

alter session enable parallel dml;		 
alter table val add aggr_est_number number(24,10) parallel (degree 8);

update /*+ parallel(val,8)*/ val set aggr_est_number = val_number;

ALTER TABLE IND ADD (AGGR_ESTIMATE_WITH_IND_SID NUMBER(10));

ALTER TABLE IND ADD CONSTRAINT RefIND855 
    FOREIGN KEY (AGGR_ESTIMATE_WITH_IND_SID)
    REFERENCES IND(IND_SID)
;



alter table ind add constraint ck_ind_aggr
check (aggregate IN  ('SUM', 'FORCE SUM', 'AVERAGE') OR (aggregate IN ('NONE', 'DOWN', 'FORCE DOWN') AND aggr_estimate_with_ind_sid IS NULL));


		 
		 
-- 
-- TABLE: TAB_USER 
--
CREATE TABLE TAB_USER(
    TAB_ID      NUMBER(10, 0)    NOT NULL,
    USER_SID    NUMBER(10, 0)    NOT NULL,
    POS         NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    IS_OWNER    NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT PK437 PRIMARY KEY (TAB_ID, USER_SID)
);


INSERT INTO TAB_USER (tab_id, user_sid, pos, is_owner) 
	SELECT TAB_ID, USER_SID, POS, 1 FROM TAB;

ALTER TABLE TAB DROP COLUMN USER_SID;

ALTER TABLE TAB DROP COLUMN POS;

ALTER TABLE TAB ADD (IS_SHARED NUMBER(1) DEFAULT 0 NOT NULL);


ALTER TABLE TAB_USER ADD CONSTRAINT RefTAB858 
    FOREIGN KEY (TAB_ID)
    REFERENCES TAB(TAB_ID)
;

ALTER TABLE TAB_USER ADD CONSTRAINT RefCSR_USER859 
    FOREIGN KEY (USER_SID)
    REFERENCES CSR_USER(CSR_USER_SID)
;

CREATE OR REPLACE VIEW V$TAB_USER AS
	SELECT t.TAB_ID, t.APP_SID, t.LAYOUT, t.NAME, t.IS_SHARED, tu.USER_SID, tu.POS, tu.IS_OWNER
	  FROM TAB t, TAB_USER tu
	 WHERE t.TAB_ID = tu.TAB_ID;



ALTER TABLE ALL_METER DROP COLUMN PRO_RATA_IND_SID;

ALTER TABLE ALL_METER DROP COLUMN PRO_RATA_MEASURE_CONVERSION_ID;


CREATE OR REPLACE VIEW METER
	(REGION_SID, NOTE, PRIMARY_IND_SID, PRIMARY_MEASURE_CONVERSION_ID) AS
  SELECT REGION_SID, NOTE, PRIMARY_IND_SID, PRIMARY_MEASURE_CONVERSION_ID
    FROM ALL_METER
   WHERE ACTIVE = 1;
   
   
CREATE OR REPLACE FORCE VIEW VAL_CONVERTED (VAL_ID, IND_SID, REGION_SID, PERIOD_START_DTM, PERIOD_END_DTM, VAL_NUMBER, AGGR_EST_NUMBER, STATUS, ALERT, FLAGS, SOURCE_ID, ENTRY_MEASURE_CONVERSION_ID, ENTRY_VAL_NUMBER, LAST_VAL_CHANGE_ID, NOTE, SOURCE_TYPE_ID, FACTOR) AS 
SELECT v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
      v.entry_val_number * NVL(NVL(mc.conversion_factor, mcp.conversion_factor),1) val_number, -- we derive val_number from entry_val_number in case of pct_ownership
      v.aggr_est_number,
      v.status, v.alert, v.flags, v.source_id,
      v.entry_measure_conversion_id, v.entry_val_number, v.last_val_change_id,
      v.note, v.source_type_id,
      NVL(mc.conversion_factor, mcp.conversion_factor) factor
 FROM VAL V, MEASURE_CONVERSION MC, MEASURE_CONVERSION_PERIOD MCP
WHERE MC.MEASURE_CONVERSION_ID = MCP.MEASURE_CONVERSION_ID(+)
  AND V.entry_measure_conversion_id = mc.measure_conversion_id(+)
  AND (v.period_start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
  AND (v.period_start_dtm < mcp.end_dtm or mcp.end_dtm is null);


@..\indicator_pkg
@..\val_pkg
@..\region_pkg
@..\portlet_pkg
@..\meter_pkg

@..\indicator_body
@..\val_body
@..\region_body
@..\portlet_body
@..\meter_body
		 
		 
@update_tail
