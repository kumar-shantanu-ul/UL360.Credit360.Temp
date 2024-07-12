-- Please update version.sql too -- this keeps clean builds in sync
define version=2271
@update_header

ALTER TABLE 	csr.ind_validation_rule 
DROP CONSTRAINT chk_ind_valid_rule_type;

ALTER TABLE 	csr.ind_validation_rule 
ADD CONSTRAINT  chk_ind_valid_rule_type CHECK (TYPE IN ('E','W','X','N'));

ALTER TABLE 	csrimp.ind_validation_rule 
DROP CONSTRAINT chk_ind_valid_rule_type;

ALTER TABLE 	csrimp.ind_validation_rule 
add constraint  CHK_IND_VALID_RULE_TYPE check (type in ('E','W','X','N'));

@../sheet_pkg
@../sheet_body

@update_tail