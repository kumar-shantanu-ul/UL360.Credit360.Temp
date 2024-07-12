-- Please update version.sql too -- this keeps clean builds in sync
define version=2752
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE cms.tab_column ADD (
	restricted_by_policy			NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_restricted_by_policy_1_0 CHECK (restricted_by_policy IN (1, 0))
);

ALTER TABLE csrimp.cms_tab_column ADD (
	restricted_by_policy			NUMBER(1) NOT NULL,
	CONSTRAINT chk_restricted_by_policy_1_0 CHECK (restricted_by_policy IN (1, 0))
);

ALTER TABLE chain.filter_value MODIFY min_num_val NUMBER(24, 10);
ALTER TABLE chain.filter_value MODIFY max_num_val NUMBER(24, 10);
ALTER TABLE csrimp.chain_filter_value MODIFY max_num_val NUMBER(24, 10);
ALTER TABLE csrimp.chain_filter_value MODIFY max_num_val NUMBER(24, 10);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data
-- Setup some sensible defaults now we can chart/filter on numbers, so we don't
-- have id columns everywhere

-- turn off charting on all cms.tab_pkg.CT_AUTO_INCREMENT columns by default
UPDATE cms.tab_column
   SET show_in_breakdown = 0
 WHERE col_type = 16; 
 
-- turn off filtering/charting on all id columns that are fks to other tables
-- (filtering is handled by adapters for these)
UPDATE cms.tab_column
   SET show_in_breakdown = 0,
       show_in_filter = 0
 WHERE col_type = 0 
   AND data_type = 'NUMBER'
   AND column_sid IN (
	SELECT column_sid
	  FROM cms.fk_cons_col
	);

-- turn off filtering on auto columns for child tables by default
UPDATE cms.tab_column
   SET show_in_filter = 0
 WHERE col_type = 16
   AND tab_sid IN (
	SELECT tab_sid
	  FROM cms.tab_column tc
	  JOIN cms.fk_cons_col fcc ON tc.column_sid = fcc.column_sid
	 WHERE tc.col_type = 0
	   AND tc.data_type = 'NUMBER'
);

-- ** New package grants **

-- *** Packages ***
@..\..\..\aspen2\cms\db\tab_pkg

@..\..\..\aspen2\cms\db\tab_body
@..\..\..\aspen2\cms\db\filter_body
@..\csrimp\imp_body
@..\chain\filter_body

@update_tail
