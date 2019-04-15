SELECT user_id,
       is_old,
       sex,
       friends_count,
       install_time,
       first_session,
       (first_session - install_time) as time_from_install_to_first_session_sec,
       session_end_day1,
       (session_end_day1 - first_session) as whole_time_day1,
       playtime_day1,
       session_number_day1,
       playtime_day1/session_number_day1 as avg_session_duration_sec_day1,
       (whole_time_day1 - playtime_day1)/(session_number_day1 - 1) as avg_session_gap_sec_day1,
       gross_day1,
       payment_count_day1,
       level_min_day1,
       level_max_day1,
       level_delta_day1,
       level_delta_day1/playtime_day1 as level_increase_rate_day1,
       whole_wasted_time_sec,
       whole_session_number,
       current_level
FROM
(SELECT user_id,
       is_old,
       sex,
       friends_count,
       --install_date,
       first_session,
       session_end_day1,
       playtime_day1,
       session_number_day1,
       gross_day1,
       payment_count_day1,
       level_min_day1,
       level_max_day1,
       level_delta_day1,
       whole_wasted_time_sec,
       whole_session_number,
       current_level
FROM
(SELECT user_id,
       first_session,
       session_end_day1,
       playtime_day1,
       gross_day1,
       payment_count_day1,
       session_number_day1,
       level_min_day1,
       level_max_day1,
       level_delta_day1,
       whole_wasted_time_sec,
       whole_session_number
FROM
  (SELECT user_id,
          first_session,
          session_end_day1,
          playtime_day1,
          gross_day1,
	  session_number_day1,
          payment_count_day1,
          whole_wasted_time_sec,
          whole_session_number
   FROM
     (SELECT user_id,
             first_session,
             max(time_end) AS session_end_day1,
             sum(duration) AS playtime_day1, --gross_day1,
	     count(duration) AS session_number_day1,
            --payment_count_day1,
            whole_wasted_time_sec,
            whole_session_number
      FROM
        (SELECT user_id,
                first_session,
                time_start,
                time_end,
                duration,
                whole_wasted_time_sec,
                whole_session_number
         FROM elka2019_ok_sessions_playtime_final ANY
         LEFT JOIN
           (SELECT user_id,
                   min(time_start) AS first_session,
                   sum(duration) AS whole_wasted_time_sec,
                   count(duration) AS whole_session_number
            FROM elka2019_ok_sessions_playtime_final
            GROUP BY user_id) USING user_id
         WHERE (time_start - first_session)/3600 < 24)
      GROUP BY user_id,
               first_session,
               whole_wasted_time_sec,
               whole_session_number
      HAVING playtime_day1 <= (session_end_day1 - first_session)) ANY
   LEFT JOIN
     (SELECT user_id,
             sum(price) AS gross_day1,
             count(price) AS payment_count_day1
      FROM
        (SELECT user_id,
                payment_date,
                first_session,
                price
         FROM elka2019_ok_payments ANY
         LEFT JOIN
           (SELECT user_id,
                   min(time_start) AS first_session
            FROM elka2019_ok_sessions_playtime_final
            GROUP BY user_id) USING user_id
         WHERE (payment_date - first_session)/3600 < 24)
      GROUP BY user_id) USING user_id) ANY
LEFT JOIN
  (SELECT user_id,
          min(level) AS level_min_day1,
          max(level) AS level_max_day1,
          max(level) - min(level) AS level_delta_day1
   FROM
     (SELECT user_id,
             event_time,
             first_session,
             level
      FROM elka2019_ok_mlevent_session_start ANY
      LEFT JOIN
        (SELECT user_id,
                min(time_start) AS first_session
         FROM elka2019_ok_sessions_playtime_final
         GROUP BY user_id) USING user_id
      WHERE (event_time - first_session)/3600 < 24)
   GROUP BY user_id) USING user_id)
   any left JOIN
   (SELECT
        user_id,
        is_old,
        user_id_platform,
        referrer,
        --install_date,
        level as current_level,
        friends_count,
        sex
    FROM elka2019_ok_users_profile_view) USING user_id) 
ANY LEFT JOIN
(SELECT user_id,
	install_time 
FROM elka2019_ok_users) USING user_id
WHERE (first_session >= toDateTime('2018-10-29 00:00:00')) 
AND (now() - first_session)/3600/24 > 30 
ORDER BY user_id
