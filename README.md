<div align="center">
  <img width="200" height="200"
    src="https://cdn.worldvectorlogo.com/logos/circleci.svg">
  <a href="https://github.com/easymetrics">
    <img width="200" height="200" vspace="" hspace="25"
      src="https://cdn.worldvectorlogo.com/logos/easymetrics-inc.svg">
  </a>
  <h1>CircleCI 2.0 OpenJDK 9 Build container</h1>
  <p>Docker Repository for the EasyMetrics OpenJDK 9 CircleCI build Image.<p>
</div>

### Usage
```bash
# config.yml
    docker:
      - image: easymetrics/circleci-gcp-jdk9
```

Essentially it's OpenJDK 9 + Gradle 4 + Google Cloud SDK. The SDK is not initialized in this build, that is done during the CI run using secure environment variables ( see the [gpc docs](https://circleci.com/docs/2.0/google-container-engine/) ).

The container does not have a headless browser configuration
