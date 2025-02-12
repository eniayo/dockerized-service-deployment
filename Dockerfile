# Use an official Node.js image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json ./
RUN npm install

# Copy application files
COPY . .

# Expose the app port
EXPOSE 3001

# Start the app
CMD ["node", "server.js"]

