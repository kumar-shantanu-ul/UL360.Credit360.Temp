-- Please update version.sql too -- this keeps clean builds in sync
define version=2325
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***

-- RLS

-- Data
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Edit personal delegation cover', 0);

-- *** Packages ***

@update_tail