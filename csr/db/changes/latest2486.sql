-- Please update version.sql too -- this keeps clean builds in sync
define version=2486
@update_header

CREATE OR REPLACE VIEW csr.v$delegation AS
	SELECT d.*, NVL(dd.description, d.name) as description, dp.submit_confirmation_text as delegation_policy
	  FROM csr.delegation d
	  LEFT JOIN csr.delegation_description dd ON dd.app_sid = d.app_sid 
	   AND dd.delegation_sid = d.delegation_sid 
	   AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  LEFT JOIN csr.delegation_policy dp ON dp.app_sid = d.app_sid 
	   AND dp.delegation_sid = d.delegation_sid;

@..\delegation_pkg
@..\delegation_body


@update_tail