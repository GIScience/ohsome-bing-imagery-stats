DESCRIBE
SELECT *
FROM read_parquet('/data/ohsome-planet/global/contributions/*/[nw]*.parquet')
LIMIT 1;


DROP TABLE IF EXISTS contributions;
CREATE TABLE contributions AS
  SELECT
  date_trunc('month', valid_from) as month,
  user.id as user_id,
  changeset.id as changeset_id,
  CASE
      WHEN changeset.tags['created_by'] ILIKE '%JOSM%' then 'JOSM'
      WHEN changeset.tags['created_by'] ILIKE '%RapiD%' then 'RapiD'
      WHEN changeset.tags['created_by'] ILIKE '%iD%' then 'iD'
      WHEN changeset.tags['created_by'] ILIKE '%StreetComplete%' then 'StreetComplete'
      ELSE 'other'
  END as editor,
  CASE
      WHEN changeset.tags['source'] ILIKE '%bing%' OR changeset.tags['imagery'] ILIKE '%bing%'  THEN 1
      ELSE 0
  END as bing_imagery,
  CASE
      WHEN changeset.tags['source'] ILIKE '%bing%' THEN 1
      WHEN changeset.tags['imagery'] ILIKE '%bing%'  THEN 1
      WHEN changeset.tags['imagery'] ILIKE '%aerial imagery%'  THEN 1
      WHEN changeset.tags['source'] ILIKE '%aerial imagery%'  THEN 1
      ELSE 0
  END as bing_imagery_2,
  CASE
      WHEN changeset.tags['source'] ILIKE '%esri%' or changeset.tags['imagery'] ILIKE '%esri%' THEN 1
      ELSE 0
  END as esri_imagery,
  CASE
      WHEN changeset.tags['source'] ILIKE '%maxar%' OR changeset.tags['imagery'] ILIKE '%maxar%' THEN 1
      ELSE 0
  END as maxar_imagery,
  CASE
      WHEN changeset.tags['source'] ILIKE '%mapillary%' OR changeset.tags['imagery'] ILIKE '%mapillary%' THEN 1
      ELSE 0
  END as mapillary_imagery,
  CASE
      WHEN changeset.tags['source'] ILIKE '%mapbox%' OR changeset.tags['imagery'] ILIKE '%mapbox%' THEN 1
      ELSE 0
  END as mapbox_imagery,
  changeset.tags['source'] as source,
  changeset.tags['created_by'] as created_by,
  countries,
  FROM read_parquet('/data/ohsome-planet/global/contributions/*/[nw]*.parquet')
  WHERE 1=1
    AND valid_from >= '2020-01-01'
  ;


------------------------------------------------------------
-- overall stats per month
-------------------------------------------------------------
DROP TABLE IF EXISTS imagery_stats_per_month;
CREATE TABLE imagery_stats_per_month AS
(
WITH overall_stats AS (
    SELECT
        month,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    GROUP BY month
    ORDER BY month
),
bing_stats AS (
    SELECT
        month,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    WHERE bing_imagery = 1 or bing_imagery_2
    GROUP BY month
    ORDER BY month
),
esri_stats AS (
    SELECT
        month,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    WHERE esri_imagery = 1
    GROUP BY month
    ORDER BY month
),
maxar_stats AS (
    SELECT
        month,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    WHERE maxar_imagery = 1
    GROUP BY month
    ORDER BY month
),
mapbox_stats AS (
    SELECT
        month,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    WHERE mapbox_imagery = 1
    GROUP BY month
    ORDER BY month
),
mapillary_stats AS (
    SELECT
        month,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    WHERE mapillary_imagery = 1
    GROUP BY month
    ORDER BY month
)
SELECT
  a.*,
  b.n_edits_million as bing_n_edits_million,
  b.n_users as bing_n_users,
  c.n_edits_million as esri_n_edits_million,
  c.n_users as esri_n_users,
  d.n_edits_million as maxar_n_edits_million,
  d.n_users as maxar_n_users,
  e.n_edits_million as mapbox_n_edits_million,
  e.n_users as mapbox_n_users,
  f.n_edits_million as mapillary_n_edits_million,
  f.n_users as mapillary_n_users
FROM overall_stats a
LEFT JOIN bing_stats b ON (a.month = b.month)
LEFT JOIN esri_stats c ON (a.month = c.month)
LEFT JOIN maxar_stats d ON (a.month = d.month)
LEFT JOIN mapbox_stats e ON (a.month = e.month)
LEFT JOIN mapillary_stats f ON (a.month = f.month)
);

