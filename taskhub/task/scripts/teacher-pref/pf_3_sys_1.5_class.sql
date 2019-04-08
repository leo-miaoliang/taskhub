-- ----------------------------------------------------------------------------------------------------------------
-- 1v1: 一对一正式课 (1v1_formal)，一对一试听课 (1v1_trial)


DROP TABLE IF EXISTS memory.teacher_pref.class;
CREATE TABLE IF NOT EXISTS memory.teacher_pref.class
(
	class_id bigint,
	class_course_type_name varchar(20),
	class_course_type_code varchar(30),
	class_salary_type varchar(15),
	student_count bigint,	-- 预定学生
	teacher_id integer,
	teacher_sso_id bigint,
	class_date DATE,
	is_valid_for_salary integer,
	class_create_at TIMESTAMP,
	is_create_in_urgent boolean,
	start_time TIMESTAMP,
	end_time TIMESTAMP,
	duration integer,
	entry_time TIMESTAMP,
	is_come_late boolean,
	exit_time TIMESTAMP,
	is_leave_early boolean,
	feedback_time TIMESTAMP,
	is_fb_on_time integer,
	sys integer
);


INSERT INTO memory.teacher_pref.class
SELECT ac.id AS class_id
	, CASE ac.course_type 
		WHEN 1 THEN '一对一试听课(1.0)' 
		WHEN 3 THEN '一对一正式课(1.0)'
	  END AS class_course_type_name
	, CASE ac.course_type 
		WHEN 1 THEN '1v1_trial_1.0' 
		WHEN 3 THEN '1v1_formal_1.0'
	  END AS class_course_type_code
	, 'to1' AS class_salary_type
	, IF(ac.disabled = 0, 1, 0) AS student_count
	, t.teacher_id
	, t.teacher_sso_id
	, DATE(FROM_UNIXTIME(ac.start_time) + INTERVAL '8' hour) AS class_date
	, IF(ac.cancel_type = 2, 0, 1) AS is_valid_for_salary
--	, ac.disabled
--	, ac.cancel_type
--	, ac.cancel_reason
	, FROM_UNIXTIME(ac.create_time) + INTERVAL '8' HOUR AS class_create_at
	, (ac.start_time - ac.create_time) <= pp.max_class_create_in_urgent AS is_create_in_urgent
	, FROM_UNIXTIME(ac.start_time) + INTERVAL '8' HOUR AS start_time
	, FROM_UNIXTIME(ac.end_time) + INTERVAL '8' HOUR AS end_time
	, (ac.end_time - ac.start_time) / 60 AS duration
	, IF(cd.teacher_into_time = 0 OR cd.teacher_into_time IS NULL, NULL
		, FROM_UNIXTIME(cd.teacher_into_time) + INTERVAL '8' HOUR) AS entry_time
	, IF (cd.teacher_into_time IS NULL OR cd.teacher_into_time = 0, -9999
		, cd.teacher_into_time - ac.start_time) > pp.min_come_late_seconds AS is_come_late
	, IF(cd.teacher_out_time = 0 OR cd.teacher_out_time IS NULL, NULL
		, FROM_UNIXTIME(cd.teacher_out_time) + INTERVAL '8' HOUR) AS exit_time
	, IF (cd.teacher_out_time IS NULL OR cd.teacher_out_time = 0, -9999
		, ac.end_time - cd.teacher_out_time) > pp.min_leave_early_seconds AS is_leave_early
	, FROM_UNIXTIME(te.created) + INTERVAL '8' HOUR AS feedback_time
	, CASE WHEN (te.created - ac.end_time) <= pp.max_fb_deferred_seconds THEN 1
		ELSE 0
	  END AS is_fb_on_time
	, 1 AS sys
FROM uumysql.newuuabc.appoint_course AS ac
	INNER JOIN memory.teacher_pref.setting_payperiod AS pp 
		ON is_cur = TRUE
	INNER JOIN memory.teacher_pref.teachers AS t
		ON ac.teacher_user_id = t.teacher_id
	LEFT JOIN uumysql.newuuabc.course_details AS cd
		ON ac.id = cd.appoint_course_id 
			AND cd."type" = 1
	LEFT JOIN uumysql.newuuabc.teacher_evaluate AS te
		ON ac.id = te.appoint_course_id
			AND te.comment_type IN (1, 2)
