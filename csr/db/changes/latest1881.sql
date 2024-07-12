-- Please update version.sql too -- this keeps clean builds in sync
define version=1881
@update_header

CREATE OR REPLACE TYPE CSR.T_INITIATIVE_METRIC_VAL_ROW AS 
  OBJECT ( 
    ITEM        NUMBER,
    POS    		NUMBER(10)
  );
/
CREATE OR REPLACE TYPE CSR.T_INITIATIVE_METRIC_VAL_TABLE AS 
  TABLE OF CSR.T_INITIATIVE_METRIC_VAL_ROW;
/

@../initiative_metric_pkg
@../initiative_pkg

@../initiative_metric_body
@../initiative_body


@update_tail
