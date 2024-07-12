CREATE OR REPLACE PACKAGE BODY csr.permit_data_import_pkg AS

NOT_CREATED							CONSTANT NUMBER(1) := 0;
CREATED								CONSTANT NUMBER(1) := 1;

NO_FAIL								CONSTANT NUMBER(10,0) := 0;
FAIL_NO_UPDATE_ALLOWED				CONSTANT NUMBER(10,0) := 1;
FAIL_NO_REGION						CONSTANT NUMBER(10,0) := 2;
FAIL_AMBIGUOUS_REGION				CONSTANT NUMBER(10,0) := 4;
FAIL_NO_ACTIVITY_TYPE				CONSTANT NUMBER(10,0) := 8;
FAIL_AMBIGUOUS_ACTIVITY_TYPE		CONSTANT NUMBER(10,0) := 16;
FAIL_NO_ACTIVITY_STYPE				CONSTANT NUMBER(10,0) := 32;
FAIL_AMBIGUOUS_ACTIVITY_STYPE		CONSTANT NUMBER(10,0) := 64;
FAIL_NO_PERMIT_TYPE					CONSTANT NUMBER(10,0) := 128;
FAIL_AMBIGUOUS_PERMIT_TYPE			CONSTANT NUMBER(10,0) := 256;
FAIL_NO_PERMIT_STYPE				CONSTANT NUMBER(10,0) := 512;
FAIL_AMBIGUOUS_PERMIT_STYPE			CONSTANT NUMBER(10,0) := 1024;
FAIL_NO_CONDITION_TYPE				CONSTANT NUMBER(10,0) := 2048;
FAIL_AMBIGUOUS_CONDITION_TYPE		CONSTANT NUMBER(10,0) := 4096;
FAIL_NO_CONDITION_STYPE				CONSTANT NUMBER(10,0) := 8192;
FAIL_AMBIGUOUS_CONDITION_STYPE		CONSTANT NUMBER(10,0) := 16384;
FAIL_NO_PERMIT						CONSTANT NUMBER(10,0) := 32768;
FAIL_AMBIGUOUS_PERMIT				CONSTANT NUMBER(10,0) := 65536;
FAIL_NO_FLOW_STATE					CONSTANT NUMBER(10,0) := 131072;
FAIL_AMBIGUOUS_FLOW_STATE			CONSTANT NUMBER(10,0) := 262144;
FAIL_NO_WORKFLOW_UPDATE				CONSTANT NUMBER(10,0) := 524288;

PROCEDURE GetAllPermitTypes (
	out_cur 						OUT SYS_REFCURSOR
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin=0 THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'Access denied. Only BuiltinAdministrator or super admins can run this.'
		);
	END IF;

	OPEN out_cur FOR
		SELECT classification , type, subtype, pos position
		FROM (
			SELECT 'Activity Type' classification, description type, '' subtype, pos
			  FROM compliance_activity_type     
			ORDER BY pos, description
		)
		UNION ALL 
		SELECT classification, type, subtype, pos position 
		  FROM (
			SELECT 'Activity Type' classification, cat.description type, casbt.description subtype, casbt.pos
			  FROM compliance_activity_type cat
			  JOIN compliance_activity_sub_type casbt ON cat.activity_type_id = casbt.activity_type_id AND cat.app_sid = casbt.app_sid
			ORDER BY cat.pos, cat.description, casbt.pos, casbt.description
		)
		UNION ALL
		SELECT classification, type, subtype, pos position
		FROM (
			SELECT 'Application Type' classification, description type, '' subtype, pos
				FROM compliance_application_type
			ORDER BY pos, description
		)
		UNION ALL
		SELECT classification, type, subtype, pos position
		FROM (
			SELECT 'Condition Type' classification, description type, '' subtype, pos
				FROM compliance_condition_type     
			ORDER BY pos, description
		)
		UNION ALL 
		SELECT classification, type, subtype, pos position 
		  FROM (
			SELECT 'Condition Type' classification, cat.description type, casbt.description subtype, casbt.pos
			  FROM compliance_condition_type cat
			  JOIN compliance_condition_sub_type casbt ON cat.condition_type_id = casbt.condition_type_id AND cat.app_sid = casbt.app_sid
			ORDER BY cat.pos, cat.description, casbt.pos, casbt.description
		)
		UNION ALL
		SELECT classification, type, subtype, pos position
		FROM (
			SELECT 'Permit Type' classification, description type, '' subtype, pos
				FROM compliance_permit_type     
			ORDER BY pos, description
		)
		UNION ALL 
		SELECT classification, type, subtype, pos position 
		  FROM (
			SELECT 'Permit Type' classification, cat.description type, casbt.description subtype, casbt.pos
			  FROM compliance_Permit_type cat
			  JOIN compliance_Permit_sub_type casbt ON cat.Permit_type_id = casbt.Permit_type_id AND cat.app_sid = casbt.app_sid
			ORDER BY cat.pos, cat.description, casbt.pos, casbt.description
		);
