/*
* 1. Get list of directors who directed a 'Comedy' in a leap year.
*/

WITH
    Comedy_Movies AS
    (
        SELECT
             -- COUNT(*)  107
            MG.MID
        FROM
                    GENRE G
            JOIN    M_GENRE MG
            ON      G.GID = MG.GID
        WHERE
            TRIM(G.Name) = 'Comedy'
    ),
    Comedy_Movies_In_Leap_Yr AS
    (
        SELECT
            M.MID,
            M.title,
            CAST(SUBSTR(M.year,-4) AS UNSIGNED) year
        FROM
                    Comedy_Movies CM
            JOIN    Movie M
            ON      CM.MID = M.MID
        WHERE
            (CAST(SUBSTR(M.year,-4) AS UNSIGNED) %4 = 0 )
    )
    SELECT
        DISTINCT
        TRIM(P.Name) Director_Name
        CM.title Movie_Name,
        CM.year
    FROM
                Comedy_Movies_In_Leap_Yr CM
        JOIN    M_Director MD
        ON      CM.MID = MD.MID
        JOIN    Person P
        ON      TRIM(MD.PID) = TRIM(P.PID);

/*
*  2. List the names of all actors who played in the movie 'Anand'
*/

SELECT
    DISTINCT
    TRIM(P.NAME) AS Actor_Name
FROM
            Movie M
    JOIN    M_Cast MC
    ON      M.MID = MC.MID
    JOIN    Person P
    ON      TRIM(MC.PID) = TRIM(P.PID)
WHERE
    M.title = 'Anand';

/*
* 3. List of all actors who acted oin a film before 1970 and in a fim after 1990.
*/

WITH
    ACTORS_BEFORE_1970 AS
    (
        SELECT
            DISTINCT
            TRIM(MC.PID) PID
        FROM
                    Movie M
            JOIN    M_Cast MC
            ON      M.MID = MC.MID
        WHERE
            CAST(SUBSTR(M.year,-4) AS UNSIGNED) < 1970
    ),
    ACTORS_AFTER_1990 AS
    (
        SELECT
            DISTINCT
            TRIM(MC.PID) PID
        FROM
                    Movie M
            JOIN    M_Cast MC
            ON      M.MID = MC.MID
        WHERE
            CAST(SUBSTR(M.year,-4) AS UNSIGNED) > 1990
    )
    SELECT
        DISTINCT
        TRIM(P.Name) Actor_Name
    FROM
                ACTORS_BEFORE_1970 A_1970
        JOIN    ACTORS_AFTER_1990 A_1990
        ON      A_1970.PID = A_1990.PID
        JOIN    Person P
        ON      A_1970.PID = TRIM(P.PID)

/*
* 4. List all directors who directed 10 or more movies.
*/

SELECT
    DISTINCT
    TRIM(P.NAME) DIRECTOR_NAME,
    NM.NUM_OF_MOVIES_DIRECTED
FROM
            (SELECT 
                PID,
                COUNT(MID) NUM_OF_MOVIES_DIRECTED
            FROM
                M_Director
            GROUP BY
                PID
            HAVING
                NUM_OF_MOVIES_DIRECTED >= 10
            ) NM
    JOIN    PERSON P
    ON      TRIM(NM.PID) = TRIM(P.PID)
ORDER BY 
    NM.NUM_OF_MOVIES_DIRECTED DESC

/*
* 5A.  Number of movies in a year with all female actors. 
*/

WITH
    MOVIES_WITH_NON_FEMALES AS
    (
        SELECT
            DISTINCT
            TRIM(MC.MID) MID
        FROM
                    M_Cast MC
            JOIN    Person P
            ON      TRIM(MC.PID) = TRIM(P.PID)
        WHERE
            TRIM(P.Gender) IN ('Male','None') -- Considering None as not female.
    )
    SELECT
        CAST(SUBSTR(M.year,-4) AS UNSIGNED) year,
        COUNT(DISTINCT TRIM(MID) ) NUM_OF_MOV_WITH_ONLY_FEMALES
    FROM
        Movie M
    WHERE
        TRIM(MID) NOT IN (SELECT MID FROM MOVIES_WITH_NON_FEMALES)
    GROUP BY 
        CAST(SUBSTR(M.year,-4) AS UNSIGNED)
    ORDER BY
        year

/*
* 5B.   Report for each year the % of movies in that year with only female actors and the 
*       total number of movies made that year.
*/

