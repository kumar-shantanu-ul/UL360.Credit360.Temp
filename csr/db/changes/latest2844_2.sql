-- Please update version.sql too -- this keeps clean builds in sync
define version=2844
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CHAIN.FILTER_FIELD ADD SHOW_OTHER NUMBER(1);
ALTER TABLE CSRIMP.CHAIN_FILTER_FIELD ADD SHOW_OTHER NUMBER(1);

--Updating data here as it's necessary for the ddl
UPDATE chain.filter_field
   SET show_other = 1
 WHERE top_n IS NOT NULL
    OR bottom_n IS NOT NULL;

UPDATE csrimp.chain_filter_field
   SET show_other = 1
 WHERE top_n IS NOT NULL
    OR bottom_n IS NOT NULL;

ALTER TABLE CHAIN.FILTER_FIELD ADD CONSTRAINT CHK_FLTR_FLD_SHO_OTH_0_1 CHECK ((TOP_N IS NULL AND BOTTOM_N IS NULL) OR SHOW_OTHER IN (0,1)),
ALTER TABLE CSRIMP.CHAIN_FILTER_FIELD ADD CONSTRAINT CHK_FLTR_FLD_SHO_OTH_0_1 CHECK ((TOP_N IS NULL AND BOTTOM_N IS NULL) OR SHOW_OTHER IN (0,1)),


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
--Path @../chain/create_views
CREATE OR REPLACE VIEW CHAIN.v$filter_field AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, ff.show_all, ff.group_by_index,
		   f.compound_filter_id, ff.top_n, ff.bottom_n, ff.column_sid, ff.period_set_id,
		   ff.period_interval_id, ff.show_other
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../chain/filter_pkg
@../chain/filter_body
@../chain/company_filter_body
@../schema_body
@../csrimp/imp_body
@update_tail
