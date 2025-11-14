# Production stage with Caddy
FROM caddy:2-alpine

COPY ./dist /usr/share/caddy
COPY ./Caddyfile /etc/caddy/Caddyfile

EXPOSE 8080