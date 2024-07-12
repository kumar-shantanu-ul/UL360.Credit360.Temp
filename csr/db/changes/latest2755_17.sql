-- Please update version.sql too -- this keeps clean builds in sync
define version=2755
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table aspen2.translation_application add static_translation_path varchar2(1000) default '/resource/tr.xml';

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../../../aspen2/NPSL.Translation/db/tr_pkg
@../../../aspen2/NPSL.Translation/db/tr_body

@update_tail
