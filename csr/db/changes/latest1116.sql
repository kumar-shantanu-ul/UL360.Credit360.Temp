-- Please update version.sql too -- this keeps clean builds in sync
define version=1116
@update_header

-- old column which is redundant
ALTER TABLE CMS.TAB_COLUMN DROP COLUMN HS_CALC_COLUMNS;


insert into cms.col_type values (28, 'Company');

@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@update_tail
