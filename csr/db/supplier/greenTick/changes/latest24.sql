-- Please update version.sql too -- this keeps clean builds in sync
define version=24
@update_header

	--- fix incorrect product tag labels
	UPDATE tag SET explanation = 'Contains natural materials or ingredients (except wood, pulp or paper)' 
	 WHERE explanation like '%gt;Green Tick Assessment%';
	 

	
@update_tail