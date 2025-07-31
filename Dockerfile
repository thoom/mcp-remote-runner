# Use a slim, recent LTS version of Node.js as recommended by mcp-remote docs (Node 18+).
# Alpine base image for a smaller footprint.
FROM node:22-alpine

# Install 'tini' and 'mcp-remote'.
# The 'node' user already exists in the base image.
# This provides a consistent /home/node directory.
RUN apk add --no-cache tini && \
    npm install -g mcp-remote && \
    chown -R node:node /usr/local/lib/node_modules && \
    chown -R node:node /usr/local/bin

# Copy the entrypoint script and tools, make them executable (do this as root)
COPY entrypoint.sh /home/node/entrypoint.sh
COPY filter-tools.js /home/node/filter-tools.js
COPY list-tools.js /home/node/list-tools.js
RUN chmod +x /home/node/entrypoint.sh /home/node/filter-tools.js /home/node/list-tools.js && \
    chown node:node /home/node/entrypoint.sh /home/node/filter-tools.js /home/node/list-tools.js

# Switch to the non-root user and set the home directory environment variable.
USER node
ENV HOME=/home/node
WORKDIR /home/node

# Use tini as the entrypoint to manage the wrapper script process.
ENTRYPOINT ["/sbin/tini", "--", "./entrypoint.sh"]