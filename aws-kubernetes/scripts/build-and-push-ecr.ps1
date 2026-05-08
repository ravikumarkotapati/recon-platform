param(
    [string]$AccountId = "860510876120",
    [string]$Region = "ap-southeast-1",
    [string]$Tag = "1.0.1"
)

$registry = "$AccountId.dkr.ecr.$Region.amazonaws.com"

aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $registry

$images = @(
    @{ Name = "recon-producer-app"; Path = "E:\workspace\recon-producer-app" },
    @{ Name = "recon-consumer-app"; Path = "E:\workspace\recon-consumer-app" },
    @{ Name = "recon-dashboard-api"; Path = "E:\workspace\recon-dashboard-api" }
)

foreach ($image in $images) {
    Push-Location $image.Path
    mvn -q -DskipTests package
    docker build -t "$registry/$($image.Name):$Tag" .
    docker push "$registry/$($image.Name):$Tag"
    Pop-Location
}
