CREATE DATABASE sampledb;
\connect sampledb;
CREATE USER existing WITH PASSWORD 'test123';
CREATE SCHEMA existing;
CREATE USER myschema WITH PASSWORD 'test123';
CREATE SCHEMA myschema;
