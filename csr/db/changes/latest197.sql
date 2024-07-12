
-- Please update version.sql too -- this keeps clean builds in sync
define version=197
@update_header

  -- add last_modified_dtm to RSS_FEED table 
  ALTER TABLE RSS_FEED ADD LAST_MODIFIED_DTM DATE;

  -- add is_hidden to TAB_USER
  ALTER TABLE TAB_USER ADD IS_HIDDEN NUMBER(1) DEFAULT 0 NOT NULL;
  
  -- update view to include IS_HIDDEN column
   CREATE OR REPLACE VIEW V$TAB_USER AS
    SELECT t.TAB_ID, t.APP_SID, t.LAYOUT, t.NAME, t.IS_SHARED, tu.USER_SID, tu.POS, tu.IS_OWNER, tu.IS_HIDDEN
      FROM TAB t, TAB_USER tu
     WHERE t.TAB_ID = tu.TAB_ID;



@update_tail

