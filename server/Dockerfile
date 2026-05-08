# =============================================================================
# Stage 1 — deps
# Install only production dependencies in a clean layer.
# Keeping deps in a separate stage means the final image won't carry npm cache
# or any leftover dev tooling.
# =============================================================================
FROM node:20-alpine AS deps

WORKDIR /app

# Copy manifests first so Docker can cache this layer and skip re-installing
# packages when only source files change.
COPY package.json package-lock.json ./

RUN npm ci --omit=dev


# =============================================================================
# Stage 2 — runner (final image)
# Copy only the installed modules + source into a minimal Alpine image.
# =============================================================================
FROM node:20-alpine AS runner

# Use a non-root user for security — never run Node as root in production.
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy pre-built production node_modules from the deps stage.
COPY --from=deps /app/node_modules ./node_modules

# Copy application source code.
COPY . .

# Ensure the uploads directory exists and is owned by the app user.
# This is where Multer writes product images.
RUN mkdir -p uploads && chown -R appuser:appgroup /app

USER appuser

# The API listens on this port (matches PORT in .env / env.js default).
EXPOSE 8000

# Use the npm start script defined in package.json ("node server.js").
CMD ["node", "server.js"]
