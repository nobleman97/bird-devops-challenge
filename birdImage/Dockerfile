# Build Stage
FROM golang:alpine3.20 AS builder

WORKDIR /app

COPY . .

RUN go build -o getBirdImage

# Second stage
FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/getBirdImage .

EXPOSE 4200

CMD ["./getBirdImage"]
