echo "💧  starting docker..."
docker-machine start default

echo "💧  exporting docker machine environment..."
eval $(docker-machine env default)

echo "💧  cleaning previous vapor-psql dev db..."
docker stop vapor-psql
docker rm vapor-psql

echo "💧  creating vapor-psql dev db..."
docker run --name vapor-psql -e POSTGRES_USER=vapor_username -e POSTGRES_DB=vapor_database -e POSTGRES_PASSWORD=vapor_password -p 5432:5432 -d postgres:latest

echo "💧  generating xcode proj..."
swift package generate-xcodeproj

echo "💧  add the following env variable to Xcode test scheme:"
echo ""
echo "    PSQL_HOSTNAME: `docker-machine ip`"
echo ""

echo "💧  opening xcode..."
open *.xcodeproj