WITH
    MOVIES_WITH_NON_FEMALES AS
    (
        SELECT
            DISTINCT
            TRIM(MC.MID) MID
        FROM
                    M_Cast MC
            JOIN    Person P
            ON      TRIM(MC.PID) = TRIM(P.PID)
        WHERE
            TRIM(P.Gender) IN ('Male','None') -- Considering None as not female.
    ),
    NUM_OF_MOV_WITH_ONLY_F_BY_YR AS
    (
    SELECT
        CAST(SUBSTR(M.year,-4) AS UNSIGNED) YEAR,
        COUNT(DISTINCT TRIM(MID) ) NUM_OF_MOV_WITH_ONLY_FEMALES
    FROM
        Movie M
    WHERE
        TRIM(MID) NOT IN (SELECT MID FROM MOVIES_WITH_NON_FEMALES)
    GROUP BY 
        CAST(SUBSTR(M.year,-4) AS UNSIGNED)
    ),
    TOTAL_NUM_OF_MOV_BY_YR AS
    (
        SELECT
            CAST(SUBSTR(M.year,-4) AS UNSIGNED) YEAR,
            COUNT(DISTINCT TRIM(MID) ) TOTAL_NUM_OF_MOV
        FROM
            Movie M
        GROUP BY
            CAST(SUBSTR(M.year,-4) AS UNSIGNED)
    )
    SELECT
        TOT_MOV.YEAR,
        TOT_MOV.TOTAL_NUM_OF_MOV,
        ROUND((IFNULL(MOV_F.NUM_OF_MOV_WITH_ONLY_FEMALES,0) * 100 )/TOT_MOV.TOTAL_NUM_OF_MOV,2) PERCENT_OF_MOV_WITH_ONLY_F
    FROM
                TOTAL_NUM_OF_MOV_BY_YR TOT_MOV
        LEFT OUTER JOIN
                NUM_OF_MOV_WITH_ONLY_F_BY_YR MOV_F
        ON      TRIM(TOT_MOV.YEAR) = TRIM(MOV_F.YEAR)
    ORDER BY
        PERCENT_OF_MOV_WITH_ONLY_F DESC;

/*
*   6) Find the film(s) with the largest cast.
*/

WITH
    CAST_NUMBER AS
    (
        SELECT
            TRIM(MID) MID,
            COUNT(DISTINCT TRIM(PID)) NUM_OF_PEOPLE
        FROM
            M_Cast
        GROUP BY 
            TRIM(MID) 
    )
    SELECT
        M.MID,
        M.title,
        CM.NUM_OF_PEOPLE
    FROM
                CAST_NUMBER CM
        JOIN    Movie M
        ON      CM.MID = TRIM(M.MID)
    WHERE
        CM.NUM_OF_PEOPLE  = (
            SELECT
                MAX(NUM_OF_PEOPLE)
            FROM
                CAST_NUMBER
        )

/*
* 7) Decade with the largest number of films and the total number of films in that decade.
*/

WITH 
    DISTINCT_YEARS AS
    (
    SELECT
        DISTINCT
        CAST(SUBSTR(year,-4) AS UNSIGNED) YEAR,
        CAST(SUBSTR(year,-4) AS UNSIGNED) START_OF_DECADE,
        CAST(SUBSTR(year,-4) AS UNSIGNED)+9 END_OF_DECADE,
        'Decade of : ' || SUBSTR(year,-4)   DECADE
    FROM
        Movie
    ),
    NUMBER_OF_MOV_BY_YR AS
    (
    SELECT
    COUNT(DISTINCT MID) NUM_OF_MOV,
    CAST(SUBSTR(year,-4) AS UNSIGNED) YEAR
    FROM
        Movie
    GROUP BY
        CAST(SUBSTR(year,-4) AS UNSIGNED)
    ),
    NUM_OF_MOV_IN_DECADE AS 
    (
    SELECT
        SUM(NUM_OF_MOV) TOTAL_MOVIES,
        DY.DECADE
    FROM
        NUMBER_OF_MOV_BY_YR NM,
        DISTINCT_YEARS DY
    WHERE
        NM.YEAR BETWEEN DY.START_OF_DECADE AND DY.END_OF_DECADE
    GROUP BY
        DY.DECADE
    )
    SELECT
        DECADE,
        TOTAL_MOVIES
    FROM
        NUM_OF_MOV_IN_DECADE
    WHERE
        TOTAL_MOVIES = (
            SELECT
                MAX(TOTAL_MOVIES)
            FROM
                NUM_OF_MOV_IN_DECADE
            )
