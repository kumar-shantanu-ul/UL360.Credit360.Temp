-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- cvs\aspen2\cms\db\create_views.sql
create or replace view cms.fk as
select fkc.app_sid, fkc.fk_cons_id, fkc.tab_sid fk_tab_sid, fkt.oracle_schema owner, fkc.constraint_name, fkt.oracle_table table_name, fktc.oracle_column column_name,
       ukc.uk_cons_id, ukc.tab_sid r_tab_sid, ukt.oracle_schema r_owner, ukt.oracle_table r_table_name, uktc.oracle_column r_column_name,
       fkcc.pos
  from cms.fk_cons fkc, cms.fk_cons_col fkcc,
       cms.uk_cons ukc, cms.uk_cons_col ukcc,
       cms.tab_column fktc, cms.tab_column uktc,
       cms.tab fkt, cms.tab ukt
 where fkc.fk_cons_id = fkcc.fk_cons_id and fkc.r_cons_id = ukc.uk_cons_id and
       ukc.uk_cons_id = ukcc.uk_cons_id and fkcc.pos = ukcc.pos and
       fkcc.column_sid = fktc.column_sid and ukcc.column_sid = uktc.column_sid and
       fktc.tab_sid = fkt.tab_sid and uktc.tab_sid = ukt.tab_sid
order by fkt.tab_sid, fkc.fk_cons_id, fkcc.pos;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/tab_pkg

@../../../aspen2/cms/db/tab_body

@update_tail
