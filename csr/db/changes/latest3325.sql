-- Please update version.sql too -- this keeps clean builds in sync
define version=3325
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
    v_cnt NUMBER;
BEGIN
    security.user_pkg.logonadmin();
    
    FOR S IN (SELECT sv.section_sid, sv.body, c.host FROM csr.section_version sv JOIN csr.customer c ON sv.app_sid = c.app_sid WHERE body LIKE '%#IMPORT_%' ORDER BY host)
    LOOP
        security.user_pkg.logonadmin(s.host);
        v_cnt := 1;
        WHILE TRUE
         LOOP
            IF DBMS_LOB.INSTR(s.body, '#IMPORT_'||v_cnt) > 0 THEN
                csr.section_pkg.SaveSectionFact(security.security_pkg.GetAct, s.section_sid, 'IMPORT_'||v_cnt, 'FILE', NULL);
                v_cnt := v_cnt + 1;
                CONTINUE;
            END IF;
            EXIT;
         END LOOP;
    END LOOP;
    
     security.user_pkg.logonadmin();
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
