-- Please update version.sql too -- this keeps clean builds in sync
define version=1261
@update_header

grant execute on csr.sheet_pkg to chem;

CREATE OR REPLACE VIEW chem.v$flat_substance_cas AS
	SELECT app_sid, substance_id, ref, description, classification_id, classification, manufacturer,
		MAX(DECODE(row_rank, 1, cas_code)) cas_code_0,
		MAX(DECODE(row_rank, 1, pct_composition)) perc_0,
		MAX(DECODE(row_rank, 2, cas_code)) cas_code_1,
		MAX(DECODE(row_rank, 2, pct_composition)) perc_1,
		MAX(DECODE(row_rank, 3, cas_code)) cas_code_2,
		MAX(DECODE(row_rank, 3, pct_composition)) perc_2,
		MAX(DECODE(row_rank, 4, cas_code)) cas_code_3,
		MAX(DECODE(row_rank, 4, pct_composition)) perc_3,
		MAX(DECODE(row_rank, 5, cas_code)) cas_code_4,
		MAX(DECODE(row_rank, 5, pct_composition)) perc_4,
		MAX(DECODE(row_rank, 6, cas_code)) cas_code_5,
		MAX(DECODE(row_rank, 6, pct_composition)) perc_5,
		MAX(DECODE(row_rank, 7, cas_code)) cas_code_6,
		MAX(DECODE(row_rank, 7, pct_composition)) perc_6,
		MAX(DECODE(row_rank, 8, cas_code)) cas_code_7,
		MAX(DECODE(row_rank, 8, pct_composition)) perc_7,
		MAX(DECODE(row_rank, 9, cas_code)) cas_code_8,
		MAX(DECODE(row_rank, 9, pct_composition)) perc_8,
		MAX(DECODE(row_rank, 10, cas_code)) cas_code_9,
		MAX(DECODE(row_rank, 10, pct_composition)) perc_9,
		MAX(DECODE(row_rank, 11, cas_code)) cas_code_10,
		MAX(DECODE(row_rank, 11, pct_composition)) perc_10,
		MAX(DECODE(row_rank, 12, cas_code)) cas_code_11,
		MAX(DECODE(row_rank, 12, pct_composition)) perc_11,
		MAX(DECODE(row_rank, 13, cas_code)) cas_code_12,
		MAX(DECODE(row_rank, 13, pct_composition)) perc_12,
		MAX(DECODE(row_rank, 14, cas_code)) cas_code_13,
		MAX(DECODE(row_rank, 14, pct_composition)) perc_13,
		MAX(DECODE(row_rank, 15, cas_code)) cas_code_14,
		MAX(DECODE(row_rank, 15, pct_composition)) perc_14,
		MAX(DECODE(row_rank, 16, cas_code)) cas_code_15,
		MAX(DECODE(row_rank, 16, pct_composition)) perc_15,
		MAX(DECODE(row_rank, 17, cas_code)) cas_code_16,
		MAX(DECODE(row_rank, 17, pct_composition)) perc_16
	FROM (	
		SELECT s.app_sid, s.substance_id, s.ref, s.description, s.classification_id, cl.description classification, 
			m.name manufacturer, 
			rank() OVER (PARTITION BY s.substance_id ORDER BY sc.cas_code) row_rank,
			sc.cas_code cas_code, sc.pct_composition pct_composition
		 FROM substance s
			JOIN substance_cas sc ON s.substance_id = sc.substance_id
			JOIN classification cl on cl.classification_id = s.classification_id
			JOIN manufacturer m on m.manufacturer_id = s.manufacturer_id
	)x
	GROUP BY app_sid, substance_id, ref, description, classification_id, classification, manufacturer;
	
@..\sheet_pkg
@..\chem\substance_pkg

@..\sheet_body
@..\chem\substance_body

@update_tail
	