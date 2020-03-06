SELECT
  DATE_TRUNC(DATE(COMPLETED_AT), MONTH) AS MONTH,
  TRANSFER_TYPE,
  COUNT(DISTINCT
    CASE
      WHEN IS_NEW_USER IS TRUE THEN USER_ID
  END
    ) AS NEW_USERS,
  COUNT(DISTINCT USER_ID) AS CUMULATIVE_USERS,
  COUNT(DISTINCT TRANSFER_ID) AS TRANSFERS,
  SUM(VOLUME_USD) AS VOLUME_USD,
  SUM(VOLUME_INR) AS VOLUME_INR,
  SUM(VOLUME_GBP) AS VOLUME_GBP,
  SUM(REVENUE_USD) AS REVENUE_USD,
  SUM(REVENUE_INR) AS REVENUE_INR,
  SUM(REVENUE_GBP) AS REVENUE_GBP
FROM (
  SELECT
    USER_ID,
    TRANSFER_ID,
    TRANSFER_TYPE,
    COMPLETED_AT,
    TRANSFER_VALUE AS VOLUME_USD,
    TRANSFER_VALUE * RATE AS VOLUME_GBP,
    TRANSFER_VALUE * INVERSE_RATE AS VOLUME_INR,
    FEE_VALUE AS REVENUE_USD,
    FEE_VALUE * RATE AS REVENUE_GBP,
    FEE_VALUE * INVERSE_RATE AS REVENUE_INR,
    IS_NEW_USER
  FROM (
    WITH
      success_transfers_base AS (
      SELECT
        *
      FROM
        `case_study.transfers`
      LEFT JOIN (
        SELECT
          *
        FROM
          `case_study.transfers_meta`)
      USING
        (TRANSFER_ID)
      LEFT JOIN (
        SELECT
          *
        FROM
          `case_study.users`)
      USING
        (USER_ID)
      WHERE
        TRANSFER_STATE = 'TRANSFERRED'
        AND FLAG_NOT_TEST = 1),
        
        
      usd_to_gbp_conversion AS(
      SELECT
        CURRENCY_DATE,
        SOURCE_CURRENCY,
        TARGET_CURRENCY,
        RATE
      FROM
        `case_study.fx_rates`
      WHERE
        SOURCE_CURRENCY = 'USD'
        AND TARGET_CURRENCY = 'GBP'),
        
        
      gbp_to_inr_conversion AS(
      SELECT
        CURRENCY_DATE,
        SOURCE_CURRENCY,
        TARGET_CURRENCY,
        INVERSE_RAATE AS INVERSE_RATE
      FROM
        `case_study.fx_rates`
      WHERE
        SOURCE_CURRENCY = 'INR'
        AND TARGET_CURRENCY = 'GBP')
        
        
    SELECT
      * EXCEPT(CURRENCY_DATE,
        SOURCE_CURRENCY,
        TARGET_CURRENCY),
      CASE
        WHEN TRANSFER_ID = FIRST_TRANSFER_ID THEN TRUE
      ELSE
      FALSE
    END
      AS IS_NEW_USER
    FROM
      success_transfers_base STB
    LEFT JOIN
      usd_to_gbp_conversion UTG
    ON
      DATE(STB.COMPLETED_AT) = UTG.CURRENCY_DATE
      AND STB.SOURCE_CURRENCY = UTG.SOURCE_CURRENCY
    LEFT JOIN
      gbp_to_inr_conversion GTI
    ON
      DATE(STB.COMPLETED_AT) = GTI.CURRENCY_DATE
      AND STB.TARGET_CURRENCY = GTI.SOURCE_CURRENCY))
GROUP BY
  1,
  2
ORDER BY
  1 DESC
