SELECT 
    user_id, 
    -- install_time, 
    first_session, 
    last_session, 
    session_id, 
    time_start as time_session_start,
    time_end AS time_session_end, 
    (time_end - time_start) as time_session_delta,
    duration AS session_duration_seconds, 
    (time_session_end - first_session) / 3600 AS hours_from_first_session_to_actual_session, 
    (now() - last_session) / 3600 AS hours_from_last_session_to_now, 
    (now() - first_session) / 3600 AS hours_from_first_session_to_now, 
    -- (now() - install_time) / 3600 AS hours_from_install_to_now, 
    -- hours_from_install_to_last_session, 
    hours_from_first_session_to_last_session, 
    whole_wasted_hours, 
    -- whole_wasted_days, 
    user_level 
FROM analytic.elka2019_ok_sessions_playtime_final 
ANY LEFT JOIN 
 (SELECT 
        user_id, 
        -- install_time, 
        first_session, 
        last_session, 
        -- (last_session - install_time) / 3600 AS hours_from_install_to_last_session, 
        (last_session - first_session) / 3600 AS hours_from_first_session_to_last_session, 
        whole_wasted_hours, 
        whole_wasted_days, 
        level AS user_level
    FROM analytic.elka2019_ok_users_data 
    ANY LEFT JOIN 
        (SELECT * 
        FROM 
        (SELECT 
                user_id, 
                min(time_start) AS first_session, 
                max(time_end) AS last_session, 
                sum(duration) / 3600 AS whole_wasted_hours, 
                whole_wasted_hours / 24 AS whole_wasted_days
            FROM analytic.elka2019_ok_sessions_playtime_final 
            GROUP BY user_id
            HAVING (first_session >= toDateTime('2018-10-29 00:00:00')) AND (last_session <= now())
            ORDER BY user_id ASC
        ) ANY LEFT JOIN 
        (SELECT 
                user_id 
                -- install_time
            FROM analytic.elka2019_ok_users 
        ) USING (user_id)
    ) USING (user_id)
) USING (user_id)
WHERE (first_session >= toDateTime('2018-10-29 00:00:00')) 
    AND (last_session <= now()) AND (time_end <= now())
    AND hours_from_first_session_to_now/24 > 30 
    AND abs(time_session_delta - session_duration_seconds) < 5
ORDER BY user_id ASC
