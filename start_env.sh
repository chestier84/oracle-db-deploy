#!/bin/bash
cd oracle-db-deploy
docker-compose up -d
sleep 60
docker-compose ps