WHERE ac.status = 3
	AND ac.course_type IN (1, 3)
	AND ac.class_appoint_course_id = 0
	AND (ac.disabled = 0 OR ac.cancel_type = 2)
	AND ac.start_time >= to_unixtime(pp.stime_utc)
	AND ac.start_time < to_unixtime(pp.etime_utc)
ORDER BY ac.start_time
;






-- ----------------------------------------------------------------------------------------------------------------
-- old 1v4: 一对四正式课 (o1v4_formal)，一对四试听课 (o1v4_trial)

INSERT INTO memory.teacher_pref.class
SELECT cac.id AS class_id
	, CASE cac.course_type 
		WHEN 1 THEN '一对四试听课(1.0)' 
		WHEN 3 THEN '一对四正式课(1.0)'
		WHEN 5 THEN 'Standby(1.0)'
		WHEN 6 THEN '双师(1.0)'
		WHEN 8 THEN '双师 Standby(1.0)'
	  END AS class_course_type_name
	, CASE cac.course_type 
		WHEN 1 THEN '1v4_trial_1.0' 
		WHEN 3 THEN '1v4_formal_1.0'
		WHEN 5 THEN 'standby_1.0'
		WHEN 6 THEN 'realclassroom_1.0'
		WHEN 8 THEN 'realclassroom_standby_1.0'
	  END AS class_course_type_code
	, CASE 
		WHEN cac.course_type IN (5, 8) THEN 'standby'
		WHEN cac.course_type = 6 THEN 'to4'		-- 双师
		WHEN COALESCE(ct.cnt, 0) < 3 THEN 'to1'
		ELSE 'to4'
	  END AS class_salary_type
	, COALESCE(ct.cnt, 0) AS student_count
	, t.teacher_id
	, t.teacher_sso_id
	, DATE(FROM_UNIXTIME(cac.start_time) + INTERVAL '8' hour) AS class_date
	, IF(cac.cancel_type = 2, 0, 1) AS is_valid_for_salary
	, FROM_UNIXTIME(cac.create_time) + INTERVAL '8' HOUR AS class_create_at
	, (cac.start_time - cac.create_time) <= pp.max_class_create_in_urgent AS is_create_in_urgent
	, FROM_UNIXTIME(cac.start_time) + INTERVAL '8' HOUR AS start_time
	, FROM_UNIXTIME(cac.end_time) + INTERVAL '8' HOUR AS end_time
	, (cac.end_time - cac.start_time) / 60 AS duration
--	, cac.disabled
--	, cac.cancel_type
--	, cac.cancel_reason
	, IF(cac.teacher_into_time = 0 OR cac.teacher_into_time IS NULL, NULL
		, FROM_UNIXTIME(cac.teacher_into_time) + INTERVAL '8' HOUR) AS entry_time
	, IF (cac.teacher_into_time IS NULL OR cac.teacher_into_time = 0, -9999
		, cac.teacher_into_time - cac.start_time) > pp.min_come_late_seconds AS is_come_late
	, IF(cac.teacher_out_time = 0 OR cac.teacher_out_time IS NULL, NULL
		, FROM_UNIXTIME(cac.teacher_out_time) + INTERVAL '8' HOUR) AS exit_time
	, IF (cac.teacher_out_time IS NULL OR cac.teacher_out_time = 0, -9999
		, cac.end_time - cac.teacher_out_time) > pp.min_leave_early_seconds AS is_leave_early
	, FROM_UNIXTIME(te.created) + INTERVAL '8' HOUR AS feedback_time
	, CASE
		WHEN cac.course_type IN (5, 8) THEN 1 -- Standby 课程不需要评语
		WHEN (te.created - cac.end_time) <= pp.max_fb_deferred_seconds THEN 1 
		ELSE 0
	  END AS is_fb_on_time
	, 1 AS sys
