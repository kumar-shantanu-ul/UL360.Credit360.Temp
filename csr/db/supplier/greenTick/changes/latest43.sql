-- Please update version.sql too -- this keeps clean builds in sync
define version=43

@update_header

-- add new accreditation
INSERT INTO gt_pda_accred_type (
   gt_pda_accred_type_id, description, score) 
VALUES (5, 'Non Natural (synthetic or mineral)', 0);


-- add mapping table to filter accreditation by provenance type
-- 
-- TABLE: GT_PDA_PROV_ACC_MAPPING 
--

CREATE TABLE GT_PDA_PROV_ACC_MAPPING(
    GT_PDA_PROVENANCE_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    GT_PDA_ACCRED_TYPE_ID        NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK327 PRIMARY KEY (GT_PDA_PROVENANCE_TYPE_ID, GT_PDA_ACCRED_TYPE_ID)
)
;
-- 
-- TABLE: GT_PDA_PROV_ACC_MAPPING 
--

ALTER TABLE GT_PDA_PROV_ACC_MAPPING ADD CONSTRAINT RefGT_PDA_ACCRED_TYPE871 
    FOREIGN KEY (GT_PDA_ACCRED_TYPE_ID)
    REFERENCES GT_PDA_ACCRED_TYPE(GT_PDA_ACCRED_TYPE_ID)
;

ALTER TABLE GT_PDA_PROV_ACC_MAPPING ADD CONSTRAINT RefGT_PDA_PROVENANCE_TYPE872 
    FOREIGN KEY (GT_PDA_PROVENANCE_TYPE_ID)
    REFERENCES GT_PDA_PROVENANCE_TYPE(GT_PDA_PROVENANCE_TYPE_ID)
;

-- insert accred / prov mappings
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (7,3);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (7,4);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (6,4);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (5,1);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (5,2);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (5,3);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (5,4);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (4,1);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (4,2);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (4,3);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (4,4);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (3,1);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (3,2);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (3,3);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (3,4);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (2,1);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (2,2);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (2,3);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (2,4);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (1,1);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (1,2);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (1,3);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (1,4);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (8,3);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (8,4);
INSERT INTO gt_pda_prov_acc_mapping (gt_pda_provenance_type_id, gt_pda_accred_type_id) VALUES (8,5);


-- set up base mappings

	
	
	
	
@update_tail