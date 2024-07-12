-- Please update version.sql too -- this keeps clean builds in sync
define version=592
@update_header

-- in the model, but missing from live
ALTER TABLE IMP_IND MODIFY APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP');
ALTER TABLE IMP_REGION MODIFY APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP');
ALTER TABLE IMP_MEASURE MODIFY APP_SID DEFAULT SYS_CONTEXT('SECURITY','APP');

@update_tail