SELECT *
FROM imagery_stats_per_month;

COPY imagery_stats_per_month
TO '~/imagery_stats_per_month.csv';


-----------------------------------------------------------------------
-- stats per country
-----------------------------------------------------------------------
DROP TABLE IF EXISTS imagery_stats_per_country;
CREATE TABLE imagery_stats_per_country AS
(
WITH overall_stats AS (
    SELECT
        countries,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    GROUP BY countries
    ORDER BY n_edits_million DESC
),
bing_stats AS (
    SELECT
        countries,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    WHERE bing_imagery = 1 or bing_imagery_2
    GROUP BY countries
    ORDER BY n_edits_million DESC
),
esri_stats AS (
    SELECT
        countries,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    WHERE esri_imagery = 1
    GROUP BY countries
    ORDER BY n_edits_million DESC
),
maxar_stats AS (
    SELECT
        countries,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    WHERE maxar_imagery = 1
    GROUP BY countries
    ORDER BY n_edits_million DESC
),
mapbox_stats AS (
    SELECT
        countries,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    WHERE mapbox_imagery = 1
    GROUP BY countries
    ORDER BY n_edits_million DESC
),
mapillary_stats AS (
    SELECT
        countries,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    WHERE mapillary_imagery = 1
    GROUP BY countries
    ORDER BY n_edits_million DESC
)
SELECT
  a.countries[1] as country,
  a.n_edits_million,
  a.n_users,
  b.n_edits_million as bing_n_edits_million,
  b.n_edits_million / a.n_edits_million as bing_n_edits_proportion,
  b.n_users as bing_n_users,
  b.n_users / a.n_users as bing_n_users_proportion,
  c.n_edits_million as esri_n_edits_million,
  c.n_users as esri_n_users,
  d.n_edits_million as maxar_n_edits_million,
  d.n_users as maxar_n_users,
  e.n_edits_million as mapbox_n_edits_million,
  e.n_users as mapbox_n_users,
  f.n_edits_million as mapillary_n_edits_million,
  f.n_users as mapillary_n_users
FROM overall_stats a
LEFT JOIN bing_stats b ON (a.countries = b.countries)
LEFT JOIN esri_stats c ON (a.countries = c.countries)
LEFT JOIN maxar_stats d ON (a.countries = d.countries)
LEFT JOIN mapbox_stats e ON (a.countries = e.countries)
LEFT JOIN mapillary_stats f ON (a.countries = f.countries)
WHERE len(a.countries) = 1
ORDER BY a.countries
);

SELECT *
FROM imagery_stats_per_country
ORDER BY bing_n_edits_proportion DESC;

COPY imagery_stats_per_country
TO '~/imagery_stats_per_country.csv';


COPY
(
with countries as (
    SELECT
     iso as country,
     ST_geomFromText(WKT) as geometry
    FROM read_csv('/data/ohsome-planet/world_boundaries_overture_iso_a3.csv', max_line_size=10000000)
)
SELECT
    a.*,
    b.geometry
FROM imagery_stats_per_country a
LEFT JOIN countries b ON (a.country = b.country)
) TO '~/imagery_stats_per_country.parquet';


COPY
(
with countries as (
    SELECT
     iso as country,
     ST_geomFromText(WKT) as geometry
    FROM read_csv('/data/ohsome-planet/world_boundaries_overture_iso_a3.csv', max_line_size=10000000)
)
SELECT
    a.*,
    ST_pointonsurface(b.geometry) as geometry
FROM imagery_stats_per_country a
LEFT JOIN countries b ON (a.country = b.country)
) TO '~/imagery_stats_per_country_point_on_surface.parquet';


