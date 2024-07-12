-- Please update version.sql too -- this keeps clean builds in sync
define version=3081
define minor_version=28
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
create or replace package csr.period_span_pattern_pkg as end;
/

-- ** New package grants **
grant execute on csr.period_span_pattern_pkg TO web_user;
-- *** Conditional Packages ***

-- *** Packages ***


@../period_span_pattern_pkg

@../period_span_pattern_body

@update_tail
