-- Please update version.sql too -- this keeps clean builds in sync
define version=2
@update_header


DELETE FROM product_tag WHERE tag_id IN (
    SELECT tag_id FROM tag WHERE tag = 'containsPlantExtracts'
);

DELETE FROM product_tag WHERE tag_id IN (
    SELECT tag_id FROM tag WHERE tag = 'containsAccreditedPackaging'
);

DELETE FROM tag_tag_attribute WHERE tag_id IN (
    SELECT tag_id FROM tag WHERE tag = 'containsPlantExtracts'
);

DELETE FROM tag_tag_attribute WHERE tag_id IN (
    SELECT tag_id FROM tag WHERE tag = 'containsAccreditedPackaging'
);

DELETE FROM questionnaire_tag WHERE tag_id IN (
    SELECT tag_id FROM tag WHERE tag = 'containsPlantExtracts'
);

DELETE FROM questionnaire_tag WHERE tag_id IN (
    SELECT tag_id FROM tag WHERE tag = 'containsAccreditedPackaging'
);

DELETE FROM tag_group_member WHERE tag_id IN (
    SELECT tag_id FROM tag WHERE tag = 'containsPlantExtracts'
);

DELETE FROM tag_group_member WHERE tag_id IN (
    SELECT tag_id FROM tag WHERE tag = 'containsAccreditedPackaging'
);

DELETE FROM tag WHERE tag = 'containsPlantExtracts';
DELETE FROM tag WHERE tag = 'containsAccreditedPackaging'; 

/
@update_tail