-- Please update version.sql too -- this keeps clean builds in sync
define version=1155
@update_header

-- Add is_hotspot to breakdown_type indexes, as the table will now contain copies of data for hotspot/non-hotspot
DROP INDEX CT.IDX_BD_TYPE_1;
DROP INDEX CT.IDX_BD_TYPE_2;
DROP INDEX CT.IDX_BD_TYPE_3;

CREATE UNIQUE INDEX CT.IDX_BD_TYPE_1 ON CT.BREAKDOWN_TYPE (APP_SID,LOWER(SINGULAR),IS_HOTSPOT);
CREATE UNIQUE INDEX CT.IDX_BD_TYPE_2 ON CT.BREAKDOWN_TYPE (APP_SID,LOWER(PLURAL),IS_HOTSPOT);
CREATE UNIQUE INDEX CT.IDX_BD_TYPE_3 ON CT.BREAKDOWN_TYPE (APP_SID, CASE "IS_REGION"
  WHEN 1 THEN
    (-1)
  ELSE
    "BREAKDOWN_TYPE_ID"
  END,IS_HOTSPOT);

-- Delete any test data thats been created - it will all be pointing to the hotspotter breakdowns
DELETE FROM CT.EC_BUS_ENTRY;
DELETE FROM CT.EC_CAR_ENTRY;
DELETE FROM CT.EC_MOTORBIKE_ENTRY;
DELETE FROM CT.EC_TRAIN_ENTRY;
DELETE FROM CT.EC_PROFILE;
DELETE FROM CT.EC_QUESTIONNAIRE_ANSWERS;
DELETE FROM CT.EC_QUESTIONNAIRE;
DELETE FROM CT.EC_OPTIONS;
DELETE FROM CT.BT_OPTIONS;
DELETE FROM CT.BT_PROFILE;
DELETE FROM CT.BREAKDOWN_REGION_GROUP;
DELETE FROM CT.BREAKDOWN_GROUP;

create or replace package ct.breakdown_type_pkg as
procedure dummy;
end;
/
create or replace package body ct.breakdown_type_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on ct.breakdown_type_pkg to web_user;

@../ct/breakdown_pkg
@../ct/breakdown_type_pkg
@../ct/snapshot_pkg

@../ct/breakdown_body
@../ct/breakdown_type_body
@../ct/snapshot_body

@update_tail
