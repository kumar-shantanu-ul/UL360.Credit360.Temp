-- Please update version.sql too -- this keeps clean builds in sync
define version=520
@update_header

CONNECT actions/actions@&_CONNECT_IDENTIFIER

GRANT SELECT,REFERENCES ON project TO csr;
GRANT SELECT,REFERENCES ON project_tag_group TO csr;

GRANT SELECT,REFERENCES ON task_tag TO csr;
GRANT SELECT,REFERENCES ON tag TO csr;
GRANT SELECT,REFERENCES ON tag_group_member TO csr;

CONNECT csr/csr@&_CONNECT_IDENTIFIER

-- Login


ALTER TABLE customer ADD (
	ORACLE_SCHEMA	VARCHAR2(255),
	IND_CMS_TABLE	VARCHAR2(255)
);

ALTER TABLE axis_member ADD (
	IMAGE_URL	VARCHAR2(255)
);




@..\csr_app_pkg
@..\csr_data_pkg
@..\indicator_pkg
@..\calc_pkg
@..\delegation_pkg
@..\pending_pkg
@..\region_pkg
@..\sheet_pkg

@..\csr_app_body
@..\csr_data_body
@..\indicator_body
@..\calc_body
@..\delegation_body
@..\pending_body
@..\region_body
@..\sheet_body

-- Create the new strategy package
@..\strategy_pkg
@..\strategy_body

@update_tail


