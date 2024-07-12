-- Please update version.sql too -- this keeps clean builds in sync
define version=561
@update_header

-- fixes:
-- Error Description: ORA-01400: cannot insert NULL into ("CSR"."REGION_RECALC_JOB"."APP_SID")
-- ORA-06512: at "CSR.INDICATOR_PKG", line 489

alter table region_recalc_job modify app_sid default SYS_CONTEXT('SECURITY', 'APP');

@update_tail