END;

PROCEDURE GetActivityTypeUsage(
	out_not_deleteable_types		OUT NUMBER
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin=0 THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'Access denied. Only BuiltinAdministrator or super admins can run this.'
		);
	END IF;

	SELECT COUNT(DISTINCT cat.activity_type_id)
	  INTO out_not_deleteable_types
	  FROM compliance_activity_type cat
	  JOIN compliance_permit cp ON cat.app_sid = cp.app_sid AND cat.activity_type_id = cp.activity_type_id;
END;

PROCEDURE TrashAllActivityTypes
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin=0 THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'Access denied. Only BuiltinAdministrator or super admins can run this.'
		);
	END IF;

	DELETE FROM compliance_activity_sub_type dst
	 WHERE dst.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		AND NOT EXISTS (
			SELECT casbt.activity_sub_type_id
			  FROM compliance_activity_sub_type casbt
			  JOIN compliance_permit cp ON casbt.app_sid = cp.app_sid AND casbt.activity_sub_type_id = cp.activity_sub_type_id
			 WHERE dst.app_sid = casbt.app_sid AND dst.activity_sub_type_id = casbt.activity_sub_type_id
		);

	DELETE FROM compliance_activity_type dt
	 WHERE dt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		AND NOT EXISTS (
			SELECT cat.activity_type_id
			  FROM compliance_activity_type cat
			  JOIN compliance_permit cp ON cat.app_sid = cp.app_sid AND cat.activity_type_id = cp.activity_type_id
			 WHERE dt.app_sid = cat.app_sid AND dt.activity_type_id = cat.activity_type_id
	);
END;

FUNCTION INTERNAL_ImportActivityType(
	in_type_id						IN  NUMBER,
	in_type							IN  compliance_activity_type.description%type,
	in_position						IN  compliance_activity_type.pos%type,
	out_type_id						OUT NUMBER
) RETURN NUMBER
AS
	v_position 							NUMBER;
BEGIN
	v_position := in_position;
  	IF in_type_id IS NULL THEN
		IF in_position IS NULL OR v_position = 0 THEN
			SELECT MAX(pos) + 1
			  INTO v_position
			  FROM compliance_activity_type;
		END IF;

		out_type_id := compliance_activity_type_seq.nextval;
		INSERT INTO compliance_activity_type (activity_type_id, description, pos) 
			VALUES (out_type_id, in_type, v_position);
		RETURN CREATED;
	END IF;
	RETURN NOT_CREATED;
END;

FUNCTION INTERNAL_ImportActivitySubType(
	in_type_id						IN  NUMBER,
	in_sub_type						IN  compliance_activity_type.description%type,
	in_position						IN  compliance_activity_type.pos%type
) RETURN NUMBER
AS
	v_position 						NUMBER;
	v_sub_type_id 					NUMBER;
BEGIN
	IF in_type_id IS NOT NULL THEN
		BEGIN
			SELECT activity_sub_type_id
			  INTO v_sub_type_id
			  FROM compliance_activity_sub_type
			 WHERE activity_type_id = in_type_id AND description = in_sub_type AND ROWNUM=1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_sub_type_id := NULL;
		END;
		IF  v_sub_type_id IS NULL THEN
			IF v_position IS NULL OR v_position = 0 THEN
				SELECT MAX(pos) + 1
				  INTO v_position
				  FROM compliance_activity_sub_type
				 WHERE  activity_type_id = in_type_id;
			END IF;


			INSERT INTO compliance_activity_sub_type (activity_sub_type_id, activity_type_id, description, pos) 
				VALUES (compliance_activ_sub_type_seq.nextval, in_type_id, in_sub_type, v_position);

			RETURN CREATED;
	
		END IF;
	END IF;

	RETURN NOT_CREATED;
END;

PROCEDURE ImportActivityTypeRow(
	in_type							IN  compliance_activity_type.description%type,
	in_sub_type 					IN  compliance_activity_sub_type.description%type,
	in_position						IN  compliance_activity_type.pos%type,
	out_successful					OUT NUMBER
)
AS
	v_type_id 							NUMBER;
BEGIN
	out_successful := NOT_CREATED;
	BEGIN
		SELECT activity_type_id
		  INTO v_type_id
		  FROM compliance_activity_type
		 WHERE description = in_type AND ROWNUM=1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_type_id := NULL;
	END;

	IF in_sub_type IS NULL OR v_type_id IS NULL  THEN
		out_successful := INTERNAL_ImportActivityType(v_type_id, in_type, in_position, v_type_id);
	END IF;
	if in_sub_type IS NOT NULL THEN
		out_successful := INTERNAL_ImportActivitySubType(v_type_id, in_sub_type, in_position);
	END IF;