/*
* 8) Find Actors that were never unemployed for more than 3 years.
*
*   Assumtions  :
* 
*   A) I'm considering only people who have worked for more than one year.
*   B) Considering the time period between min and max years of the actor.
*      i.e if the actor has been working from 1990 to 2000 and the actor 
*      acted only in 1990, 1991 1996, 1998 and 2000. Then he is considered as
*      unemployed for more than 3 yrs ( > 3 yrs => atleast 4 years). 
*
*   Logic for solving :
*       Calculate the total num of movies that the actor acted from his min year i.e 1990 to 1991, 
*       let say it's 3 and then calculate the total num of movies he acted from his min year 1990 to 1991+4 (1995)
*       and it comes back as 3 since he hasn't made any movies between 1991 and 1995 , this means that he has been
*       unemployed for more than 3 years (4 years) 1992,1993,1994,1995 , therefore we don't consider him.
*/
WITH
    NUM_OF_MOV_FOR_AN_ACTR_BY_YR AS
    (
        SELECT
            TRIM(MC.PID) PID,
            CAST(SUBSTR(year,-4) AS UNSIGNED) YEAR,
            COUNT(DISTINCT TRIM(M.MID)) NUM_OF_MOV
        FROM
            M_Cast MC,
            Movie M
        WHERE
            TRIM(MC.MID) = TRIM(M.MID) 
        GROUP BY
            TRIM(MC.PID),
            CAST(SUBSTR(year,-4) AS UNSIGNED)
        ORDER BY 
            NUM_OF_MOV DESC
    ),
    ACTRS_FOR_MORE_THAN_ONE_YR AS
    (
        SELECT
            PID,
            COUNT(YEAR) AS NUM_OF_YEARS,
            MIN(YEAR) AS MIN_YEAR,
            MAX(YEAR) AS MAX_YEAR
        FROM
            NUM_OF_MOV_FOR_AN_ACTR_BY_YR
        GROUP BY
            PID
        HAVING
            COUNT(YEAR) > 1
    ),
    NUM_OF_FOR_ACTR_W_MRE_THN_1_YR AS
    (
        SELECT
            NM.PID,
            NM.YEAR,
            NM.YEAR+4 AS YEAR_PLUS_4,
            NM.NUM_OF_MOV,
            AY.MIN_YEAR,
            AY.MAX_YEAR
        FROM
            NUM_OF_MOV_FOR_AN_ACTR_BY_YR NM,
            ACTRS_FOR_MORE_THAN_ONE_YR AY
        WHERE
            NM.PID = AY.PID
    ),
    NUM_OF_MOV_TILL_DATE_BY_ACTOR AS
    (
        SELECT
            NA.PID,
            NY.YEAR,
            SUM(NA.NUM_OF_MOV) AS NUM_OF_MOV_TILL_THAT_YEAR
        FROM
            NUM_OF_FOR_ACTR_W_MRE_THN_1_YR NA,
            NUM_OF_FOR_ACTR_W_MRE_THN_1_YR NY
        WHERE
            NA.PID = NY.PID AND
            NA.YEAR BETWEEN NY.MIN_YEAR AND  NY.YEAR
        GROUP BY
            NA.PID,
            NY.YEAR
    ),
    NUM_OF_MV_BY_ACTR_BY_YR_PLS_4 AS
    (
        SELECT
            NA.PID,
            NY.YEAR,
            SUM(NA.NUM_OF_MOV) AS NUM_OF_MOV_TILL_AS_OF_YR_PLS_4
        FROM
            NUM_OF_FOR_ACTR_W_MRE_THN_1_YR NA,
            NUM_OF_FOR_ACTR_W_MRE_THN_1_YR NY
        WHERE
            NA.PID = NY.PID AND
            NA.YEAR BETWEEN NY.MIN_YEAR AND  NY.YEAR_PLUS_4 AND
            NY.YEAR_PLUS_4 <= NY.MAX_YEAR
        GROUP BY
            NA.PID,
            NY.YEAR
    )
    SELECT
        DISTINCT
        TRIM(P.Name) AS ACTORS_NEVER_UNEMPLOYED_FOR_MORE_THAN_3_YRS
    FROM
        Person P
    WHERE
        TRIM(P.PID) NOT IN 
            (
            SELECT
                DISTINCT
                NMT.PID
            FROM
                NUM_OF_MOV_TILL_DATE_BY_ACTOR NMT,
                NUM_OF_MV_BY_ACTR_BY_YR_PLS_4 NMP
            WHERE
                NMT.PID = NMP.PID AND
                NMT.YEAR = NMP.YEAR AND
                NMT.NUM_OF_MOV_TILL_THAT_YEAR = NMP.NUM_OF_MOV_TILL_AS_OF_YR_PLS_4
            )

/*
* 9. Find all the actors that made more movies with Yash Chopra than any other director.
*/

