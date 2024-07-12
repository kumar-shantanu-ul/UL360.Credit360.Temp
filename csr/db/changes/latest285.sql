-- Please update version.sql too -- this keeps clean builds in sync
define version=285
@update_header

ALTER TABLE CSR.MODEL_SHEET
ADD (DISPLAY_CHARTS_BOO NUMBER(1) DEFAULT 0);

ALTER TABLE CSR.MODEL_SHEET
ADD (CHART_COUNT NUMBER(10) DEFAULT 0);

@update_tail
