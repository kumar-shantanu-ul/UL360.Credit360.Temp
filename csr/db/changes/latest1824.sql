-- Please update version.sql too -- this keeps clean builds in sync
define version=1824
@update_header


ALTER TABLE CSR.EXPORT_FEED DROP (
    USERNAME,
	HOST_KEY,
    PASSWORD
    );
  
ALTER TABLE CSR.EXPORT_FEED ADD (
    SECURE_CREDS        CLOB
);

ALTER TABLE CSR.EXPORT_FEED_DATAVIEW ADD (
    ASSEMBLY_NAME       VARCHAR2(150)
    );

@update_tail