END;

PROCEDURE GetApplicationTypeUsage(
	out_not_deleteable_types		OUT NUMBER
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin=0 THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'Access denied. Only BuiltinAdministrator or super admins can run this.'
		);
	END IF;

	SELECT COUNT(DISTINCT cat.application_type_id)
	  INTO out_not_deleteable_types
	  FROM compliance_application_type cat
	  JOIN compliance_permit_application cp ON cat.app_sid = cp.app_sid AND cat.application_type_id = cp.application_type_id;
END;

PROCEDURE TrashAllApplicationTypes
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin=0 THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'Access denied. Only BuiltinAdministrator or super admins can run this.'
		);
	END IF;

	DELETE FROM compliance_application_type dt
	 WHERE dt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		AND NOT EXISTS (
			SELECT cat.application_type_id
			  FROM compliance_application_type cat
			  JOIN compliance_permit_application ca ON cat.app_sid = ca.app_sid AND cat.application_type_id = ca.application_type_id
			 WHERE dt.app_sid = cat.app_sid AND dt.application_type_id = cat.application_type_id
		);
END;

PROCEDURE ImportApplicationTypeRow(
	in_type							IN  compliance_activity_type.description%type,
	in_sub_type 					IN  compliance_activity_sub_type.description%type,
	in_position						IN  compliance_activity_type.pos%type,
	out_successful					OUT NUMBER
)
AS
	v_type_id 							NUMBER;
	v_position							NUMBER;
BEGIN
	v_position := in_position;
	out_successful := NOT_CREATED;
	BEGIN
		SELECT application_type_id
		  INTO v_type_id
		  FROM compliance_application_type
		 WHERE description = in_type AND ROWNUM=1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_type_id := NULL;
	END;

	IF in_sub_type IS NULL THEN
		IF v_type_id IS NULL THEN
			IF v_position IS NULL OR v_position = 0 THEN
				SELECT MAX(pos) + 1
				  INTO v_position
				  FROM compliance_application_type;
			END IF;
			INSERT INTO compliance_application_type (application_type_id, description, pos) 
				VALUES (compliance_application_tp_seq.nextval, in_type, v_position);

			out_successful := CREATED;
		END IF;
	END IF;
END;

PROCEDURE GetConditionTypeUsage(
	out_not_deleteable_types		OUT NUMBER
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin=0 THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'Access denied. Only BuiltinAdministrator or super admins can run this.'
		);
	END IF;

	SELECT COUNT(distinct cat.condition_type_id)
	  INTO out_not_deleteable_types
	  FROM compliance_condition_type cat
	  JOIN compliance_permit_condition cp ON cat.app_sid = cp.app_sid AND cat.condition_type_id = cp.condition_type_id;
END;

PROCEDURE TrashAllConditionTypes
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin=0 THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'Access denied. Only BuiltinAdministrator or super admins can run this.'
		);
	END IF;

	DELETE FROM compliance_condition_sub_type dst
	 WHERE dst.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND NOT EXISTS (
			SELECT casbt.condition_sub_type_id
			  FROM compliance_condition_sub_type casbt
			  JOIN compliance_permit_condition cp ON casbt.app_sid = cp.app_sid AND casbt.condition_sub_type_id = cp.condition_sub_type_id
			 WHERE dst.app_sid = casbt.app_sid AND dst.condition_sub_type_id = casbt.condition_sub_type_id
		);

	DELETE FROM compliance_condition_type dt
	 WHERE dt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		AND NOT EXISTS (
			SELECT cat.condition_type_id
			  FROM compliance_condition_type cat
			  JOIN compliance_permit_condition cp ON cat.app_sid = cp.app_sid AND cat.condition_type_id = cp.condition_type_id
			 WHERE dt.app_sid = cat.app_sid AND dt.condition_type_id = cat.condition_type_id
		);

END;

FUNCTION INTERNAL_ImportConditionType(
	in_type_id						IN  NUMBER,
	in_type							IN  compliance_condition_type.description%type,
	in_position						IN  compliance_condition_type.pos%type,
	out_type_id						OUT NUMBER
) RETURN NUMBER
AS
	v_position 							NUMBER;
BEGIN
	v_position := in_position;
  	IF in_type_id IS NULL THEN
		IF in_position IS NULL OR v_position = 0 THEN
			SELECT MAX(pos) + 1
			  INTO v_position
			  FROM compliance_condition_type;
		END IF;

		out_type_id := compliance_condition_type_seq.nextval;
		INSERT INTO compliance_condition_type (condition_type_id, description, pos) 
			VALUES (out_type_id, in_type, v_position);
		RETURN CREATED;
	END IF;

	RETURN NOT_CREATED;
