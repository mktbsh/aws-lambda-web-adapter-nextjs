ARG NODE_VERSION=18

FROM node:${NODE_VERSION} AS builder
WORKDIR /build
COPY package*.json ./
RUN corepack enable && corepack prepare pnpm@latest --activate && pnpm install
COPY . ./
RUN pnpm run build

# Use a common base image to reduce the cold start time
FROM amazon/aws-lambda-nodejs:${NODE_VERSION}

# Install Lambda Web Adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.7.0 /lambda-adapter /opt/extensions/lambda-adapter
ENV PORT=3000

COPY --from=builder /build/next.config.js ./
COPY --from=builder /build/public ./public
COPY --from=builder /build/.next/static ./.next/static
COPY --from=builder /build/.next/standalone ./

# Changes due to the base image
ENTRYPOINT ["node"]
CMD ["server.js"]