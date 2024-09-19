# Build Stage
FROM golang:alpine3.20 AS builder

WORKDIR /app

COPY . .

RUN go build -o getBird

# Second stage
FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/getBird .

EXPOSE 4201

CMD ["./getBird"]