END;

FUNCTION INTERNAL_ImportCondSubType(
	in_type_id						IN  NUMBER,
	in_sub_type						IN  compliance_activity_type.description%type,
	in_position						IN  compliance_activity_type.pos%type
)RETURN NUMBER
AS
v_position 								NUMBER;
v_sub_type_id 							NUMBER;
BEGIN
v_position := in_position;
	IF in_type_id IS NOT NULL THEN
		BEGIN
			SELECT condition_sub_type_id
			  INTO v_sub_type_id
			  FROM compliance_condition_sub_type
			 WHERE condition_type_id = in_type_id AND description = in_sub_type AND ROWNUM=1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_sub_type_id := NULL;
		END;
		IF  v_sub_type_id IS NULL THEN
			IF v_position IS NULL OR v_position = 0 THEN
				SELECT MAX(POS) + 1
				  INTO v_position
				  FROM compliance_condition_sub_type
				 WHERE condition_type_id = in_type_id;
			END IF;


			INSERT INTO compliance_condition_sub_type (condition_sub_type_id, condition_type_id, description, pos) 
				VALUES (compliance_cond_sub_type_seq.nextval, in_type_id, in_sub_type, v_position);
			RETURN CREATED;
	
		END IF;
	END IF;
	RETURN NOT_CREATED;
END;


PROCEDURE ImportConditionTypeRow(
	in_type							IN  compliance_activity_type.description%type,
	in_sub_type 					IN  compliance_activity_sub_type.description%type,
	in_position						IN  compliance_activity_type.pos%type,
	out_successful					OUT NUMBER
	
)
AS
	v_type_id							NUMBER;
BEGIN
	out_successful :=NOT_CREATED;
	BEGIN
		SELECT condition_type_id
		  INTO v_type_id
		  FROM compliance_condition_type
		 WHERE description = in_type AND ROWNUM=1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_type_id := NULL;
	END;
	
	IF in_sub_type IS NULL OR v_type_id IS NULL  THEN
		out_successful := INTERNAL_ImportConditionType(v_type_id, in_type, in_position, v_type_id);
	END IF;
	IF in_sub_type IS NOT NULL THEN
		out_successful := INTERNAL_ImportCondSubType(v_type_id, in_sub_type, in_position);
	END IF;
END;

PROCEDURE GetPermitTypeUsage(
	out_not_deleteable_types		OUT NUMBER
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin=0 THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'Access denied. Only BuiltinAdministrator or super admins can run this.'
		);
	END IF;

	SELECT COUNT(distinct cat.permit_type_id)
	  INTO out_not_deleteable_types
	  FROM compliance_permit_type cat
	  JOIN compliance_permit cp ON cat.app_sid = cp.app_sid AND cat.permit_type_id = cp.permit_type_id;
END;

PROCEDURE TrashAllPermitTypes
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin=0 THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'Access denied. Only BuiltinAdministrator or super admins can run this.'
		);
	END IF;
	
	DELETE FROM compliance_permit_sub_type dst
	 WHERE dst.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		AND NOT EXISTS (
			SELECT casbt.permit_sub_type_id
			  FROM compliance_permit_sub_type casbt
			  JOIN compliance_permit cp ON casbt.app_sid = cp.app_sid AND casbt.permit_sub_type_id = cp.permit_sub_type_id
			 WHERE dst.app_sid = casbt.app_sid AND dst.permit_sub_type_id = casbt.permit_sub_type_id
		);

	DELETE FROM compliance_permit_type dt
	WHERE dt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	AND NOT EXISTS (
		SELECT cat.permit_type_id
		  FROM compliance_permit_type cat
		  JOIN compliance_permit cp ON cat.app_sid = cp.app_sid AND cat.permit_type_id = cp.permit_type_id
		 WHERE dt.app_sid = cat.app_sid AND dt.permit_type_id = cat.permit_type_id
	);
END;

FUNCTION INTERNAL_ImportPermitType(
	in_type_id						IN  NUMBER,
	in_type							IN  compliance_activity_type.description%type,
	in_position						IN  compliance_activity_type.pos%type, 
	out_type_id						OUT NUMBER
) RETURN NUMBER
AS
v_position 								NUMBER;
BEGIN
	v_position := in_position;
  	IF in_type_id IS NULL THEN
		IF in_position IS NULL OR v_position = 0 THEN
			SELECT MAX(POS) + 1
			  INTO v_position
			  FROM compliance_permit_type;
		END IF;

		out_type_id := compliance_permit_type_seq.nextval;
		INSERT INTO compliance_permit_type (permit_type_id, description, pos) 
		VALUES (out_type_id, in_type, v_position);
		RETURN CREATED;
	END IF;
	RETURN NOT_CREATED;
