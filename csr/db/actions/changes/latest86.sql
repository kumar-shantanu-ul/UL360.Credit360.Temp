-- Please update version.sql too -- this keeps clean builds in sync
define version=86
@update_header

DELETE FROM import_template_mapping;
DELETE FROM import_template;

ALTER TABLE IMPORT_TEMPLATE DROP COLUMN WORKBOOK;

ALTER TABLE IMPORT_TEMPLATE ADD (
	NAME                  VARCHAR2(1024)    NOT NULL,
	WORKBOOK              BLOB              NULL,
	IS_DEFAULT            NUMBER(1, 0)      DEFAULT 0 NOT NULL
                          CHECK (IS_DEFAULT IN(0,1))
)
;

ALTER TABLE IMPORT_TEMPLATE_MAPPING ADD(
    FROM_IDX              NUMBER(10, 0)     NOT NULL
)
;

connect csr/csr@&_CONNECT_IDENTIFIER
BEGIN
	INSERT INTO capability (name, allow_by_default) VALUES ('Manage import templates', 1);
	INSERT INTO capability (name, allow_by_default) VALUES ('Set initiative metric details', 0);
END;
/

connect actions/actions@&_CONNECT_IDENTIFIER
@../initiative_body
@../importer_pkg
@../importer_body

@update_tail
