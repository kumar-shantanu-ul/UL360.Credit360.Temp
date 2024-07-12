-- Please update version.sql too -- this keeps clean builds in sync
define version=3414
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_SHEETS_IND_REG_TO_USE_ROW AS
  OBJECT (
  APP_SID             NUMBER(10),
  DELEGATION_SID      NUMBER(10),
  LVL                 NUMBER(10),
  SHEET_ID            NUMBER(10),
  IND_SID             NUMBER(10),
  REGION_SID          NUMBER(10),
  START_DTM           DATE,
  END_DTM             DATE,
  LAST_ACTION_COLOUR  VARCHAR2(1)
  );
/

CREATE OR REPLACE TYPE CSR.T_SHEETS_IND_REG_TO_USE_TABLE AS 
  TABLE OF CSR.T_SHEETS_IND_REG_TO_USE_ROW;
/

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../stored_calc_datasource_pkg
@../stored_calc_datasource_body

@update_tail