END;

FUNCTION INTERNAL_ImportPermitSubType(
	in_type_id						IN  NUMBER,
	in_sub_type						IN  compliance_activity_type.description%type,
	in_position						IN  compliance_activity_type.pos%type
) RETURN NUMBER
AS
	v_position 							NUMBER;
	v_sub_type_id						NUMBER;
BEGIN
	v_position := in_position;
	IF in_type_id IS NOT NULL THEN
		BEGIN
			SELECT permit_sub_type_id
			  INTO v_sub_type_id
			  FROM compliance_permit_sub_type
			 WHERE permit_type_id = in_type_id AND description = in_sub_type AND ROWNUM=1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_sub_type_id := NULL;
		END;
		IF  v_sub_type_id IS NULL THEN
			IF v_position IS NULL OR v_position = 0 THEN
				SELECT NVL(MAX(pos),0) + 1
				INTO v_position
				FROM compliance_permit_sub_type
				WHERE permit_type_id = in_type_id;
			END IF;

			INSERT INTO compliance_permit_sub_type (permit_sub_type_id, permit_type_id, description, pos) 
				VALUES (compliance_permit_sub_type_seq.nextval, in_type_id, in_sub_type, v_position);
			RETURN CREATED;
		END IF;
	END IF;
	RETURN NOT_CREATED;
END;

PROCEDURE ImportPermitTypeRow(
	in_type							IN  compliance_activity_type.description%type,
	in_sub_type 					IN  compliance_activity_sub_type.description%type,
	in_position						IN  compliance_activity_type.pos%type,
	out_successful 					OUT NUMBER
)
AS
	v_type_id							NUMBER(10,0);
BEGIN
	out_successful := NOT_CREATED;
	BEGIN
		SELECT permit_type_id
	  	  INTO v_type_id
		  FROM compliance_permit_type
		 WHERE description = in_type AND ROWNUM=1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_type_id := NULL;
	END;

	IF in_sub_type IS NULL OR v_type_id IS NULL THEN
		out_successful := INTERNAL_ImportPermitType(v_type_id, in_type, in_position, v_type_id);
	END IF;
	IF in_sub_type IS NOT NULL THEN
		out_successful := INTERNAL_ImportPermitSubType(v_type_id, in_sub_type, in_position);
	END IF;

END;

FUNCTION INTERNAL_LookupActivityTypeId(
	in_activity_type				IN  compliance_activity_type.description%type,
	out_result						OUT NUMBER
) RETURN compliance_permit.activity_type_id%type
AS
	v_activity_type_id						compliance_permit.activity_type_id%type;
BEGIN
	v_activity_type_id := NULL;

	BEGIN
		SELECT activity_type_id
		  INTO v_activity_type_id
		  FROM compliance_activity_type
		 WHERE description = in_activity_type;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_activity_type_id := NULL;
			out_result := FAIL_NO_ACTIVITY_TYPE;
		WHEN TOO_MANY_ROWS THEN
			v_activity_type_id := NULL;
			out_result := FAIL_AMBIGUOUS_ACTIVITY_TYPE;
	END;

	RETURN v_activity_type_id;
END;

FUNCTION INTERNAL_LookupActivitySTypeId(
	in_activity_type_id				IN  compliance_activity_type.activity_type_id%type,
	in_activity_sub_type			IN  compliance_activity_sub_type.description%type,
	out_result						OUT NUMBER
) RETURN compliance_permit.activity_sub_type_id%type
AS
	v_activity_sub_type_id						compliance_permit.activity_sub_type_id%type;
BEGIN
	v_activity_sub_type_id := NULL;

	BEGIN
		SELECT activity_sub_type_id
		  INTO v_activity_sub_type_id
		  FROM compliance_activity_sub_type
		  WHERE description = in_activity_sub_type and activity_type_id = in_activity_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_activity_sub_type_id := NULL;
			out_result := FAIL_NO_ACTIVITY_STYPE;
		WHEN TOO_MANY_ROWS THEN
			v_activity_sub_type_id := NULL;
			out_result := FAIL_AMBIGUOUS_ACTIVITY_STYPE;
	END;

	RETURN v_activity_sub_type_id;
END;




FUNCTION INTERNAL_LookupPermitTypeId(
	in_permit_type					IN  compliance_permit_type.description%type,
	out_result						OUT NUMBER
) RETURN compliance_permit.permit_type_id%type
AS
	v_permit_type_id					compliance_permit.permit_type_id%type;
