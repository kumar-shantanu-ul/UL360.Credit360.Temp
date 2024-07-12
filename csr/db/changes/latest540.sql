-- Please update version.sql too -- this keeps clean builds in sync
define version=540
@update_header

INSERT INTO std_measure_conversion (std_measure_conversion_id, std_measure_id, description, a, b, c)
	VALUES (49, 9, 'lb/MWh', 7936641432, 1, 0);

UPDATE region SET egrid_ref = NULL;
DELETE FROM egrid;

INSERT INTO egrid (egrid_ref, name) values('AKGD', 'ASCC Alaska Grid');
INSERT INTO egrid (egrid_ref, name) values('AKMS', 'ASCC Miscellaneous');
INSERT INTO egrid (egrid_ref, name) values('AZNM', 'WECC Southwest');
INSERT INTO egrid (egrid_ref, name) values('CAMX', 'WECC California');
INSERT INTO egrid (egrid_ref, name) values('ERCT', 'ERCOT All');
INSERT INTO egrid (egrid_ref, name) values('FRCC', 'FRCC All');
INSERT INTO egrid (egrid_ref, name) values('HIMS', 'HICC Miscellaneous');
INSERT INTO egrid (egrid_ref, name) values('HIOA', 'HICC Oahu');
INSERT INTO egrid (egrid_ref, name) values('MROE', 'MRO East');
INSERT INTO egrid (egrid_ref, name) values('MROW', 'MRO West');
INSERT INTO egrid (egrid_ref, name) values('NEWE', 'NPCC New England');
INSERT INTO egrid (egrid_ref, name) values('NWPP', 'WECC Northwest');
INSERT INTO egrid (egrid_ref, name) values('NYCW', 'NPCC NYC/Westchester');
INSERT INTO egrid (egrid_ref, name) values('NYLI', 'NPCC Long Island');
INSERT INTO egrid (egrid_ref, name) values('NYUP', 'NPCC Upstate NY');
INSERT INTO egrid (egrid_ref, name) values('RFCE', 'RFC East');
INSERT INTO egrid (egrid_ref, name) values('RFCM', 'RFC Michigan');
INSERT INTO egrid (egrid_ref, name) values('RFCW', 'RFC West');
INSERT INTO egrid (egrid_ref, name) values('RMPA', 'WECC Rockies');
INSERT INTO egrid (egrid_ref, name) values('SPNO', 'SPP North');
INSERT INTO egrid (egrid_ref, name) values('SPSO', 'SPP South');
INSERT INTO egrid (egrid_ref, name) values('SRMV', 'SERC Mississippi Valley');
INSERT INTO egrid (egrid_ref, name) values('SRMW', 'SERC Midwest');
INSERT INTO egrid (egrid_ref, name) values('SRSO', 'SERC South');
INSERT INTO egrid (egrid_ref, name) values('SRTV', 'SERC Tennessee Valley');
INSERT INTO egrid (egrid_ref, name) values('SRVC', 'SERC Virginia/Carolina');

@update_tail
