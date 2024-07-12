-- Please update version.sql too -- this keeps clean builds in sync
define version=3167
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_item_rollout
	ADD federal_requirement_code VARCHAR2(255);

ALTER TABLE csr.compliance_item_rollout
	ADD is_federal_req NUMBER(10,0);

ALTER TABLE csrimp.compliance_item_rollout
	ADD federal_requirement_code VARCHAR2(255);

ALTER TABLE csrimp.compliance_item_rollout
	ADD is_federal_req NUMBER(10,0);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (50, 'Set duplicated Enhesa items to out of scope.', 'Sets to out of scope all federal Enhesa requirements that have an unmerged duplicate in the local feed.', 'SetEnhesaDupesOutOfScope', NULL);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../compliance_pkg
@../util_script_pkg

@../compliance_body
@../schema_body
@../util_script_body
@../csrimp/imp_body


@update_tail
