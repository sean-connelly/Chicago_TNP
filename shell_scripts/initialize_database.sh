#!/bin/bash

psql -U postgres -c 'create database chicago_tnp_data;'

psql -U postgres -d chicago_tnp_data -f setup_files/create_schema.sql;
