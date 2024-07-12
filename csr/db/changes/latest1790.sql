-- Please update version.sql too -- this keeps clean builds in sync
define version=1790
@update_header

CREATE TABLE csr.delegation_policy (
  app_sid NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
  delegation_sid NUMBER(10) NOT NULL,
  submit_confirmation_text VARCHAR2(4000) NOT NULL,
  CONSTRAINT pk_delegation_policy PRIMARY KEY(app_sid, delegation_sid),
  CONSTRAINT fk_delegation_polidy_deleg FOREIGN KEY(app_sid, delegation_sid) REFERENCES csr.delegation(app_sid, delegation_sid)
);

CREATE OR REPLACE VIEW csr.v$delegation AS
	SELECT d.*, dp.submit_confirmation_text
	  FROM (
		SELECT delegation.*, CONNECT_BY_ROOT(delegation_sid) root_delegation_sid
		  FROM delegation
		 START WITH parent_sid = app_sid
	   CONNECT BY parent_sid = prior delegation_sid) d
	  LEFT JOIN delegation_policy dp ON dp.delegation_sid = root_delegation_sid;

@../region_pkg
@../region_body	  
@../delegation_pkg
@../delegation_body
@../sheet_body
--@../../../clients/heinekenspm/db/report_pkg
--@../../../clients/heinekenspm/db/report_body

@update_tail