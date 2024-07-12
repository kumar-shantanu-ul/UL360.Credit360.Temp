-- Please update version.sql too -- this keeps clean builds in sync
define version=337
@update_header

-- Pending datasets should now be using SIDs. See pending_pkg.CreateDataset. If you come across code that is using this sequence, then the code needs to be
-- updated to create securable objects (via pending_pkg.CreateDataset).

DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count FROM all_sequences WHERE sequence_name = 'PENDING_DATASET_ID_SEQ' AND sequence_owner = 'CSR';

	IF v_count = 1 THEN
		EXECUTE IMMEDIATE 'DROP SEQUENCE csr.pending_dataset_id_seq';
	END IF;
END;
/

@update_tail
