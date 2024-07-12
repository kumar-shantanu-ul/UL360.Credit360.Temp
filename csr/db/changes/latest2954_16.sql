-- Please update version.sql too -- this keeps clean builds in sync
define version=2954
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.DATAVIEW ADD TREAT_NULL_AS_ZERO NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW ADD CONSTRAINT CK_DATAVIEW_TREAT_NULL_AS_ZRO CHECK (TREAT_NULL_AS_ZERO IN (0,1));
ALTER TABLE CSR.DATAVIEW_HISTORY ADD TREAT_NULL_AS_ZERO NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW_HISTORY ADD CONSTRAINT CK_DV_HIST_TREAT_NULL_AS_ZERO CHECK (TREAT_NULL_AS_ZERO IN (0,1));
ALTER TABLE CSR.DATAVIEW DROP COLUMN USE_BACKFILL;
ALTER TABLE CSR.DATAVIEW_HISTORY DROP COLUMN USE_BACKFILL;

ALTER TABLE CSRIMP.DATAVIEW ADD TREAT_NULL_AS_ZERO NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW ADD CONSTRAINT CK_DATAVIEW_TREAT_NULL_AS_ZRO CHECK (TREAT_NULL_AS_ZERO IN (0,1));
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD TREAT_NULL_AS_ZERO NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD CONSTRAINT CK_DV_HIST_TREAT_NULL_AS_ZERO CHECK (TREAT_NULL_AS_ZERO IN (0,1));
ALTER TABLE CSRIMP.DATAVIEW DROP COLUMN USE_BACKFILL;
ALTER TABLE CSRIMP.DATAVIEW_HISTORY DROP COLUMN USE_BACKFILL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
begin
	update security.menu
	   set action = '/csr/site/reports/excel2/values.acds'
	 where action = '/csr/site/reports/excel/values.acds';
end;
/

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../dataview_pkg
@../dataview_body
@../schema_body
@../csrimp/imp_body

@update_tail
