-- Please update version.sql too -- this keeps clean builds in sync
define version=1291
@update_header

INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL)
     VALUES (12, 'All selected');

@../templated_report_pkg

@update_tail
