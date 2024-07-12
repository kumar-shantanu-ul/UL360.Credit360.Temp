-- Please update version.sql too -- this keeps clean builds in sync
define version=2764
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table csr.delegation
add allow_multi_period number(1) DEFAULT 0 NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
-- These views are in csr\db\create_views.sql - there isn't actually any change to the sql content - it just needs to pick up the new columns
-- that are in d.*
CREATE OR REPLACE VIEW csr.v$delegation AS
	SELECT d.*, NVL(dd.description, d.name) as description, dp.SUBMIT_CONFIRMATION_TEXT as delegation_policy
	  FROM csr.delegation d
    LEFT JOIN csr.delegation_description dd ON dd.app_sid = d.app_sid 
     AND dd.delegation_sid = d.delegation_sid  
	 AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
    LEFT JOIN CSR.DELEGATION_POLICY dp ON dp.app_sid = d.app_sid 
     AND dp.delegation_sid = d.delegation_sid;
     
CREATE OR REPLACE VIEW csr.v$delegation_hierarchical AS
	SELECT d.*, NVL(dd.description, d.name) as description, dp.submit_confirmation_text
	  FROM (
		SELECT delegation.*, CONNECT_BY_ROOT(delegation_sid) root_delegation_sid
		  FROM delegation
		 START WITH parent_sid = app_sid
	   CONNECT BY parent_sid = prior delegation_sid) d
	  LEFT JOIN delegation_description dd ON dd.app_sid = d.app_sid 
	   AND dd.delegation_sid = d.delegation_sid 
	   AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  LEFT JOIN delegation_policy dp ON dp.delegation_sid = root_delegation_sid;

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
	VALUES (4, 'Toggle mutli-period delegation flag', 'Toggles the multi-period override for the specified delegation and its children. See wiki for details ("Per delegation" section)', 
		'ToggleDelegMutliPeriodFlag', 'W2324');
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (4, 'Delegation sid', 'The sid of the delegation to run against', 1);
END;
/

-- ** New package grants **

-- *** Packages ***
@..\delegation_pkg
@..\delegation_body
@..\util_script_pkg
@..\util_script_body

@update_tail
