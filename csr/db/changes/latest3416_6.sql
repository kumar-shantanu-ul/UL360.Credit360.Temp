-- Please update version.sql too -- this keeps clean builds in sync
define version=3416
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_IND_TREE_ROW AS
  OBJECT (
  APP_SID					NUMBER(10),
  IND_SID                   NUMBER(10, 0),
  PARENT_SID                NUMBER(10, 0),
  DESCRIPTION               VARCHAR2(1023),
  IND_TYPE                  NUMBER(10, 0),
  MEASURE_SID               NUMBER(10, 0),
  MEASURE_DESCRIPTION		VARCHAR2(255),
  FORMAT_MASK				VARCHAR2(255),
  ACTIVE                    NUMBER(10, 0)
  );
/

CREATE OR REPLACE TYPE CSR.T_IND_TREE_TABLE AS
  TABLE OF CSR.T_IND_TREE_ROW;
/

CREATE OR REPLACE TYPE CSR.T_SEARCH_TAG_ROW AS
  OBJECT (
  SET_ID					NUMBER(10),
  TAG_ID                    NUMBER(10, 0)
  );
/

CREATE OR REPLACE TYPE CSR.T_SEARCH_TAG_TABLE AS
  TABLE OF CSR.T_SEARCH_TAG_ROW;
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
@../scenario_pkg
@../scenario_body

@update_tail