WITH
    YASH_CHOPRAS_PID AS
    (
        SELECT
            TRIM(P.PID) AS PID
        FROM
            Person P
        WHERE
            Trim(P.Name) = 'Yash Chopra'
    ),
    NUM_OF_MOV_BY_ACTOR_DIRECTOR AS
    (
        SELECT
            TRIM(MC.PID) ACTOR_PID,
            TRIM(MD.PID) DIRECTOR_PID,
            COUNT(DISTINCT TRIM(MD.MID)) AS NUM_OF_MOV
        FROM
            M_Cast MC,
            M_Director MD
        WHERE
            TRIM(MC.MID)= TRIM(MD.MID)
        GROUP BY
            ACTOR_PID,
            DIRECTOR_PID
    ),
    NUM_OF_MOVIES_BY_YC AS
    (
        SELECT
            NM.ACTOR_PID,
            NM.DIRECTOR_PID,
            NM.NUM_OF_MOV NUM_OF_MOV_BY_YC
        FROM
            NUM_OF_MOV_BY_ACTOR_DIRECTOR NM,
            YASH_CHOPRAS_PID YCP
        WHERE
            NM.DIRECTOR_PID = YCP.PID
    ),
    MAX_MOV_BY_OTHER_DIRECTORS AS
    (
        SELECT
            ACTOR_PID,
            MAX(NUM_OF_MOV) MAX_NUM_OF_MOV
        FROM
            NUM_OF_MOV_BY_ACTOR_DIRECTOR NM,
            YASH_CHOPRAS_PID YCP
        WHERE
            NM.DIRECTOR_PID <> YCP.PID 
        GROUP BY
            ACTOR_PID
    ),
    ACTORS_MOV_COMPARISION AS
    (
    SELECT
        NMY.ACTOR_PID,
        CASE WHEN NMY.NUM_OF_MOV_BY_YC > IFNULL(NMO.MAX_NUM_OF_MOV,0) THEN 'Y' ELSE 'N' END MORE_MOV_BY_YC
    FROM
        NUM_OF_MOVIES_BY_YC NMY
        LEFT OUTER JOIN
        MAX_MOV_BY_OTHER_DIRECTORS NMO
        ON
        NMY.ACTOR_PID = NMO.ACTOR_PID 
    )
    SELECT
        DISTINCT
        TRIM(P.Name) ACTOR_NAME
    FROM
        Person P
    WHERE
        TRIM(P.PID) IN (
            SELECT
                DISTINCT
                ACTOR_PID
            FROM
                ACTORS_MOV_COMPARISION
            WHERE
                MORE_MOV_BY_YC = 'Y'
        )

/*
*  10.  The Shahrukh number of an actor is the length of the shortest path 
*       between the actor and Shahrukh Khan in the "co-acting" graph. That 
*       is, Shahrukh Khan has Shahrukh number 0; all actors who acted in 
*       the same film as Shahrukh have Shahrukh number 1; all actors who 
*       acted in the same film as some actor with Shahrukh number 1 have 
*       Shahrukh number 2, etc. Return all actors whose Shahrukh number is 2. 
*/

WITH 
    SHAHRUKH_0 AS
    (
        SELECT
            TRIM(P.PID) PID
        FROM
            Person P
        WHERE
            Trim(P.Name) like '%Shahrukh%'
    ),
    SHAHRUKH_1_MOVIES AS
    (
        SELECT
            DISTINCT
            TRIM(MC.MID) MID,
            S0.PID
        FROM
            M_Cast MC,
            SHAHRUKH_0 S0
        WHERE
            TRIM(MC.PID) = S0.PID
    ),
    SHAHRUKH_1_ACTORS AS
    (
        SELECT
            DISTINCT
            TRIM(MC.PID) PID
        FROM
            M_Cast MC,
            SHAHRUKH_1_MOVIES S1M
        WHERE
            TRIM(MC.MID) = S1M.MID AND
            TRIM(MC.PID) <> S1M.PID
    ),
    SHAHRUKH_2_MOVIES AS
    (
        SELECT
            DISTINCT
            TRIM(MC.MID) MID,
            S1A.PID
        FROM
            M_Cast MC,
            SHAHRUKH_1_ACTORS S1A
        WHERE
            TRIM(MC.PID) = S1A.PID
    )
    SELECT
        DISTINCT
        TRIM(MC.PID) PID,
        TRIM(P.Name) ACTOR_NAME
    FROM
        Person P,
        M_Cast MC,
        SHAHRUKH_2_MOVIES S2M
    WHERE
            TRIM(MC.PID) = TRIM(P.PID) AND
            TRIM(MC.MID) = S2M.MID AND
            TRIM(MC.PID) <> S2M.PID;