FROM uumysql.newuuabc.class_appoint_course AS cac
	INNER JOIN memory.teacher_pref.setting_payperiod AS pp 
		ON is_cur = TRUE
	INNER JOIN memory.teacher_pref.teachers AS t
		ON cac.teacher_user_id = t.teacher_id
	LEFT JOIN (
		SELECT te.class_appoint_course_id, MIN(te.created) AS created 
		FROM uumysql.newuuabc.teacher_evaluate AS te
			INNER JOIN memory.teacher_pref.setting_payperiod AS pp 
				ON is_cur = TRUE
		WHERE te.comment_type = 3
			AND te.created >= to_unixtime(pp.stime_utc)
		GROUP BY te.class_appoint_course_id
	) AS te
		ON cac.id = te.class_appoint_course_id
	LEFT JOIN (
		SELECT class_appoint_course_id, COUNT(*) cnt 
		FROM uumysql.newuuabc.appoint_course AS ac
			INNER JOIN memory.teacher_pref.setting_payperiod AS pp 
				ON is_cur = TRUE
		WHERE ac.class_appoint_course_id > 0 
			AND ac.status = 3 
			AND (ac.disabled = 0  OR  (ac.disabled = 1 AND ac.cancel_type = 2))  
			AND ac.course_type IN (1, 3)
			-- AND start_time >= to_unixtime(from_iso8601_date('2018-12-01'))
			AND start_time >= to_unixtime(pp.stime_utc)
		GROUP BY class_appoint_course_id
	) AS ct
		ON ct.class_appoint_course_id = cac.id
WHERE cac.status = 3
	AND cac.course_type IN (1, 3, 5, 6, 8)
	AND (cac.disabled = 0 OR cac.cancel_type = 2)
	AND cac.start_time >= to_unixtime(pp.stime_utc)
	-- AND cac.start_time >= to_unixtime(from_iso8601_date('2018-12-01'))
	AND cac.start_time < to_unixtime(pp.etime_utc) 
;




-- ----------------------------------------------------------------------------------------------------------------
-- new 1v4: 一对四正式课 (n1v4_formal)

INSERT INTO memory.teacher_pref.class
SELECT c.room_id AS class_id
	, '一对四正式课(1.5)' AS class_course_type_name
	, '1v4_formal_1.5' AS class_course_type_code
	, IF(COALESCE(ct.cnt, 0) < 3, 'to1', 'to4') AS class_salary_type
	, COALESCE(ct.cnt, 0) AS student_count
	, t.teacher_id
	, t.teacher_sso_id
	, DATE(FROM_UNIXTIME(c.class_date)) AS class_date
	, IF(c.status = 4, 0, 1) AS is_valid_for_salary
	, FROM_UNIXTIME(c.create_date) AS class_create_at
	, (c.start_time - c.create_date) <= pp.max_class_create_in_urgent AS is_create_in_urgent
	, FROM_UNIXTIME(c.start_time) AS start_time
	, FROM_UNIXTIME(c.end_time) AS end_time
	, (c.end_time - c.start_time) / 60 AS duration
	, IF(c.teacher_entry_time = 0 OR c.teacher_entry_time IS NULL, NULL
		, FROM_UNIXTIME(c.teacher_entry_time)) AS entry_time
	, IF (c.teacher_entry_time IS NULL OR c.teacher_entry_time = 0, -9999
		, c.teacher_entry_time - c.start_time) > pp.min_come_late_seconds AS is_come_late
	, IF(c.teacher_leave_time = 0 OR c.teacher_leave_time IS NULL, NULL
		, FROM_UNIXTIME(c.teacher_leave_time)) AS exit_time
	, IF (c.teacher_leave_time IS NULL OR c.teacher_leave_time = 0, -9999
		, c.end_time - c.teacher_leave_time) > pp.min_leave_early_seconds AS is_leave_early
	, FROM_UNIXTIME(c.teacher_feedback_time) AS feedback_time
	, CASE WHEN (c.teacher_feedback_time - c.end_time) <= pp.max_fb_deferred_seconds THEN 1
		ELSE 0
	  END AS is_fb_on_time
	, 1 AS sys
