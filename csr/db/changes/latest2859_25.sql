-- Please update version.sql too -- this keeps clean builds in sync
define version=2859
define minor_version=25
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.cms_tab_issue_aggregate_ind ADD (
    closed_ind_sid					NUMBER(10),
    open_ind_sid 					NUMBER(10),
    closed_td_ind_sid 				NUMBER(10),
    rejected_td_ind_sid 			NUMBER(10),
    open_od_ind_sid 				NUMBER(10),
    open_nod_ind_sid 				NUMBER(10),
    open_od_u30_ind_sid 			NUMBER(10),
    open_od_u60_ind_sid 			NUMBER(10),
    open_od_u90_ind_sid 			NUMBER(10),
    open_od_o90_ind_sid 			NUMBER(10)
);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../../../aspen2/cms/db/tab_body
@../csrimp/imp_body

@update_tail