BEGIN
	v_permit_type_id := NULL;

	BEGIN
		SELECT permit_type_id
		  INTO v_permit_type_id
		  FROM compliance_permit_type
		 WHERE description = in_permit_type;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_permit_type_id := NULL;
			out_result := FAIL_NO_PERMIT_TYPE;
		WHEN TOO_MANY_ROWS THEN
			v_permit_type_id := NULL;
			out_result := FAIL_AMBIGUOUS_PERMIT_TYPE;
	END;

	RETURN v_permit_type_id;
END;

FUNCTION INTERNAL_LookupPermitSubTypeId(
	in_permit_type_id				IN  compliance_permit_type.permit_type_id%type,
	in_permit_sub_type				IN  compliance_permit_sub_type.description%type,
	out_result						OUT NUMBER
) RETURN compliance_permit.permit_sub_type_id%type
AS
	v_permit_sub_type_id				compliance_permit.permit_sub_type_id%type;
BEGIN
	v_permit_sub_type_id := NULL;

	BEGIN
		SELECT permit_sub_type_id
		  INTO v_permit_sub_type_id
		  FROM compliance_permit_sub_type
		 WHERE description = in_permit_sub_type AND permit_type_id = in_permit_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_permit_sub_type_id := NULL;
			out_result := FAIL_NO_PERMIT_STYPE;
		WHEN TOO_MANY_ROWS THEN
			v_permit_sub_type_id := NULL;
			out_result := FAIL_AMBIGUOUS_PERMIT_STYPE;
	END;

	RETURN v_permit_sub_type_id;
END;

FUNCTION INTERNAL_LookupConditionTypeId(
	in_condition_type				IN  compliance_condition_type.description%type,
	out_result						OUT NUMBER
) RETURN compliance_permit.permit_type_id%type
AS
	v_condition_type_id					compliance_permit_condition.condition_type_id%type;
BEGIN
	v_condition_type_id := NULL;

	BEGIN
		SELECT condition_type_id
		  INTO v_condition_type_id
		  FROM compliance_condition_type
		 WHERE description = in_condition_type;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		v_condition_type_id := NULL;
			out_result := FAIL_NO_CONDITION_TYPE;
		WHEN TOO_MANY_ROWS THEN
			v_condition_type_id := NULL;
			out_result := FAIL_AMBIGUOUS_CONDITION_TYPE;
	END;

	RETURN v_condition_type_id;
END;

FUNCTION INTERNAL_LookupCondSTypeId(
	in_condition_type_id			IN  compliance_condition_type.condition_type_id%type,
	in_condition_sub_type			IN  compliance_condition_sub_type.description%type,
	out_result						OUT NUMBER
) RETURN compliance_permit_condition.condition_sub_type_id%type
AS
	v_condition_sub_type_id				compliance_permit_condition.condition_sub_type_id%type;
BEGIN
	v_condition_sub_type_id := NULL;

	BEGIN
		SELECT condition_sub_type_id
		  INTO v_condition_sub_type_id
		  FROM compliance_condition_sub_type
		 WHERE description = in_condition_sub_type AND condition_type_id = in_condition_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_condition_sub_type_id := NULL;
			out_result := FAIL_NO_CONDITION_STYPE;
		WHEN TOO_MANY_ROWS THEN
			v_condition_sub_type_id := NULL;
			out_result := FAIL_AMBIGUOUS_CONDITION_STYPE;
	END;

	RETURN v_condition_sub_type_id;
END;


PROCEDURE ImportPermit(
	in_title						IN  compliance_permit.title%type,	
	in_region_sid					IN  region.region_sid%type,
	in_activity_details				IN  compliance_permit.activity_details%type,
	in_activity_type				IN  compliance_activity_type.description%type,
	in_activity_sub_type			IN  compliance_activity_sub_type.description%type,
	in_activity_start_date			IN  compliance_permit.activity_start_dtm%type,
	in_activity_end_date 			IN  compliance_permit.activity_end_dtm%type,
	in_permit_type					IN  compliance_permit_type.description%type,
	in_permit_sub_type				IN  compliance_permit_sub_type.description%type,
	in_permit_start_date			IN  compliance_permit.permit_start_dtm%type,
	in_permit_end_date				IN  compliance_permit.permit_end_dtm%type,
	in_reference					IN  compliance_permit.permit_reference%type,
	in_commissioning_req			IN  VARCHAR2,
	in_commision_date				IN  compliance_permit.site_commissioning_dtm%type,
	in_workflow_state				IN  flow_state.lookup_key%type,
	in_allow_update					IN  NUMBER,
	out_status_code					OUT NUMBER
)
AS
	v_activity_type_id					compliance_permit.activity_type_id%type;
	v_activity_sub_type_id				compliance_permit.activity_sub_type_id%type;
	v_permit_type_id					compliance_permit.permit_type_id%type;
	v_permit_sub_type_id				compliance_permit.permit_sub_type_id%type;
	v_permit_id							compliance_permit.compliance_permit_id%type;
	v_comm_req							compliance_permit.site_commissioning_required%type;
	v_flow_item_id						flow_item.flow_item_id%type;
	v_flow_state_id						flow_state.flow_state_id%type;
	v_flow_sid							flow.flow_sid%type;
	v_cache_keys						security_pkg.T_VARCHAR2_ARRAY;
	v_lookup_return_code				NUMBER;

