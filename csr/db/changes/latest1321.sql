-- Please update version.sql too -- this keeps clean builds in sync
define version=1321
@update_header
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

create table cms.sys_schema (
	oracle_schema varchar2(30) not null,
	constraint pk_sys_schema primary key (oracle_schema)
);

BEGIN
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('ACTIONS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('ANONYMOUS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('APEX_030200');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('APEX_PUBLIC_USER');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('APPQOSSYS');			
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('ASPEN2');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('CHAIN');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('CHEM');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('CMS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('COMMERCE2');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('CSMART');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('CSR');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('CSRIMP');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('CT');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('CTXSYS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('DBSNMP');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('DIP');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('DMSYS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('DONATIONS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('EXFSYS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('FLOWS_FILES');			
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('GEMIMA');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('GT');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('MAIL');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('MDDATA');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('MDSYS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('MGMT_VIEW');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('MTDATA');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('MTSSYS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('OLAPSYS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('ORACLE_OCM');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('ORDDATA');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('ORDPLUGINS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('ORDSYS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('OUTLN');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('OWBSYS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('OWBSYS_AUDIT');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('POSTCODE');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('SECURITY');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('SI_INFORMTN_SCHEMA');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('SPATIAL_CSW_ADMIN_USR');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('SPATIAL_WFS_ADMIN_USR');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('SUPPLIER');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('SYS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('SYSMAN');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('SYSTEM');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('TSMSYS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('UPD');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('WEBFERRET');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('WEB_USER');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('WMSYS');
	INSERT INTO cms.sys_schema (oracle_schema) VALUES ('XDB');
END;
/

CREATE OR REPLACE VIEW cms.v$cms_schema AS
	-- no security, only used by csrexp
	SELECT oracle_schema
	  FROM tab
	 WHERE oracle_schema NOT IN (
	 		SELECT oracle_schema
	 		  FROM sys_schema)
	 UNION
	-- we can handle non-cms registered tables, so lets pick those
	-- up as well (provided customer.oracle_schema is set)
	SELECT oracle_schema
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

grant select on cms.sys_schema to csrimp;

@../../../aspen2/cms/db/tab_pkg
@../csrimp/imp_pkg
@../../../aspen2/cms/db/tab_body
@../csrimp/imp_body
@../csr_data_body
@../schema_body

@update_tail
