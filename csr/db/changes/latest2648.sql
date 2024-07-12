--Please update version.sql too -- this keeps clean builds in sync
define version=2648
@update_header

ALTER TABLE csr.delegation 
  ADD tag_visibility_matrix_group_id NUMBER(10,0);

ALTER TABLE csr.delegation ADD CONSTRAINT FK_DELEG_TAG_GROUP_ID
	FOREIGN KEY(APP_SID, tag_visibility_matrix_group_id)
	REFERENCES CSR.TAG_GROUP(APP_SID, TAG_GROUP_ID);
	

-- Recreate the views to pickup the new column on csr.delegation
CREATE OR REPLACE VIEW csr.v$delegation AS
	SELECT d.*, NVL(dd.description, d.name) as description, dp.submit_confirmation_text as delegation_policy
	  FROM csr.delegation d
	  LEFT JOIN csr.delegation_description dd ON dd.app_sid = d.app_sid 
	   AND dd.delegation_sid = d.delegation_sid 
	   AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  LEFT JOIN csr.delegation_policy dp ON dp.app_sid = d.app_sid 
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
	   
-- Recompile on delegation pkg&body
@../delegation_pkg
@../delegation_body


@update_tail