BEGIN
	out_status_code := 0;
	IF csr_user_pkg.IsSuperAdmin=0 THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED, 
			'Access denied. Only BuiltinAdministrator or super admins can run this.'
		);
	END IF;


	IF in_commissioning_req = 'Y' THEN
		v_comm_req := 1;
	ELSE
		v_comm_req := 0;
	END IF;

	IF v_lookup_return_code <> 0 THEN
		out_status_code := out_status_code + v_lookup_return_code;
	END IF;

	v_activity_type_id := INTERNAL_LookupActivityTypeId(in_activity_type, v_lookup_return_code);
	IF v_lookup_return_code <> 0 THEN
		out_status_code := out_status_code + v_lookup_return_code;
	END IF;

	IF in_activity_sub_type IS NOT NULL THEN
		v_activity_sub_type_id := INTERNAL_LookupActivitySTypeId(v_activity_type_id, in_activity_sub_type, v_lookup_return_code);
		IF v_lookup_return_code <> 0 THEN
			out_status_code := out_status_code + v_lookup_return_code;
		END IF;
	END IF;
	 
	v_permit_type_id := INTERNAL_LookupPermitTypeId(in_permit_type, v_lookup_return_code);
	IF v_lookup_return_code <> 0 THEN
		out_status_code := out_status_code + v_lookup_return_code;
	END IF;

	IF in_permit_sub_type IS NOT NULL THEN
		v_permit_sub_type_id := INTERNAL_LookupPermitSubTypeId(v_permit_type_id, in_permit_sub_type, v_lookup_return_code);
		IF v_lookup_return_code <> 0 THEN
			out_status_code := out_status_code + v_lookup_return_code;
		END IF;
	END IF;

	BEGIN
		SELECT compliance_permit_id, flow_item_id
		  INTO v_permit_id, v_flow_item_id
		  FROM compliance_permit
		 WHERE permit_reference = in_reference;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_permit_id := NULL;
	END;

	IF v_permit_id IS NOT NULL AND in_allow_update = 0 THEN
		out_status_code := out_status_code + 1;
		RETURN;
	ELSIF out_status_code <> NO_FAIL THEN
		RETURN;
	ELSE 
		IF v_permit_id IS NOT NULL AND in_workflow_state IS NOT NULL THEN
			out_status_code := OUT_STATUS_CODE + FAIL_NO_WORKFLOW_UPDATE;
			RETURN;
		END IF;

		permit_pkg.SavePermit(
			in_permit_id					=> v_permit_id,
			in_region_sid					=> in_region_sid,
			in_title						=> in_title,
			in_activity_type_id				=> v_activity_type_id,
			in_activity_sub_type_id			=> v_activity_sub_type_id,
			in_activity_start_dtm			=> in_activity_start_date,
			in_activity_end_dtm				=> in_activity_end_date,
			in_activity_details				=> in_activity_details,
			in_permit_ref					=> in_reference,
			in_permit_type_id				=> v_permit_type_id,
			in_permit_sub_type_id			=> v_permit_sub_type_id,
			in_site_commissioning_required	=> v_comm_req,
			in_site_commissioning_dtm 		=> in_commision_date,
			in_permit_start_dtm				=> in_permit_start_date,
			in_permit_end_dtm				=> in_permit_end_date,
			in_is_major_change				=> 1,
			in_change_reason				=> 'Bulk import',
			out_permit_id					=> v_permit_id
		);

		SELECT flow_item_id
		  INTO v_flow_item_id
		  FROM compliance_permit
		 WHERE compliance_permit_id = v_permit_id;

		SELECT fi.flow_sid
		  INTO v_flow_sid
		  FROM compliance_permit cp
		  JOIN flow_item fi ON cp.flow_item_id = fi.flow_item_id
		 WHERE compliance_permit_id = v_permit_id;

		v_flow_state_id := flow_pkg.GetStateId(v_flow_sid, in_workflow_state);
	
		IF (v_flow_state_id IS NOT NULL) THEN
			flow_pkg.SetItemState(
				in_flow_item_id		=> v_flow_item_id,
				in_to_state_Id		=> v_flow_state_id,
				in_comment_text		=> 'Forced by bulk import',				
				in_cache_keys		=> v_cache_keys,
				in_force			=> 1
			);
		END IF;
	END IF;
END;


