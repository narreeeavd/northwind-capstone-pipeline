-- 01_create_db_and_schemas.sql
-- Creates the analytical database and the two isolated schemas.
-- NOTE: in MySQL a "schema" is a synonym for a "database", so `stg` and `dw`
-- are two physically separate databases next to the project database.

CREATE DATABASE IF NOT EXISTS northwind_warehouse;

CREATE SCHEMA IF NOT EXISTS stg;   -- raw 1:1 staging tables

CREATE SCHEMA IF NOT EXISTS dw;    -- star schema (fact + dimensions)
