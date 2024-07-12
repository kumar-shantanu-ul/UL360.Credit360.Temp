-- Please update version.sql too -- this keeps clean builds in sync
define version=525
@update_header

ALTER TABLE CUSTOMER ADD (
    TARGET_LINE_COL_FROM_GRADIENT    NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CHECK (TARGET_LINE_COL_FROM_GRADIENT IN (0,1))
);

-- legacy behaviour (in future we're going to default to 0, but keep existing sites
-- apart from produceworld the same as before)
UPDATE customer 
   SET target_line_col_from_gradient = 1 
 WHERE host != 'produceworld.credit360.com';

@..\csr_app_body

@update_tail


