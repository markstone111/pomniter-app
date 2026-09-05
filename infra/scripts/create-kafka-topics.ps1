# Create Kafka topics for Pomniter event streaming
param(
    [string]$BootstrapServer = "localhost:9092"
)

$topics = @(
    "screenshot.uploaded",
    "screenshot.ocr.completed",
    "screenshot.embedding.completed",
    "screenshot.indexed"
)

Write-Host "Creating Pomniter Kafka Topics on $BootstrapServer..." -ForegroundColor Cyan

foreach ($topic in $topics) {
    docker exec -it pomniter-kafka /opt/kafka/bin/kafka-topics.sh `
        --create --if-not-exists `
        --bootstrap-server $BootstrapServer `
        --partitions 3 `
        --replication-factor 1 `
        --topic $topic
    Write-Host "Created topic: $topic" -ForegroundColor Green
}