FROM uumysql.classbooking.classroom AS c
	INNER JOIN memory.teacher_pref.setting_payperiod AS pp 
		ON is_cur = TRUE
	INNER JOIN memory.teacher_pref.teachers AS t
		ON c.teacher_id = t.teacher_id
	LEFT JOIN (
		SELECT room_id, COUNT(*) cnt 
		FROM uumysql.classbooking.student_class AS sc
			INNER JOIN memory.teacher_pref.setting_payperiod AS pp 
				ON is_cur = TRUE
		WHERE status IN (3, 5, 6, 7, 9)
			AND class_date >= to_unixtime(pp.stime)
			-- AND class_date >= to_unixtime(from_iso8601_date('2018-12-01'))
		GROUP BY room_id
	) AS ct
		ON c.room_id = ct.room_id
WHERE c.status >= 3
	AND c.start_time >= to_unixtime(pp.stime)
	-- AND c.start_time >= to_unixtime(from_iso8601_date('2018-12-01'))
	AND c.start_time < to_unixtime(pp.etime)
;




-- ----------------------------------------------------------------------------------------------------------------
-- live

INSERT INTO memory.teacher_pref.class
SELECT lc.id AS class_id
	, '直播课(1.0)' AS class_course_type_name
	, 'live_1.0' AS class_course_type_code
	, 'live' AS class_salary_type
	, COALESCE(sic.cnt, 0) AS student_count
	, t.teacher_id
	, t.teacher_sso_id
	, DATE(FROM_UNIXTIME(lc.start_time) + INTERVAL '8' HOUR) AS class_date
	, IF(lc."attributes" = 3 OR lc.cancel_type = 2, 0 , 1) AS is_valid_for_salary
	, FROM_UNIXTIME(lc.create_time) + INTERVAL '8' HOUR AS class_create_at
	, (lc.start_time - lc.create_time) <= pp.max_class_create_in_urgent AS is_create_in_urgent
	, FROM_UNIXTIME(lc.start_time) + INTERVAL '8' HOUR AS start_time
	, FROM_UNIXTIME(lc.start_time + lc.class_time * 60) + INTERVAL '8' HOUR AS end_time
	, lc.class_time AS duration
	, IF(lc.enter_time = 0 OR lc.enter_time IS NULL, NULL
		, FROM_UNIXTIME(lc.enter_time) + INTERVAL '8' HOUR) AS entry_time
	, IF (lc.enter_time IS NULL OR lc.enter_time = 0, -9999
		, lc.enter_time - lc.start_time) > pp.min_come_late_seconds AS is_come_late
	, IF(lc.leave_time = 0 OR lc.leave_time IS NULL, NULL
		, FROM_UNIXTIME(lc.leave_time) + INTERVAL '8' HOUR) AS exit_time
	, IF (lc.leave_time IS NULL OR lc.leave_time = 0, -9999
		, (lc.start_time + lc.class_time * 60) - lc.leave_time) > pp.min_leave_early_seconds AS is_leave_early
	, NULL AS feedback_time
	, 1 AS is_fb_on_time
	, 1 AS sys
FROM uumysql.newuuabc.live_course AS lc
	INNER JOIN memory.teacher_pref.setting_payperiod AS pp 
		ON is_cur = TRUE
	INNER JOIN memory.teacher_pref.teachers AS t
		ON lc.teacher_user_id = t.teacher_id
	LEFT JOIN (
		SELECT lcd.appoint_course_id, COUNT(*) as cnt 
		FROM uumysql.newuuabc.live_course_details AS lcd
			INNER JOIN memory.teacher_pref.setting_payperiod AS pp 
				ON is_cur = TRUE
		WHERE lcd.created >= to_unixtime(pp.stime_utc)
		GROUP BY lcd.appoint_course_id
	) AS sic
		ON sic.appoint_course_id = lc.id
WHERE lc.disabled = 1
	AND lc.status = 3
	-- AND (lc."attributes" IN (1, 4)  OR  (lc."attributes" = 2 AND lc.disabled = 1)  OR  (lc."attributes" = 3 OR lc.cancel_type = 2))
	AND (lc.disabled = 1 OR lc.cancel_type = 2 OR lc."attributes" = 3)
	AND lc.start_time >= to_unixtime(pp.stime_utc)
	AND lc.start_time < to_unixtime(pp.etime_utc)
;


