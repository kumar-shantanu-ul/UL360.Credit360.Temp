-- Please update version.sql too -- this keeps clean builds in sync
define version=3018
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

--I can''t find any better way to rename sequences... 
DECLARE v_curr NUMBER;
BEGIN
	SELECT chain.dedupe_rule_id_seq.nextval
	  INTO v_curr
	  FROM dual;

	EXECUTE IMMEDIATE'
		CREATE SEQUENCE chain.dedupe_rule_set_id_seq
			START WITH '||v_curr||' 
			INCREMENT BY 1
			NOMINVALUE
			NOMAXVALUE
			CACHE 20
			NOORDER
	';

	EXECUTE IMMEDIATE 'DROP SEQUENCE chain.dedupe_rule_id_seq';
END;
/

grant select on chain.dedupe_rule_set_id_seq to csrimp;

ALTER TABLE chain.dedupe_rule RENAME TO dedupe_rule_set;
ALTER TABLE chain.dedupe_rule_set RENAME COLUMN dedupe_rule_id TO dedupe_rule_set_id;
ALTER TABLE chain.dedupe_rule_set RENAME CONSTRAINT pk_dedupe_rule TO pk_dedupe_rule_set;
ALTER INDEX chain.pk_dedupe_rule RENAME TO pk_dedupe_rule_set;

ALTER TABLE chain.dedupe_rule_set RENAME CONSTRAINT uc_dedupe_rule TO uc_dedupe_rule_set;
ALTER INDEX chain.uc_dedupe_rule RENAME TO uc_dedupe_rule_set;
	
ALTER TABLE chain.dedupe_rule_mapping RENAME TO dedupe_rule;
ALTER TABLE chain.dedupe_rule RENAME COLUMN dedupe_rule_id TO dedupe_rule_set_id;
ALTER TABLE chain.dedupe_rule RENAME CONSTRAINT pk_dedupe_rule_mapping TO pk_dedupe_rule;
ALTER INDEX chain.pk_dedupe_rule_mapping RENAME TO pk_dedupe_rule;

ALTER TABLE chain.dedupe_rule DROP COLUMN is_fuzzy;

ALTER TABLE chain.dedupe_rule RENAME CONSTRAINT uc_dedupe_rule_mapping TO uc_dedupe_rule;
ALTER INDEX chain.uc_dedupe_rule_mapping RENAME TO uc_dedupe_rule;

ALTER TABLE chain.dedupe_rule RENAME CONSTRAINT fk_dedupe_rule_mapping_rule TO fk_dedupe_rule_rule_set;

ALTER TABLE chain.dedupe_rule RENAME CONSTRAINT FK_DEDUPE_RULE_MAPPING_MAP to fk_dedupe_rule_mapping;

ALTER TABLE chain.dedupe_match RENAME COLUMN dedupe_rule_id TO dedupe_rule_set_id;
ALTER TABLE chain.dedupe_match RENAME CONSTRAINT fk_dedupe_match_rule TO fk_dedupe_match_rule_set;

ALTER TABLE csrimp.chain_dedupe_rule RENAME TO chain_dedupe_rule_set;
ALTER TABLE csrimp.chain_dedupe_rule_mappin RENAME TO chain_dedupe_rule;

ALTER TABLE csrimp.chain_dedupe_rule_set RENAME COLUMN dedupe_rule_id to dedupe_rule_set_id;
ALTER TABLE csrimp.chain_dedupe_rule RENAME COLUMN dedupe_rule_id to dedupe_rule_set_id;

ALTER TABLE csrimp.chain_dedupe_match RENAME COLUMN dedupe_rule_id to dedupe_rule_set_id;

ALTER TABLE csrimp.map_chain_dedupe_rule RENAME TO map_chain_dedupe_rule_set;
ALTER TABLE csrimp.map_chain_dedupe_rule_set RENAME COLUMN old_dedupe_rule_id to old_dedupe_rule_set_id;
ALTER TABLE csrimp.map_chain_dedupe_rule_set RENAME COLUMN new_dedupe_rule_id to new_dedupe_rule_set_id;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/company_dedupe_pkg

@../schema_body
@../csrimp/imp_body
@../chain/chain_body
@../chain/company_dedupe_body
@../chain/test_chain_utils_body

@update_tail
