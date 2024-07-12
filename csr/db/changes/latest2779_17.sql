-- Please update version.sql too -- this keeps clean builds in sync
define version=2779
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer
ADD tolerance_checker_req_merged NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csr.customer
ADD CONSTRAINT ck_customer_tol_chk_req_mrgd CHECK (tolerance_checker_req_merged IN (0, 1, 2));

-- Now CSRIMP

ALTER TABLE csrimp.customer
ADD tolerance_checker_req_merged NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csrimp.customer
ADD CONSTRAINT ck_customer_tol_chk_req_mrgd CHECK (tolerance_checker_req_merged IN (0, 1, 2));


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (8, 'Set tolerance checker data requirement', 'Sets the tolerance checker requirement in regards to merged data. See wiki for details.', 'SetToleranceChkrMergedDataReq', 'W2405');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (8, 'Setting value (0 off, 1 merged, 2 submit)', 'The (side wide) setting to use.', 0);

-- ** New package grants **

-- *** Packages ***
@../csr_app_body
@../csrimp/imp_body
@../sheet_pkg
@../sheet_body
@../delegation_pkg
@../delegation_body
@../util_script_pkg
@../util_script_body


@update_tail
