-- Please update version.sql too -- this keeps clean builds in sync
define version=867
@update_header


ALTER TABLE CSR.EXCEL_EXPORT_OPTIONS ADD (
    METER_SHOW_COST_IND            NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    METER_SHOW_COST_MEASURE        NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    METER_SHOW_DAYS_IND            NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_EE_M_SHOW_COST_IND CHECK (METER_SHOW_COST_IND IN (0,1)),
    CONSTRAINT CHK_EE_M_SHOW_COST_MEASURE CHECK (METER_SHOW_COST_MEASURE IN (0,1)),
    CONSTRAINT CHK_EE_M_SHOW_DAYS_IND CHECK (METER_SHOW_DAYS_IND IN (0,1))
 );

@..\excel_export_pkg
@..\region_pkg

@..\excel_export_body
@..\region_body

@update_tail
