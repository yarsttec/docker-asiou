
$BUILD_DATE = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

docker build `
  -t yarsttec/asiou:7.7-base `
  -f Dockerfile `
  --build-arg BUILD_DATE=$BUILD_DATE `
  .
