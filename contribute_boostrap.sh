echo "💧  generating xcode proj..."
swift package generate-xcodeproj

echo "💧  opening xcode..."
open *.xcodeproj

echo "💧  starting docker..."
docker-compose up psql-10
