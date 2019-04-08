
-- Fix teacher leave

DROP TABLE IF EXISTS memory.teacher_pref.tmp_teacher_leave;
CREATE TABLE IF NOT EXISTS memory.teacher_pref.tmp_teacher_leave AS 
SELECT DISTINCT teacher_id
	, start_time
	, end_time
FROM memory.teacher_pref.teacher_leave
WHERE current_timestamp > start_time
	AND (current_timestamp - INTERVAL '1' DAY) <= end_time
;


DROP TABLE IF EXISTS memory.teacher_pref.tmp_teacher_leave2;
CREATE TABLE IF NOT EXISTS memory.teacher_pref.tmp_teacher_leave2 AS 
SELECT tl1.teacher_id
	, IF(tl1.start_time > tl2.start_time, tl2.start_time, tl1.start_time) AS start_time
	, IF(tl1.end_time > tl2.end_time, tl1.end_time, tl2.end_time) AS end_time
FROM memory.teacher_pref.tmp_teacher_leave AS tl1
	INNER JOIN memory.teacher_pref.tmp_teacher_leave AS tl2
		ON tl1.teacher_id = tl2.teacher_id
			AND tl1.start_time <> tl2.start_time
			AND tl1.end_time <> tl2.end_time
			AND tl2.start_time >= tl1.start_time
			AND tl2.start_time <= tl1.end_time
;


DROP TABLE IF EXISTS memory.teacher_pref.teacher_leave_fixed;
CREATE TABLE IF NOT EXISTS memory.teacher_pref.teacher_leave_fixed AS
SELECT tl.*
FROM memory.teacher_pref.tmp_teacher_leave AS tl
	LEFT JOIN memory.teacher_pref.tmp_teacher_leave2 AS tl2
		ON tl.teacher_id = tl2.teacher_id
			AND (tl.start_time = tl2.start_time OR tl.end_time = tl2.end_time)
WHERE tl2.teacher_id IS NULL
UNION
SELECT * FROM memory.teacher_pref.tmp_teacher_leave2
;



