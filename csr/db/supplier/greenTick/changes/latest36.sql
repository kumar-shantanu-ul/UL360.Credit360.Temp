-- Please update version.sql too -- this keeps clean builds in sync
define version=36
@update_header

set define off;

-- haz chem scores
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (1 ,'Phthalate plasticisers: - DEHP, DBP and BBP' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (2 ,'HBCDD' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (3 ,'SCCP' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (4 ,'TBTO' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (5 ,'Cobalt dichloride' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (6 ,'Diarsenic pentoxide' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (7 ,'Diarsenic trioxide' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (8 ,'MDA' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (9 ,'Anthracene' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (10 ,'Sodium dichromate (dehydrate form)' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (11 ,'Musk xylene' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (12 ,'Lead hydrogen arsenate' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (13 ,'Triethyl arsenate' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (14 ,'Plasticiser: DIBP' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (15 ,'Flame retardant: Tris(2-chloroethyl) phosphate' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (16 ,'Lead chromate, lead chromate molybdate sulfate red, lead sulfochromate yellow' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (17 ,'2,4 – Dinitrotoluene' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (18 ,'Five variants of anthracene oils and pastes' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (19 ,'Aluminosilicate and Zirconia Aluminosilicate refractory ceramic fibres' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (20 ,'Coal tar pitch' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (21 ,'Trichloroethylene' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (22 ,'Salts of Arsenic acid' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (23 ,'Residues & Distillates (Coal Tar), pitch distillates' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (24 ,'Disodium Tetraborate Decahydrate' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (25 ,'Sodium chromate' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (26 ,'Ammonium dichromate' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (27 ,'Potassium dichromate' ,10 );
INSERT INTO gt_pda_haz_chem (gt_pda_haz_chem_id, description, score) VALUES (28 ,'Potassium chromate' ,10 );
		
		
@update_tail