-- Please update version.sql too -- this keeps clean builds in sync
define version=2821
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
DELETE FROM csr.branding_availability
 WHERE client_folder_name IN ('acona', 'allianceboots', 'bclc', 'brooks', 'chipotle', 'coinstar', 'elektro', 'fiep', 'greenlife', 'huawei', 'ma-industries', 'mcnicholas', 'mettlertoledo', 'mtn', 'payroll_giving', 'pearson', 'prologis', 'rim', 'rmenergy', 'taqa', 'td', 'towngas', 'tullowoil', 'ubs', 'uniq', 'vtplc', 'xyz');

DELETE FROM csr.branding
 WHERE client_folder_name IN ('acona', 'allianceboots', 'bclc', 'brooks', 'chipotle', 'coinstar', 'elektro', 'fiep', 'greenlife', 'huawei', 'ma-industries', 'mcnicholas', 'mettlertoledo', 'mtn', 'payroll_giving', 'pearson', 'prologis', 'rim', 'rmenergy', 'taqa', 'td', 'towngas', 'tullowoil', 'ubs', 'uniq', 'vtplc', 'xyz');

DELETE FROM csr.branding_availability
 WHERE client_folder_name IN ('2012', 'essent', 'itv', 'mace', 'sustainability', 'telekom');

DELETE FROM csr.branding
 WHERE client_folder_name IN ('2012', 'essent', 'itv', 'mace', 'sustainability', 'telekom');

-- ** New package grants **

-- *** Packages ***

@update_tail
