FROM maven:3.8.3-adoptopenjdk-8@sha256:460f40e4d6e5f4563907e639ef452ca892e5864faceec698fbab44d1a090a6cd AS builder

ARG VERSION_PARQUET_MR=1.12.2

RUN git clone --depth 1 -b "apache-parquet-${VERSION_PARQUET_MR}" https://github.com/apache/parquet-mr.git

WORKDIR /parquet-mr/parquet-cli

RUN mvn package -B -DskipTests
RUN mvn dependency:copy-dependencies
RUN mkdir /parquet-cli
RUN cp \
    /parquet-mr/parquet-cli/target/parquet-cli-${VERSION_PARQUET_MR}-runtime.jar \
    /parquet-cli/parquet-cli.jar
RUN cp -r \
    /parquet-mr/parquet-cli/target/dependency \
    /parquet-cli

FROM adoptopenjdk/openjdk8:alpine-jre@sha256:748901649a64386943fb8415d672e03645caed15acade660f99b1fff9e4707a4

RUN apk add --no-cache tini

COPY --from=builder /parquet-cli /parquet-cli

ENTRYPOINT ["/sbin/tini", "--", "java", "-cp", "/parquet-cli/*:/parquet-cli/dependency/*", "org.apache.parquet.cli.Main"]