PROCEDURE ImportCondition(
	in_permit_reference				IN  compliance_permit.permit_reference%type,
	in_condition_title				IN  compliance_item.title%type,
	in_details						IN  compliance_item.details%type,
	in_condition_type				IN  compliance_condition_type.description%type,
	in_condition_sub_type			IN  compliance_condition_sub_type.description%type,
	in_condition_reference			IN  compliance_item.reference_code%type,
	in_workflow_state 				IN  flow_state.lookup_key%type,
	in_allow_update					IN  NUMBER,
	out_status_code					OUT NUMBER
)
AS
	v_permit_condition_id				compliance_item.compliance_item_id%type;
	v_condition_type_id					compliance_permit_condition.condition_type_id%type;
	v_condition_sub_type_id				compliance_permit_condition.condition_sub_type_id%type;
	v_permit_id							compliance_permit.compliance_permit_id%type;
	v_flow_item_id						flow_item.flow_item_id%type;
	v_lookup_return_code				NUMBER;
	v_flow_state_id						flow_state.flow_state_id%type;
	v_flow_sid							flow.flow_sid%type;
	v_cache_keys						security_pkg.T_VARCHAR2_ARRAY;
	v_has_access						NUMBEr;

BEGIN
	out_status_code := 0;

	v_condition_type_id := INTERNAL_LookupConditionTypeId(in_condition_type, v_lookup_return_code);
	IF v_lookup_return_code <> 0 THEN
		out_status_code := out_status_code + v_lookup_return_code;
	END IF;

	IF in_condition_sub_type IS NOT NULL THEN
		v_condition_sub_type_id := INTERNAL_LookupCondSTypeId(v_condition_type_id, in_condition_sub_type, v_lookup_return_code);
		IF v_lookup_return_code <> 0 THEN
			out_status_code := out_status_code + v_lookup_return_code;
		END IF;
	END IF;
	 
	 BEGIN
	 	SELECT compliance_permit_id
		  INTO v_permit_id
		  FROM csr.compliance_permit 
		 WHERE permit_reference = in_permit_reference;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_permit_id := NULL;
			out_status_code := out_status_code + FAIL_NO_PERMIT;
		WHEN TOO_MANY_ROWS THEN
			v_permit_id := NULL;
			out_status_code := out_status_code + FAIL_AMBIGUOUS_PERMIT;
	 END;

	BEGIN
		SELECT ci.compliance_item_id
		  INTO v_permit_condition_id 
		  FROM csr.compliance_item ci
		 WHERE ci.reference_code = in_condition_reference;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_permit_condition_id := NULL;
	END;

	IF v_permit_condition_id IS NOT NULL AND in_allow_update = 0 THEN
		out_status_code := out_status_code + 1;
		RETURN;
	ELSIF out_status_code <> NO_FAIL THEN
		RETURN;
	ELSIF v_permit_condition_id is NULL THEN
		compliance_pkg.CreatePermitCondition(
			in_title				=> in_condition_title,
			in_details				=> in_details,
			in_reference_code		=> in_condition_reference,
			in_change_type			=> NULL,	
			in_permit_id			=> v_permit_id,
			in_condition_type_id	=> v_condition_type_id,	
			in_condition_sub_type_id=> v_condition_sub_type_id,
			out_compliance_item_id	=> v_permit_condition_id
		);
		compliance_pkg.CreatePermitConditionFlowItem(
				in_compliance_item_id => v_permit_condition_id,
				in_permit_id => v_permit_id,
				out_flow_item_id=> v_flow_item_id
			);

	   SELECT condition_flow_sid
 		 INTO v_flow_sid
		 FROM compliance_options
    	WHERE app_sid = security_pkg.GetApp;

		v_flow_state_id := flow_pkg.GetStateId(v_flow_sid, in_workflow_state);

		IF (v_flow_state_id IS NOT NULL) THEN
			flow_pkg.SetItemState(
				in_flow_item_id		=> v_flow_item_id,
				in_to_state_Id		=> v_flow_state_id,
				in_comment_text		=> 'Bulk import'

			);
		END IF;
	ELSE
		IF in_workflow_state IS NULL THEN
			compliance_pkg.UpdatePermitCondition(
				in_compliance_item_id 	=> v_permit_condition_id,
				in_title				=> in_condition_title,
				in_details				=> in_details,
				in_reference_code		=> in_condition_reference,
				in_change_type			=> null ,	
				in_condition_type_id	=>v_condition_type_id,	
				in_condition_sub_type_id	=>v_condition_sub_type_id,
				in_is_major_change => 1,
				in_change_reason => 'Bulk import',
				in_flow_item_id		=>null
			);
		ELSE
			out_status_code := OUT_STATUS_CODE + FAIL_NO_WORKFLOW_UPDATE;

		END IF;
	END IF;
END;

END;
/