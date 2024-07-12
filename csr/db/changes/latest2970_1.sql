-- Please update version.sql too -- this keeps clean builds in sync
define version=2970
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

--Matthew Dropped a sequence I was re-purposing.
CREATE SEQUENCE CSR.FACTOR_SET_ID_SEQ START WITH 1000;

-- Alter tables

DROP SEQUENCE csr.custom_factor_set_id_seq;

-- Live is on std_factor_id >180000000, god knows why...
ALTER SEQUENCE csr.std_factor_id_seq INCREMENT BY +200000000;
SELECT csr.std_factor_id_seq.NEXTVAL FROM dual;
ALTER SEQUENCE csr.std_factor_id_seq INCREMENT BY 1;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (9, 'Factor set export', 'Credit360.ExportImport.Export.Batched.Exporters.FactorSetExporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../factor_pkg

@../factor_body
@../factor_set_group_body

@update_tail