SELECT
  country,
  bing_n_users,
  round(bing_n_users_proportion, 2) as bing_n_users_proportion,
  round(bing_n_edits_million, 2) as bing_n_edits_million,
  round(bing_n_edits_proportion, 2) as bing_n_edits_proportion
FROM imagery_stats_per_country
WHERE 1=1
    AND bing_n_edits_proportion > 0.25
ORDER BY bing_n_edits_million DESC
LIMIT 25

/*
┌─────────┬──────────────┬─────────────────────────┬──────────────────────┬─────────────────────────┐
│ country │ bing_n_users │ bing_n_users_proportion │ bing_n_edits_million │ bing_n_edits_proportion │
│ varchar │    int64     │         double          │        double        │         double          │
├─────────┼──────────────┼─────────────────────────┼──────────────────────┼─────────────────────────┤
│ GBR     │         5162 │                    0.13 │                18.11 │                    0.35 │
│ NGA     │         1946 │                    0.08 │                10.69 │                    0.49 │
│ DZA     │          646 │                    0.15 │                 3.72 │                    0.59 │
│ KEN     │         2224 │                    0.16 │                 3.26 │                     0.4 │
│ IRL     │          752 │                    0.15 │                 3.14 │                    0.33 │
│ BGD     │         1186 │                    0.07 │                 1.85 │                    0.32 │
│ THA     │         1158 │                    0.12 │                 1.66 │                    0.29 │
│ PRY     │          732 │                    0.27 │                 1.15 │                    0.31 │
│ MOZ     │          959 │                    0.12 │                 1.05 │                     0.3 │
│ MLI     │          719 │                    0.14 │                 1.02 │                    0.27 │
│ LKA     │         1418 │                    0.18 │                 0.95 │                    0.34 │
│ CMR     │          723 │                     0.2 │                 0.93 │                    0.32 │
│ SEN     │          636 │                    0.18 │                  0.9 │                    0.45 │
│ GHA     │         1254 │                    0.29 │                 0.89 │                    0.36 │
│ BIH     │          420 │                    0.17 │                  0.8 │                    0.31 │
│ PAK     │          795 │                    0.12 │                 0.74 │                    0.25 │
│ NIC     │          333 │                    0.06 │                 0.65 │                    0.52 │
│ BWA     │          575 │                    0.05 │                 0.62 │                    0.34 │
│ TGO     │          423 │                    0.15 │                 0.58 │                    0.41 │
│ CIV     │          480 │                    0.19 │                  0.5 │                    0.34 │
│ GIN     │          511 │                    0.25 │                  0.5 │                     0.5 │
│ XG      │          111 │                    0.17 │                 0.48 │                    0.73 │
│ LBN     │          510 │                    0.09 │                 0.44 │                    0.27 │
│ PRK     │          229 │                    0.22 │                  0.4 │                    0.26 │
│ GAB     │          183 │                    0.22 │                 0.37 │                    0.64 │
├─────────┴──────────────┴─────────────────────────┴──────────────────────┴─────────────────────────┤
│ 25 rows                                                                                 5 columns │
└───────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

-----------------------------------------------------------------------
-- Which editor is used to map from Bing imagery?
-----------------------------------------------------------------------
DROP TABLE IF EXISTS imagery_stats_per_editor;
CREATE TABLE imagery_stats_per_editor AS
WITH overall_stats AS (
    SELECT
        editor,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    GROUP BY editor
    ORDER BY editor
),
bing_stats AS (
    SELECT
        editor,
        count(*) / 10**6 as n_edits_million,
        count(distinct user_id) as n_users
    FROM contributions
    WHERE bing_imagery = 1 or bing_imagery_2
    GROUP BY editor
    ORDER BY editor
)
SELECT
  a.*,
  b.n_edits_million as bing_n_edits_million,
  b.n_edits_million / a.n_edits_million as bing_n_edits_proportion,
  b.n_users as bing_n_users,
  b.n_users / a.n_users as bing_n_users_proportion,
FROM overall_stats a
LEFT JOIN bing_stats b ON (a.editor = b.editor)

COPY imagery_stats_per_editor
TO '~/imagery_stats_per_editor.csv';
