# syntax=docker/dockerfile:1

# Build Stage
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build

COPY . /source

WORKDIR /source/src/Chirp.Web

# This is the architecture you're building for, which is passed in by the builder.
# Placing it here allows the previous steps to be cached across architectures.
ARG TARGETARCH

# Build the application.
RUN --mount=type=cache,id=nuget,target=/root/.nuget/packages \
    dotnet publish -a ${TARGETARCH/amd64/x64} --use-current-runtime --self-contained false -o /app

# Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS final
WORKDIR /app

# Install tzdata for time zone handling
RUN apk add --no-cache tzdata

# Set the time zone to 'Europe/Copenhagen' (or another timezone if needed)
ENV TZ=Europe/Copenhagen

# Copy everything needed to run the app from the build stage
COPY --from=build /app .

# Switch to a non-privileged user (defined in the base image)
USER $APP_UID

# Set entry point for the application
ENTRYPOINT ["dotnet", "Chirp.Web.dll"]
